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
