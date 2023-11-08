# Midjourney Client Changelog

Format - `## {version} (YYYY-MM-DD)`

## 0.4.1 (2023-11-07)

- Added more tests
- Refactored inner structure & code & comments
- Now commands are fetched during initialization
- Refactored Logger

## 0.4.0 (2023-11-06)

- Versions are not marked as alpha anymore
- Refactored modules & improved docs

## 0.3.4-alpha (2023-06-30)

- Fixed wrong discord baseUrl

## 0.3.3-alpha (2023-06-29)

- Moved initialization logic to `init` method of `Midjourney`
- Transformed `Midjourney` to singleton
- Added `close` method to `Midjourney`
- Updated ws library to 0.0.7-dev

## 0.3.2-dev.7 (2023-06-28)

- Updated ws library

## 0.3.2-dev.6 (2023-06-28)

- Added Proxy Support

## 0.3.2-dev.5 (2023-06-27)

- Fixed wrong queued behaviour [#32](https://github.com/hawkkiller/midjourney_client/issues/32)

## 0.3.2-dev.4 (2023-06-27)

- Added clear description to queued warning [#32](https://github.com/hawkkiller/midjourney_client/issues/32)

## 0.3.2-dev.3 (2023-06-26)

- Fixed failures with rate limiter and interactions

## 0.3.2-dev.2 (2023-06-25)

- Created interface for websocket

## 0.3.2-dev.1 (2023-06-25)

- Fixed embed structure

## 0.3.2-dev.0 (2023-06-25)

- Redesigned RateLimiter
- Created tests for RateLimiter
- Created general structure for tests

## 0.3.1-dev.0 (2023-06-24)

- Added unique identifiers to `MidjourneyMessage`
- Renamed `id` to `messageId`

## 0.3.0-dev.1 (2023-06-20)

- Created README
- Improved examples

## 0.3.0-dev.0 (2023-06-19)

- Implemented `imagine` command.
- Fixed bug when overloaded with concurrent jobs.

## 0.2.0-dev.3 (2023-06-18)

- Removed useless dependencies

## 0.2.0-dev.2 (2023-06-18)

- Stick to dart line length 80

## 0.2.0-dev.1 (2023-06-18)

- Implemented `variation` command.
- Added init method

## 0.1.0-dev.0 (2023-06-09)

- Implemented models for interaction with API.
- Implemented `imagine` command.

## 0.0.1 (2023-06-08)

- Initial version.
