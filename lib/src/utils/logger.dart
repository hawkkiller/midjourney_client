import 'dart:async';

final class MLoggerMessage {
  const MLoggerMessage({
    required this.message,
    required this.level,
    required this.timestamp,
    this.stackTrace,
    this.error,
  });

  final Object message;
  final MLoggerLevel level;
  final DateTime timestamp;
  final StackTrace? stackTrace;
  final Object? error;
}

enum MLoggerLevel implements Comparable<MLoggerLevel> {
  /// show all messages
  verbose(200),

  /// show debug messages and above
  debug(400),

  /// show info messages and above
  info(600),

  /// show warning messages and above
  warning(800),

  /// show error messages and above
  error(1000);

  const MLoggerLevel(this.level);

  final int level;

  bool operator >(MLoggerLevel other) => level > other.level;

  bool operator >=(MLoggerLevel other) => level >= other.level;

  bool operator <(MLoggerLevel other) => level < other.level;

  bool operator <=(MLoggerLevel other) => level <= other.level;

  @override
  int compareTo(MLoggerLevel other) => level.compareTo(other.level);

  bool get isVerbose => switch (this) {
        >= MLoggerLevel.verbose => true,
        _ => false,
      };

  bool get isDebug => switch (this) {
        >= MLoggerLevel.debug => true,
        _ => false,
      };

  bool get isInfo => switch (this) {
        >= MLoggerLevel.info => true,
        _ => false,
      };

  bool get isWarning => switch (this) {
        >= MLoggerLevel.warning => true,
        _ => false,
      };

  bool get isError => switch (this) {
        >= MLoggerLevel.error => true,
        _ => false,
      };

  @override
  String toString() => switch (this) {
        MLoggerLevel.verbose => 'VERBOSE',
        MLoggerLevel.debug => 'DEBUG',
        MLoggerLevel.info => 'INFO',
        MLoggerLevel.warning => 'WARNING',
        MLoggerLevel.error => 'ERROR',
      };
}

/// The logger which is used by the Midjourney.
///
/// This class implements Singleton pattern and is used
/// throughout the library.
final class MLogger {
  MLogger._internal();

  /// The instance of the logger.
  static MLogger get instance => _instance;

  static final MLogger _instance = MLogger._internal();

  /// The log level to use.
  ///
  /// Alter this if you need more or less logs.
  static MLoggerLevel level = MLoggerLevel.info;

  /// Whether to print the logs to the console.
  ///
  /// This is useful for debugging.
  static bool printToConsole = true;

  /// The stream of messages.
  Stream<MLoggerMessage> get stream => _controller.stream;

  /// Permanent controller that is used to stream the messages.
  final _controller = StreamController<MLoggerMessage>.broadcast();

  /// Log a verbose message.
  void v(
    Object message, {
    StackTrace? stackTrace,
    Object? error,
  }) {
    _log(
      message,
      level: MLoggerLevel.verbose,
      stackTrace: stackTrace,
      error: error,
    );
  }

  /// Log a debug message.
  void d(
    Object message, {
    StackTrace? stackTrace,
    Object? error,
  }) {
    _log(
      message,
      level: MLoggerLevel.debug,
      stackTrace: stackTrace,
      error: error,
    );
  }

  /// Log an info message.
  void i(
    Object message, {
    StackTrace? stackTrace,
    Object? error,
  }) {
    _log(
      message,
      level: MLoggerLevel.info,
      stackTrace: stackTrace,
      error: error,
    );
  }

  /// Log a warning message.
  void w(
    Object message, {
    StackTrace? stackTrace,
    Object? error,
  }) {
    _log(
      message,
      level: MLoggerLevel.warning,
      stackTrace: stackTrace,
      error: error,
    );
  }

  /// Log an error message.
  void e(
    Object message, {
    StackTrace? stackTrace,
    Object? error,
  }) {
    _log(
      message,
      level: MLoggerLevel.error,
      stackTrace: stackTrace,
      error: error,
    );
  }

  void _log(
    Object message, {
    required MLoggerLevel level,
    StackTrace? stackTrace,
    Object? error,
  }) {
    _controller.add(
      MLoggerMessage(
        message: message,
        level: level,
        timestamp: DateTime.now(),
        stackTrace: stackTrace,
        error: error,
      ),
    );

    if (printToConsole && level >= MLogger.level) {
      final buf = StringBuffer()
        ..write(level.toString())
        ..write(': ')
        ..write(message);

      if (stackTrace != null) {
        buf
          ..writeln()
          ..write(stackTrace);
      }

      if (error != null) {
        buf
          ..writeln()
          ..write(error);
      }

      Zone.current.print(buf.toString());
    }
  }
}
