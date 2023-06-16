// ignore_for_file: avoid_print

import 'dart:async';
import 'dart:developer';

import 'package:midjourney_client/midjourney_client.dart' as midjourney_client;
import 'package:midjourney_client/src/core/midjourney/model/midjourney_message.dart';

import 'env.dart';

Future<void> main(List<Object> arguments) async {
  final client = midjourney_client.Midjourney(
    serverId: Env.serverId,
    channelId: Env.channelId,
    token: Env.token,
    loggerLevel: midjourney_client.MLoggerLevel.debug,
  );

  final imagine = client.imagine('Cat with sword')..listen(print);

  final result = await imagine.last;

  if (result is! ImageMessage$Finish) {
    throw Exception('Expected ImageMessage\$Finish but got $imagine');
  }

  log(result.toString());

  client.variation(result, 1).listen(print);
  client.variation(result, 2).listen(print);
  client.variation(result, 3).listen(print);
}
