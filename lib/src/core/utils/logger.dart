import 'package:l/l.dart';

enum MLoggerLevel {
  /// show all messages
  verbose,

  /// show debug messages and above
  debug,

  /// show info messages and above
  info,

  /// show warning messages and above
  warning,

  /// show error messages and above
  error;

  bool get isVerbose => switch (this) {
        MLoggerLevel.verbose => true,
        _ => false,
      };

  bool get isDebug => switch (this) {
        MLoggerLevel.verbose => true,
        MLoggerLevel.debug => true,
        _ => false,
      };

  bool get isInfo => switch (this) {
        MLoggerLevel.verbose => true,
        MLoggerLevel.debug => true,
        MLoggerLevel.info => true,
        _ => false,
      };

  bool get isWarning => switch (this) {
        MLoggerLevel.verbose => true,
        MLoggerLevel.debug => true,
        MLoggerLevel.info => true,
        MLoggerLevel.warning => true,
        _ => false,
      };

  bool get isError => switch (this) {
        _ => true,
      };
}

mixin MLogger {
  /// The log level to use.
  static MLoggerLevel level = MLoggerLevel.info;

  static void d(Object obj) {
    if (level.isDebug) {
      l.d(obj);
    }
  }

  static void i(Object obj) {
    if (level.isInfo) {
      l.i(obj);
    }
  }

  static void w(
    Object obj, [
    StackTrace? stackTrace,
  ]) {
    if (level.isWarning) {
      l.w(obj, stackTrace ?? StackTrace.current);
    }
  }

  static void e(
    Object obj, [
    StackTrace? stackTrace,
  ]) {
    if (level.isError) {
      l.e(obj, stackTrace ?? StackTrace.current);
    }
  }

  static void v(Object obj) {
    if (level.isVerbose) {
      l.v(obj);
    }
  }
}
