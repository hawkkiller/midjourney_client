import 'dart:async';

import 'package:midjourney_client/midjourney_client.dart' as midjourney_client;
import 'package:midjourney_client/src/core/utils/logger.dart';
import 'env.dart';

Future<void> main(List<Object> arguments) async {
  final client = midjourney_client.Midjourney(
    serverId: Env.serverId,
    channelId: Env.channelId,
    token: Env.token,
    loggerLevel: midjourney_client.MLoggerLevel.debug,
  );

  client.imagine('Elephant on a tree').listen(MLogger.i);
}
