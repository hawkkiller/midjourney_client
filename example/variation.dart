// ignore_for_file: avoid_print

import 'dart:async';

import 'package:midjourney_client/midjourney_client.dart' as midjourney_client;

import 'env.dart';

Future<void> main(List<Object> arguments) async {
  final client = midjourney_client.Midjourney(
    serverId: Env.serverId,
    channelId: Env.channelId,
    token: Env.token,
    loggerLevel: midjourney_client.MLoggerLevel.debug,
  );

  await client.init();

  final imagine = client.imagine('Cat with sword')..listen(print);

  final result = await imagine.last;

  client.variation(result, 1).listen(print);
  client.variation(result, 2).listen(print);
  client.variation(result, 3).listen(print);
}
