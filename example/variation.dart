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

  final imagine = client.imagine('Cat with sword').asBroadcastStream()
    ..listen(print);

  final imagineResult = await imagine.finished;

  final variation = client.variation(imagineResult, 4).asBroadcastStream()
    ..listen(print);

  final variationResult = await variation.finished;

  print(variationResult);
  exit(0);
}
