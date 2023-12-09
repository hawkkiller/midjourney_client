import 'dart:async';

import 'package:midjourney_client/src/discord/discord_connection.dart';
import 'package:midjourney_client/src/discord/discord_interaction_client.dart';
import 'package:midjourney_client/src/midjourney/model/midjourney_message.dart';
import 'package:snowflaker/snowflaker.dart';

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
  Stream<MidjourneyMessageImage> imagine(String prompt, {int? seed});

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
    Snowflaker? snowflaker,
  }) : snowflaker = snowflaker ?? Snowflaker(workerId: 2, datacenterId: 2);

  /// The snowflaker.
  final Snowflaker snowflaker;

  /// The discord interaction client.
  final DiscordInteractionClient interactionClient;

  /// The discord connection.
  final DiscordConnection connection;

  /// Generates a seed with max value of 2^32 (4 bytes).
  int generateSeed() {
    final id = snowflaker.nextId();

    // The seed is the last 32 bits of the snowflake ID.
    return id & 0xFFFFFFFF;
  }

  @override
  Stream<MidjourneyMessageImage> imagine(String prompt, {int? seed}) async* {
    seed = seed ?? generateSeed();

    // Add a seed to the prompt to avoid collisions because prompt
    // is the only thing that is lasted between requests.
    prompt = '$prompt --seed $seed';
    final nonce = await interactionClient.createImagine(prompt);
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
    final nonce = await interactionClient.createVariation(imageMessage, index);
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
    final nonce = await interactionClient.createUpscale(imageMessage, index);
    yield* connection.waitImageMessage(nonce);
  }

  @override
  Future<void> initialize() async {
    await interactionClient.initialize();
    await connection.initialize();

    return;
  }

  @override
  Future<void> close() => connection.close();
}
