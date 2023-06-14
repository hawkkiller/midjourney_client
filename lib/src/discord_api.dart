import 'dart:async';
import 'dart:convert';

import 'package:collection/collection.dart';
import 'package:http/http.dart' as http;
import 'package:meta/meta.dart';
import 'package:midjourney_client/src/core/model/discord/discord_message.dart';
import 'package:midjourney_client/src/core/model/discord/discord_ws.dart';
import 'package:midjourney_client/src/core/model/discord/interaction.dart';
import 'package:midjourney_client/src/core/model/midjourney/midjourney_message.dart';
import 'package:midjourney_client/src/core/model/midjourney_config.dart';
import 'package:midjourney_client/src/core/utils/logger.dart';
import 'package:midjourney_client/src/core/utils/rate_limiter.dart';
import 'package:midjourney_client/src/core/utils/stream_transformers.dart';
import 'package:snowflaker/snowflaker.dart';
import 'package:ws/ws.dart';

typedef WaitMessageCallback = FutureOr<void> Function(
  ImageMessage msg,
  Exception? exception,
);

typedef WaitMessage = ({String nonce, String prompt});

abstract interface class DiscordInteractionClient {
  /// Imagine a new picture with the given [prompt].
  int imagine(String prompt);

  /// Create a new variation based on the picture
  int variation(ImageMessage$Finish imageMessage, int index);
}

abstract interface class DiscordConnection {
  /// Wait for a message with the given [nonce].
  Stream<ImageMessage> waitImageMessage(int nonce);
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

    _rateLimitedInteractions(body);

    return nonce;
  }

  @override
  int variation(ImageMessage$Finish imageMessage, int index) {
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

final class DiscordConnectionImpl implements DiscordConnection {
  DiscordConnectionImpl({
    required this.config,
  }) {
    _client.connect(config.wsUrl);
    _client.stateChanges.listen((event) async {
      MLogger.d('State change: $event');
      if (event.readyState == WebSocketReadyState.open) {
        await _auth();
        _timer?.cancel();
        _timer = Timer.periodic(
          const Duration(seconds: 40),
          (timer) => _heartbeat(timer.tick),
        );
      }
    });

    _discordMessages.listen((event) {
      MLogger.v('Discord ws message: $event');
    });
  }

  Timer? _timer;

  late final Stream<DiscordMessage$Message> _discordMessages = _client.stream
      .whereType<String>()
      .map($discordMessageDecoder.convert)
      .whereType<DiscordMessage$Message>();

  Future<void> _auth() async {
    final auth = DiscordWs$Auth(config.token).toJson();

    await _client.add(jsonEncode(auth));

    MLogger.d('Auth sent $auth');
  }

  Future<void> _heartbeat(int seq) async {
    final heartbeat = DiscordWs$Heartbeat(seq).toJson();

    await _client.add(jsonEncode(heartbeat));

    MLogger.d('Heartbeat sent $heartbeat');
  }

  final _client = WebSocketClient();

  /// Key is ID of the message
  /// Value is nonce of the associated imagine interaction
  final _waitMessages = <String, WaitMessage>{};

  final MidjourneyConfig config;

  String content2Prompt(String? content) {
    if (content == null || content.isEmpty) return '';
    final pattern = RegExp(r'\*\*(.*?)\*\*'); // Match **middle content
    final matches = pattern.allMatches(content);
    if (matches.isNotEmpty && matches.first.groupCount >= 1) {
      return matches.first.group(1) ?? ''; // Get the matched content
    } else {
      MLogger.w('Failed to parse prompt from content: $content');
      return content;
    }
  }

  ({
    WaitMessage? waitMessage,
    String? id,
  }) getEventByContent(String content) {
    final prompt = content2Prompt(content);

    final entry =
        _waitMessages.entries.firstWhereOrNull((element) => element.value.prompt == prompt);

    return (waitMessage: entry?.value, id: entry?.key);
  }

  void _onceImage(
    String nonce,
    WaitMessageCallback fn,
  ) {
    StreamSubscription<DiscordMessage>? sub;

    sub = _discordMessages.listen(
      (event) async {
        // Image generation started event
        if (event.created && event.nonce == nonce) {
          MLogger.d('Image message created: $event');
          // check embeds (error or warning)
          _waitMessages[event.id] = (
            nonce: nonce,
            prompt: content2Prompt(event.content),
          );
          await fn(
            ImageMessage$Progress(
              progress: 0,
              id: event.id,
              content: event.content,
            ),
            null,
          );
        }

        // Image generated event
        if (event.created && event.nonce == null && (event.attachments?.isNotEmpty ?? false)) {
          MLogger.d('Image generated: $event');
          final msg = getEventByContent(event.content);

          if (msg.waitMessage?.nonce == nonce) {
            fn(
              ImageMessage$Finish(
                id: event.id,
                content: event.content,
                uri: event.attachments!.first.url,
              ),
              null,
            );

            _waitMessages.remove(msg.id);
            await sub?.cancel();
          }
        }

        // Image progress event
        if (event.updated && event.nonce == null && (event.attachments?.isNotEmpty ?? false)) {
          MLogger.d('Image updated: $event');
          final $nonce = _waitMessages[event.id]?.nonce;
          if ($nonce == nonce) {
            final progress = RegExp(r'\((\d+)%\)').firstMatch(event.content)?.group(1) ?? '0';
            await fn(
              ImageMessage$Progress(
                progress: int.tryParse(progress) ?? 0,
                id: event.id,
                content: event.content,
                uri: event.attachments!.first.url,
              ),
              null,
            );
          }
        }
      },
    );
  }

  @override
  Stream<ImageMessage> waitImageMessage(int nonce) async* {
    final controller = StreamController<ImageMessage>.broadcast(sync: true);
    _onceImage(
      nonce.toString(),
      (msg, e) async {
        if (e != null) {
          controller.addError(e);
          await controller.close();
        } else {
          controller.add(msg);
          if (msg.finished) {
            await controller.close();
          }
        }
      },
    );
    yield* controller.stream;
  }

  void close() {
    _client.close();
    _timer?.cancel();
  }
}
