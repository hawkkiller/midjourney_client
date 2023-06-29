import 'package:midjourney_client/src/utils/rate_limiter.dart';
import 'package:test/test.dart';

void main() {
  group('Utils >', () {
    group('Rate Limiter >', () {
      late RateLimiter rateLimiter;
      late Duration period;
      late int limit;

      setUp(() {
        limit = 1;
        period = const Duration(seconds: 1);
        rateLimiter = RateLimiter(
          limit: limit,
          period: period,
        );
      });

      test('Should not allow more than 1 requests per second', () async {
        var counter = 0;

        for (var i = 0; i < 2; i++) {
          rateLimiter(() => counter++).ignore();
        }

        expect(counter, 1);

        await Future<void>.delayed(period);

        expect(counter, 2);
      });

      test('Should not lose stackTrace', () async {
        var counter = 0;

        await rateLimiter(() => counter++);

        expect(counter, 1);

        expect(
          () async => rateLimiter(() {
            counter++;
            throw Exception('Test');
          }),
          throwsA(isA<Exception>()),
        );
      });

      test('Should not break if error occur', () async {
        var counter = 0;

        expect(
          () => rateLimiter(() {
            counter++;
            throw Exception('Test');
          }),
          throwsA(isA<Exception>()),
        );

        expect(counter, 1);

        rateLimiter(() => counter++).ignore();

        await Future<void>.delayed(period);

        expect(counter, 2);
      });

      test('Should consider the limit', () async {
        limit = 2;
        rateLimiter = RateLimiter(
          limit: limit,
          period: period,
        );

        var counter = 0;

        for (var i = 0; i < 3; i++) {
          rateLimiter(() => counter++).ignore();
        }

        expect(counter, 2);

        await Future<void>.delayed(period);

        expect(counter, 3);

        limit = 10;
        counter = 0;

        rateLimiter = RateLimiter(
          limit: limit,
          period: period,
        );

        for (var i = 0; i < 10; i++) {
          rateLimiter(() => counter++).ignore();
        }

        expect(counter, 10);
      });

      test('Should work correctly with delays', () async {
        var counter = 0;
        rateLimiter.call(() => counter++).ignore();

        expect(counter, 1);

        await Future<void>.delayed(period);

        await rateLimiter(() => counter++);
        rateLimiter(() => counter++).ignore();

        expect(counter, 2);

        await Future<void>.delayed(period);

        expect(counter, 3);
      });
    });
  });
}
