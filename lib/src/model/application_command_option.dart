import 'package:midjourney_client/src/model/application_command_option_type.dart';

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
}
