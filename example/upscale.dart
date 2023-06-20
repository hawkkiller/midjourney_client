// ignore_for_file: avoid_print

import 'dart:async';
import 'dart:io';

import 'package:midjourney_client/midjourney_client.dart' as midjourney_client;

import 'env.dart';

Future<void> main(List<Object> arguments) async {
  final client = midjourney_client.Midjourney(
    serverId: Env.serverId,
    channelId: Env.channelId,
    token: Env.token,
    loggerLevel: midjourney_client.MLoggerLevel.verbose,
  );

  await client.init();

  final imagine = client.imagine('Cat with a sword')..listen(print);

  final result = await imagine.last;

  final upscaled = client.upscale(result, 1)..listen(print);

  final uResult = await upscaled.last;

  print('Result: $uResult');
  exit(0);
}
