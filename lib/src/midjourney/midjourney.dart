import 'dart:async';

import 'package:midjourney_client/src/discord/discord_connection.dart';
import 'package:midjourney_client/src/discord/discord_interaction_client.dart';
import 'package:midjourney_client/src/exception/exception.dart';
import 'package:midjourney_client/src/midjourney/midjourney_api.dart';
import 'package:midjourney_client/src/midjourney/model/midjourney_config.dart';
import 'package:midjourney_client/src/midjourney/model/midjourney_message.dart';
import 'package:midjourney_client/src/utils/logger.dart';

/// The main instance of the midjourney client.
///
/// This is the main class to use to interact with the midjourney api.
///
/// See [imagine], [variation], [upscale] for more information.
class Midjourney {
  factory Midjourney() => instance;

  Midjourney._();

  static final instance = Midjourney._();

  /// The api to use.
  MidjourneyApi? _api;

  MidjourneyApi get _$api => _api ?? (throw const NotInitializedException());

  /// Initialize the client.
  ///
  /// This is required to be called before any other method.
  ///
  /// [token] is the discord self token.
  ///
  /// [serverId] is the id of the server to use.
  ///
  /// [channelId] is the id of the channel to use.
  ///
  /// [baseUrl] is the base url for the discord api. Set it to your proxy if you have one.
  ///
  /// [cdnUrl] is the cdn url for the discord api. Set it to your proxy if you have one.
  ///
  /// [wsUrl] is the websocket url for the discord api. Set it to your proxy if you have one.
  FutureOr<void> initialize({
    /// The discord self token.
    required String token,

    /// The id of the server to use.
    required String serverId,

    /// The id of the channel to use.
    required String channelId,

    /// The base url for the discord api. Set it to your proxy if you have one.
    String? baseUrl,

    /// The cdn url for the discord api. Set it to your proxy if you have one.
    String? cdnUrl,

    /// The websocket url for the discord api. Set it to your proxy if you have one.
    String? wsUrl,

    /// The log level to use.
    MLoggerLevel logLevel = MLoggerLevel.info,
  }) async {
    final config = MidjourneyConfig(
      baseUrl: baseUrl ?? 'https://discord.com',
      wsUrl: wsUrl ?? 'wss://gateway.discord.gg/?v=10&encoding=json',
      token: token,
      guildId: serverId,
      channelId: channelId,
      cdnUrl: cdnUrl ?? 'https://cdn.discordapp.com',
    );
    MLogger.level = logLevel;
    if (_api != null) {
      MLogger.w('Midjourney client is already initialized, closing it');
      await close();
    }
    _api ??= MidjourneyApiDiscordImpl(
      connection: DiscordConnectionImpl(config: config),
      interactionClient: DiscordInteractionClientImpl(config: config),
    );
    return _$api.initialize();
  }

  /// Releases the resources.
  /// If you want to use the client again, you need to call [initialize] again.
  Future<void> close() async {
    MLogger.i('Closing midjourney client');
    if (_api == null) {
      MLogger.w('Midjourney client is already closed or not initialized');
      return;
    }
    await _api?.close();
    _api = null;
    MLogger.i('Closed midjourney client');
  }

  /// Imagine a new picture with the given [prompt].
  ///
  /// Returns streamed messages of progress.
  Stream<MidjourneyMessage$Image> imagine(String prompt) =>
      _$api.imagine(prompt).asBroadcastStream();

  /// Create a new variation based on the picture
  ///
  /// Returns streamed messages of progress.
  Stream<MidjourneyMessage$Image> variation(
    MidjourneyMessage$Image imageMessage,
    int index,
  ) =>
      _$api.variation(imageMessage, index).asBroadcastStream();

  /// Upscale the given [imageMessage].
  ///
  /// Returns streamed messages of progress.
  Stream<MidjourneyMessage$Image> upscale(
    MidjourneyMessage$Image imageMessage,
    int index,
  ) =>
      _$api.upscale(imageMessage, index).asBroadcastStream();
}
