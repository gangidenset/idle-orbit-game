import 'dart:developer' as developer;

/// Minimal logger. Errors are always logged (never swallowed silently);
/// a crash reporter (e.g. Crashlytics) can be attached via [onError].
class Logger {
  void Function(Object error, StackTrace? stack, String message)? onError;

  void info(String message) => developer.log(message, name: 'IdleOrbit');

  void warn(String message) => developer.log(message, name: 'IdleOrbit', level: 900);

  void error(String message, [Object? error, StackTrace? stack]) {
    developer.log(message,
        name: 'IdleOrbit', level: 1000, error: error, stackTrace: stack);
    if (error != null) onError?.call(error, stack, message);
  }
}

final log = Logger();
