import 'dart:async';

import 'package:ws/ws.dart';

enum WebsocketState {
  connecting,
  open,
  disconnecting,
  closed;
}

extension WebsocketStateX on WebSocketReadyState {
  WebsocketState get websocketState => switch (this) {
        WebSocketReadyState.connecting => WebsocketState.connecting,
        WebSocketReadyState.open => WebsocketState.open,
        WebSocketReadyState.disconnecting => WebsocketState.disconnecting,
        WebSocketReadyState.closed => WebsocketState.closed,
      };
}

abstract interface class WebsocketClient {
  /// The stream of events from the websocket.
  abstract final Stream<Object> stream;

  /// The stream of state changes from the websocket.
  abstract final Stream<WebsocketState> stateChanges;

  /// Add an event to the websocket.
  FutureOr<void> add(Object event);

  /// Connect to the websocket.
  Future<void> connect(String url);

  /// Close the websocket.
  Future<void> disconnect([
    int? code = 1000,
    String? reason = 'NORMAL_CLOSURE',
  ]);
}

final class WebsocketClient$Ws implements WebsocketClient {
  WebsocketClient$Ws();

  final _ws = WebSocketClient();

  @override
  Stream<Object> get stream => _ws.stream;

  @override
  FutureOr<void> add(Object event) => _ws.add(event);

  @override
  Future<void> connect(String url) => _ws.connect(url);

  @override
  Future<void> disconnect([
    int? code = 1000,
    String? reason = 'NORMAL_CLOSURE',
  ]) =>
      _ws.disconnect(code, reason);

  @override
  Stream<WebsocketState> get stateChanges => _ws.stateChanges.map(
        (event) => event.readyState.websocketState,
      );
}
