import 'package:midjourney_client/src/model/interaction_data.dart';
import 'package:midjourney_client/src/model/interaction_type.dart';

class Interaction {
  Interaction({
    required this.sessionId,
    required this.channelId,
    required this.guildId,
    required this.applicationId,
    required this.type,
    required this.data,
    required this.nonce,
  });

  final InteractionType type;
  final String applicationId;
  final String guildId;
  final String channelId;
  final String sessionId;
  final InteractionData data;
  final int nonce;

  Map<String, Object?> toJson() => {
        'type': type.toInt(),
        'application_id': applicationId,
        'guild_id': guildId,
        'channel_id': channelId,
        'session_id': sessionId,
        'data': data.toJson(),
        'nonce': nonce,
      };
}

// {
//   'type': 2,
//   'application_id': '936929561302675456',
//   'guild_id': '1014828232740192296',
//   'channel_id': '1110474702335520768',
//   'session_id': '08eea0d2b1374d01971314073d32d769',
//   'data': {
//     'version': '1077969938624553050',
//     'id': '938956540159881230',
//     'name': 'imagine',
//     'type': 1,
//     'options': [
//       {'type': 3, 'name': 'prompt', 'value': 'aboba'}
//     ],
//     'application_command': {
//       'id': '938956540159881230',
//       'application_id': '936929561302675456',
//       'version': '1077969938624553050',
//       'default_member_permissions': null,
//       'type': 1,
//       'nsfw': false,
//       'name': 'imagine',
//       'description': 'Create images with Midjourney',
//       'dm_permission': true,
//       'contexts': null,
//       'options': [
//         {'type': 3, 'name': 'prompt', 'description': 'The prompt to imagine', 'required': true}
//       ]
//     },
//     'attachments': []
//   },
//   'nonce': '1116376177905238016',
// }
