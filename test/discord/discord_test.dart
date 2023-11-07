import 'dart:convert';

import 'package:http/http.dart' as http;
import 'package:http/testing.dart' as http_testing;
import 'package:midjourney_client/src/discord/discord_interaction_client.dart';
import 'package:midjourney_client/src/discord/model/interaction.dart';
import 'package:midjourney_client/src/exception/exception.dart';
import 'package:midjourney_client/src/midjourney/model/midjourney_config.dart';
import 'package:midjourney_client/src/midjourney/model/midjourney_message.dart';
import 'package:snowflaker/snowflaker.dart';
import 'package:test/test.dart';

class _SnowflakerMock implements Snowflaker {
  @override
  int nextId() => 123;

  @override
  int get datacenterId => 0;

  @override
  int get epoch => 0;

  @override
  int get workerId => 0;
}

void main() {
  const emptyConfig = MidjourneyConfig(
    baseUrl: 'empty',
    wsUrl: 'empty',
    token: 'empty',
    guildId: 'empty',
    channelId: 'empty',
    cdnUrl: 'empty',
  );

  final applicationCommand = ApplicationCommand(
    id: 'id',
    applicationId: 'applicationId',
    version: 'version',
    type: ApplicationCommandType.chatInput,
    nsfw: false,
    name: 'imagine',
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

  final overrideCommands = {
    CommandName.imagine: applicationCommand,
  };

  group('Discord >', () {
    group('Interaction Client >', () {
      late http.Client httpClient;
      late DiscordInteractionClient discordInteractionClient;
      late Snowflaker snowflaker;

      setUp(() {
        httpClient = http_testing.MockClient(
          (request) async => http.Response(
            '',
            // discord interaction api returns 204 on success
            204,
          ),
        );
        snowflaker = _SnowflakerMock();
        discordInteractionClient = DiscordInteractionClientImpl(
          config: emptyConfig,
          httpClient: httpClient,
          snowflaker: snowflaker,
          overrideCommands: overrideCommands,
        );
      });

      tearDown(() {
        httpClient.close();
      });

      test('Imagine should work correctly with 204', () {
        expect(
          discordInteractionClient.createImagine('prompt'),
          completion(123),
        );
      });

      test('Variation should work correctly with 204', () {
        final response = discordInteractionClient.createVariation(
          const MidjourneyMessageImageFinish(
            id: 'id',
            content: '',
            messageId: '',
            uri: '',
          ),
          1,
        );

        expect(
          response,
          completion(123),
        );
      });

      test('Upscale should work correctly with 204', () {
        final response = discordInteractionClient.createUpscale(
          const MidjourneyMessageImageFinish(
            id: 'id',
            content: '',
            messageId: '',
            uri: '',
          ),
          1,
        );

        expect(
          response,
          completion(123),
        );
      });

      test('Imagine should fail with non 204', () {
        httpClient = http_testing.MockClient(
          (request) async => http.Response(
            '{"id": "000"}',
            // discord interaction api returns 204 on success
            404,
          ),
        );
        discordInteractionClient = DiscordInteractionClientImpl(
          config: emptyConfig,
          httpClient: httpClient,
          snowflaker: snowflaker,
          overrideCommands: overrideCommands,
        );

        expect(
          discordInteractionClient.createImagine('prompt'),
          throwsA(
            isA<InteractionException>().having(
              (e) => e.code,
              'code',
              404,
            ),
          ),
        );
      });

      test('Variation should fail with non 204', () {
        httpClient = http_testing.MockClient(
          (request) async => http.Response(
            '{"id": "000"}',
            // discord interaction api returns 204 on success
            404,
          ),
        );
        discordInteractionClient = DiscordInteractionClientImpl(
          config: emptyConfig,
          httpClient: httpClient,
          snowflaker: snowflaker,
          overrideCommands: overrideCommands,
        );

        final response = discordInteractionClient.createVariation(
          const MidjourneyMessageImageFinish(
            id: 'id',
            content: '',
            messageId: '',
            uri: '',
          ),
          1,
        );

        expect(
          response,
          throwsA(
            isA<InteractionException>().having(
              (e) => e.code,
              'code',
              404,
            ),
          ),
        );
      });

      test('Upscale should fail with non 204', () {
        httpClient = http_testing.MockClient(
          (request) async => http.Response(
            '{"id": "000"}',
            // discord interaction api returns 204 on success
            404,
          ),
        );
        discordInteractionClient = DiscordInteractionClientImpl(
          config: emptyConfig,
          httpClient: httpClient,
          snowflaker: snowflaker,
          overrideCommands: overrideCommands,
        );

        final response = discordInteractionClient.createUpscale(
          const MidjourneyMessageImageFinish(
            id: 'id',
            content: '',
            messageId: '',
            uri: '',
          ),
          1,
        );

        expect(
          response,
          throwsA(
            isA<InteractionException>().having(
              (e) => e.code,
              'code',
              404,
            ),
          ),
        );
      });
      test('Fetch commands on initialize', () async {
        final mockClient = http_testing.MockClient(
          (request) async => http.Response(
            jsonEncode([applicationCommand.toJson()]),
            200,
          ),
        );

        final discordInteractionClient = DiscordInteractionClientImpl(
          config: emptyConfig,
          httpClient: mockClient,
          snowflaker: snowflaker,
        );

        await expectLater(
          discordInteractionClient.initialize(),
          completes,
        );

        expect(
          discordInteractionClient.commandsCache,
          isNotEmpty,
        );
      });
    });
    group('Interaction >', () {
      final snowflaker = Snowflaker(
        workerId: 10,
        datacenterId: 15,
      );
      final interactionData = InteractionDataApplicationCommand(
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
        nonce: snowflaker.nextId().toString(),
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
    group('ApplicationCommand >', () {
      test('ApplicationCommand fields', () {
        expect(applicationCommand.id, 'id');
        expect(applicationCommand.applicationId, 'applicationId');
        expect(applicationCommand.version, 'version');
        expect(applicationCommand.type, ApplicationCommandType.chatInput);
        expect(applicationCommand.nsfw, false);
        expect(applicationCommand.name, 'imagine');
        expect(applicationCommand.description, 'description');
        expect(applicationCommand.dmPermission, true);
        expect(applicationCommand.options, isNotEmpty);
      });

      test('ApplicationCommand toJson', () {
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

      test('ApplicationCommand fromJson', () {
        final fromJson = ApplicationCommand.fromJson({
          'id': 'id',
          'application_id': 'applicationId',
          'version': 'version',
          'type': ApplicationCommandType.chatInput.toInt(),
          'nsfw': false,
          'name': 'name',
          'description': 'description',
          'dm_permission': true,
          'options': [
            {
              'type': ApplicationCommandOptionType.string.toInt(),
              'name': 'name',
              'description': 'description',
              'required': true,
            },
          ],
        });

        expect(fromJson.id, 'id');
        expect(fromJson.applicationId, 'applicationId');
        expect(fromJson.version, 'version');
        expect(fromJson.type, ApplicationCommandType.chatInput);
        expect(fromJson.nsfw, false);
        expect(fromJson.name, 'name');
        expect(fromJson.description, 'description');
        expect(fromJson.dmPermission, true);
        expect(fromJson.options, isNotEmpty);
      });

      test('ApplicationCommandOptionType toInt', () {
        expect(ApplicationCommandOptionType.subCommand.toInt(), 1);
        expect(ApplicationCommandOptionType.subCommandGroup.toInt(), 2);
        expect(ApplicationCommandOptionType.string.toInt(), 3);
        expect(ApplicationCommandOptionType.integer.toInt(), 4);
        expect(ApplicationCommandOptionType.boolean.toInt(), 5);
        expect(ApplicationCommandOptionType.user.toInt(), 6);
        expect(ApplicationCommandOptionType.channel.toInt(), 7);
        expect(ApplicationCommandOptionType.role.toInt(), 8);
        expect(ApplicationCommandOptionType.mentionable.toInt(), 9);
        expect(ApplicationCommandOptionType.number.toInt(), 10);
        expect(ApplicationCommandOptionType.attachment.toInt(), 11);
      });

      test('ApplicationCommandType toInt', () {
        expect(ApplicationCommandType.chatInput.toInt(), 1);
        expect(ApplicationCommandType.user.toInt(), 2);
        expect(ApplicationCommandType.message.toInt(), 3);
      });

      test('CommandName fromString', () {
        expect(CommandName.imagine, CommandName.fromString('imagine'));
      });

      test('Command Throws', () {
        expect(
          () => CommandName.fromString('invalid'),
          throwsA(
            isA<ArgumentError>().having(
              (e) => e.name,
              'name',
              'name',
            ),
          ),
        );
      });
    });
  });
}
