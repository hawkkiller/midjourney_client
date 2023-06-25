import 'package:test/test.dart';
import 'core/discord_test.dart' as discord_test;
import 'utils/utils_test.dart' as utils_test;

void main() {
  group('Midjourney Client >', () {
    discord_test.main();
    utils_test.main();
  });
}
