import 'package:flutter_markdown_plus/flutter_markdown_plus.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:material_ui/material_ui.dart';

import 'path_models.dart';
import 'path_providers.dart';

class LessonScreen extends ConsumerStatefulWidget {
  const LessonScreen({super.key, required this.lesson});

  final Lesson lesson;

  @override
  ConsumerState<LessonScreen> createState() => _LessonScreenState();
}

class _LessonScreenState extends ConsumerState<LessonScreen> {
  bool _showSolution = false;
  final Map<int, int> _answers = {};
  bool _submitted = false;

  Lesson get lesson => widget.lesson;

  int get _score => [
    for (var i = 0; i < lesson.questions.length; i++)
      if (_answers[i] == lesson.questions[i].correct) i,
  ].length;

  void _complete() {
    ref.read(progressProvider.notifier).setCompleted(lesson.id, true);
    Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    final done = ref.watch(progressProvider).contains(lesson.id);
    return Scaffold(
      appBar: AppBar(title: Text(lesson.title)),
      body: SelectionArea(
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            if (lesson.content.isNotEmpty) MarkdownBody(data: lesson.content),
            if (lesson.type == LessonType.practice) ..._practice(),
            if (lesson.type == LessonType.quiz) ..._quiz(context),
            const SizedBox(height: 24),
            if (lesson.type != LessonType.quiz)
              FilledButton(
                onPressed: done ? null : _complete,
                child: Text(done ? 'Lección completada' : 'Marcar como completada'),
              ),
          ],
        ),
      ),
    );
  }

  List<Widget> _practice() => [
    const SizedBox(height: 16),
    if (lesson.solution != null)
      Align(
        alignment: Alignment.centerLeft,
        child: OutlinedButton(
          onPressed: () => setState(() => _showSolution = !_showSolution),
          child: Text(_showSolution ? 'Ocultar solución' : 'Ver solución'),
        ),
      ),
    if (_showSolution && lesson.solution != null)
      Padding(
        padding: const EdgeInsets.only(top: 12),
        child: MarkdownBody(data: lesson.solution!),
      ),
  ];

  List<Widget> _quiz(BuildContext context) {
    final theme = Theme.of(context);
    final allAnswered = _answers.length == lesson.questions.length;
    final passed = _score == lesson.questions.length;
    return [
      for (var i = 0; i < lesson.questions.length; i++) ...[
        Padding(
          padding: const EdgeInsets.only(top: 16, bottom: 4),
          child: Text(
            '${i + 1}. ${lesson.questions[i].question}',
            style: theme.textTheme.titleSmall,
          ),
        ),
        RadioGroup<int>(
          groupValue: _answers[i],
          onChanged: (v) {
            if (_submitted || v == null) return;
            setState(() => _answers[i] = v);
          },
          child: Column(
            children: [
              for (var o = 0; o < lesson.questions[i].options.length; o++)
                RadioListTile<int>(
                  value: o,
                  dense: true,
                  title: Text(lesson.questions[i].options[o]),
                ),
            ],
          ),
        ),
        if (_submitted)
          Text(
            '${_answers[i] == lesson.questions[i].correct ? 'Correcto' : 'Incorrecto'}. '
            '${lesson.questions[i].explanation}',
            style: TextStyle(
              color: _answers[i] == lesson.questions[i].correct
                  ? theme.colorScheme.primary
                  : theme.colorScheme.error,
            ),
          ),
      ],
      const SizedBox(height: 24),
      if (!_submitted)
        FilledButton(
          onPressed: allAnswered ? () => setState(() => _submitted = true) : null,
          child: const Text('Comprobar respuestas'),
        )
      else ...[
        Text(
          'Resultado: $_score de ${lesson.questions.length}',
          style: theme.textTheme.titleMedium,
        ),
        const SizedBox(height: 8),
        if (passed)
          FilledButton(onPressed: _complete, child: const Text('Completar lección'))
        else
          OutlinedButton(
            onPressed: () => setState(() {
              _answers.clear();
              _submitted = false;
            }),
            child: const Text('Intentar de nuevo'),
          ),
      ],
    ];
  }
}
