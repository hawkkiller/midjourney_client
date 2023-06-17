import 'dart:async';
import 'dart:convert';

import 'package:http/http.dart' as http;
import 'package:meta/meta.dart';
import 'package:midjourney_client/src/core/discord/model/interaction.dart';
import 'package:midjourney_client/src/core/midjourney/model/midjourney_config.dart';
import 'package:midjourney_client/src/core/midjourney/model/midjourney_message.dart';
import 'package:midjourney_client/src/core/utils/logger.dart';
import 'package:midjourney_client/src/core/utils/rate_limiter.dart';
import 'package:snowflaker/snowflaker.dart';

typedef ImageMessageCallback = FutureOr<void> Function(
  MidjourneyMessage$Image? msg,
  Exception? error,
);

abstract interface class DiscordInteractionClient {
  /// Imagine a new picture with the given [prompt].
  int imagine(String prompt);

  /// Create a new variation based on the picture
  int variation(MidjourneyMessage$Image imageMessage, int index);
}

final class DiscordInteractionClientImpl implements DiscordInteractionClient {
  DiscordInteractionClientImpl({
    required MidjourneyConfig config,
    @visibleForTesting http.Client? client,
  })  : _config = config,
        _client = client ?? http.Client() {
    rateLimiter.stream.listen(_interactions);
  }

  final http.Client _client;
  final MidjourneyConfig _config;
  final _snowflaker = Snowflaker(workerId: 1, datacenterId: 1);
  final rateLimiter = RateLimiter<Map<String, Object?>>(
    const Duration(seconds: 2),
  );

  void _rateLimitedInteractions(Map<String, Object?> body) => rateLimiter.add(body);

  /// Execute a Discord interaction.
  Future<void> _interactions(Map<String, Object?> body) async {
    final headers = {
      'Content-Type': 'application/json',
      'Authorization': _config.token,
    };

    MLogger.d('Sending interaction: $body');

    final response = await _client.post(
      Uri.parse('${_config.baseUrl}/api/v10/interactions'),
      body: jsonEncode(body),
      headers: headers,
    );

    if (response.statusCode != 204) {
      throw Exception('Failed to send interaction: ${response.body}');
    }

    MLogger.d('Interaction success');

    return;
  }

  @override
  int imagine(String prompt) {
    final nonce = _snowflaker.nextId();
    final imaginePayload = Interaction(
      type: InteractionType.applicationCommand,
      applicationId: '936929561302675456',
      sessionId: _config.token,
      channelId: _config.channelId,
      guildId: _config.guildId,
      nonce: nonce.toString(),
      data: InteractionData$ApplicationCommand(
        version: '1118961510123847772',
        id: '938956540159881230',
        name: 'imagine',
        type: ApplicationCommandType.chatInput,
        options: [
          InteractionDataOption(
            type: ApplicationCommandOptionType.string,
            name: 'prompt',
            value: prompt,
          ),
        ],
        applicationCommand: ApplicationCommand(
          id: '938956540159881230',
          applicationId: '936929561302675456',
          version: '1118961510123847772',
          type: ApplicationCommandType.chatInput,
          nsfw: false,
          name: 'imagine',
          description: 'Create images with Midjourney',
          dmPermission: true,
          options: [
            ApplicationCommandOption(
              type: ApplicationCommandOptionType.string,
              name: 'prompt',
              description: 'The prompt to imagine',
              required: true,
            ),
          ],
        ),
      ),
    );

    final body = imaginePayload.toJson();

    _rateLimitedInteractions(body);

    return nonce;
  }

  @override
  int variation(MidjourneyMessage$Image imageMessage, int index) {
    final nonce = _snowflaker.nextId();
    final hash = uriToHash(imageMessage.uri!);
    final variationPayload = Interaction(
      messageFlags: 0,
      messageId: imageMessage.id,
      type: InteractionType.messageComponent,
      applicationId: '936929561302675456',
      sessionId: _config.token,
      channelId: _config.channelId,
      guildId: _config.guildId,
      nonce: nonce.toString(),
      data: InteractionData$MessageComponent(
        customId: 'MJ::JOB::variation::$index::$hash',
        componentType: MessageComponentType.button,
      ),
    );

    final body = variationPayload.toJson();

    _rateLimitedInteractions(body);

    return nonce;
  }

  String uriToHash(String uri) => uri.split('_').removeLast().split('.').first;
}
