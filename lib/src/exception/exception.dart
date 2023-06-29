sealed class MidjourneyException implements Exception {
  /// Create a new [MidjourneyException] with the given [message].
  factory MidjourneyException(String message) => _MidjourneyException(message);

  /// The error message.
  String get message;
}

final class _MidjourneyException implements MidjourneyException {
  _MidjourneyException(this.message);

  @override
  final String message;

  @override
  String toString() => 'MidjourneyException: $message';
}

final class NotInitializedException implements MidjourneyException {
  const NotInitializedException();

  @override
  String get message => 'Midjourney is not initialized';

  @override
  String toString() => 'MidjourneyNotInitializedException: $message';
}

final class InteractionException implements MidjourneyException {
  const InteractionException({
    required this.code,
    required this.message,
  });

  /// The error code.
  final int code;

  /// The error message.
  @override
  final String message;

  @override
  String toString() => 'MidjourneyInteractionException: $message';
}
