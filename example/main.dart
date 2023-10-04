// ignore_for_file: avoid_print

import 'dart:async';

import 'package:midjourney_client/midjourney_client.dart' as midjourney_client;

import 'env.dart';

Future<void> main(List<Object> arguments) async {
  final client = midjourney_client.Midjourney();

  await client.initialize(
    channelId: Env.channelId,
    serverId: Env.serverId,
    token: Env.token,
    logLevel: midjourney_client.MLoggerLevel.verbose,
  );

  final imagine = client.imagine('Elephant on a tree').asBroadcastStream()
    ..listen(print);

  final result = await imagine.last;

  final upscaled = client.upscale(result, 1).asBroadcastStream()..listen(print);
  final uResult = await upscaled.last;

  print(uResult);
}
