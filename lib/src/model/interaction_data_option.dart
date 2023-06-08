import 'package:midjourney_client/src/model/application_command_option_type.dart';

class InteractionDataOption {
  InteractionDataOption({
    required this.type,
    required this.name,
    required this.value,
  });

  final ApplicationCommandOptionType type;
  final String name;
  final String value;
}
