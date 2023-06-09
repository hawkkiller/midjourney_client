import 'package:midjourney_client/midjourney_client.dart' as midjourney_client;

class Env {
  static const serverId = String.fromEnvironment('SERVER_ID');
  static const channelId = String.fromEnvironment('CHANNEL_ID');
  static const token = String.fromEnvironment('TOKEN');
}

Future<void> main(List<Object> arguments) async {
  final client = midjourney_client.Midjourney(
    serverId: Env.serverId,
    channelId: Env.channelId,
    token: Env.token,
    isDebug: true,
  );

  await client.imagine('Cat in a hat');
}
