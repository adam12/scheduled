#!/usr/bin/env ruby -w
require "scheduled"

Scheduled.every(5) { puts "Running", Time.now }

two_hours_from_last_run = ->(job) do
  Time.now - job.last_run >= 60*60*2
end
Scheduled.every(two_hours_from_last_run) { puts "Updating" }

Scheduled.every("* * * * *") { puts "Cron" }

Scheduled.wait
