import 'package:http/http.dart' as http;

abstract base class MidjourneyApi {
  const MidjourneyApi();

  /// Imagine a new picture with the given [prompt].
  Future<void> imagine(
    String prompt, {
    bool isDebug = false,
  });
}

final class MidjourneyApiDiscordImpl extends MidjourneyApi {
  MidjourneyApiDiscordImpl({
    http.Client? client,
  }) : _client = client ?? http.Client();

  final http.Client _client;

  @override
  Future<void> imagine(
    String prompt, {
    bool isDebug = false,
  }) async {}

  Future<void> interactions() async {

  }
}
