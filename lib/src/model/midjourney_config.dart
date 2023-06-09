class MidjourneyConfig {
  MidjourneyConfig({
    required this.baseUrl,
    this.token = '',
    this.guildId = '',
    this.channelId = '',
    this.isDebug = false,
  });

  final String baseUrl;
  final String token;
  final String guildId;
  final String channelId;
  final bool isDebug;

  static final discord = MidjourneyConfig(
    baseUrl: 'https://discord.com',
  );

  MidjourneyConfig copyWith({
    String? baseUrl,
    String? token,
    String? guildId,
    String? channelId,
    bool? isDebug,
  }) =>
      MidjourneyConfig(
        baseUrl: baseUrl ?? this.baseUrl,
        token: token ?? this.token,
        guildId: guildId ?? this.guildId,
        channelId: channelId ?? this.channelId,
        isDebug: isDebug ?? this.isDebug,
      );
}
