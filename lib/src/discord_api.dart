import 'dart:async';
import 'dart:convert';

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

abstract interface class DiscordInteractionClient {
  /// Imagine a new picture with the given [prompt].
  void imagine(String prompt);

  /// Create a new variation based on the picture
  int variation(ImageMessage$Finish imageMessage, int index);
}

abstract interface class DiscordConnection {
  /// Wait for a message with the given [prompt].
  Stream<ImageMessage> waitImageMessage(String prompt, [String? nonce]);
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
  void imagine(String prompt) {
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
  }

  @override
  int variation(ImageMessage$Finish imageMessage, int index) {
    final nonce = _snowflaker.nextId();
    final hash = uriToHash(imageMessage.uri);
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

  late final Stream<DiscordMessage> _discordMessages =
      _client.stream.whereType<String>().map($discordMessageDecoder.convert);

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

  final MidjourneyConfig config;

  @override
  Stream<ImageMessage> waitImageMessage(String prompt, [String? nonce]) async* {
    StreamSubscription<DiscordMessage>? subscription;
    final controller = StreamController<ImageMessage>(sync: true);

    subscription = _discordMessages.listen((event) async {
      if (event case final DiscordMessage$MessageCreate msg) {
        if (!msg.author.bot || msg.author.username != 'Midjourney Bot') return;
        if (msg.content.contains(prompt) && msg.nonce == null) {
          final uri = msg.attachments!.first.url;
          controller.add(
            ImageMessage$Finish(
              id: msg.id,
              content: msg.content,
              uri: uri,
            ),
          );
          await subscription?.cancel();
          await controller.close();
        }
      }

      if (event case final DiscordMessage$MessageUpdate msg) {
        if (!msg.author.bot || msg.author.username != 'Midjourney Bot') return;
        if (msg.content.contains(prompt)) {
          // content: **Cat in a hat --seed 745825 --upbeta --s 250 --style raw** - <@292625550051246080> (62%) (fast)
          final progress = RegExp(r'\((\d+)%\)').firstMatch(msg.content)?.group(1);
          controller.add(
            ImageMessage$Progress(
              progress: int.tryParse(progress ?? '0') ?? 0,
              id: msg.id,
              content: msg.content,
              uri: msg.attachments!.first.url,
            ),
          );
        }
      }
    });
    yield* controller.stream;
  }

  void close() {
    _client.close();
    _timer?.cancel();
  }
}

// {
//   "type": 3,
//   "nonce": "1117911755964547072",
//   "guild_id": "1014828232740192296",
//   "channel_id": "1014828233226735648",
//   "message_flags": 0,
//   "message_id": "1117911635139514458",
//   "application_id": "936929561302675456",
//   "session_id": "8c52679dad307da8eeacc3471343a21b",
//   "data": {
//     "component_type": 2,
//     "custom_id": "MJ::JOB::variation::2::8ed1ed9f-8761-4a06-85a7-b1dc5fdfbb5f"
//   }
// }