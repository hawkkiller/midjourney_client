import 'dart:async';
import 'dart:convert';

import 'package:meta/meta.dart';
import 'package:midjourney_client/midjourney_client.dart';
import 'package:midjourney_client/src/discord/constants/constants.dart';
import 'package:midjourney_client/src/discord/discord_interaction_client.dart';
import 'package:midjourney_client/src/discord/model/discord_message.dart';
import 'package:midjourney_client/src/discord/model/discord_ws.dart';
import 'package:midjourney_client/src/discord/websocket_client.dart';
import 'package:midjourney_client/src/exception/exception.dart';
import 'package:midjourney_client/src/midjourney/model/midjourney_config.dart';
import 'package:midjourney_client/src/utils/extension.dart';
import 'package:midjourney_client/src/utils/logger.dart';
import 'package:midjourney_client/src/utils/stream_transformers.dart';

typedef ValueChanged<T> = void Function(T value);

/// Discord message with `associated` nonce
///
/// This is used to create association between nonce and message.
typedef DiscordMessageWithNonce = ({String? nonce, DiscordMessage message});

/// Model that is used to store temporary data about a message that is being waited for.
///
/// This model is created when `MESSAGE_CREATE` event is emitted at first.
typedef WaitDiscordMessage = ({String nonce, String prompt});

/// Discord connection interface
///
/// This is used to communicate with Discord.
abstract interface class DiscordConnection {
  /// Wait for a message with the given [nonce].
  Stream<MidjourneyMessageImage> waitImageMessage(int nonce);

  /// Initialize the connection.
  Future<void> initialize();

  /// Close the connection
  Future<void> close();
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
  ///
  /// Key is message ID, value is [WaitDiscordMessage]
  final Map<String, WaitDiscordMessage> _waitMessages = {};

  /// Callbacks for waiting messages
  ///
  /// Key is nonce, value is a callback
  final _waitMessageCallbacks =
      <String, ValueChanged<DiscordMessageWithNonce>>{};

  StreamSubscription<DiscordMessageWithNonce>? _messagesSubscription;
  StreamSubscription<WebsocketState>? _socketStateSubscription;

  @override
  Future<void> close() async {
    _heartbeatTimer?.cancel();
    await _webSocketClient.disconnect();
    await _messagesSubscription?.cancel();
    await _socketStateSubscription?.cancel();

    _waitMessageCallbacks.clear();
    _waitMessages.clear();
  }

  @override
  Future<void> initialize() => _establishWebSocketConnection();

  /// Wait for an [MidjourneyMessageImage] with a given [nonce]. Returns a stream of [MidjourneyMessageImage].
  /// This stream broadcasts multiple subscribers and synchronizes the delivery of events.
  /// It registers a callback function that adds new messages to the stream or, in case of an error,
  /// adds the error to the stream and then closes it.
  @override
  Stream<MidjourneyMessageImage> waitImageMessage(int nonce) async* {
    final controller = StreamController<MidjourneyMessageImage>.broadcast(
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
    DiscordMessageWithNonce messageNonce,
    ImageMessageCallback callback,
    String nonce,
  ) async {
    if (messageNonce.nonce != nonce) return;

    // Discord message
    final msg = messageNonce.message;

    // If the message is created, then:
    // - if it has a nonce -> it is the first message,
    //   that signifies the start of the image generation
    // - if it has no nonce -> image generation is finished
    if (msg.created) {
      await _handleCreatedImageMessage(msg, callback, nonce);
    }

    // Updated message event
    // Nonce should be null and attachments should be present
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
    callback(null, MidjourneyException(error));
    _waitMessageCallbacks.remove(nonce);
    _waitMessages.remove(nonce);
  }

  /// Handle created image message
  ///
  /// If the message has a nonce, add it to the waiting pool
  /// and trigger an image generation started event.
  ///
  /// If the message has no nonce, remove it from the waiting
  /// pool and trigger an image generation finished event.
  Future<void> _handleCreatedImageMessage(
    DiscordMessage msg,
    ImageMessageCallback callback,
    String nonce,
  ) async {
    if (msg.nonce == null) {
      // Trigger an image generation finished event
      _waitMessageCallbacks.remove(nonce);
      await callback(
        MidjourneyMessageImageFinish(
          id: nonce,
          messageId: msg.id,
          content: msg.content,
          uri: msg.attachments!.first.url.replaceHost(config.cdnUrl),
        ),
        null,
      );
      return;
    }
    String? reason;
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
        MLogger.w('Discord warning: ${embed.description}');
      }

      final title = embed.title;
      final description = embed.description;

      if (title == null || description == null) {
        // do nothing
      } else if (title.contains('continue') &&
          description.contains("verify you're human")) {
        // TODO(hawkkiller): handle captcha
        return;
      } else if (title.contains('Invalid')) {
        await _imageMessageError(
          callback: callback,
          error: embed.description!,
          nonce: nonce,
        );
        return;
      } else if (title.contains('Job queued')) {
        reason = '$title\n$description';
      }
    }
    _waitMessages[msg.id] = (
      nonce: msg.nonce!,
      prompt: _content2Prompt(msg.content),
    );

    // Trigger an image generation started event
    await callback(
      MidjourneyMessageImageProgress(
        progress: 0,
        id: msg.nonce!,
        messageId: msg.id,
        content: reason ?? msg.content,
      ),
      null,
    );
    return;
  }

  /// Handle updated image message
  ///
  /// Trigger an image progress event.
  Future<void> _handleUpdatedImageMessage(
    DiscordMessage msg,
    ImageMessageCallback callback,
    String nonce,
  ) async {
    final progressMatch = RegExp(r'\((\d+)%\)').firstMatch(msg.content);
    final progress =
        progressMatch != null ? int.tryParse(progressMatch.group(1) ?? '0') : 0;

    // Trigger an image progress event
    await callback(
      MidjourneyMessageImageProgress(
        id: nonce,
        progress: progress ?? 0,
        messageId: msg.id,
        content: msg.content,
        uri: msg.attachments!.first.url.replaceHost(config.cdnUrl),
      ),
      null,
    );
  }

  /// Establish WebSocket connection and listen for incoming messages
  ///
  /// This method is called once the client is initialized.
  Future<void> _establishWebSocketConnection() async {
    await _webSocketClient.connect(config.wsUrl);
    _messagesSubscription = _webSocketClient.stream
        .whereType<String>()
        .map($discordMessageDecoder.convert)
        .whereType<DiscordMessage>()
        .where((event) {
          final isChannel = event.channelId == config.channelId;
          // midjourney bot id in discord
          final isMidjourneyBot = event.author.id == Constants.midjourneyBotID;
          return isChannel && isMidjourneyBot;
        })
        .map(_associateDiscordMessageWithNonce)
        .listen(_handleDiscordMessage);
  }

  /// Handle WebSocket state changes and perform related actions
  ///
  /// This method is called once the client is initialized.
  void _handleWebSocketStateChanges() {
    _socketStateSubscription =
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
    final authJson = DiscordWsAuth(config.token).toJson();
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
    final heartbeatJson = DiscordWsHeartbeat(seq).toJson();
    await _webSocketClient.add(jsonEncode(heartbeatJson));
    MLogger.d('Heartbeat sent $heartbeatJson');
  }

  /// Process incoming Discord message and map it to nonce-message pair
  DiscordMessageWithNonce _associateDiscordMessageWithNonce(
    DiscordMessage msg,
  ) {
    final nonce = _getNonceForMessage(msg);
    return (nonce: nonce, message: msg);
  }

  /// Handle received Discord event
  void _handleDiscordMessage(DiscordMessageWithNonce event) {
    MLogger.v('Discord message received: $event');
    final callback = _waitMessageCallbacks[event.nonce];
    callback?.call(event);
  }

  /// Retrieve nonce associated with a message
  String? _getNonceForMessage(DiscordMessage msg) {
    if (msg.created) return _getNonceForCreatedMessage(msg);
    if (msg.updated) return _getNonceForUpdatedMessage(msg);
    return null;
  }

  /// Get nonce for created message
  String? _getNonceForCreatedMessage(DiscordMessage msg) {
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
  String? _getNonceForUpdatedMessage(DiscordMessage msg) {
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
  ({WaitDiscordMessage? waitMessage, String? id}) _getWaitMessageByContent(
    String content,
  ) {
    final prompt = _content2Prompt(content);

    MapEntry<String, WaitDiscordMessage>? entry;

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
}
