import 'dart:async';

import 'package:midjourney_client/src/core/model/midjourney/midjourney_message.dart';
import 'package:midjourney_client/src/discord_api.dart';

abstract interface class MidjourneyApi {
  const MidjourneyApi();

  /// Imagine a new picture with the given [prompt].
  ///
  /// Returns streamed messages of progress.
  Stream<ImagineMessage> imagine(String prompt);
}

final class MidjourneyApiDiscordImpl extends MidjourneyApi {
  MidjourneyApiDiscordImpl({
    required this.interactionClient,
    required this.connection,
  });

  final DiscordInteractionClient interactionClient;
  final DiscordConnection connection;

  @override
  Stream<ImagineMessage> imagine(String prompt) async* {
    /// Add a seed to the prompt to avoid collisions because prompt
    /// is the only thing that is lasted between requests.
    prompt = '$prompt --seed ${DateTime.now().microsecondsSinceEpoch % 1000000}';
    await interactionClient.imagine(prompt);
    yield* connection.waitImageMessage(prompt);
  }
}
