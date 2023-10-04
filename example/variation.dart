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

  final imagine = client.imagine('Cat with sword')..listen(print);

  final imagineResult = await imagine.last;

  final variation = client.variation(imagineResult, 1)..listen(print);

  final variationResult = await variation.last;

  print(variationResult);
  exit(0);
}
