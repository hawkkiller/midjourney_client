import 'dart:async';

class RateLimiter<T> {
  RateLimiter(this._duration);

  final Duration _duration;

  bool _isFirst = true;

  late final stream = _controller.stream.asyncMap<T>(
    (event) {
      if (_isFirst) {
        _isFirst = false;
        return event;
      }

      return Future.delayed(_duration, () => event);
    },
  );

  late final _controller = StreamController<T>.broadcast();

  void add(T value) => _controller.add(value);

  Future<void> close() => _controller.close();
}
