class MidjourneyConfig {
  MidjourneyConfig({
    required this.baseUrl,
    this.token = '',
    this.guildId = '',
    this.channelId = '',
    this.wsUrl = '',
  });

  final String baseUrl;
  final String wsUrl;
  final String token;
  final String guildId;
  final String channelId;

  static final discord = MidjourneyConfig(
    baseUrl: 'https://discord.com',
    wsUrl: 'wss://gateway.discord.gg?v=9&encoding=json&compress=gzip-stream',
  );

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
}
