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
  );

  final imagine = client.imagine('Cat with a sword').asBroadcastStream()
    ..listen(print);

  final imagineResult = await imagine.finished;

  final upscaled = client.upscale(imagineResult, 1).asBroadcastStream()
    ..listen(print);

  final upscaledResult = await upscaled.finished;

  print('Result: $upscaledResult');
  exit(0);
}
