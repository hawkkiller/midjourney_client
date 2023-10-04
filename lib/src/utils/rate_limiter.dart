import 'dart:async';

/// A simple rate limiter.
/// 
/// Set [limit] to the maximum number of calls per [period].
/// 
/// If the number of calls exceeds the limit, the next call will be delayed
/// 
/// Example:
/// 
/// ```dart
/// final rateLimiter = RateLimiter(limit: 5, period: Duration(seconds: 1));
/// 
/// for (var i = 0; i < 10; i++) {
///  await rateLimiter(() async {
///   print('Hello world!');
/// });
/// }
/// ```
/// This will print "Hello world!" 5 times per second.
class RateLimiter {
  RateLimiter({required this.limit, required this.period});

  final int limit;
  final Duration period;
  final List<int> _timestamps = [];

  Future<void> call(FutureOr<void> Function() fn) async {
    var now = DateTime.now().millisecondsSinceEpoch;

    // If the number of timestamps in the list is equal to or greater than the limit
    if (_timestamps.length >= limit) {
      // Enter a loop to process existing timestamps
      while (_timestamps.isNotEmpty) {
        final elapsed = now - _timestamps[0];

        if (elapsed >= period.inMilliseconds) {
          // Remove the earliest timestamp from the list as it's no longer relevant
          _timestamps.removeAt(0);
        } else {
          // Otherwise, delay the next function call until the period has passed
          await Future<void>.delayed(period - Duration(milliseconds: elapsed));
          now = DateTime.now().millisecondsSinceEpoch;
        }
      }
    }
    _timestamps.add(now);
    await fn();
  }
}
