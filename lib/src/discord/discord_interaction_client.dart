import 'dart:async';
import 'dart:convert';

import 'package:http/http.dart' as http;
import 'package:meta/meta.dart';
import 'package:midjourney_client/src/discord/constants/constants.dart';
import 'package:midjourney_client/src/discord/model/interaction.dart';
import 'package:midjourney_client/src/exception/exception.dart';
import 'package:midjourney_client/src/midjourney/model/midjourney_config.dart';
import 'package:midjourney_client/src/midjourney/model/midjourney_message.dart';
import 'package:midjourney_client/src/utils/logger.dart';
import 'package:midjourney_client/src/utils/rate_limiter.dart';
import 'package:snowflaker/snowflaker.dart';

typedef ImageMessageCallback = FutureOr<void> Function(
  MidjourneyMessageImage? msg,
  Exception? error,
);

abstract interface class DiscordInteractionClient {
  /// Initialize the client.
  Future<void> initialize();

  /// Imagine a new picture with the given [prompt].
  Future<int> imagine(String prompt);

  /// Create a new variation based on the picture
  Future<int> variation(MidjourneyMessageImage imageMessage, int index);

  /// Upscale the given [imageMessage] to better quality.
  Future<int> upscale(MidjourneyMessageImage imageMessage, int index);
}

final class DiscordInteractionClientImpl implements DiscordInteractionClient {
  DiscordInteractionClientImpl({
    required MidjourneyConfig config,
    @visibleForTesting Snowflaker? snowflaker,
    @visibleForTesting http.Client? client,
  })  : _snowflaker = snowflaker ?? Snowflaker(workerId: 1, datacenterId: 1),
        _config = config,
        _client = client ?? http.Client();

  final http.Client _client;

  final MidjourneyConfig _config;

  final Snowflaker _snowflaker;

  final _rateLimiter = RateLimiter(
    limit: 1,
    period: const Duration(seconds: 2),
  );

  late final _headers = {
    'Content-Type': 'application/json',
    'Authorization': _config.token,
  };

  final _commandsCache = <String, ApplicationCommand>{};

  /// Returns command from cache by name.
  ApplicationCommand _getCommandForName(CommandName commandName) {
    final command = _commandsCache[commandName.name];

    if (command == null) {
      throw InitializationException(
        message: 'Command $commandName not found',
      );
    }

    return command;
  }

  Future<void> _rateLimitedInteractions(
    Map<String, Object?> body,
  ) async =>
      _rateLimiter(
        () async => _interactions(body),
      );

  /// Execute a Discord interaction.
  Future<void> _interactions(Map<String, Object?> body) async {
    MLogger.d('Sending interaction: $body');

    final response = await _client.post(
      Uri.parse('${_config.baseUrl}/api/v10/interactions'),
      body: jsonEncode(body),
      headers: _headers,
    );

    if (response.statusCode != 204) {
      throw InteractionException(
        code: response.statusCode,
        message: response.body,
      );
    }

    MLogger.d('Interaction success');

    return;
  }

  @override
  Future<void> initialize() async {
    final response = await _client.get(
      Uri.parse(
        '${_config.baseUrl}/api/v10/applications/${Constants.botID}/commands',
      ),
      headers: _headers,
    );

    if (response.statusCode != 200) {
      throw InitializationException(
        code: response.statusCode,
        message: response.body,
      );
    }

    final commands = jsonDecode(response.body) as List<Object?>;

    final appCommands = commands
        .map((e) => ApplicationCommand.fromJson(e! as Map<String, Object?>))
        .toList();

    for (final command in appCommands) {
      _commandsCache[command.name] = command;
    }
  }

  @override
  Future<int> imagine(String prompt) async {
    final nonce = _snowflaker.nextId();

    final command = _getCommandForName(CommandName.imagine);

    final imaginePayload = Interaction(
      type: InteractionType.applicationCommand,
      applicationId: command.applicationId,
      sessionId: _config.token,
      channelId: _config.channelId,
      guildId: _config.guildId,
      nonce: nonce.toString(),
      data: InteractionDataApplicationCommand(
        version: command.version,
        id: command.id,
        name: command.name,
        type: ApplicationCommandType.chatInput,
        options: [
          InteractionDataOption(
            type: ApplicationCommandOptionType.string,
            name: 'prompt',
            value: prompt,
          ),
        ],
        applicationCommand: command,
      ),
    );

    final body = imaginePayload.toJson();

    await _rateLimitedInteractions(body);
    return nonce;
  }

  @override
  Future<int> variation(MidjourneyMessageImage imageMessage, int index) async {
    final nonce = _snowflaker.nextId();
    final hash = uriToHash(imageMessage.uri!);
    
    final variationPayload = Interaction(
      messageFlags: 0,
      messageId: imageMessage.messageId,
      type: InteractionType.messageComponent,
      applicationId: Constants.botID,
      sessionId: _config.token,
      channelId: _config.channelId,
      guildId: _config.guildId,
      nonce: nonce.toString(),
      data: InteractionDataMessageComponent(
        customId: 'MJ::JOB::variation::$index::$hash',
        componentType: MessageComponentType.button,
      ),
    );

    final body = variationPayload.toJson();

    await _rateLimitedInteractions(body);

    return nonce;
  }

  @override
  Future<int> upscale(MidjourneyMessageImage imageMessage, int index) async {
    final nonce = _snowflaker.nextId();
    final hash = uriToHash(imageMessage.uri!);
    final upscalePayload = Interaction(
      messageFlags: 0,
      messageId: imageMessage.messageId,
      type: InteractionType.messageComponent,
      applicationId: Constants.botID,
      sessionId: _config.token,
      channelId: _config.channelId,
      guildId: _config.guildId,
      nonce: nonce.toString(),
      data: InteractionDataMessageComponent(
        customId: 'MJ::JOB::upsample::$index::$hash',
        componentType: MessageComponentType.button,
      ),
    );

    final body = upscalePayload.toJson();

    await _rateLimitedInteractions(body);

    return nonce;
  }

  String uriToHash(String uri) => uri.split('_').removeLast().split('.').first;
}
