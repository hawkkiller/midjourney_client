import 'package:midjourney_client/src/model/application_command.dart';
import 'package:midjourney_client/src/model/application_command_type.dart';
import 'package:midjourney_client/src/model/interaction_data_option.dart';

class InteractionData {
  InteractionData({
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

  Map<String, Object?> toJson() => {
        'version': version,
        'id': id,
        'name': name,
        'type': type.toInt(),
        'options': options.map((e) => e.toJson()).toList(),
        'application_command': applicationCommand.toJson(),
      };
}
