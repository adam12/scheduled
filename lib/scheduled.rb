# frozen_string_literal: true

require "logger"
require "concurrent"
require "scheduled/cron_parser"

module Scheduled
  Job = Struct.new(:last_run)

  module ClassMethods
    attr_writer :logger

    def logger
      @logger ||= Logger.new($stdout, level: :info)
    end

    def every(interval, name: nil, &block)
      logger = logger_for_task(name, block)

      rescued_block = ->() do
        begin
          block.call
        rescue Exception => e
          Thread.new { raise e }
        end
      end

      if interval.is_a?(Integer)
        logger.debug { "Running every #{interval} seconds" }

        task = Concurrent::TimerTask.new(execution_interval: interval, run_now: true) do
          rescued_block.call
        end

        task.execute

      elsif interval.is_a?(String)
        run = ->() {
          now = Time.now
          parsed_cron = CronParser.new(interval)
          next_tick_delay = (parsed_cron.next(now) - now).ceil

          logger.debug { "Next run at #{now + next_tick_delay} (tick delay of #{next_tick_delay})" }

          task = Concurrent::ScheduledTask.execute(next_tick_delay) do
            rescued_block.call
            run.call
          end

          task.execute
        }

        run.call

      elsif interval.respond_to?(:call)
        job = Job.new

        task = Concurrent::TimerTask.new(execution_interval: 1, run_now: true) do |timer_task|
          case interval.call(job)
          when true
            rescued_block.call

            job.last_run = Time.now
          when :cancel
            logger.debug { "Received :cancel. Shutting down." }
            timer_task.shutdown
          end
        end

        task.execute
      else
        raise ArgumentError, "Unsupported value for interval"
      end
    end

    def wait
      trap("INT") { exit }

      loop do
        sleep 1
      end
    end

    private

    def logger_for_task(name, block)
      return logger if name == false

      name ||= block_name(block)
      logger = self.logger.dup
      logger.progname = name
      logger
    end

    # Generate name for block
    def block_name(block)
      file, line = block.source_location
      "#{file}:#{line}"
    end 
  end

  extend ClassMethods
end
