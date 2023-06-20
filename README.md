# Midjourney Client

Unofficial midjourney client that communicates with the real Midjourney Bot via Discord account token. It's not recommended to use this client in production, because it's not stable yet.

__Note__: This client is not affiliated with Midjourney Bot.

## Examples

### Imagine

This example will trigger /imagine command in the channel.

```shell
dart run --define=SERVER_ID="" --define=CHANNEL_ID="" --define=TOKEN="" bin/midjourney_client.dart
```
