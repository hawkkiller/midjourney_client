import 'dart:convert';

import 'package:meta/meta.dart';

/// The type of a [DiscordMessage].
enum DiscordMessageType {
  create,
  update,
  delete,
  unsupported;

  /// Contstruct a [DiscordMessageType] from a string.
  static DiscordMessageType fromString(String value) => switch (value) {
        'MESSAGE_CREATE' => DiscordMessageType.create,
        'MESSAGE_UPDATE' => DiscordMessageType.update,
        'MESSAGE_DELETE' => DiscordMessageType.delete,
        _ => DiscordMessageType.unsupported,
      };
}

@immutable
sealed class DiscordEvent {
  const DiscordEvent();
}

base class DiscordMessage extends DiscordEvent {
  const DiscordMessage({
    required this.type,
    this.id,
    this.channelId,
    this.guildId,
    this.embeds,
    this.content,
    this.author,
    this.nonce,
    this.attachments,
  });

  /// Construct a [DiscordMessage] from a JSON map.
  factory DiscordMessage.fromJson(
    Map<String, Object?> json,
    DiscordMessageType type,
  ) =>
      DiscordMessage(
        id: json['id'] as String?,
        channelId: json['channel_id'] as String?,
        guildId: json['guild_id'] as String?,
        type: type,
        content: json['content'] as String?,
        embeds: (json['embeds'] as List<Object?>?)
            ?.map((e) => Embed.fromJson(e! as Map<String, Object?>))
            .toList(),
        attachments: (json['attachments'] as List<Object?>?)
            ?.map((e) => Attachment.fromJson(e! as Map<String, Object?>))
            .toList(),
        author: json['author'] == null
            ? null
            : Author.fromJson(json['author']! as Map<String, Object?>),
        nonce: json['nonce'] as String?,
      );

  /// The type of this message.
  final DiscordMessageType type;

  /// The ID of this message.
  final String? id;

  /// The ID of the server this message was sent in.
  final String? guildId;

  /// The ID of the channel this message was sent in.
  final String? channelId;

  /// The content of this message.
  final String? content;

  /// The embeds of this message.
  final List<Embed>? embeds;

  /// The author of this message.
  final Author? author;

  /// The nonce of this message.
  final String? nonce;

  /// The attachments of this message.
  final List<Attachment>? attachments;

  /// Whether this message is a create message.
  bool get isCreated => type == DiscordMessageType.create;

  /// Whether this message is a update message.
  bool get isUpdated => type == DiscordMessageType.update;

  /// Whether this message is a delete message.
  bool get isDelete => type == DiscordMessageType.delete;

  @override
  String toString() => '$DiscordMessage('
      'id: $id, '
      'channelId: $channelId, '
      'guildId: $guildId, '
      'type: $type, '
      'content: $content, '
      'embeds: $embeds, '
      'auhor: $author, '
      'nonce: $nonce, '
      'attachments: $attachments'
      ')';
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
      final type = DiscordMessageType.fromString(t);

      return DiscordMessage.fromJson(d, type);
    }

    return DiscordMessage(
      type: DiscordMessageType.unsupported,
      content: input,
    );
  }
}
