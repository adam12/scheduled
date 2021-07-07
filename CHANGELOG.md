# Changelog

## master
- `Scheduled` is no longer an includable module. The class interface is the only
  interface.
- A default `Logger` is provided but is silent by default.
- Scheduling events are logged at the `debug` level.
- Cron-style tasks use Integers when having their next
  tick scheduled (instead of Floats).
- Cron-style tasks have a minimum 1 second next-tick. They
  should never be scheduled within the same second that
  they originally ran.
- Raised exceptions are re-raised in new `Thread`. This is
  to work around `concurrent-ruby` wanting to swallow exceptions.
- Logger without `progname=` method is no longer a failure.
- Job blocks are evaluated inside their own context with a logger available
  to them.

## 0.1.0 (2017-06-20)
- Initial release

