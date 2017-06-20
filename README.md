# Scheduled

A simple task scheduler, akin to ClockWork or Rufus Scheduler.

## Project Goals

* Absolutely no dependency on ActiveSupport
* Very small dependency tree
* Framework agnostic
* No built-in daemonization
* No scheduling DSL

## Installation

Add this line to your application's Gemfile:

```ruby
gem "scheduled"
```

And then execute:

    $ bundle

Or install it yourself as:

    $ gem install scheduled

## Usage

### Defining tasks

Tasks are defined by calling `Scheduled.every` with an interval and a block to execute.
The interval can be a basic Integer to represent seconds, or a callable object that receives
the current Job.

If the callable object returns a truthy value, the block is executed.

```ruby
require "scheduled"

# Called every 60 seconds
Scheduled.every(60) { do_work } # Perform some job

# Using a cronline
Scheduled.every("* * * * *") { do_work }

two_hours_from_last_run = ->(job) do
  Time.now - job.last_run >= 60*60*2
end
Scheduled.every(two_hours_from_last_run) { puts "Updating" }

# Run the scheduler
Scheduled.wait
```

### Running the scheduler

Provided your schedule file ends with a call to `Scheduled.wait`, just run it
as any other Ruby script.

    ruby schedule.rb

### Quick Returning Tasks

Scheduled works best if you schedule the tasks into a long-running queue, such as
Backburner or Sidekiq.

## Contributing

Bug reports and pull requests are welcome on GitHub at https://github.com/adam12/scheduled.

I love pull requests! If you fork this project and modify it, please ping me to see
if your changes can be incorporated back into this project.

That said, if your feature idea is nontrivial, you should probably open an issue to
[discuss it](http://www.igvita.com/2011/12/19/dont-push-your-pull-requests/)
before attempting a pull request.

## License

The gem is available as open source under the terms of the [MIT License](http://opensource.org/licenses/MIT).
