# Midjourney Client (Unofficial)

This is an unofficial client for Midjourney that interfaces with the authentic Midjourney Bot via a Discord account token. As of now, it's stability has not been thoroughly tested. Consequently, it is advised against utilizing this client in production environments.

## Table of Contents

- [Midjourney Client (Unofficial)](#midjourney-client-unofficial)
  - [Table of Contents](#table-of-contents)
  - [Install](#install)
  - [Usage](#usage)
  - [Set up](#set-up)
    - [How to get server id \& channel id](#how-to-get-server-id--channel-id)
    - [How to get token](#how-to-get-token)
  - [Examples](#examples)
    - [Imagine](#imagine)
    - [Variation](#variation)
    - [Upscale](#upscale)

## Install

For a flutter project, consider running this command:

```shell
flutter pub add midjourney_client
```

For a dart project, consider running this command:

```shell
dart pub add midjourney_client
```

This installs the midjourney_client library and its dependencies.

## Usage

```dart

import 'dart:async';

import 'package:midjourney_client/midjourney_client.dart' as midjourney_client;

Future<void> main(List<Object> arguments) async {
  final client = midjourney_client.Midjourney();

  await client.initialize(
    channelId: Env.channelId,
    serverId: Env.serverId,
    token: Env.token,
  );

  final imagine = client.imagine('Elephant on a tree')..listen(print);

  final result = await imagine.last;

  final upscaled = client.upscale(result, 1)..listen(print);
  final uResult = await upscaled.last;

  print(uResult);
}

```

## Set up

__Pre-requisites__:

- [Discord account](https://discord.com/register)
- [Discord server](https://support.discord.com/hc/en-us/articles/204849977-How-do-I-create-a-server-)

### How to get server id & channel id

1. Open Discord app
2. Open your server
3. Right click on the message inside the channel you want to use
4. Copy link to message, this should look like `https://discord.com/channels/${SERVER_ID}/${CHANNEL_ID}/${MESSAGE_ID}`
5. Extract `SERVER_ID` and `CHANNEL_ID` from the link

### How to get token

This one is a bit tricky, but here's how you can get it:

1. Login to discord web app
2. Open developer tools, head for Network tab
3. Send a message to the channel you want to use or reload the page
4. Click on a random request and go to request headers
5. Find `Authorization` header and extract the value, it is your token

## Examples

This examples will instantiate a websocket connection to Discord Server and act as a Discord client sending messages to the channel specified by the `CHANNEL_ID` environment variable. The `SERVER_ID` environment variable is used to identify the server to which the channel belongs. The `TOKEN` environment variable is used to authenticate the client.

### Imagine

This example will trigger `/imagine` command on the Midjourney Bot and print the result.

```shell
dart run --define=SERVER_ID="" --define=CHANNEL_ID="" --define=TOKEN="" example/imagine.dart
```

```dart
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

  final result = await imagine.last;

  print('Result: $result');
  exit(0);
}
```

### Variation

This example will trigger `/imagine` command on the Midjourney Bot, wait and trigger first variation.

```shell
dart run --define=SERVER_ID="" --define=CHANNEL_ID="" --define=TOKEN="" example/variations.dart
```

```dart
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
```

### Upscale

This example will trigger `/imagine` command on the Midjourney Bot, wait and trigger first upscale.

```shell
dart run --define=SERVER_ID="" --define=CHANNEL_ID="" --define=TOKEN="" example/upscale.dart
```

```dart
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
```
