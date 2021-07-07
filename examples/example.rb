#!/usr/bin/env ruby -w
require "scheduled"

Scheduled.logger.level = :debug
Scheduled.task_logger = ->(logger, name) {
  logger = logger.dup
  logger.progname = name
  logger
}

Scheduled.every(5) { logger.info "Running: #{Time.now}" }

two_hours_from_last_run = ->(job) do
  Time.now - job.last_run >= 60*60*2
end
Scheduled.every(two_hours_from_last_run) { puts "Updating" }

Scheduled.every("* * * * *") { puts "Cron" }

Scheduled.wait
