abstract class MidjourneyMessage {
  const MidjourneyMessage();
}

sealed class MidjourneyMessageImage extends MidjourneyMessage {
  const MidjourneyMessageImage({
    required this.messageId,
    required this.content,
    required this.id,
    this.jobId,
    this.uri,
    this.seed,
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

  /// The Midjourney job id
  final String? jobId;

  /// The seed of a message
  final int? seed;

  String get type;

  int get progress => switch (this) {
        final MidjourneyMessageImageProgress v => v.progress,
        MidjourneyMessageImageFinish() => 100,
      };

  bool get finished => switch (this) {
        MidjourneyMessageImageProgress() => false,
        MidjourneyMessageImageFinish() => true,
      };

  @override
  String toString() => '$type('
      'messageId: $messageId, '
      'content: $content, '
      'id: $id, '
      'jobId: $jobId, '
      'uri: $uri, '
      'seed: $seed, '
      'progress: $progress, '
      ')';
}

final class MidjourneyMessageImageProgress extends MidjourneyMessageImage {
  const MidjourneyMessageImageProgress({
    required this.progress,
    required super.messageId,
    required super.content,
    required super.id,
    super.jobId,
    super.uri,
    super.seed,
  });

  @override
  String get type => 'InProgress';

  @override
  final int progress;
}

final class MidjourneyMessageImageFinish extends MidjourneyMessageImage {
  const MidjourneyMessageImageFinish({
    required super.messageId,
    required super.content,
    required super.uri,
    required super.id,
    required String super.jobId,
    super.seed,
  });

  @override
  String get type => 'Finished';
}
