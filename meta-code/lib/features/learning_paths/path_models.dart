enum LessonType { theory, practice, quiz }

class QuizQuestion {
  const QuizQuestion({
    required this.question,
    required this.options,
    required this.correct,
    required this.explanation,
  });

  final String question;
  final List<String> options;
  final int correct;
  final String explanation;

  factory QuizQuestion.fromJson(Map<String, dynamic> json) => QuizQuestion(
    question: json['pregunta'] as String,
    options: (json['opciones'] as List).cast<String>(),
    correct: json['correcta'] as int,
    explanation: json['explicacion'] as String,
  );
}

class Lesson {
  const Lesson({
    required this.id,
    required this.title,
    required this.type,
    this.content = '',
    this.solution,
    this.questions = const [],
  });

  final String id;
  final String title;
  final LessonType type;

  /// Markdown. En una práctica es el enunciado.
  final String content;

  /// Markdown con la solución de una práctica.
  final String? solution;
  final List<QuizQuestion> questions;

  factory Lesson.fromJson(Map<String, dynamic> json) => Lesson(
    id: json['id'] as String,
    title: json['titulo'] as String,
    type: switch (json['tipo']) {
      'practica' => LessonType.practice,
      'quiz' => LessonType.quiz,
      _ => LessonType.theory,
    },
    content: json['contenido'] as String? ?? '',
    solution: json['solucion'] as String?,
    questions: [
      for (final q in json['preguntas'] as List? ?? [])
        QuizQuestion.fromJson(q as Map<String, dynamic>),
    ],
  );
}

class PathModule {
  const PathModule({required this.id, required this.title, required this.lessons});

  final String id;
  final String title;
  final List<Lesson> lessons;

  factory PathModule.fromJson(Map<String, dynamic> json) => PathModule(
    id: json['id'] as String,
    title: json['titulo'] as String,
    lessons: [
      for (final l in json['lecciones'] as List) Lesson.fromJson(l as Map<String, dynamic>),
    ],
  );
}

class LearningPath {
  const LearningPath({
    required this.id,
    required this.title,
    required this.description,
    required this.level,
    required this.modules,
    required this.bookIds,
  });

  final String id;
  final String title;
  final String description;
  final String level;
  final List<PathModule> modules;

  /// Ids del catálogo de libros recomendados para la ruta.
  final List<String> bookIds;

  Iterable<Lesson> get lessons => modules.expand((m) => m.lessons);

  factory LearningPath.fromJson(Map<String, dynamic> json) => LearningPath(
    id: json['id'] as String,
    title: json['titulo'] as String,
    description: json['descripcion'] as String,
    level: json['nivel'] as String,
    modules: [
      for (final m in json['modulos'] as List) PathModule.fromJson(m as Map<String, dynamic>),
    ],
    bookIds: (json['libros'] as List? ?? []).cast<String>(),
  );
}
