import 'package:meta/meta.dart';

/// MidjourneyConfig is a class that holds the configuration for the Midjourney
///
/// [baseUrl] is the base url for the discord api
///
/// [wsUrl] is the websocket url for the discord api
///
/// [token] is the token for the discord api
///
/// [guildId] is the guild id for the discord api
///
/// [channelId] is the channel id for the discord api
class MidjourneyConfig {
  const MidjourneyConfig({
    required this.baseUrl,
    this.token = '',
    this.guildId = '',
    this.channelId = '',
    this.wsUrl = '',
  });

  /// The base url for the discord api
  final String baseUrl;

  /// The websocket url for the discord api
  final String wsUrl;

  /// The token for the discord api
  final String token;

  /// The guild id for the discord api
  final String guildId;

  /// The channel id for the discord api
  final String channelId;

  /// Creates a copy of this MidjourneyConfig
  ///
  /// but with the given fields replaced with the new values.
  MidjourneyConfig copyWith({
    String? baseUrl,
    String? wsUrl,
    String? token,
    String? guildId,
    String? channelId,
  }) =>
      MidjourneyConfig(
        baseUrl: baseUrl ?? this.baseUrl,
        wsUrl: wsUrl ?? this.wsUrl,
        token: token ?? this.token,
        guildId: guildId ?? this.guildId,
        channelId: channelId ?? this.channelId,
      );

  @visibleForTesting
  static const empty = MidjourneyConfig(
    baseUrl: 'empty',
    wsUrl: 'empty',
    token: 'empty',
    guildId: 'empty',
    channelId: 'empty',
  );
}
