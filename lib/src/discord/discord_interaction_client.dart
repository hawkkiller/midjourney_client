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

typedef ImageProgressNotifyCallback = FutureOr<void> Function(
  MidjourneyMessageImage? imageMessage,
  Exception? error,
);

/// Defines the interface for interacting with Discord's interaction API.
abstract class DiscordInteractionClient {
  /// Initializes the client
  ///
  /// Fetches the list of commands from Discord.
  /// This is required to be called before any other method.
  Future<void> initialize();

  /// Creates a new imagine job.
  ///
  /// Returns the nonce of the interaction.
  Future<String> createImagine(String prompt);

  /// Creates a new variation job.
  ///
  /// Returns the nonce of the interaction.
  Future<String> createVariation(
    MidjourneyMessageImage imageMessage,
    int index,
  );

  /// Creates a new upscale job.
  ///
  /// Returns the nonce of the interaction.
  Future<String> createUpscale(MidjourneyMessageImage imageMessage, int index);
}

/// Implementation of the Discord interaction service.
class DiscordInteractionClientImpl implements DiscordInteractionClient {
  DiscordInteractionClientImpl({
    required MidjourneyConfig config,
    Snowflaker? snowflaker,
    http.Client? httpClient,
    @visibleForTesting Map<CommandName, ApplicationCommand>? overrideCommands,
  })  : _config = config,
        _snowflaker = snowflaker ?? Snowflaker(workerId: 1, datacenterId: 1),
        _httpClient = httpClient ?? http.Client(),
        commandsCache = overrideCommands ?? {};

  final http.Client _httpClient;
  final MidjourneyConfig _config;
  final Snowflaker _snowflaker;

  final RateLimiter _rateLimiter = RateLimiter(
    limit: 1,
    period: const Duration(seconds: 2),
  );

  Map<String, String> get _headers => {
        'Content-Type': 'application/json',
        'Authorization': _config.token,
      };

  @visibleForTesting
  final Map<CommandName, ApplicationCommand> commandsCache;

  /// Retrieves a command from cache by its name.
  @visibleForTesting
  ApplicationCommand getCommandByName(CommandName commandName) {
    final command = commandsCache[commandName];
    if (command == null) {
      throw InitializationException(message: 'Command $commandName not found');
    }
    return command;
  }

  /// Executes a rate-limited interaction with the Discord API.
  Future<void> _rateLimitedInteraction(Interaction interaction) async {
    await _rateLimiter(() => _sendInteraction(interaction));
  }

  /// Sends an interaction to the Discord API.
  Future<void> _sendInteraction(Interaction interaction) async {
    final body = interaction.toJson();
    MLogger.instance.d('Sending interaction: $body');
    final uri = Uri.parse('${_config.baseUrl}/api/v10/interactions');
    final response = await _httpClient.post(
      uri,
      body: jsonEncode(body),
      headers: _headers,
    );

    if (response.statusCode != 204) {
      throw InteractionException(
        code: response.statusCode,
        message: response.body,
      );
    }
    MLogger.instance.d('Interaction sent successfully');
  }

  @override
  Future<void> initialize() async {
    final uri = Uri.parse(
      '${_config.baseUrl}/api/v10/applications/${Constants.botID}/commands',
    );
    final response = await _httpClient.get(uri, headers: _headers);

    if (response.statusCode != 200) {
      throw InitializationException(
        code: response.statusCode,
        message: response.body,
      );
    }

    final commandsList =
        (jsonDecode(response.body) as List<Object?>).whereType<Object>();
    for (final commandData in commandsList) {
      final command =
          ApplicationCommand.fromJson(commandData as Map<String, Object?>);
      commandsCache[CommandName.fromString(command.name)] = command;
    }
  }

  @override
  Future<String> createImagine(String prompt) async {
    final command = getCommandByName(CommandName.imagine);
    final interaction = _createImagineInteraction(prompt, command);
    await _rateLimitedInteraction(interaction);

    return interaction.nonce;
  }

  @override
  Future<String> createVariation(
    MidjourneyMessageImage imageMessage,
    int index,
  ) async {
    final interaction = _createVariationInteraction(
      imageMessage: imageMessage,
      index: index,
    );
    await _rateLimitedInteraction(interaction);
    return interaction.nonce;
  }

  @override
  Future<String> createUpscale(
    MidjourneyMessageImage imageMessage,
    int index,
  ) async {
    final interaction = _createUpscaleInteraction(
      imageMessage: imageMessage,
      index: index,
    );
    await _rateLimitedInteraction(interaction);
    return interaction.nonce;
  }

  /// Helper method to create imagine interaction.
  Interaction _createImagineInteraction(
    String prompt,
    ApplicationCommand command,
  ) {
    final nonce = _snowflaker.nextId();

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

    return imaginePayload;
  }

  String uriToHash(String uri) => uri.split('_').removeLast().split('.').first;

  /// Helper method to create variation interaction.
  Interaction _createVariationInteraction({
    required MidjourneyMessageImage imageMessage,
    required int index,
  }) {
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

    return variationPayload;
  }

  /// Helper method to create upscale interaction.
  Interaction _createUpscaleInteraction({
    required MidjourneyMessageImage imageMessage,
    required int index,
  }) {
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

    return upscalePayload;
  }
}
