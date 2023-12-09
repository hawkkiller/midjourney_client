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
final class LinkedMessage {
  LinkedMessage({
    required this.discordMessage,
    required this.inProgressMessage,
  });

  final DiscordMessage discordMessage;
  final InProgressMessage inProgressMessage;

  @override
  String toString() => (StringBuffer()
        ..write('LinkedMessage(')
        ..write('discordMessage: $discordMessage, ')
        ..write('inProgressMessage: $inProgressMessage')
        ..write(')'))
      .toString();
}

/// Model that is used to store temporary data about a message that is being waited for.
///
/// This model is created when `MESSAGE_CREATE` event is emitted at first.
final class InProgressMessage {
  InProgressMessage({
    required this.nonce,
    required this.prompt,
    required this.id,
  });

  final String nonce;
  final String? prompt;
  final String? id;

  @override
  String toString() => (StringBuffer()
        ..write('InProgressMessage(')
        ..write('nonce: $nonce, ')
        ..write('prompt: $prompt, ')
        ..write('id: $id')
        ..write(')'))
      .toString();
}

/// Discord connection interface
///
/// This is used to communicate with Discord.
abstract interface class DiscordConnection {
  /// Wait for a message with the given [nonce].
  Stream<MidjourneyMessageImage> waitImageMessage(String nonce);

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
  /// Key is message ID, value is [InProgressMessage]
  final Map<String, InProgressMessage> _inProgressMessages = {};

  /// Callbacks for waiting messages
  ///
  /// Key is nonce, value is a callback
  final _inProgressCalbacks = <String, ValueChanged<LinkedMessage>>{};

  StreamSubscription<LinkedMessage>? _messagesSubscription;
  StreamSubscription<WebsocketState>? _socketStateSubscription;

  @override
  Future<void> close() async {
    _heartbeatTimer?.cancel();
    await _webSocketClient.disconnect();
    await _messagesSubscription?.cancel();
    await _socketStateSubscription?.cancel();

    _inProgressCalbacks.clear();
    _inProgressMessages.clear();
  }

  @override
  Future<void> initialize() => _establishWebSocketConnection();

  /// Wait for an [MidjourneyMessageImage] with a given [nonce]. Returns a stream of [MidjourneyMessageImage].
  /// This stream broadcasts multiple subscribers and synchronizes the delivery of events.
  /// It registers a callback function that adds new messages to the stream or, in case of an error,
  /// adds the error to the stream and then closes it.
  @override
  Stream<MidjourneyMessageImage> waitImageMessage(String nonce) async* {
    final controller = StreamController<MidjourneyMessageImage>.broadcast(
      sync: true,
    );

    _registerImageMessageNotifyCallback(
      nonce,
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

  /// Register a callback to be invoked once an
  /// image message with a specific nonce is received
  void _registerImageMessageNotifyCallback(
    String nonce,
    ImageProgressNotifyCallback notify,
  ) {
    _inProgressCalbacks[nonce] = (discordMsg) async {
      await _imageMessageNotifyCallback(discordMsg, notify, nonce);
    };
    MLogger.instance.v('Registered callback for nonce $nonce');
  }

  /// Process the image message callback
  /// If the nonce of the incoming message matches the expected nonce,
  /// handle the message according to its state and invoke the callback with appropriate arguments
  Future<void> _imageMessageNotifyCallback(
    LinkedMessage linkedMessage,
    ImageProgressNotifyCallback callback,
    String nonce,
  ) async {
    if (linkedMessage.inProgressMessage.nonce != nonce) return;

    // Discord message
    final discordMessage = linkedMessage.discordMessage;

    // If the message is created, then:
    // - if it has a nonce -> it is the first message,
    //   that signifies the start of the image generation
    // - if it has no nonce -> image generation is finished
    if (discordMessage.isCreated) {
      await _handleCreatedImageMessage(linkedMessage, callback, nonce);
      return;
    }

    // Updated message event
    // Nonce should be null and attachments should be present
    if (discordMessage.isUpdated &&
        discordMessage.nonce == null &&
        (discordMessage.attachments?.isNotEmpty ?? false)) {
      await _handleUpdatedImageMessage(discordMessage, callback, nonce);
      return;
    }

    return;
  }

  Future<void> _imageMessageError({
    required ImageProgressNotifyCallback notify,
    required String error,
    required String nonce,
  }) async {
    notify(null, MidjourneyException(error));
    _removeInProgressMessage(nonce);
  }

  void _removeInProgressMessage(String nonce) {
    _inProgressCalbacks.remove(nonce);
    _inProgressMessages.removeWhere((key, value) => value.nonce == nonce);
  }

  /// Get job id from uri
  /// https://cdn.discordapp.com/bla/bla/bla/some_title_ed0bd7bf-f628-4e9w-828a-cebee56e0d5f.png
  /// where ed0bd7bf-f628-4e9d-828a-cebee56e0d5f is the job id
  String _getJobId(String uri) {
    final uriSegments = Uri.parse(uri).pathSegments;
    final jobId = uriSegments.last.split('_').last.split('.').first;
    return jobId;
  }

  /// Handle created image message
  ///
  /// If the message has a nonce, add it to the waiting pool
  /// and trigger an image generation started event.
  ///
  /// If the message has no nonce, remove it from the waiting
  /// pool and trigger an image generation finished event.
  Future<void> _handleCreatedImageMessage(
    LinkedMessage linkedMessage,
    ImageProgressNotifyCallback notify,
    String nonce,
  ) async {
    final msg = linkedMessage.discordMessage;

    if (msg.nonce == null) {
      // Clean up
      _removeInProgressMessage(nonce);

      final uri = msg.attachments!.first.url.replaceHost(config.cdnUrl);

      final jobId = _getJobId(uri);

      final seed = getSeedFromContent(msg.content ?? '');

      // Trigger an image generation finished event
      await notify(
        MidjourneyMessageImageFinish(
          id: nonce,
          messageId: msg.id!,
          content: msg.content!,
          jobId: jobId,
          seed: seed,
          uri: uri,
        ),
        null,
      );
      MLogger.instance.d('Triggered image generation finished event');
      return;
    }
    String? reason;
    final embeds = msg.embeds ?? [];
    // check if there is an issue with message, i.e. error or warning
    if (embeds.isNotEmpty) {
      final embed = embeds.first;

      // Discord error color
      if (embed.color == 16711680) {
        await _imageMessageError(
          notify: notify,
          error: embed.description!,
          nonce: nonce,
        );
        MLogger.instance.e('Discord error: ${embed.description}');
        return;
      }

      if (embed.color == 16776960) {
        MLogger.instance.w('Discord warning: ${embed.description}');
      }

      final title = embed.title;
      final description = embed.description;

      if (title == null || description == null) {
        // do nothing
      } else if (title.contains('continue') && description.contains("verify you're human")) {
        // TODO(hawkkiller): handle captcha
        return;
      } else if (title.contains('Invalid')) {
        await _imageMessageError(
          notify: notify,
          error: embed.description!,
          nonce: nonce,
        );
        MLogger.instance.e('Discord error: ${embed.description}');
        return;
      } else if (title.contains('Job queued')) {
        reason = '$title\n$description';
      }
    }
    _inProgressMessages[msg.id!] = InProgressMessage(
      nonce: msg.nonce!,
      prompt: _content2Prompt(msg.content),
      id: msg.id,
    );
    MLogger.instance.d('Added ${msg.id} to in progress messages');

    final seed = getSeedFromContent(msg.content ?? '');

    // Trigger an image generation started event
    await notify(
      MidjourneyMessageImageProgress(
        progress: 0,
        id: msg.nonce!,
        messageId: msg.id!,
        content: reason ?? msg.content ?? '',
        seed: seed,
      ),
      null,
    );
    MLogger.instance.d('Triggered image generation started event');
    return;
  }

  @visibleForTesting
  int? getProgressFromContent(String content) {
    final progressMatch = RegExp(r'\((\d+)%\)').firstMatch(content);
    final progress = progressMatch != null ? int.tryParse(progressMatch.group(1) ?? '0') : null;
    return progress;
  }

  @visibleForTesting
  int? getSeedFromContent(String content) {
    final seedMatch = Constants.seedRegex.firstMatch(content);
    final seed = seedMatch != null ? int.tryParse(seedMatch.group(1) ?? '') : null;
    return seed;
  }

  /// Handle updated image message
  ///
  /// Trigger an image progress event.
  Future<void> _handleUpdatedImageMessage(
    DiscordMessage msg,
    ImageProgressNotifyCallback callback,
    String nonce,
  ) async {
    final progress = getProgressFromContent(msg.content ?? '') ?? 0;

    final seed = getSeedFromContent(msg.content ?? '');

    final uri = msg.attachments!.first.url.replaceHost(config.cdnUrl);

    final jobId = _getJobId(uri);

    // Trigger an image progress event
    await callback(
      MidjourneyMessageImageProgress(
        id: nonce,
        progress: progress,
        messageId: msg.id!,
        content: msg.content!,
        uri: uri,
        seed: seed,
        jobId: jobId,
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
          final isMidjourneyBot = event.author?.id == Constants.botID;

          final show = isChannel && isMidjourneyBot;

          if (!show) return false;

          return isChannel && isMidjourneyBot;
        })
        .map(_linkDiscordToInProgressMessage)
        .whereType<LinkedMessage>()
        .listen(_handleDiscordMessage);
  }

  /// Handle WebSocket state changes and perform related actions
  ///
  /// This method is called once the client is initialized.
  void _handleWebSocketStateChanges() {
    _socketStateSubscription = _webSocketClient.stateChanges.listen(
      (event) async {
        MLogger.instance.d('WebSocket state change: $event');
        if (event == WebsocketState.open) {
          await _authenticate();
          _initiatePeriodicHeartbeat();
        }
      },
    );
  }

  /// Authenticate client with Discord server
  ///
  /// This method is called once the connection is established.
  Future<void> _authenticate() async {
    final authJson = DiscordWsAuth(config.token).toJson();
    await _webSocketClient.add(jsonEncode(authJson));
    MLogger.instance.v('Auth sent $authJson');
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
    MLogger.instance.v('Heartbeat sent $heartbeatJson');
  }

  /// Process incoming Discord message and map it to nonce-message pair
  LinkedMessage? _linkDiscordToInProgressMessage(
    DiscordMessage discordMessage,
  ) {
    final inProgressMessage = _getInProgressMessage(discordMessage);

    if (inProgressMessage == null) {
      MLogger.instance.v(
        'No inProgress message found for ${discordMessage.id}, $_inProgressMessages',
      );
      return null;
    }

    return LinkedMessage(
      inProgressMessage: inProgressMessage,
      discordMessage: discordMessage,
    );
  }

  /// Handle received Discord event
  void _handleDiscordMessage(LinkedMessage event) {
    MLogger.instance.v('Discord message received: $event');
    final callback = _inProgressCalbacks[event.inProgressMessage.nonce];
    callback?.call(event);
  }

  /// Get nonce associated with a message
  InProgressMessage? _getInProgressMessage(DiscordMessage msg) {
    if (msg.isCreated) return _getInProgressMessageForCreatedMessage(msg);
    if (msg.isUpdated) return _getInProgressMessageForUpdatedMessage(msg);
    if (msg.isDelete) return _getInProgressMessageForDeletedMessage(msg);

    return null;
  }

  /// Get nonce for deleted message
  InProgressMessage? _getInProgressMessageForDeletedMessage(
    DiscordMessage msg,
  ) {
    final message = _inProgressMessages[msg.id];

    if (message == null) {
      MLogger.instance.v('In progress messages: $_inProgressMessages');
      MLogger.instance.v('In progress message callbacks: $_inProgressCalbacks');
      MLogger.instance.d(
        'No in progress message found for ${msg.id}, returning',
      );

      return null;
    }

    return message;
  }

  /// Get nonce for created message
  InProgressMessage? _getInProgressMessageForCreatedMessage(
    DiscordMessage msg,
  ) {
    if (msg.nonce != null) {
      MLogger.instance.d('Created message: ${msg.id}');
      return InProgressMessage(
        nonce: msg.nonce!,
        id: msg.id,
        prompt: null,
      );
    }

    // Get nonce for created message without nonce
    final msgWithSamePrompt = _getInProgressMessageByContent(msg.content!);

    return msgWithSamePrompt;
  }

  /// Get nonce for updated message
  InProgressMessage? _getInProgressMessageForUpdatedMessage(
    DiscordMessage msg,
  ) {
    MLogger.instance.v('Trying to find nonce for updated message: ${msg.id}');
    final message = _inProgressMessages[msg.id];

    if (message == null) {
      MLogger.instance.v('In progress messages: $_inProgressMessages');
      MLogger.instance.v('In progress message callbacks: $_inProgressCalbacks');

      return null;
    }

    return message;
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
      MLogger.instance.w('Failed to parse prompt from content: $content');
      return content;
    }
  }

  /// Get In progress message by content
  InProgressMessage? _getInProgressMessageByContent(
    String content,
  ) {
    final prompt = _content2Prompt(content);

    for (final message in _inProgressMessages.values) {
      if (message.prompt == prompt) {
        return message;
      }
    }

    return null;
  }
}
