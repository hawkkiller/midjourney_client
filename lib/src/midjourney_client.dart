import 'package:meta/meta.dart';
import 'package:midjourney_client/src/midjourney_api.dart';

class Midjourney {
  Midjourney({
    required this.serverId,
    required this.channelId,
    required this.token,
    this.isDebug = false,
    @visibleForTesting MidjourneyApi? api,
  }) : _api = api ?? MidjourneyApiDiscordImpl();

  /// The server id of the server what the client should use.
  final int serverId;

  /// The channel id of the channel inside [serverId] what the client should use.
  final int channelId;

  /// The token of the client.
  final String token;

  /// Whether to log debug messages.
  final bool isDebug;

  /// The api to use.
  final MidjourneyApi _api;

  Future<void> imagine(
    String prompt, {
    bool isDebug = false,
  }) =>
      _api.imagine(
        prompt,
        isDebug: isDebug || this.isDebug,
      );
}
