class Interaction {
  Interaction({
    required this.sessionId,
    required this.channelId,
    required this.guildId,
    required this.applicationId,
    required this.type,
    required this.data,
    required this.nonce,
    this.messageFlags,
    this.messageId,
  });

  final InteractionType type;
  final String applicationId;
  final String guildId;
  final String channelId;
  final String sessionId;
  final InteractionData data;
  final String nonce;
  final int? messageFlags;
  final String? messageId;

  Map<String, Object?> toJson() => {
        'type': type.toInt(),
        'application_id': applicationId,
        'guild_id': guildId,
        'channel_id': channelId,
        'session_id': sessionId,
        'data': data.toJson(),
        'nonce': nonce,
        if (messageFlags != null) 'message_flags': messageFlags,
        if (messageId != null) 'message_id': messageId,
      };
}

sealed class InteractionData {
  Map<String, Object?> toJson();
}

class InteractionData$MessageComponent extends InteractionData {
  InteractionData$MessageComponent({
    required this.customId,
    required this.componentType,
    this.values,
  });

  final String customId;
  final MessageComponentType componentType;
  final List<String>? values;

  @override
  Map<String, Object?> toJson() => {
        'component_type': componentType.toInt(),
        'custom_id': customId,
        if (values != null) 'values': values,
      };
}

class InteractionData$ApplicationCommand extends InteractionData {
  InteractionData$ApplicationCommand({
    required this.applicationCommand,
    required this.version,
    required this.id,
    required this.name,
    required this.type,
    required this.options,
  });

  final String version;
  final String id;
  final String name;
  final ApplicationCommandType type;
  final List<InteractionDataOption> options;
  final ApplicationCommand applicationCommand;

  @override
  Map<String, Object?> toJson() => {
        'version': version,
        'id': id,
        'name': name,
        'type': type.toInt(),
        'options': options.map((e) => e.toJson()).toList(),
        'application_command': applicationCommand.toJson(),
      };
}

class InteractionDataOption {
  InteractionDataOption({
    required this.type,
    required this.name,
    required this.value,
  });

  final ApplicationCommandOptionType type;
  final String name;
  final String value;

  Map<String, Object?> toJson() => {
        'type': type.toInt(),
        'name': name,
        'value': value,
      };
}

class ApplicationCommand {
  ApplicationCommand({
    required this.id,
    required this.applicationId,
    required this.version,
    required this.type,
    required this.nsfw,
    required this.name,
    required this.description,
    required this.dmPermission,
    this.defaultMemberPermissions,
    this.options,
    this.contexts,
  });

  final String id;
  final String applicationId;
  final String version;
  final String? defaultMemberPermissions;
  final ApplicationCommandType type;
  final bool nsfw;
  final String name;
  final String description;
  final bool dmPermission;
  final List<dynamic>? contexts;
  final List<ApplicationCommandOption>? options;

  Map<String, Object?> toJson() => {
        'id': id,
        'application_id': applicationId,
        'version': version,
        'default_member_permissions': defaultMemberPermissions,
        'type': type.toInt(),
        'nsfw': nsfw,
        'name': name,
        'description': description,
        'dm_permission': dmPermission,
        'contexts': contexts,
        'options': options?.map((e) => e.toJson()).toList(),
      };
}

class ApplicationCommandOption {
  ApplicationCommandOption({
    required this.type,
    required this.name,
    required this.description,
    this.required,
  });

  final ApplicationCommandOptionType type;
  final String name;
  final String description;
  final bool? required;

  Map<String, Object?> toJson() => {
        'type': type.toInt(),
        'name': name,
        'description': description,
        'required': required,
      };
}

enum MessageComponentType {
  actionRow,
  button,
  stringSelect,
  textInput,
  userSelect,
  roleSelect,
  mentionableSelect,
  channelSelect;

  int toInt() => switch (this) {
        MessageComponentType.actionRow => 1,
        MessageComponentType.button => 2,
        MessageComponentType.stringSelect => 3,
        MessageComponentType.textInput => 4,
        MessageComponentType.userSelect => 5,
        MessageComponentType.roleSelect => 6,
        MessageComponentType.mentionableSelect => 7,
        MessageComponentType.channelSelect => 8,
      };
}

enum InteractionType {
  ping,
  applicationCommand,
  messageComponent,
  applicationCommandAutocomplete,
  modalSubmit;

  int toInt() => switch (this) {
        InteractionType.ping => 1,
        InteractionType.applicationCommand => 2,
        InteractionType.messageComponent => 3,
        InteractionType.applicationCommandAutocomplete => 4,
        InteractionType.modalSubmit => 5,
      };
}

enum ApplicationCommandType {
  chatInput,
  user,
  message;

  int toInt() => switch (this) {
        ApplicationCommandType.chatInput => 1,
        ApplicationCommandType.user => 2,
        ApplicationCommandType.message => 3,
      };
}

enum ApplicationCommandOptionType {
  subCommand,
  subCommandGroup,
  string,
  integer,
  boolean,
  user,
  channel,
  role,
  mentionable,
  number,
  attachment;

  int toInt() => switch (this) {
        ApplicationCommandOptionType.subCommand => 1,
        ApplicationCommandOptionType.subCommandGroup => 2,
        ApplicationCommandOptionType.string => 3,
        ApplicationCommandOptionType.integer => 4,
        ApplicationCommandOptionType.boolean => 5,
        ApplicationCommandOptionType.user => 6,
        ApplicationCommandOptionType.channel => 7,
        ApplicationCommandOptionType.role => 8,
        ApplicationCommandOptionType.mentionable => 9,
        ApplicationCommandOptionType.number => 10,
        ApplicationCommandOptionType.attachment => 11,
      };
}
