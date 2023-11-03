import 'dart:async';

import 'package:midjourney_client/src/discord/discord_connection.dart';
import 'package:midjourney_client/src/discord/discord_interaction_client.dart';
import 'package:midjourney_client/src/midjourney/model/midjourney_message.dart';

/// The midjourney api
abstract interface class MidjourneyApi {
  const MidjourneyApi();

  /// Initialize the api.
  FutureOr<void> initialize();

  /// Closes the api.
  ///
  /// After calling this method the connection is closed
  /// and no more events will be emitted.
  ///
  /// If you want to use the api again you have to call [initialize] again.
  Future<void> close();

  /// Imagine a new picture with the given [prompt].
  ///
  /// Returns streamed messages of progress.
  Stream<MidjourneyMessageImage> imagine(String prompt);

  /// Create a new variation based on the picture
  ///
  /// Returns streamed messages of progress.
  Stream<MidjourneyMessageImage> variation(
    MidjourneyMessageImage imageMessage,
    int index,
  );

  /// Upscale the given [imageMessage] to better quality.
  ///
  /// Returns streamed messages of progress.
  Stream<MidjourneyMessageImage> upscale(
    MidjourneyMessageImage imageMessage,
    int index,
  );
}

/// The midjourney api implementation for discord.
final class MidjourneyApiDiscordImpl implements MidjourneyApi {
  MidjourneyApiDiscordImpl({
    required this.interactionClient,
    required this.connection,
  });

  /// The discord interaction client.
  final DiscordInteractionClient interactionClient;

  /// The discord connection.
  final DiscordConnection connection;

  @override
  Stream<MidjourneyMessageImage> imagine(String prompt) async* {
    // Add a seed to the prompt to avoid collisions because prompt
    // is the only thing that is lasted between requests.
    prompt =
        '$prompt --seed ${DateTime.now().microsecondsSinceEpoch % 1000000}';
    final nonce = await interactionClient.imagine(prompt);
    yield* connection.waitImageMessage(nonce);
  }

  @override
  Stream<MidjourneyMessageImage> variation(
    MidjourneyMessageImage imageMessage,
    int index,
  ) async* {
    if (index < 1 && index > 4) {
      throw ArgumentError.value(
        index,
        'index',
        'Index must be between 0 and 5',
      );
    }
    final nonce = await interactionClient.variation(imageMessage, index);
    yield* connection.waitImageMessage(nonce);
  }

  @override
  Stream<MidjourneyMessageImage> upscale(
    MidjourneyMessageImage imageMessage,
    int index,
  ) async* {
    if (index < 1 && index > 4) {
      throw ArgumentError.value(
        index,
        'index',
        'Index must be between 0 and 5',
      );
    }
    final nonce = await interactionClient.upscale(imageMessage, index);
    yield* connection.waitImageMessage(nonce);
  }

  @override
  Future<void> initialize() => connection.initialize();

  @override
  Future<void> close() => connection.close();
}
