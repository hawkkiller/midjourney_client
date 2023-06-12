abstract class MidjourneyMessage {
  const MidjourneyMessage();
}

sealed class ImagineMessage extends MidjourneyMessage {
  const ImagineMessage({
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
        final ImagineMessage$Progress v => v.progress,
        ImagineMessage$Finish() => 100,
      };
}

class ImagineMessage$Progress extends ImagineMessage {
  const ImagineMessage$Progress({
    required this.progress,
    required super.id,
    required super.content,
    required super.hash,
    required super.uri,
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
              'hash: $hash, ',
              'uri: $uri',
              ')',
            ],
          ),
      )
          .toString();
}

class ImagineMessage$Finish extends ImagineMessage {
  const ImagineMessage$Finish({
    required super.id,
    required super.content,
    required super.hash,
    required super.uri,
  });

  @override
  String toString() => (
        StringBuffer()
          ..writeAll(
            [
              r'MidjourneyMessage$Finish(',
              'id: $id, ',
              'content: $content, ',
              'hash: $hash, ',
              'uri: $uri',
              ')',
            ],
          ),
      )
          .toString();
}
