import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:meta_code/features/agent_lab/skill_client.dart';
import 'package:meta_code/features/learning_paths/path_models.dart';
import 'package:meta_code/features/learning_paths/path_providers.dart';
import 'package:meta_code/features/library_catalog/library_models.dart';
import 'package:meta_code/features/tutor_companion/tutor_models.dart';

Map<String, dynamic> _asset(String name) =>
    jsonDecode(File('assets/data/$name').readAsStringSync()) as Map<String, dynamic>;

void main() {
  final catalog = Catalog.fromJson(_asset('libros_catalogo.json'));
  final paths = [
    for (final p in _asset('learning_paths.json')['rutas'] as List)
      LearningPath.fromJson(p as Map<String, dynamic>),
  ];

  group('catálogo', () {
    test('carga todos los libros con ids únicos', () {
      expect(catalog.books, isNotEmpty);
      expect(catalog.books.map((b) => b.id).toSet().length, catalog.books.length);
    });

    test('busca sin distinguir tildes ni mayúsculas', () {
      final results = catalog.search(query: 'PROGRAMACION');
      expect(results, isNotEmpty);
      expect(results.any((b) => b.title.contains('Programación')), isTrue);
    });

    test('filtra por categoría y formato', () {
      final results = catalog.search(categoryId: 'git', format: 'PDF');
      expect(results, isNotEmpty);
      expect(results.every((b) => b.categoryId == 'git' && b.formats.contains('PDF')), isTrue);
    });
  });

  group('rutas', () {
    test('las lecciones tienen ids únicos y contenido', () {
      final lessons = paths.expand((p) => p.lessons).toList();
      expect(lessons.map((l) => l.id).toSet().length, lessons.length);
      for (final l in lessons) {
        if (l.type == LessonType.quiz) {
          expect(l.questions, isNotEmpty, reason: l.id);
          for (final q in l.questions) {
            expect(q.correct, inInclusiveRange(0, q.options.length - 1), reason: l.id);
          }
        } else {
          expect(l.content, isNotEmpty, reason: l.id);
        }
        if (l.type == LessonType.practice) expect(l.solution, isNotNull, reason: l.id);
      }
    });

    test('los libros recomendados existen en el catálogo', () {
      for (final id in paths.expand((p) => p.bookIds)) {
        expect(catalog.byId(id), isNotNull, reason: id);
      }
    });

    test('calcula el progreso', () {
      final path = paths.first;
      final lessons = path.lessons.toList();
      expect(pathProgress(path, {}), 0);
      expect(pathProgress(path, {lessons.first.id}), closeTo(1 / lessons.length, 1e-9));
      expect(pathProgress(path, {for (final l in lessons) l.id}), 1);
    });
  });

  group('tutor', () {
    test('la configuración sobrevive a guardar y cargar', () {
      const config = TutorConfig(
        name: 'Pixel',
        persona: TutorPersona.mascota,
        mode: TutorMode.creador,
        level: TutorLevel.avanzado,
        apiKey: 'clave',
      );
      final restored = TutorConfig.fromJson(
        jsonDecode(jsonEncode(config.toJson())) as Map<String, dynamic>,
      );
      expect(restored.name, 'Pixel');
      expect(restored.persona, TutorPersona.mascota);
      expect(restored.mode, TutorMode.creador);
      expect(restored.level, TutorLevel.avanzado);
      expect(restored.isConnected, isTrue);
    });

    test('el prompt refleja la personalización', () {
      const config = TutorConfig(name: 'Pixel', mode: TutorMode.creador, tone: 'directo');
      expect(config.systemPrompt, contains('Pixel'));
      expect(config.systemPrompt, contains('Modo creador'));
      expect(config.systemPrompt, contains('tono directo'));
    });

    test('reenvía sin cambios el contenido original del modelo', () {
      final raw = [
        {'type': 'thinking', 'thinking': '', 'signature': 'abc'},
        {'type': 'text', 'text': 'Hola'},
      ];
      final message = ChatMessage(fromUser: false, text: 'Hola', rawContent: raw);
      final restored = ChatMessage.fromJson(
        jsonDecode(jsonEncode(message.toJson())) as Map<String, dynamic>,
      );
      expect(restored.toApi(), {'role': 'assistant', 'content': raw});
      expect(const ChatMessage(fromUser: true, text: 'Hola').toApi(), {
        'role': 'user',
        'content': 'Hola',
      });
    });
  });

  group('MCP', () {
    test('lee una respuesta JSON directa', () {
      final r = parseRpcResponse('{"jsonrpc":"2.0","id":1,"result":{"ok":true}}', 1);
      expect(r?['result'], {'ok': true});
    });

    test('lee una respuesta en formato SSE y elige el id correcto', () {
      const body =
          'event: message\ndata: {"jsonrpc":"2.0","method":"notifications/progress"}\n\n'
          'event: message\ndata: {"jsonrpc":"2.0","id":2,"result":{"tools":[]}}\n\n';
      expect(parseRpcResponse(body, 2)?['result'], {'tools': <dynamic>[]});
      expect(parseRpcResponse(body, 9), isNull);
    });

    test('devuelve null si no es JSON-RPC', () {
      expect(parseRpcResponse('<html>404</html>', 1), isNull);
    });
  });
}
