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
