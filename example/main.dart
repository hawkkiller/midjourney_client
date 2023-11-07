// ignore_for_file: avoid_print

import 'dart:async';
import 'dart:io';

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

  final imagineResult = await imagine.finished;

  final upscaled = client.upscale(imagineResult, 1).asBroadcastStream()
    ..listen(print);

  final upscaleResult = await upscaled.finished;

  print(upscaleResult);
  exit(0);
}
