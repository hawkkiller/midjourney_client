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

/// Associated nonce
typedef DiscordMessageNonce = ({String? nonce, DiscordMessage$Message message});

typedef WaitMessage = ({String nonce, String prompt});

typedef ValueChanged<T> = void Function(T value);

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

class DiscordConnectionImpl implements DiscordConnection {
  DiscordConnectionImpl({required this.config}) {
    _establishWebSocketConnection();
    _handleWebSocketStateChanges();
  }

  final MidjourneyConfig config;

  /// Connection state timer
  Timer? _connectionStateTimer;

  /// Client for WebSocket communication
  final WebSocketClient _webSocketClient = WebSocketClient();

  /// Message waiting pool
  final Map<String, WaitMessage> _waitMessages = {};

  /// Callbacks for waiting messages
  final Map<String, ValueChanged<DiscordMessageNonce>> _waitMessageCallbacks = {};

  /// Wait for an ImageMessage with a given nonce and returns a stream of these messages.
  /// This stream broadcasts multiple subscribers and synchronizes the delivery of events.
  /// It registers a callback function that adds new messages to the stream or, in case of an error,
  /// adds the error to the stream and then closes it.
  @override
  Stream<ImageMessage> waitImageMessage(int nonce) async* {
    final controller = StreamController<ImageMessage>.broadcast(sync: true);

    _registerImageMessageCallback(
      nonce.toString(),
      (msg, e) async {
        if (e != null) {
          // In case of error, add error to the stream and close it
          controller.addError(e);
          await controller.close();
        } else {
          // Add new message to the stream
          controller.add(msg);

          // If message indicates finish, close the stream
          if (msg.finished) {
            await controller.close();
          }
        }
      },
    );

    // Yield all data coming from the controller's stream
    yield* controller.stream;
  }

  /// Register a callback to be invoked once an image message with a specific nonce is received
  void _registerImageMessageCallback(String nonce, WaitMessageCallback callback) {
    _waitMessageCallbacks[nonce] = (discordMsg) async {
      await _processImageMessageCallback(discordMsg, callback, nonce);
    };
  }

  /// Process the image message callback
  /// If the nonce of the incoming message matches the expected nonce,
  /// handle the message according to its state and invoke the callback with appropriate arguments
  Future<void> _processImageMessageCallback(
    DiscordMessageNonce messageNonce,
    WaitMessageCallback callback,
    String nonce,
  ) async {
    if (messageNonce.nonce != nonce) return;

    // Discord message
    final msg = messageNonce.message;

    if (msg.created) {
      await _handleCreatedImageMessage(msg, callback);
    }

    if (msg.updated && msg.nonce == null && (msg.attachments?.isNotEmpty ?? false)) {
      await _handleUpdatedImageMessage(msg, callback);
    }
  }

  /// Handle created image message
  Future<void> _handleCreatedImageMessage(
    DiscordMessage$Message msg,
    WaitMessageCallback callback,
  ) async {
    if (msg.nonce != null) {
      _waitMessages[msg.id] = (nonce: msg.nonce!, prompt: _content2Prompt(msg.content));

      // Trigger an image generation started event
      await callback(
        ImageMessage$Progress(progress: 0, id: msg.id, content: msg.content),
        null,
      );
    } else {
      // Trigger an image generation finished event
      _waitMessageCallbacks.remove(msg.nonce);
      await callback(
        ImageMessage$Finish(id: msg.id, content: msg.content, uri: msg.attachments!.first.url),
        null,
      );
    }
  }

  /// Handle updated image message
  Future<void> _handleUpdatedImageMessage(
      DiscordMessage$Message msg, WaitMessageCallback callback) async {
    final progressMatch = RegExp(r'\((\d+)%\)').firstMatch(msg.content);
    final progress = progressMatch != null ? int.tryParse(progressMatch.group(1) ?? '0') : 0;

    // Trigger an image progress event
    await callback(
      ImageMessage$Progress(
          progress: progress ?? 0,
          id: msg.id,
          content: msg.content,
          uri: msg.attachments!.first.url),
      null,
    );
  }

  /// Establish WebSocket connection and listen for incoming messages
  void _establishWebSocketConnection() {
    _webSocketClient.connect(config.wsUrl);
    _webSocketClient.stream
        .whereType<String>()
        .map($discordMessageDecoder.convert)
        .whereType<DiscordMessage$Message>()
        .map(_processDiscordMessage)
        .listen(_handleDiscordEvent);
  }

  /// Handle WebSocket state changes and perform related actions
  void _handleWebSocketStateChanges() {
    _webSocketClient.stateChanges.listen((event) async {
      MLogger.d('WebSocket state change: $event');
      if (event.readyState == WebSocketReadyState.open) {
        await _authenticate();
        _initiatePeriodicHeartbeat();
      }
    });
  }

  /// Authenticate client with Discord server
  Future<void> _authenticate() async {
    final authJson = DiscordWs$Auth(config.token).toJson();
    await _webSocketClient.add(jsonEncode(authJson));
    MLogger.d('Auth sent $authJson');
  }

  /// Initiate periodic heartbeat to maintain connection
  void _initiatePeriodicHeartbeat() {
    _connectionStateTimer?.cancel();
    _connectionStateTimer = Timer.periodic(
      const Duration(seconds: 40),
      (timer) => _sendHeartbeat(timer.tick),
    );
  }

  /// Send heartbeat signal to Discord server
  Future<void> _sendHeartbeat(int seq) async {
    final heartbeatJson = DiscordWs$Heartbeat(seq).toJson();
    await _webSocketClient.add(jsonEncode(heartbeatJson));
    MLogger.d('Heartbeat sent $heartbeatJson');
  }

  /// Process incoming Discord message and map it to nonce-message pair
  DiscordMessageNonce _processDiscordMessage(DiscordMessage$Message msg) {
    final nonce = _getNonceFromMessage(msg);
    return (nonce: nonce, message: msg);
  }

  /// Handle received Discord event
  void _handleDiscordEvent(DiscordMessageNonce event) {
    final callback = _waitMessageCallbacks[event.nonce];
    callback?.call(event);
  }

  /// Retrieve nonce associated with a message
  String? _getNonceFromMessage(DiscordMessage$Message msg) {
    if (msg.created) return _getNonceForCreatedMessage(msg);
    if (msg.updated) return _getNonceForUpdatedMessage(msg);
    return null;
  }

  /// Get nonce for created message
  String? _getNonceForCreatedMessage(DiscordMessage$Message msg) {
    if (msg.nonce != null) {
      MLogger.d('Created message: ${msg.id}');
      return msg.nonce;
    }
    return _getNonceForCreatedMessageWithoutNonce(msg);
  }

  /// Get nonce for updated message
  String? _getNonceForUpdatedMessage(DiscordMessage$Message msg) {
    final nonce = _waitMessages[msg.id]?.nonce;
    if (nonce != null) {
      MLogger.d('Updated message: ${msg.id} with nonce $nonce');
    }
    return nonce;
  }

  /// Get nonce for created message without nonce
  String? _getNonceForCreatedMessageWithoutNonce(DiscordMessage$Message msg) {
    final msgWithSamePrompt = _getWaitMessageByContent(msg.content);
    final waitMessage = msgWithSamePrompt.waitMessage;

    if (waitMessage != null) {
      final nonce = waitMessage.nonce;
      MLogger.d('Associated ${msg.id} with nonce $nonce');
      return nonce;
    }
    return null;
  }

  /// Convert message content to prompt
  String _content2Prompt(String? content) {
    if (content == null || content.isEmpty) return '';
    // Match content between ** **
    final pattern = RegExp(r'\*\*(.*?)\*\*');
    final matches = pattern.allMatches(content);
    if (matches.isNotEmpty && matches.first.groupCount >= 1) {
      return matches.first.group(1) ?? '';
    } else {
      MLogger.w('Failed to parse prompt from content: $content');
      return content;
    }
  }

  /// Get wait message by content
  ({WaitMessage? waitMessage, String? id}) _getWaitMessageByContent(String content) {
    final prompt = _content2Prompt(content);

    final entry = _waitMessages.entries.firstWhereOrNull(
      (element) => element.value.prompt == prompt,
    );

    final value = _waitMessages.remove(entry?.key);

    return (waitMessage: value, id: entry?.key);
  }

  void close() {
    _webSocketClient.close();
    _connectionStateTimer?.cancel();
  }
}
