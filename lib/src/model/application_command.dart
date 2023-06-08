import 'package:midjourney_client/src/model/application_command_option.dart';
import 'package:midjourney_client/src/model/application_command_type.dart';

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
}
