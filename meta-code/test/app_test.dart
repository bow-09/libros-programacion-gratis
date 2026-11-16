import 'dart:convert';
import 'dart:io';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:meta_code/core/storage.dart';
import 'package:meta_code/features/learning_paths/path_models.dart';
import 'package:meta_code/features/learning_paths/path_providers.dart';
import 'package:meta_code/features/library_catalog/library_models.dart';
import 'package:meta_code/features/library_catalog/library_providers.dart';
import 'package:meta_code/main.dart';
import 'package:shared_preferences/shared_preferences.dart';

Map<String, dynamic> _asset(String name) =>
    jsonDecode(File('assets/data/$name').readAsStringSync()) as Map<String, dynamic>;

void main() {
  testWidgets('recorre las cuatro secciones y guarda el progreso', (tester) async {
    SharedPreferences.setMockInitialValues({});
    final prefs = await SharedPreferences.getInstance();
    // Los datos se leen del disco: el cargador de assets no avanza con el reloj simulado.
    final catalog = Catalog.fromJson(_asset('libros_catalogo.json'));
    final paths = [
      for (final p in _asset('learning_paths.json')['rutas'] as List)
        LearningPath.fromJson(p as Map<String, dynamic>),
    ];
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          sharedPreferencesProvider.overrideWithValue(prefs),
          catalogProvider.overrideWith((ref) async => catalog),
          learningPathsProvider.overrideWith((ref) async => paths),
        ],
        child: const MetaCodeApp(),
      ),
    );
    await tester.pumpAndSettle();

    // Rutas: abrir una ruta, una lección y completarla.
    expect(find.text('Fundamentos de Dart'), findsOneWidget);
    await tester.tap(find.text('Fundamentos de Dart'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Tu primer programa'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Marcar como completada'));
    await tester.pumpAndSettle();
    expect(prefs.getStringList('progress.completedLessons'), ['dart-m1-l1']);
    await tester.pageBack();
    await tester.pumpAndSettle();

    await tester.tap(find.text('Tutor'));
    await tester.pumpAndSettle();
    expect(find.text('El tutor aún no está conectado'), findsOneWidget);

    await tester.tap(find.text('Laboratorio'));
    await tester.pumpAndSettle();
    expect(find.text('Todavía no has registrado ninguna skill.'), findsOneWidget);

    await tester.tap(find.text('Biblioteca'));
    await tester.pumpAndSettle();
    expect(find.textContaining('de 314 libros'), findsOneWidget);
  });
}
