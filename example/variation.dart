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

  final result = await imagine.last;

  final variation = client.variation(result, 1)..listen(print);

  final vResult = await variation.last;

  print(vResult);
  exit(0);
}
