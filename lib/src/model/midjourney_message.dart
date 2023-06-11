sealed class MidjourneyMessage {
  const MidjourneyMessage({
    required this.id,
    required this.content,
    required this.hash,
    required this.uri,
  });

  final String id;

  final String content;

  final String hash;

  final String uri;

  int get progress => switch (this) {
        final MidjourneyMessageProgress v => v.progress,
        MidjourneyMessageFinish() => 100,
      };
}

class MidjourneyMessageProgress extends MidjourneyMessage {
  const MidjourneyMessageProgress({
    required this.progress,
    required super.id,
    required super.content,
    required super.hash,
    required super.uri,
  });

  @override
  final int progress;
}

class MidjourneyMessageFinish extends MidjourneyMessage {
  const MidjourneyMessageFinish({
    required super.id,
    required super.content,
    required super.hash,
    required super.uri,
  });
}
