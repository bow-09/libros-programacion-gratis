import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:meta_code/features/agent_lab/skill_client.dart';
import 'package:meta_code/features/agent_lab/skill_models.dart';
import 'package:meta_code/features/tutor_companion/tutor_client.dart';
import 'package:meta_code/features/tutor_companion/tutor_models.dart';

const _json = {'content-type': 'application/json; charset=utf-8'};

void main() {
  const config = TutorConfig(apiKey: 'clave-de-prueba');
  const history = [ChatMessage(fromUser: true, text: '¿Qué es una variable?')];

  group('TutorClient', () {
    test('envía la petición con el formato de la Messages API', () async {
      late http.Request sent;
      final client = TutorClient(
        httpClient: MockClient((request) async {
          sent = request;
          return http.Response(
            jsonEncode({
              'stop_reason': 'end_turn',
              'content': [
                {'type': 'thinking', 'thinking': '', 'signature': 's'},
                {'type': 'text', 'text': 'Una caja con nombre.'},
              ],
            }),
            200,
            headers: _json,
          );
        }),
      );

      final reply = await client.send(config, history);

      expect(sent.url.toString(), 'https://api.anthropic.com/v1/messages');
      expect(sent.headers['x-api-key'], 'clave-de-prueba');
      expect(sent.headers['anthropic-version'], isNotEmpty);
      final body = jsonDecode(sent.body) as Map<String, dynamic>;
      expect(body['model'], TutorConfig.defaultModel);
      expect(body['system'], contains('meta-code'));
      expect(body['messages'], [
        {'role': 'user', 'content': '¿Qué es una variable?'},
      ]);
      expect(reply.text, 'Una caja con nombre.');
      expect(reply.rawContent, hasLength(2));
    });

    test('explica una clave inválida', () async {
      final client = TutorClient(
        httpClient: MockClient(
          (_) async => http.Response(
            jsonEncode({
              'error': {'type': 'authentication_error', 'message': 'invalid x-api-key'},
            }),
            401,
            headers: _json,
          ),
        ),
      );
      expect(
        () => client.send(config, history),
        throwsA(isA<TutorException>().having((e) => e.message, 'message', contains('clave'))),
      );
    });

    test('avisa cuando el modelo rechaza la petición', () async {
      final client = TutorClient(
        httpClient: MockClient(
          (_) async => http.Response(
            jsonEncode({'stop_reason': 'refusal', 'content': <dynamic>[]}),
            200,
            headers: _json,
          ),
        ),
      );
      expect(() => client.send(config, history), throwsA(isA<TutorException>()));
    });
  });

  group('SkillClient', () {
    test('recorre el saludo MCP y lista las herramientas', () async {
      final methods = <String>[];
      final client = SkillClient(
        httpClient: MockClient((request) async {
          final rpc = jsonDecode(request.body) as Map<String, dynamic>;
          methods.add(rpc['method'] as String);
          switch (rpc['method']) {
            case 'initialize':
              return http.Response(
                jsonEncode({
                  'jsonrpc': '2.0',
                  'id': rpc['id'],
                  'result': {
                    'serverInfo': {'name': 'mi-servidor'},
                  },
                }),
                200,
                headers: {..._json, 'mcp-session-id': 'sesion-1'},
              );
            case 'tools/list':
              expect(request.headers['mcp-session-id'], 'sesion-1');
              expect(request.headers['authorization'], 'Bearer secreto');
              return http.Response(
                'event: message\ndata: ${jsonEncode({
                  'jsonrpc': '2.0',
                  'id': rpc['id'],
                  'result': {
                    'tools': [
                      {'name': 'validar_codigo'},
                      {'name': 'buscar_noticias'},
                    ],
                  },
                })}\n\n',
                200,
                headers: {'content-type': 'text/event-stream'},
              );
            default:
              return http.Response('', 202);
          }
        }),
      );

      final result = await client.check(
        const Skill(
          id: '1',
          name: 'Mi skill',
          kind: SkillKind.mcp,
          url: 'https://ejemplo.dev/mcp',
          token: 'secreto',
        ),
      );

      expect(methods, ['initialize', 'notifications/initialized', 'tools/list']);
      expect(result.ok, isTrue);
      expect(result.tools, ['validar_codigo', 'buscar_noticias']);
      expect(result.summary, contains('mi-servidor'));
    });

    test('informa de un fallo en una API REST', () async {
      final client = SkillClient(httpClient: MockClient((_) async => http.Response('', 503)));
      final result = await client.check(
        const Skill(id: '1', name: 'API', kind: SkillKind.rest, url: 'https://ejemplo.dev/estado'),
      );
      expect(result.ok, isFalse);
      expect(result.summary, contains('503'));
    });

    test('rechaza una URL inválida sin hacer peticiones', () async {
      final client = SkillClient(httpClient: MockClient((_) async => fail('no debe llamar')));
      final result = await client.check(
        const Skill(id: '1', name: 'API', kind: SkillKind.rest, url: 'no es una url'),
      );
      expect(result.ok, isFalse);
    });
  });
}
