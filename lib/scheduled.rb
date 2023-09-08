# frozen_string_literal: true

require "logger"
require "concurrent"
require "scheduled/cron_parser"
require "scheduled/instrumenters"

##
# Schedule jobs to run at specific intervals.
#
module Scheduled
  # @api private
  Job = Struct.new(:last_run)

  # Context the job is run in
  # @api private
  Context = Struct.new(:logger)

  # Default task logger implementation
  DEFAULT_TASK_LOGGER = ->(logger, name) {
    logger = logger.dup
    logger.progname = name if logger.respond_to?(:progname=)
    logger
  }
  private_constant :DEFAULT_TASK_LOGGER

  @task_logger = DEFAULT_TASK_LOGGER
  @logger = Logger.new($stdout, level: :info)
  @instrumenter = Instrumenters::Noop

  class << self
    # An object that when called creates a logger for the provided task
    #
    # @return [#call(original_logger, task_name)]
    #   a callable object that returns a a +Logger+ like instance which responds to +info+ and +debug+
    # @example
    #   Scheduled.task_logger = ->(original_logger, task_name) {
    #     logger = original_logger.dup
    #     logger.progname = task_name
    #     logger
    #   }
    attr_accessor :task_logger

    # @return [#info, #debug]
    #   a +Logger+ like instance which responds to +info+ and +debug+
    attr_accessor :logger

    # @return [#instrument]
    #   an +ActiveSupport::Notifications+ like object which responds to +instrument+
    attr_accessor :instrumenter

    # An object that responds to +call+ and receives an exception as an argument.
    attr_accessor :error_notifier

    # Create task to run every interval.
    #
    # @param interval [Integer, String, #call]
    #   Interval to perform task.
    #
    #   When provided as an +Integer+, is the number of seconds between task runs.
    #
    #   When provided as a +String+, is a cron-formatted interval line.
    #
    #   When provided as an object that responds to +#call+, will run when truthy.
    #
    # @param name [String, false]
    #   Name of task, used during logging. Will use block location and line number by
    #   default. Use +false+ to prevent a name being automatically assigned.
    #
    # @return [void]
    #
    # @example Run every 60 seconds
    #   Scheduled.every(60) { puts "Running every 60 seconds" }
    #
    # @example Run every day at 9:10 AM
    #   Scheduled.every("10 9 * * *") { puts "Performing billing" }
    #
    def every(interval, name: nil, &block)
      name ||= block_name(block)
      logger = logger_for_task(name, block)
      context = Context.new(logger)

      rescued_block = ->() do
        instrumenter.instrument("scheduled.run", {name: name}) do |payload|
          begin
            result = context.instance_eval(&block)
            payload[:result] = result
            result
          rescue => e
            payload[:exception] = [e.class.to_s, e.message]
            payload[:exception_object] = e

            if error_notifier
              error_notifier.call(e)
            end
          end
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
          next_tick_delay = [1, (parsed_cron.next(now) - now).ceil].max

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

    # Run task scheduler indefinitely.
    #
    # @return [void]
    def wait
      trap("INT") { exit }

      loop do
        sleep 1
      end
    end

    private

    # Build a logger for the current task
    # @api private
    def logger_for_task(name, block)
      return logger if name == false

      task_logger.call(logger, name)
    end

    # Generate name for block
    # @api private
    def block_name(block)
      file, line = block.source_location
      "#{file}:#{line}"
    end 
  end

  Scheduled.error_notifier = proc do |error|
    $stderr.puts error.full_message
  end
end
