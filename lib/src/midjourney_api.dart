import 'dart:async';
import 'dart:convert';

import 'package:http/http.dart' as http;
import 'package:meta/meta.dart';
import 'package:midjourney_client/src/misc/logger.dart';
import 'package:midjourney_client/src/model/discord_ws.dart';
import 'package:midjourney_client/src/model/interaction.dart';
import 'package:midjourney_client/src/model/midjourney_config.dart';
import 'package:midjourney_client/src/model/midjourney_message.dart';
import 'package:snowflaker/snowflaker.dart';
import 'package:ws/ws.dart';

abstract interface class MidjourneyApi {
  const MidjourneyApi();

  /// Imagine a new picture with the given [prompt].
  ///
  /// Returns streamed messages of progress.
  Stream<MidjourneyMessage> imagine(String prompt);
}

abstract interface class DiscordInteractionClient {
  /// Imagine a new picture with the given [prompt].
  ///
  /// Returns nonce.
  Future<int> imagine(String prompt);
}

abstract interface class DiscordConnection {
  /// Wait for a message with the given [nonce].
  Stream<MidjourneyMessage> waitImageMessage(int nonce);
}

final class MidjourneyApiDiscordImpl extends MidjourneyApi {
  MidjourneyApiDiscordImpl({
    required this.interactionClient,
    required this.connection,
  });

  final DiscordInteractionClient interactionClient;
  final DiscordConnection connection;

  @override
  Stream<MidjourneyMessage> imagine(String prompt) async* {
    final nonce = await interactionClient.imagine(prompt);
    yield* connection.waitImageMessage(nonce);
  }
}

final class DiscordInteractionClientImpl implements DiscordInteractionClient {
  DiscordInteractionClientImpl({
    required MidjourneyConfig config,
    @visibleForTesting http.Client? client,
  })  : _config = config,
        _client = client ?? http.Client();

  final http.Client _client;
  final MidjourneyConfig _config;
  final Snowflaker _snowflaker = Snowflaker(workerId: 1, datacenterId: 1);

  /// Execute a Discord interaction.
  Future<void> _interactions(Map<String, Object?> body) async {
    final headers = {
      'Content-Type': 'application/json',
      'Authorization': _config.token,
    };

    MLogger.d('Sending interaction: $body');

    final response = await _client.post(
      Uri.parse('${_config.baseUrl}/api/v9/interactions'),
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
  Future<int> imagine(String prompt) async {
    final nonce = _snowflaker.nextId();
    final imaginePayload = Interaction(
      type: InteractionType.applicationCommand,
      applicationId: '936929561302675456',
      sessionId: _config.token,
      channelId: _config.channelId,
      guildId: _config.guildId,
      nonce: nonce,
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

    await _interactions(body);

    return nonce;
  }
}

final class DiscordConnectionImpl implements DiscordConnection {
  DiscordConnectionImpl({
    required this.config,
  }) {
    _client.stateChanges.listen((event) async {
      MLogger.d('State change: $event');
      if (event.readyState == WebSocketReadyState.open) {
        await _auth();
        _timer = Timer.periodic(
          const Duration(seconds: 40),
          (timer) {
            _heartbeat(timer.tick);
          },
        );
      }
    });

    _client.stream.listen((event) {
      MLogger.v('Discord ws message: $event');
    });
  }

  Timer? _timer;

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

  Future<void> _connect() async {
    await _client.connect(config.wsUrl);
  }

  late final Completer<void> _connected = Completer()..complete(_connect());
  final WebSocketClient _client = WebSocketClient();
  final MidjourneyConfig config;

  @override
  Stream<MidjourneyMessage> waitImageMessage(int nonce) async* {
    await _connected.future;
  }

  void close() {
    _client.close();
    _timer?.cancel();
  }
}
