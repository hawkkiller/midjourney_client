import 'dart:convert';

import 'package:meta/meta.dart';

@immutable
sealed class DiscordEvent {
  const DiscordEvent();
}

final class DiscordEventUnsupported extends DiscordEvent {
  const DiscordEventUnsupported({
    required this.type,
    required this.data,
  });

  final String type;
  final Map<String, Object?> data;

  @override
  String toString() => '$type('
      'type: $type, '
      'data: $data'
      ')';
}

sealed class DiscordMessage extends DiscordEvent {
  const DiscordMessage({
    required this.id,
    required this.content,
    required this.embeds,
    required this.channelId,
    this.author,
    this.nonce,
    this.attachments,
  });

  final String content;
  final String id;
  final List<Embed> embeds;
  final Author? author;
  final String? nonce;
  final List<Attachment>? attachments;
  final String channelId;

  @override
  String toString() => '$runtimeType('
      'id: $id, '
      'content: $content, '
      'embeds: $embeds, '
      'auhor: $author, '
      'nonce: $nonce, '
      'attachments: $attachments'
      ')';

  bool get created => switch (this) {
        DiscordMessageCreate() => true,
        _ => false,
      };

  bool get updated => switch (this) {
        DiscordMessageUpdate() => true,
        _ => false,
      };
}

final class DiscordMessageCreate extends DiscordMessage {
  const DiscordMessageCreate({
    required super.id,
    required super.content,
    required super.embeds,
    required super.channelId,
    super.author,
    super.nonce,
    super.attachments,
  });

  factory DiscordMessageCreate.fromJson(Map<String, Object?> json) =>
      DiscordMessageCreate(
        nonce: json['nonce'] as String?,
        id: json['id']! as String,
        content: json['content']! as String,
        author: json['author'] != null
            ? Author.fromJson(json['author']! as Map<String, Object?>)
            : null,
        attachments: (json['attachments'] as List<Object?>?)
            ?.map((e) => Attachment.fromJson(e! as Map<String, Object?>))
            .toList(),
        embeds: (json['embeds']! as List<Object?>)
            .map((e) => Embed.fromJson(e! as Map<String, Object?>))
            .toList(),
        channelId: json['channel_id']! as String,
      );
}

final class DiscordMessageUpdate extends DiscordMessage {
  const DiscordMessageUpdate({
    required super.id,
    required super.embeds,
    required super.content,
    required super.channelId,
    super.author,
    super.attachments,
    super.nonce,
  });

  factory DiscordMessageUpdate.fromJson(Map<String, Object?> json) =>
      DiscordMessageUpdate(
        nonce: json['nonce'] as String?,
        id: json['id']! as String,
        content: json['content'] as String? ?? '',
        author: json['author'] != null
            ? Author.fromJson(json['author']! as Map<String, Object?>)
            : null,
        attachments: (json['attachments'] as List<Object?>?)
            ?.map((e) => Attachment.fromJson(e! as Map<String, Object?>))
            .toList(),
        embeds: (json['embeds']! as List<Object?>)
            .map((e) => Embed.fromJson(e! as Map<String, Object?>))
            .toList(),
        channelId: json['channel_id']! as String,
      );
}

@immutable
class Embed {
  const Embed({
    this.title,
    this.description,
    this.color,
  });

  factory Embed.fromJson(Map<String, dynamic> json) => Embed(
        title: json['title'] as String?,
        description: json['description'] as String?,
        color: json['color'] as int?,
      );

  final String? title;
  final String? description;
  final int? color;

  @override
  String toString() => 'Embed('
      'title: $title, '
      'description: $description, '
      'color: $color'
      ')';
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
  String toString() => 'Attachment('
      'width: $width, '
      'height: $height, '
      'url: $url, '
      'proxyUrl: $proxyUrl, '
      'size: $size, '
      'filename: $filename, '
      'id: $id'
      ')';
}

@immutable
final class Author {
  const Author({
    required this.username,
    required this.discriminator,
    required this.id,
    this.avatar,
    this.bot,
  });

  factory Author.fromJson(Map<String, Object?> json) => Author(
        username: json['username']! as String,
        discriminator: json['discriminator']! as String,
        id: json['id']! as String,
        bot: json['bot'] as bool?,
        avatar: json['avatar'] as String?,
      );

  final String username;
  final String discriminator;
  final String id;
  final bool? bot;
  final String? avatar;

  @override
  String toString() => 'Author('
      'username: $username, '
      'discriminator: $discriminator, '
      'id: $id, '
      'avatar: $avatar'
      ')';
}

const $discordMessageDecoder = DiscordMessageDecoder();

@immutable
@internal
class DiscordMessageDecoder extends Converter<String, DiscordEvent> {
  const DiscordMessageDecoder();

  @override
  DiscordEvent convert(String input) {
    final json = jsonDecode(input);

    if (json is! Map<String, Object?>) {
      throw const FormatException('Expected a JSON object');
    }

    if (json
        case <String, Object?>{
          't': final String t,
          'd': final Map<String, Object?> d,
        }) {
      return switch (t) {
        'MESSAGE_CREATE' => DiscordMessageCreate.fromJson(d),
        'MESSAGE_UPDATE' => DiscordMessageUpdate.fromJson(d),
        _ => DiscordEventUnsupported(type: t, data: d),
      };
    }

    return DiscordEventUnsupported(type: 'Unknown', data: json);
  }
}
