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

  final imagine = client.imagine('Cat in a hat')..listen(print);

  final result = await imagine.finished;

  print('Result: $result');
  exit(0);
}
