import 'dart:async';

class RateLimiter {
  RateLimiter({required this.limit, required this.period});

  final int limit;
  final Duration period;
  final List<int> _timestamps = [];

  FutureOr<void> call(void Function() fn) async {
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
    fn();
  }
}
