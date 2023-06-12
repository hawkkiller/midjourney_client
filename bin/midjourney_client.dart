import 'dart:async';

import 'package:midjourney_client/midjourney_client.dart' as midjourney_client;
import 'package:midjourney_client/src/core/utils/logger.dart';

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
    loggerLevel: midjourney_client.MLoggerLevel.debug,
  );

  client.imagine('Cat in a hat').listen(MLogger.i);
  client.imagine('Cat in a mask').listen(MLogger.i);
  client.imagine('Cat with sword').listen(MLogger.i);
}
