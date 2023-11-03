/// Base discord model
sealed class DiscordWsModel {
  const DiscordWsModel();

  Map<String, Object?> toJson();
}

class DiscordWsAuth extends DiscordWsModel {
  const DiscordWsAuth(this.token);

  final String token;

  @override
  Map<String, Object?> toJson() => {
        'op': 2,
        'd': {
          'token': token,
          'capabilities': 8189,
          'properties': {
            'os': 'osx',
            'browser': 'Chrome',
            'device': '',
          },
        },
      };
}

class DiscordWsHeartbeat extends DiscordWsModel {
  const DiscordWsHeartbeat(this.sequence);

  final int sequence;

  @override
  Map<String, Object?> toJson() => {
        'op': 1,
        'd': sequence,
      };
}
