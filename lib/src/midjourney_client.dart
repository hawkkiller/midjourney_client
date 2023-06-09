import 'package:meta/meta.dart';
import 'package:midjourney_client/src/midjourney_api.dart';
import 'package:midjourney_client/src/model/midjourney_config.dart';

class Midjourney {
  Midjourney({
    /// The server id of the server what the client should use.
    required String serverId,

    /// The channel id of the channel inside [serverId] what the client should use.
    required String channelId,

    /// The token of the client.
    required String token,

    /// Whether to log debug messages.
    bool isDebug = false,
    @visibleForTesting MidjourneyApi? api,
  })  : assert(serverId.isNotEmpty, 'serverId must not be empty'),
        assert(channelId.isNotEmpty, 'channelId must not be empty'),
        assert(token.isNotEmpty, 'token must not be empty'),
        _api = api ??
            MidjourneyApiDiscordImpl(
              config: MidjourneyConfig.discord.copyWith(
                channelId: channelId,
                guildId: serverId,
                token: token,
                isDebug: isDebug,
              ),
            );

  /// The api to use.
  late final MidjourneyApi _api;

  Future<void> imagine(String prompt) => _api.imagine(prompt);
}
