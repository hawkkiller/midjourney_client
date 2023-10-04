import 'dart:async';

/// A simple wrapper around [Stream] to provide additional functionality.
///
/// [T] is the type of the stream's data.
/// [S] is the type of the stream's expected data.
final class StreamedBroadcastMessage<T extends Object, S extends Object>
    extends StreamView<T> {
  StreamedBroadcastMessage.from(Stream<T> stream)
      : super(stream.asBroadcastStream());

  Future<S> get finished => last.then((value) => value as S);
}
