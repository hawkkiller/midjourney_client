# Unofficial Midjourney Client

Enhance your creative workflows with the Unofficial Midjourney Client, designed to integrate seamlessly with Discord's Midjourney Bot. Discover the potential of this library, whether you're crafting digital art or exploring new AI-driven frontiers.

## Quick Navigation

- [Installation Instructions](#installation)
- [Getting Started](#getting-started)
- [Configuration Steps](#configuration)
- [Practical Examples](#examples)

## Installation

### Flutter Projects

```shell
flutter pub add midjourney_client
```

### Dart Projects

```shell
dart pub add midjourney_client
```

> This command incorporates the `midjourney_client` package along with necessary dependencies into your project.

## Getting Started

```dart
import 'dart:async';
import 'package:midjourney_client/midjourney_client.dart';

Future<void> main() async {
  var client = MidjourneyClient();
  
  // Initialization with environment variables
  await client.initialize(
    channelId: Env.channelId,
    serverId: Env.serverId,
    token: Env.token,
  );

  // Example: Imagining an Elephant on a tree
  var imaginationStream = client.imagine('Elephant on a tree');
  imaginationStream.listen(print);

  // Retrieving and printing the last item from the stream
  var finalImagination = await imaginationStream.last;
  print(finalImagination);
}
```

## Configuration

### Prerequisites

- [Discord Account](https://discord.com/register)
- [Discord Server Setup Guide](https://support.discord.com/hc/en-us/articles/204849977)

### Acquiring Server & Channel IDs

1. Navigate to your Discord server.
2. Right-click on the desired channel.
3. Select 'Copy ID' for both server and channel.

### Obtaining Your Token

1. Log into the Discord Web App.
2. Open the developer console (Network tab).
3. Send a message or refresh the page.
4. Look for the 'Authorization' header in request headers.
5. Copy the token value.

> **Note:** The token is sensitive information. Do not share it with anyone.

## Examples

### Imagine

Execute the `/imagine` command and showcase the results.

```shell
dart run --define=SERVER_ID="" --define=CHANNEL_ID="" --define=TOKEN="" example/imagine.dart
```

```dart
final client = midjourney_client.Midjourney();

await client.initialize(
  channelId: Env.channelId,
  serverId: Env.serverId,
  token: Env.token,
);

final imagine = client.imagine('Cat in a hat');

final result = await imagine.finished;
```

### Variation

Create a variation on a theme with the Midjourney Bot.

```shell
dart run --define=SERVER_ID="" --define=CHANNEL_ID="" --define=TOKEN="" example/variations.dart
```

```dart
await client.initialize(
  channelId: Env.channelId,
  serverId: Env.serverId,
  token: Env.token,
);

final imagine = client.imagine('Cat with sword');

final imagineResult = await imagine.finished;

final variation = client.variation(imagineResult,1);

final result = await variation.finished
```

### Upscale

Upscale an image for enhanced detail and clarity.

```shell
dart run --define=SERVER_ID="" --define=CHANNEL_ID="" --define=TOKEN="" example/upscale.dart
```

```dart
final client = midjourney_client.Midjourney();

await client.initialize(
  channelId: Env.channelId,
  serverId: Env.serverId,
  token: Env.token,
);

final imagine = client.imagine('Cat with asword');

final imagineResult = await imagine.finished;

final upscaled = client.upscale(imagineResult, 1);

final result = await upscaled.finished;
```

> **Note:** All examples code are located in the `example` folder.
