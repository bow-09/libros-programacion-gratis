import 'dart:convert';

import 'package:flutter/services.dart' show rootBundle;
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/storage.dart';
import 'path_models.dart';

final learningPathsProvider = FutureProvider<List<LearningPath>>((ref) async {
  final raw = await rootBundle.loadString('assets/data/learning_paths.json');
  final json = jsonDecode(raw) as Map<String, dynamic>;
  return [
    for (final p in json['rutas'] as List) LearningPath.fromJson(p as Map<String, dynamic>),
  ];
});

/// Ids de las lecciones completadas, guardados en el dispositivo.
class ProgressNotifier extends Notifier<Set<String>> {
  static const _key = 'progress.completedLessons';

  @override
  Set<String> build() => (ref.watch(sharedPreferencesProvider).getStringList(_key) ?? []).toSet();

  void setCompleted(String lessonId, bool completed) {
    final next = {...state};
    completed ? next.add(lessonId) : next.remove(lessonId);
    state = next;
    ref.read(sharedPreferencesProvider).setStringList(_key, next.toList());
  }
}

final progressProvider = NotifierProvider<ProgressNotifier, Set<String>>(ProgressNotifier.new);

double pathProgress(LearningPath path, Set<String> completed) {
  final lessons = path.lessons.toList();
  if (lessons.isEmpty) return 0;
  return lessons.where((l) => completed.contains(l.id)).length / lessons.length;
}
