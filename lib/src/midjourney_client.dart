import 'package:meta/meta.dart';
import 'package:midjourney_client/src/core/model/midjourney/midjourney_message.dart';
import 'package:midjourney_client/src/core/model/midjourney_config.dart';
import 'package:midjourney_client/src/core/utils/logger.dart';
import 'package:midjourney_client/src/discord_api.dart';
import 'package:midjourney_client/src/midjourney_api.dart';

class Midjourney {
  Midjourney({
    /// The server id of the server what the client should use.
    required String serverId,

    /// The channel id of the channel inside [serverId] what the client should use.
    required String channelId,

    /// The token of the client.
    required String token,

    /// Whether to log debug messages.
    MLoggerLevel loggerLevel = MLoggerLevel.info,
    @visibleForTesting MidjourneyApi? api,
  })  : assert(serverId.isNotEmpty, 'serverId must not be empty'),
        assert(channelId.isNotEmpty, 'channelId must not be empty'),
        assert(token.isNotEmpty, 'token must not be empty') {
    MLogger.level = loggerLevel;
    final config = MidjourneyConfig.discord.copyWith(
      channelId: channelId,
      guildId: serverId,
      token: token,
    );
    _api = api ??
        MidjourneyApiDiscordImpl(
          connection: DiscordConnectionImpl(config: config),
          interactionClient: DiscordInteractionClientImpl(config: config),
        );
  }

  /// The api to use.
  late final MidjourneyApi _api;

  Stream<ImageMessage> imagine(String prompt) => _api.imagine(prompt);

  Stream<ImageMessage> variation(ImageMessage$Finish imageMessage, int index) =>
      _api.variation(imageMessage, index);
}
