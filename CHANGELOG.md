# Changelog

## master

## 0.2.0 (2023-09-09)
- `Scheduled` is no longer an includable module. The class interface is the only
  interface.
- A default `Logger` is provided but is silent by default.
- Scheduling events are logged at the `debug` level.
- Cron-style tasks use Integers when having their next
  tick scheduled (instead of Floats).
- Cron-style tasks have a minimum 1 second next-tick. They
  should never be scheduled within the same second that
  they originally ran.
- Logger without `progname=` method is no longer a failure.
- Job blocks are evaluated inside their own context with a logger available
  to them.
- Job execution is instrumented using an `ActiveSupport::Notifications` style of interface.
- No longer rescue `Exception` class
- Customizable error notifier hook called when exceptions are rescued

## 0.1.0 (2017-06-20)
- Initial release

