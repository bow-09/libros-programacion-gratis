import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:material_ui/material_ui.dart';

import '../library_catalog/library_providers.dart';
import '../library_catalog/library_screen.dart';
import 'lesson_screen.dart';
import 'path_models.dart';
import 'path_providers.dart';

class PathsScreen extends ConsumerWidget {
  const PathsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final paths = ref.watch(learningPathsProvider);
    final completed = ref.watch(progressProvider);
    return Scaffold(
      appBar: AppBar(title: const Text('Rutas de aprendizaje')),
      body: paths.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('No se pudieron cargar las rutas: $e')),
        data: (data) => ListView(
          padding: const EdgeInsets.all(16),
          children: [
            for (final path in data)
              Card(
                clipBehavior: Clip.antiAlias,
                child: InkWell(
                  onTap: () => Navigator.of(context).push(
                    MaterialPageRoute<void>(builder: (_) => PathDetailScreen(path: path)),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(path.title, style: Theme.of(context).textTheme.titleLarge),
                        const SizedBox(height: 4),
                        Text(path.description),
                        const SizedBox(height: 12),
                        LinearProgressIndicator(value: pathProgress(path, completed)),
                        const SizedBox(height: 6),
                        Text(
                          '${path.level} · ${path.lessons.length} lecciones · '
                          '${(pathProgress(path, completed) * 100).round()} % completado',
                          style: Theme.of(context).textTheme.labelMedium,
                        ),
                      ],
                    ),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

class PathDetailScreen extends ConsumerWidget {
  const PathDetailScreen({super.key, required this.path});

  final LearningPath path;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final completed = ref.watch(progressProvider);
    final catalog = ref.watch(catalogProvider).value;
    final books = [
      for (final id in path.bookIds) ?catalog?.byId(id),
    ];
    final theme = Theme.of(context);
    return Scaffold(
      appBar: AppBar(title: Text(path.title)),
      body: ListView(
        children: [
          for (final module in path.modules) ...[
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 20, 16, 4),
              child: Text(module.title, style: theme.textTheme.titleMedium),
            ),
            for (final lesson in module.lessons)
              ListTile(
                leading: Icon(
                  completed.contains(lesson.id) ? Icons.check_circle : Icons.circle_outlined,
                  color: completed.contains(lesson.id) ? theme.colorScheme.primary : null,
                ),
                title: Text(lesson.title),
                subtitle: Text(switch (lesson.type) {
                  LessonType.theory => 'Teoría',
                  LessonType.practice => 'Práctica',
                  LessonType.quiz => 'Cuestionario',
                }),
                onTap: () => Navigator.of(context).push(
                  MaterialPageRoute<void>(builder: (_) => LessonScreen(lesson: lesson)),
                ),
              ),
          ],
          if (books.isNotEmpty) ...[
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 24, 16, 4),
              child: Text('Libros para profundizar', style: theme.textTheme.titleMedium),
            ),
            for (final book in books) BookTile(book: book),
          ],
          const SizedBox(height: 24),
        ],
      ),
    );
  }
}
