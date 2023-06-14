import 'dart:async';

import 'package:midjourney_client/midjourney_client.dart' as midjourney_client;
import 'package:midjourney_client/src/core/model/midjourney/midjourney_message.dart';
import 'package:midjourney_client/src/core/utils/logger.dart';
import 'env.dart';

Future<void> main(List<Object> arguments) async {
  final client = midjourney_client.Midjourney(
    serverId: Env.serverId,
    channelId: Env.channelId,
    token: Env.token,
    loggerLevel: midjourney_client.MLoggerLevel.verbose,
  );

  final result = await client.imagine('Cat with sword').last;

  MLogger.i(result);

  if (result is! ImageMessage$Finish) {
    throw Exception('Expected ImageMessage\$Finish but got $result');
  }

  client.variation(result, 1).listen(MLogger.e);
}
