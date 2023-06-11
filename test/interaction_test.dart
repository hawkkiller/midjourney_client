import 'package:midjourney_client/src/model/interaction.dart';
import 'package:snowflaker/snowflaker.dart';
import 'package:test/test.dart';

void main() {
  group('Interaction test >', () {
    final snowflaker = Snowflaker(
      workerId: 10,
      datacenterId: 15,
    );
    final applicationCommand = ApplicationCommand(
      id: 'id',
      applicationId: 'applicationId',
      version: 'version',
      type: ApplicationCommandType.chatInput,
      nsfw: false,
      name: 'name',
      description: 'description',
      dmPermission: true,
      options: [
        ApplicationCommandOption(
          type: ApplicationCommandOptionType.string,
          name: 'name',
          description: 'description',
          required: true,
        ),
      ],
    );
    final interactionData = InteractionData(
      version: 'version',
      id: 'id',
      name: 'name',
      type: ApplicationCommandType.chatInput,
      options: [
        InteractionDataOption(
          type: ApplicationCommandOptionType.string,
          name: 'name',
          value: 'value',
        ),
      ],
      applicationCommand: applicationCommand,
    );
    final interaction = Interaction(
      sessionId: 'sessionId',
      channelId: 'channelId',
      guildId: 'guildId',
      applicationId: 'applicationId',
      type: InteractionType.applicationCommand,
      nonce: snowflaker.nextId(),
      data: interactionData,
    );

    test('InteractionData fields', () {
      expect(interactionData.version, 'version');
      expect(interactionData.id, 'id');
      expect(interactionData.name, 'name');
      expect(interactionData.type, ApplicationCommandType.chatInput);
      expect(interactionData.options, isNotEmpty);
      expect(interactionData.applicationCommand, applicationCommand);
    });

    test('InteractionData toJson()', () {
      final toJson = interactionData.toJson();

      expect(toJson['version'], interactionData.version);
      expect(toJson['id'], interactionData.id);
      expect(toJson['name'], interactionData.name);
      expect(toJson['type'], interactionData.type.toInt());
      expect(toJson['options'], isNotEmpty);
      expect(toJson['application_command'], applicationCommand.toJson());
    });

    test('ApplicationCommand fields', () {
      expect(applicationCommand.id, 'id');
      expect(applicationCommand.applicationId, 'applicationId');
      expect(applicationCommand.version, 'version');
      expect(applicationCommand.type, ApplicationCommandType.chatInput);
      expect(applicationCommand.nsfw, false);
      expect(applicationCommand.name, 'name');
      expect(applicationCommand.description, 'description');
      expect(applicationCommand.dmPermission, true);
      expect(applicationCommand.options, isNotEmpty);
    });

    test('ApplicationCommand toJson()', () {
      final toJson = applicationCommand.toJson();

      expect(toJson['id'], applicationCommand.id);
      expect(toJson['application_id'], applicationCommand.applicationId);
      expect(toJson['version'], applicationCommand.version);
      expect(toJson['type'], applicationCommand.type.toInt());
      expect(toJson['nsfw'], applicationCommand.nsfw);
      expect(toJson['name'], applicationCommand.name);
      expect(toJson['description'], applicationCommand.description);
      expect(toJson['dm_permission'], applicationCommand.dmPermission);
      expect(toJson['options'], isNotEmpty);
    });

    test('Interaction fields', () {
      expect(interaction.sessionId, 'sessionId');
      expect(interaction.channelId, 'channelId');
      expect(interaction.guildId, 'guildId');
      expect(interaction.applicationId, 'applicationId');
      expect(interaction.type, InteractionType.applicationCommand);
      expect(interaction.nonce, isNotNull);
      expect(interaction.data, interactionData);
    });

    test('Interaction toJson()', () {
      final toJson = interaction.toJson();

      expect(toJson['type'], InteractionType.applicationCommand.toInt());
      expect(toJson['data'], interactionData.toJson());
      expect(toJson['nonce'], interaction.nonce);
      expect(toJson['application_id'], interaction.applicationId);
      expect(toJson['guild_id'], interaction.guildId);
      expect(toJson['channel_id'], interaction.channelId);
      expect(toJson['session_id'], interaction.sessionId);
    });
  });
}
