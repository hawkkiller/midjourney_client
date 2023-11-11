# How it works?

WIP.

## Overview

Currently, the library uses the Discord APIs, as Midjourney doesn't have a public API yet. Basically it acts as a Discord client and communicates with the Discord gateway. It sends commands which are handled by the Midjourney bot. Then it listens for events and sends them to the library user.

## Technical details

During the initialization, client connects to Discord web socket. It sends the needed commands to maintain the connection:

- Auth message with JWT Token (should be the first message)
- Heartbeat (every 40 seconds)

Also, during initialization all commands are fetched from the Discord API(). They are needed to create pictures, variations and upscales. After that, the client is ready.

---

So, when the client is initialized it can be used to generate images. The generation algorithm is quite simple:

1. When `imagine` method is called, the client generates unique identifier called nonce (using snowflake algorithm) and sends an interaction to Discord REST API. If the interaction was successful, callback is registered in a map called *waitMessageCallbacks* (where key is a nonce and value is a callback). This callback will be used later to notify about generation progress.

2. If everything is **good** (i.e. there are no errors), MidjourneyBot will respond with a message that has the same nonce. The library uses this nonce to get the callback and notify that generation has started. **Note**, that callback not only notifies about progress or errors, but also performs some logic:
    - It detects that the event is "Created" (not "Updated") and has a nonce, which means that generation has started.
    - Then it takes the `id` of the message (not a `nonce`) and stores it in another map called *waitMessages* where a key is `id` and a value is `(nonce, prompt)`. The nonce is needed to get the notify callback from *waitMessageCallbacks* as later update events will not have `nonce`, so it is needed to get the associated nonce with the `id` of message and after that, by nonce, find the needed notify callback.
    - When generation finishes, midjourney **deletes** original message and there is no other way to link original one and completed except matching by prompt.

3. When Midjourney **updates** image, it alters original one, so `id` remains the same, but nonce is null. As described above, the library uses `id` to get the nonce and then the callback.

TODO: When message is deleted mark it as waiting for complete.
