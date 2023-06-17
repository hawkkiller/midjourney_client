abstract class MidjourneyMessage {
  const MidjourneyMessage();
}

sealed class MidjourneyMessage$Image extends MidjourneyMessage {
  const MidjourneyMessage$Image({
    required this.id,
    required this.content,
    this.uri,
  });

  final String id;

  final String content;

  final String? uri;

  int get progress => switch (this) {
        final MidjourneyMessage$ImageProgress v => v.progress,
        MidjourneyMessage$ImageFinish() => 100,
      };
  
  bool get finished => switch (this) {
        MidjourneyMessage$ImageProgress() => false,
        MidjourneyMessage$ImageFinish() => true,
      };
}

class MidjourneyMessage$ImageProgress extends MidjourneyMessage$Image {
  const MidjourneyMessage$ImageProgress({
    required this.progress,
    required super.id,
    required super.content,
    super.uri,
  });

  @override
  final int progress;

  @override
  String toString() => (
        StringBuffer()
          ..writeAll(
            [
              r'MidjourneyMessage$Progress(',
              'progress: $progress, ',
              'id: $id, ',
              'content: $content, ',
              'uri: $uri',
              ')',
            ],
          ),
      )
          .toString();
}

class MidjourneyMessage$ImageFinish extends MidjourneyMessage$Image {
  const MidjourneyMessage$ImageFinish({
    required super.id,
    required super.content,
    required String super.uri,
  });

  @override
  String toString() => (
        StringBuffer()
          ..writeAll(
            [
              r'MidjourneyMessage$Finish(',
              'id: $id, ',
              'content: $content, ',
              'uri: $uri',
              ')',
            ],
          ),
      )
          .toString();
}
