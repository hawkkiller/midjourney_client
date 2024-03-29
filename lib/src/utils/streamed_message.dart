import 'dart:async';

/// A simple wrapper around [Stream] to provide additional functionality.
///
/// [T] is the type of the stream's data.
/// [S] is the type of the stream's expected data.
final class StreamedMessage<T extends Object, S extends T>
    extends StreamView<T> {
  StreamedMessage.from(super.stream);

  Future<S> get finished => last.then((value) => value as S);

  @override
  StreamedMessage<T, S> asBroadcastStream({
    void Function(StreamSubscription<T> subscription)? onListen,
    void Function(StreamSubscription<T> subscription)? onCancel,
  }) =>
      StreamedMessage.from(
        super.asBroadcastStream(
          onListen: onListen,
          onCancel: onCancel,
        ),
      );
}
