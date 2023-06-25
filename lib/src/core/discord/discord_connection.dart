import 'dart:async';
import 'dart:convert';

import 'package:meta/meta.dart';
import 'package:midjourney_client/midjourney_client.dart';
import 'package:midjourney_client/src/core/discord/discord_interaction_client.dart';
import 'package:midjourney_client/src/core/discord/exception/discord_exception.dart';
import 'package:midjourney_client/src/core/discord/model/discord_message.dart';
import 'package:midjourney_client/src/core/discord/model/discord_ws.dart';
import 'package:midjourney_client/src/core/discord/websocket_client.dart';
import 'package:midjourney_client/src/core/midjourney/model/midjourney_config.dart';
import 'package:midjourney_client/src/core/utils/logger.dart';
import 'package:midjourney_client/src/core/utils/stream_transformers.dart';

typedef ValueChanged<T> = void Function(T value);

/// Discord message with `associated` nonce
///
/// This is used to create association between nonce and message.
typedef DiscordMessageNonce = ({String? nonce, DiscordMessage$Message message});

/// Model that is used to store temporary data about a message that is being waited for.
///
/// This model is created when `MESSAGE_CREATE` event is emitted at first.
typedef WaitMessage = ({String nonce, String prompt});

/// Discord connection interface
///
/// This is used to communicate with Discord.
abstract interface class DiscordConnection {
  /// Wait for a message with the given [nonce].
  Stream<MidjourneyMessage$Image> waitImageMessage(int nonce);

  /// Initialize the connection.
  Future<void> init();
}

final class DiscordConnectionImpl implements DiscordConnection {
  DiscordConnectionImpl({
    required this.config,
    @visibleForTesting WebsocketClient? websocketClient,
  }) : _webSocketClient = websocketClient ?? WebsocketClient$Ws() {
    _handleWebSocketStateChanges();
  }

  final MidjourneyConfig config;

  /// Connection state timer
  Timer? _heartbeatTimer;

  /// Client for WebSocket communication
  final WebsocketClient _webSocketClient;

  /// Message waiting pool
  final Map<String, WaitMessage> _waitMessages = {};

  /// Callbacks for waiting messages
  final _waitMessageCallbacks = <String, ValueChanged<DiscordMessageNonce>>{};

  /// Wait for an [MidjourneyMessage$Image] with a given [nonce]. Returns a stream of [MidjourneyMessage$Image].
  /// This stream broadcasts multiple subscribers and synchronizes the delivery of events.
  /// It registers a callback function that adds new messages to the stream or, in case of an error,
  /// adds the error to the stream and then closes it.
  @override
  Stream<MidjourneyMessage$Image> waitImageMessage(int nonce) async* {
    final controller = StreamController<MidjourneyMessage$Image>.broadcast(
      sync: true,
    );

    _registerImageMessageCallback(
      nonce.toString(),
      (msg, e) async {
        if (e != null) {
          // In case of error, add error to the stream and close it
          controller.addError(e);
          await controller.close();
          return;
        }
        if (msg != null) {
          // Add new message to the stream
          controller.add(msg);

          // If message indicates finish, close the stream
          if (msg.finished) {
            await controller.close();
          }
          return;
        }
      },
    );

    // Yield all data coming from the controller's stream
    yield* controller.stream;
  }

  /// Register a callback to be invoked once an image message with a specific nonce is received
  void _registerImageMessageCallback(
    String nonce,
    ImageMessageCallback callback,
  ) {
    _waitMessageCallbacks[nonce] = (discordMsg) async {
      await _imageMessageCallback(discordMsg, callback, nonce);
    };
  }

  /// Process the image message callback
  /// If the nonce of the incoming message matches the expected nonce,
  /// handle the message according to its state and invoke the callback with appropriate arguments
  Future<void> _imageMessageCallback(
    DiscordMessageNonce messageNonce,
    ImageMessageCallback callback,
    String nonce,
  ) async {
    if (messageNonce.nonce != nonce) return;

    // Discord message
    final msg = messageNonce.message;

    if (msg.created) {
      await _handleCreatedImageMessage(msg, callback, nonce);
    }

    if (msg.updated &&
        msg.nonce == null &&
        (msg.attachments?.isNotEmpty ?? false)) {
      await _handleUpdatedImageMessage(msg, callback, nonce);
    }
  }

  Future<void> _imageMessageError({
    required ImageMessageCallback callback,
    required String error,
    required String nonce,
  }) async {
    callback(null, DiscordException(error));
    _waitMessageCallbacks.remove(nonce);
    _waitMessages.remove(nonce);
  }

  /// Handle created image message
  ///
  /// If the message has a nonce, add it to the waiting pool and trigger an image generation started event.
  ///
  /// If the message has no nonce, remove it from the waiting pool and trigger an image generation finished event.
  Future<void> _handleCreatedImageMessage(
    DiscordMessage$Message msg,
    ImageMessageCallback callback,
    String nonce,
  ) async {
    if (msg.nonce != null) {
      // check if there is an issue with message, i.e. error or warning
      if (msg.embeds.isNotEmpty) {
        final embed = msg.embeds.first;

        // Discord error color
        if (embed.color == 16711680) {
          await _imageMessageError(
            callback: callback,
            error: embed.description!,
            nonce: nonce,
          );
          return;
        }

        if (embed.color == 16776960) {
          MLogger.i('Discord warning: ${embed.description}');
        }

        if ((embed.title?.contains('continue') ?? false) &&
            (embed.description?.contains("verify you're human") ?? false)) {
          // TODO(MichaelLazebny): handle captcha
          return;
        }

        if (embed.title?.contains('Invalid') ?? false) {
          await _imageMessageError(
            callback: callback,
            error: embed.description!,
            nonce: nonce,
          );
          return;
        }
      }
      _waitMessages[msg.id] = (
        nonce: msg.nonce!,
        prompt: _content2Prompt(msg.content),
      );

      // Trigger an image generation started event
      await callback(
        MidjourneyMessage$ImageProgress(
          progress: 0,
          id: msg.nonce!,
          messageId: msg.id,
          content: msg.content,
        ),
        null,
      );
    } else {
      // Trigger an image generation finished event
      _waitMessageCallbacks.remove(nonce);
      await callback(
        MidjourneyMessage$ImageFinish(
          id: nonce,
          messageId: msg.id,
          content: msg.content,
          uri: msg.attachments!.first.url,
        ),
        null,
      );
    }
  }

  /// Handle updated image message
  ///
  /// Trigger an image progress event.
  Future<void> _handleUpdatedImageMessage(
    DiscordMessage$Message msg,
    ImageMessageCallback callback,
    String nonce,
  ) async {
    final progressMatch = RegExp(r'\((\d+)%\)').firstMatch(msg.content);
    final progress =
        progressMatch != null ? int.tryParse(progressMatch.group(1) ?? '0') : 0;

    // Trigger an image progress event
    await callback(
      MidjourneyMessage$ImageProgress(
        id: nonce,
        progress: progress ?? 0,
        messageId: msg.id,
        content: msg.content,
        uri: msg.attachments!.first.url,
      ),
      null,
    );
  }

  /// Establish WebSocket connection and listen for incoming messages
  ///
  /// This method is called once the client is initialized.
  Future<void> _establishWebSocketConnection() async {
    await _webSocketClient.connect(config.wsUrl);
    _webSocketClient.stream
        .whereType<String>()
        .map($discordMessageDecoder.convert)
        .whereType<DiscordMessage$Message>()
        .where((event) {
          final isChannel = event.channelId == config.channelId;
          final isMidjourneyBot =
              event.author.id == MidjourneyConfig.midjourneyBotId;
          return isChannel && isMidjourneyBot;
        })
        .map(_associateDiscordMessageWithNonce)
        .listen(_handleDiscordMessage);
  }

  /// Handle WebSocket state changes and perform related actions
  ///
  /// This method is called once the client is initialized.
  void _handleWebSocketStateChanges() {
    _webSocketClient.stateChanges.listen((event) async {
      MLogger.d('WebSocket state change: $event');
      if (event == WebsocketState.open) {
        await _authenticate();
        _initiatePeriodicHeartbeat();
      }
    });
  }

  /// Authenticate client with Discord server
  ///
  /// This method is called once the connection is established.
  Future<void> _authenticate() async {
    final authJson = DiscordWs$Auth(config.token).toJson();
    await _webSocketClient.add(jsonEncode(authJson));
    MLogger.d('Auth sent $authJson');
  }

  /// Initiate periodic heartbeat to maintain connection
  ///
  /// This method is called once the connection is established.
  void _initiatePeriodicHeartbeat() {
    _heartbeatTimer?.cancel();
    _heartbeatTimer = Timer.periodic(
      const Duration(seconds: 40),
      (timer) => _sendHeartbeat(timer.tick),
    );
  }

  /// Send heartbeat signal to Discord server
  ///
  /// This method is called periodically to maintain connection.
  Future<void> _sendHeartbeat(int seq) async {
    final heartbeatJson = DiscordWs$Heartbeat(seq).toJson();
    await _webSocketClient.add(jsonEncode(heartbeatJson));
    MLogger.d('Heartbeat sent $heartbeatJson');
  }

  /// Process incoming Discord message and map it to nonce-message pair
  DiscordMessageNonce _associateDiscordMessageWithNonce(
    DiscordMessage$Message msg,
  ) {
    final nonce = _getNonceForMessage(msg);
    return (nonce: nonce, message: msg);
  }

  /// Handle received Discord event
  void _handleDiscordMessage(DiscordMessageNonce event) {
    MLogger.v('Discord message received: $event');
    final callback = _waitMessageCallbacks[event.nonce];
    callback?.call(event);
  }

  /// Retrieve nonce associated with a message
  String? _getNonceForMessage(DiscordMessage$Message msg) {
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

    // Get nonce for created message without nonce
    final msgWithSamePrompt = _getWaitMessageByContent(msg.content);
    final waitMessage = msgWithSamePrompt.waitMessage;

    if (waitMessage != null) {
      final nonce = waitMessage.nonce;
      MLogger.v('Associated ${msg.id} with nonce $nonce');
      return nonce;
    }
    return null;
  }

  /// Get nonce for updated message
  String? _getNonceForUpdatedMessage(DiscordMessage$Message msg) {
    final waitMessage = _waitMessages[msg.id];
    if (waitMessage == null) return null;
    final nonce = waitMessage.nonce;
    MLogger.v('Updated message: ${msg.id} with nonce $nonce');

    if (waitMessage.prompt.isEmpty) {
      // handle overloaded case when first created was without content
      _waitMessages[msg.id] = (
        prompt: _content2Prompt(msg.content),
        nonce: nonce,
      );
    }

    return nonce;
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
  ({WaitMessage? waitMessage, String? id}) _getWaitMessageByContent(
    String content,
  ) {
    final prompt = _content2Prompt(content);

    MapEntry<String, WaitMessage>? entry;

    for (final e in _waitMessages.entries) {
      MLogger.v('Comparing $prompt with ${e.value.prompt}');
      if (e.value.prompt == prompt) {
        entry = e;
        break;
      }
    }

    final value = _waitMessages.remove(entry?.key);

    return (waitMessage: value, id: entry?.key);
  }

  void close() {
    _webSocketClient.disconnect();
    _heartbeatTimer?.cancel();
  }

  @override
  Future<void> init() => _establishWebSocketConnection();
}
