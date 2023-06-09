import 'dart:convert';

import 'package:http/http.dart' as http;
import 'package:l/l.dart';
import 'package:meta/meta.dart';
import 'package:midjourney_client/src/model/application_command.dart';
import 'package:midjourney_client/src/model/application_command_option.dart';
import 'package:midjourney_client/src/model/application_command_option_type.dart';
import 'package:midjourney_client/src/model/application_command_type.dart';
import 'package:midjourney_client/src/model/interaction.dart';
import 'package:midjourney_client/src/model/interaction_data.dart';
import 'package:midjourney_client/src/model/interaction_data_option.dart';
import 'package:midjourney_client/src/model/interaction_type.dart';
import 'package:midjourney_client/src/model/midjourney_config.dart';
import 'package:snowflaker/snowflaker.dart';

abstract base class MidjourneyApi {
  const MidjourneyApi();

  /// Imagine a new picture with the given [prompt].
  Future<void> imagine(
    String prompt, {
    bool isDebug = false,
  });
}

final class MidjourneyApiDiscordImpl extends MidjourneyApi {
  MidjourneyApiDiscordImpl({
    required MidjourneyConfig config,
    @visibleForTesting http.Client? client,
  })  : _config = config,
        _client = client ?? http.Client(),
        _snowflaker = Snowflaker(datacenterId: 1, workerId: 1);

  final http.Client _client;
  final MidjourneyConfig _config;
  final Snowflaker _snowflaker;

  @override
  Future<void> imagine(
    String prompt, {
    bool isDebug = false,
  }) async {
    final imaginePayload = Interaction(
      type: InteractionType.applicationCommand,
      applicationId: '936929561302675456',
      sessionId: _config.token,
      channelId: _config.channelId,
      guildId: _config.guildId,
      nonce: _snowflaker.nextId(),
      data: InteractionData(
        version: '1077969938624553050',
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
          version: '1077969938624553050',
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

    return interactions(body);
  }

  Future<void> interactions(Map<String, Object?> body) async {
    final headers = {
      'Content-Type': 'application/json',
      'Authorization': _config.token,
    };

    final response = await _client.post(
      Uri.parse('${_config.baseUrl}/api/v9/interactions'),
      body: jsonEncode(body),
      headers: headers,
    );

    if (response.statusCode != 204) {
      throw Exception('Failed to send interaction: ${response.body}');
    }

    l.v1('Successfully sent interaction: ${response.body}');

    return;
  }
}
