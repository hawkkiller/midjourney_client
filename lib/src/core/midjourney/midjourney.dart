import 'package:midjourney_client/src/core/discord/discord_connection.dart';
import 'package:midjourney_client/src/core/discord/discord_interaction_client.dart';
import 'package:midjourney_client/src/core/midjourney/midjourney_api.dart';
import 'package:midjourney_client/src/core/midjourney/model/midjourney_config.dart';
import 'package:midjourney_client/src/core/midjourney/model/midjourney_message.dart';
import 'package:midjourney_client/src/core/utils/logger.dart';

/// The main instance of the midjourney client.
///
/// This is the main class to use to interact with the midjourney api.
///
/// See [imagine] and [variation] for more information.
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
  })  : assert(serverId.isNotEmpty, 'serverId must not be empty'),
        assert(channelId.isNotEmpty, 'channelId must not be empty'),
        assert(token.isNotEmpty, 'token must not be empty') {
    MLogger.level = loggerLevel;
    final config = MidjourneyConfig.discord.copyWith(
      channelId: channelId,
      guildId: serverId,
      token: token,
    );
    _api = MidjourneyApiDiscordImpl(
      connection: DiscordConnectionImpl(config: config),
      interactionClient: DiscordInteractionClientImpl(config: config),
    );
  }

  /// The api to use.
  late final MidjourneyApi _api;

  Future<void> init() => _api.init();

  /// Imagine a new picture with the given [prompt].
  ///
  /// Returns streamed messages of progress.
  Stream<MidjourneyMessage$Image> imagine(String prompt) =>
      _api.imagine(prompt).asBroadcastStream();

  /// Create a new variation based on the picture
  ///
  /// Returns streamed messages of progress.
  Stream<MidjourneyMessage$Image> variation(
    MidjourneyMessage$Image imageMessage,
    int index,
  ) =>
      _api.variation(imageMessage, index).asBroadcastStream();

  /// Upscale the given [imageMessage].
  /// 
  /// Returns streamed messages of progress.
  Stream<MidjourneyMessage$Image> upscale(
    MidjourneyMessage$Image imageMessage,
    int index,
  ) =>
      _api.upscale(imageMessage, index).asBroadcastStream();
}
