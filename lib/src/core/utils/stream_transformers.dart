// ignore_for_file: avoid_types_on_closure_parameters

import 'dart:async';

extension Where<T> on Stream<T> {
  Stream<S> whereType<S>() => transformByHandlers(
        onData: (event, sink) {
          if (event is S) sink.add(event);
        },
      );
}

extension TransformByHandlers<S> on Stream<S> {
  /// Transform a stream by callbacks.
  ///
  /// This is similar to `transform(StreamTransformer.fromHandler(...))` except
  /// that the handlers are called once per event rather than called for the
  /// same event for each listener on a broadcast stream.
  Stream<T> transformByHandlers<T>({
    void Function(S, EventSink<T>)? onData,
    void Function(Object, StackTrace, EventSink<T>)? onError,
    void Function(EventSink<T>)? onDone,
  }) {
    final handleData = onData ?? _defaultHandleData;
    final handleError = onError ?? _defaultHandleError;
    final handleDone = onDone ?? _defaultHandleDone;

    final controller =
        isBroadcast ? StreamController<T>.broadcast(sync: true) : StreamController<T>(sync: true);

    StreamSubscription<S>? subscription;
    controller.onListen = () {
      assert(subscription == null, 'subscription was not null');
      var valuesDone = false;
      subscription = listen(
        (value) => handleData(value, controller),
        onError: (Object error, StackTrace stackTrace) {
          handleError(error, stackTrace, controller);
        },
        onDone: () async {
          valuesDone = true;
          handleDone(controller);
          await controller.close();
          await subscription?.cancel();
        },
      );
      if (!isBroadcast) {
        controller
          ..onPause = subscription!.pause
          ..onResume = subscription!.resume;
      }
      controller.onCancel = () {
        final toCancel = subscription;
        subscription = null;
        if (!valuesDone) return toCancel!.cancel();
        return null;
      };
    };
    return controller.stream;
  }

  static void _defaultHandleData<S, T>(S value, EventSink<T> sink) {
    sink.add(value as T);
  }

  static void _defaultHandleError<T>(
    Object error,
    StackTrace stackTrace,
    EventSink<T> sink,
  ) {
    sink.addError(error, stackTrace);
  }

  static void _defaultHandleDone<T>(EventSink<T> sink) {
    sink.close();
  }
}
