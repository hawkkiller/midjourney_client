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
