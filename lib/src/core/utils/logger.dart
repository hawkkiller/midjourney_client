import 'dart:developer';

import 'package:meta/meta.dart';

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

@internal
mixin MLogger {
  /// The log level to use.
  static MLoggerLevel level = MLoggerLevel.info;

  static void d(Object obj) {
    if (level.isDebug) {
      log(
        obj.toString(),
        name: 'DEBUG',
        time: DateTime.now(),
      );
    }
  }

  static void i(Object obj) {
    if (level.isInfo) {
      log(
        obj.toString(),
        name: 'INFO',
        time: DateTime.now(),
      );
    }
  }

  static void w(
    Object obj, [
    StackTrace? stackTrace,
  ]) {
    if (level.isWarning) {
      log(
        obj.toString(),
        name: 'WARNING',
        stackTrace: stackTrace,
        time: DateTime.now(),
      );
    }
  }

  static void e(
    Object obj, [
    StackTrace? stackTrace,
  ]) {
    if (level.isError) {
      log(
        obj.toString(),
        name: 'ERROR',
        stackTrace: stackTrace,
        time: DateTime.now(),
      );
    }
  }

  static void v(Object obj) {
    if (level.isVerbose) {
      log(
        obj.toString(),
        name: 'VERBOSE',
        time: DateTime.now(),
      );
    }
  }
}
