# frozen_string_literal: true
require "concurrent"
require "scheduled/cron_parser"

module Scheduled
  Job = Struct.new(:last_run)

  module_function

  def every(interval, &block)
    rescued_block = ->() do
      begin
        block.call
      rescue Exception => e
        Thread.new { raise e }
      end
    end

    if interval.is_a?(Integer)
      task = Concurrent::TimerTask.new(execution_interval: interval, run_now: true) do
        rescued_block.call
      end

      task.execute

    elsif interval.is_a?(String)
      run = ->() {
        parsed_cron = CronParser.new(interval)
        next_tick_delay = parsed_cron.next(Time.now) - Time.now

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
end
