abstract interface class DiscordException implements Exception {
  /// Create a new [DiscordException] with the given [message].
  factory DiscordException(String message) => _DiscordException(message);

  /// The error message.
  String get message;
}

class _DiscordException implements DiscordException {
  _DiscordException(this.message);

  @override
  final String message;

  @override
  String toString() => 'DiscordException: $message';
}
