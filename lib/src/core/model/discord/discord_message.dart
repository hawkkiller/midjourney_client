import 'dart:convert';

import 'package:meta/meta.dart';
import 'package:midjourney_client/src/core/utils/logger.dart';

@immutable
sealed class DiscordMessage {
  const DiscordMessage();
}

final class DiscordMessage$MessageCreate extends DiscordMessage {
  const DiscordMessage$MessageCreate({
    required this.nonce,
    required this.id,
    required this.content,
    required this.embeds,
    required this.attachments,
  });

  factory DiscordMessage$MessageCreate.fromJson(Map<String, Object?> json) =>
      DiscordMessage$MessageCreate(
        nonce: json['nonce'] as String?,
        id: json['id']! as String,
        content: json['content']! as String,
        attachments: (json['attachments'] as List<Object?>?)
            ?.map((e) => Attachment.fromJson(e! as Map<String, Object?>))
            .toList(),
        embeds: (json['embeds']! as List<Object?>)
            .map((e) => Embed.fromJson(e! as Map<String, Object?>))
            .toList(),
      );

  final String? nonce;
  final String content;
  final String id;
  final List<Embed> embeds;
  final List<Attachment>? attachments;

  @override
  String toString() => (
        StringBuffer()
          ..writeAll(
            [
              r'DiscordMessage$MessageCreate(',
              'nonce: $nonce, ',
              'id: $id, ',
              'content: $content, ',
              'attachments: $attachments, ',
              'embeds: $embeds',
              ')',
            ],
          ),
      )
          .toString();
}

final class DiscordMessage$MessageUpdate extends DiscordMessage {
  const DiscordMessage$MessageUpdate({
    required this.nonce,
    required this.id,
    required this.embeds,
    required this.attachments,
    required this.content,
  });

  factory DiscordMessage$MessageUpdate.fromJson(Map<String, Object?> json) =>
      DiscordMessage$MessageUpdate(
        nonce: json['nonce'] as String?,
        id: json['id']! as String,
        content: json['content']! as String,
        attachments: (json['attachments'] as List<Object?>?)
            ?.map((e) => Attachment.fromJson(e! as Map<String, Object?>))
            .toList(),
        embeds: (json['embeds']! as List<Object?>)
            .map((e) => Embed.fromJson(e! as Map<String, Object?>))
            .toList(),
      );

  final String? nonce;
  final String id;
  final List<Embed> embeds;
  final List<Attachment>? attachments;
  final String content;

  @override
  String toString() => (
        StringBuffer()
          ..writeAll(
            [
              r'DiscordMessage$MessageUpdate(',
              'nonce: $nonce, ',
              'id: $id, ',
              'content: $content, ',
              'attachments: $attachments, ',
              'embeds: $embeds',
              ')',
            ],
          ),
      )
          .toString();
}

final class DiscordMessage$Unsupported extends DiscordMessage {
  const DiscordMessage$Unsupported({
    required this.json,
  });

  final Map<String, dynamic> json;

  @override
  String toString() => 'DiscordMessage\$Unsupported(json: $json)';
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
        _ => DiscordMessage$Unsupported(json: d),
      };
    }

    return DiscordMessage$Unsupported(json: json);
  }
}
