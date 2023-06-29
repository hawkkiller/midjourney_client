abstract class MidjourneyMessage {
  const MidjourneyMessage();
}

sealed class MidjourneyMessage$Image extends MidjourneyMessage {
  const MidjourneyMessage$Image({
    required this.messageId,
    required this.content,
    required this.id,
    this.uri,
  });

  /// The id of the message
  /// This is the id that will be used to update the message
  /// when the image is finished. It is from Midjourney.
  final String messageId;

  /// The content of the message
  /// This is the prompt that will be shown to the user.
  /// It is from Midjourney.
  final String content;

  /// The uri of the image
  /// Only present when the image is finished or in progress.
  final String? uri;

  /// The unique identifier for this message
  /// Generated when first message created.
  final String id;

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
    required super.messageId,
    required super.content,
    required super.id,
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
              'messageId: $messageId, ',
              'content: $content, ',
              'uri: $uri, ',
              'id: $id',
              ')',
            ],
          ),
      ).toString();
}

class MidjourneyMessage$ImageFinish extends MidjourneyMessage$Image {
  const MidjourneyMessage$ImageFinish({
    required super.messageId,
    required super.content,
    required super.uri,
    required super.id,
  });

  @override
  String toString() => (
        StringBuffer()
          ..writeAll(
            [
              r'MidjourneyMessage$Finish(',
              'id: $messageId, ',
              'content: $content, ',
              'uri: $uri',
              'id: $id, ',
              ')',
            ],
          ),
      ).toString();
}
