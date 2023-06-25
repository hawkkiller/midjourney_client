import 'dart:async';
import 'dart:collection';

class RateLimiter {
  // Constructor requiring limit and period
  RateLimiter({required this.limit, required this.period});

  /// Maximum calls within a period
  final int limit; 

  /// The period within which the number of calls is limited
  final Duration period;

  /// Queue to hold the timestamps of each function call
  final Queue<int> _timestamps = Queue<int>();

  // Method to call the function with rate limiting
  Future<void> call(void Function() fn) async {
    // Get the current timestamp
    var now = DateTime.now().millisecondsSinceEpoch;

    // If the number of timestamps in the queue is greater than the limit
    while (_timestamps.length >= limit) {
      // Calculate the elapsed time since the first function call
      final elapsed = now - _timestamps.first;

      // If the elapsed time is greater than the limit period
      if (elapsed > period.inMilliseconds) {
        // Remove the earliest timestamp from the queue as it's no longer relevant
        _timestamps.removeFirst();
      } else {
        // Otherwise, delay the next function call until the period has passed
        await Future<void>.delayed(period - Duration(milliseconds: elapsed));
        // Update the current timestamp
        now = DateTime.now().millisecondsSinceEpoch;
      }
    }

    // Add a new timestamp to the queue
    _timestamps.add(now);
    // Execute the function
    fn();
  }
}
