sealed class DiscordWs {
  const DiscordWs();

  Map<String, Object?> toJson();
}

class DiscordWs$Auth extends DiscordWs {
  const DiscordWs$Auth(this.token);

  final String token;

  @override
  Map<String, Object?> toJson() => {
        'op': 2,
        'd': {
          'token': token,
          'capabilities': 8189,
          'properties': {
            'os': 'linux',
            'browser': 'Chrome',
            'device': '',
          },
        },
      };
}

class DiscordWs$Heartbeat extends DiscordWs {
  const DiscordWs$Heartbeat(this.sequence);

  final int sequence;

  @override
  Map<String, Object?> toJson() => {
        'op': 1,
        'd': sequence,
      };
}
