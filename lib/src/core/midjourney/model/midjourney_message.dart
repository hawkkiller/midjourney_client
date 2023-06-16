abstract class MidjourneyMessage {
  const MidjourneyMessage();
}

sealed class ImageMessage extends MidjourneyMessage {
  const ImageMessage({
    required this.id,
    required this.content,
    this.uri,
  });

  final String id;

  final String content;

  final String? uri;

  int get progress => switch (this) {
        final ImageMessage$Progress v => v.progress,
        ImageMessage$Finish() => 100,
      };
  
  bool get finished => switch (this) {
        ImageMessage$Progress() => false,
        ImageMessage$Finish() => true,
      };
}

class ImageMessage$Progress extends ImageMessage {
  const ImageMessage$Progress({
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

class ImageMessage$Finish extends ImageMessage {
  const ImageMessage$Finish({
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
