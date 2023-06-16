import 'dart:convert';

import 'package:meta/meta.dart';
import 'package:midjourney_client/src/core/utils/logger.dart';

@immutable
sealed class DiscordMessage {
  const DiscordMessage();
}

final class DiscordMessage$Unsupported extends DiscordMessage {
  const DiscordMessage$Unsupported({
    required this.type,
    required this.data,
  });

  final String type;
  final Map<String, Object?> data;

  @override
  String toString() => (
        StringBuffer()
          ..writeAll(
            [
              '$type(',
              'type: $type, ',
              'data: $data',
              ')',
            ],
          ),
      )
          .toString();
}

sealed class DiscordMessage$Message extends DiscordMessage {
  const DiscordMessage$Message({
    required this.id,
    required this.content,
    required this.embeds,
    required this.author,
    this.nonce,
    this.attachments,
  });

  final String content;
  final String id;
  final List<Embed> embeds;
  final Author author;
  final String? nonce;
  final List<Attachment>? attachments;

  @override
  String toString() => (
        StringBuffer()
          ..writeAll(
            [
              '$runtimeType(',
              'id: $id, ',
              'content: $content, ',
              'embeds: $embeds, ',
              'auhor: $author, ',
              'nonce: $nonce, ',
              'attachments: $attachments',
              ')',
            ],
          ),
      )
          .toString();
  
  bool get created => switch (this) {
        DiscordMessage$MessageCreate() => true,
        _ => false,
      }; 
  
  bool get updated => switch (this) {
        DiscordMessage$MessageUpdate() => true,
        _ => false,
      };
}

final class DiscordMessage$MessageCreate extends DiscordMessage$Message {
  const DiscordMessage$MessageCreate({
    required super.id,
    required super.content,
    required super.embeds,
    required super.author,
    super.nonce,
    super.attachments,
  });

  factory DiscordMessage$MessageCreate.fromJson(Map<String, Object?> json) =>
      DiscordMessage$MessageCreate(
        nonce: json['nonce'] as String?,
        id: json['id']! as String,
        content: json['content']! as String,
        author: Author.fromJson(json['author']! as Map<String, Object?>),
        attachments: (json['attachments'] as List<Object?>?)
            ?.map((e) => Attachment.fromJson(e! as Map<String, Object?>))
            .toList(),
        embeds: (json['embeds']! as List<Object?>)
            .map((e) => Embed.fromJson(e! as Map<String, Object?>))
            .toList(),
      );
}

final class DiscordMessage$MessageUpdate extends DiscordMessage$Message {
  const DiscordMessage$MessageUpdate({
    required super.id,
    required super.embeds,
    required super.content,
    required super.author,
    super.attachments,
    super.nonce,
  });

  factory DiscordMessage$MessageUpdate.fromJson(Map<String, Object?> json) =>
      DiscordMessage$MessageUpdate(
        nonce: json['nonce'] as String?,
        id: json['id']! as String,
        content: json['content'] as String? ?? '',
        author: Author.fromJson(json['author']! as Map<String, Object?>),
        attachments: (json['attachments'] as List<Object?>?)
            ?.map((e) => Attachment.fromJson(e! as Map<String, Object?>))
            .toList(),
        embeds: (json['embeds']! as List<Object?>)
            .map((e) => Embed.fromJson(e! as Map<String, Object?>))
            .toList(),
      );
}

@immutable
final class Embed {
  const Embed({
    required this.title,
    required this.description,
    required this.color,
  });

  factory Embed.fromJson(Map<String, Object?> json) => Embed(
        title: json['title']! as String,
        description: json['description']! as String,
        color: json['color']! as int,
      );

  final String title;
  final String description;
  final int color;

  @override
  String toString() => (
        StringBuffer()
          ..writeAll(
            [
              'Embed(',
              'title: $title, ',
              'description: $description, ',
              'color: $color',
              ')',
            ],
          ),
      )
          .toString();
}

@immutable
final class Attachment {
  const Attachment({
    required this.width,
    required this.height,
    required this.url,
    required this.proxyUrl,
    required this.size,
    required this.filename,
    required this.id,
  });

  factory Attachment.fromJson(Map<String, Object?> json) => Attachment(
        width: json['width']! as int,
        height: json['height']! as int,
        url: json['url']! as String,
        proxyUrl: json['proxy_url']! as String,
        size: json['size']! as int,
        filename: json['filename']! as String,
        id: json['id']! as String,
      );

  final int width;
  final int height;
  final String url;
  final String proxyUrl;
  final int size;
  final String filename;
  final String id;

  @override
  String toString() => (
        StringBuffer()
          ..writeAll(
            [
              'Attachment(',
              'width: $width, ',
              'height: $height, ',
              'url: $url, ',
              'proxyUrl: $proxyUrl, ',
              'size: $size, ',
              'filename: $filename, ',
              'id: $id',
              ')',
            ],
          ),
      )
          .toString();
}

@immutable
final class Author {
  const Author({
    required this.username,
    required this.discriminator,
    required this.id,
    required this.avatar,
    required this.bot,
  });

  factory Author.fromJson(Map<String, Object?> json) => Author(
        username: json['username']! as String,
        discriminator: json['discriminator']! as String,
        id: json['id']! as String,
        bot: json['bot']! as bool,
        avatar: json['avatar']! as String?,
      );

  final String username;
  final String discriminator;
  final String id;
  final bool bot;
  final String? avatar;

  @override
  String toString() => (
        StringBuffer()
          ..writeAll(
            [
              'Author(',
              'username: $username, ',
              'discriminator: $discriminator, ',
              'id: $id, ',
              'avatar: $avatar',
              ')',
            ],
          ),
      )
          .toString();
}

const $discordMessageDecoder = DiscordMessageDecoder();

@immutable
@internal
class DiscordMessageDecoder extends Converter<String, DiscordMessage> {
  const DiscordMessageDecoder();

  @override
  DiscordMessage convert(String input) {
    final json = jsonDecode(input);

    if (json is! Map<String, Object?>) {
      throw const FormatException('Expected a JSON object');
    }

    if (json
        case <String, Object?>{
          't': final String t,
          'd': final Map<String, Object?> d,
        }) {
      MLogger.v('Parsing event: $json');
      return switch (t) {
        'MESSAGE_CREATE' => DiscordMessage$MessageCreate.fromJson(d),
        'MESSAGE_UPDATE' => DiscordMessage$MessageUpdate.fromJson(d),
        _ => DiscordMessage$Unsupported(type: t, data: d),
      };
    }

    return DiscordMessage$Unsupported(type: 'Unknown', data: json);
  }
}
