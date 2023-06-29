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

  final imagine = client.imagine('Cat with a sword')..listen(print);

  final result = await imagine.last;

  final upscaled = client.upscale(result, 1)..listen(print);

  final uResult = await upscaled.last;

  print('Result: $uResult');
  exit(0);
}
