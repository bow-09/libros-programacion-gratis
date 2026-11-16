enum TutorPersona {
  mentor('Mentor técnico', 'un mentor técnico con experiencia, riguroso y paciente'),
  colega('Colega de estudio', 'un compañero de estudio que aprende junto al usuario y piensa en voz alta'),
  mascota('Mascota guía', 'una mascota guía simpática y animada, sin perder precisión técnica');

  const TutorPersona(this.label, this.prompt);
  final String label;
  final String prompt;
}

enum TutorMode {
  conceptual(
    'Tutor conceptual',
    'Modo conceptual: explica los fundamentos desde varios ángulos, usa analogías y propone '
        'ejercicios cortos de razonamiento. No exijas construir sistemas completos.',
  ),
  creador(
    'Creador práctico',
    'Modo creador: guía paso a paso para construir software real. Ayuda a estructurar el código, '
        'escribir funciones útiles y gestionar el repositorio. Deja que el usuario escriba el '
        'código y revisa lo que te muestre.',
  );

  const TutorMode(this.label, this.prompt);
  final String label;
  final String prompt;
}

enum TutorLevel {
  principiante('Principiante'),
  intermedio('Intermedio'),
  avanzado('Avanzado');

  const TutorLevel(this.label);
  final String label;
}

class TutorConfig {
  const TutorConfig({
    this.name = 'Meta',
    this.persona = TutorPersona.mentor,
    this.mode = TutorMode.conceptual,
    this.level = TutorLevel.principiante,
    this.tone = 'cercano y claro',
    this.apiKey = '',
    this.baseUrl = defaultBaseUrl,
    this.model = defaultModel,
  });

  static const defaultBaseUrl = 'https://api.anthropic.com';
  static const defaultModel = 'claude-opus-5-5';

  final String name;
  final TutorPersona persona;
  final TutorMode mode;
  final TutorLevel level;
  final String tone;
  final String apiKey;
  final String baseUrl;
  final String model;

  bool get isConnected => apiKey.trim().isNotEmpty;

  String get systemPrompt =>
      'Eres $name, ${persona.prompt}. Acompañas a una persona que aprende programación en la '
      'aplicación meta-code. Su nivel es ${level.label.toLowerCase()}.\n\n'
      'Responde siempre en español, con un tono $tono. ${mode.prompt}\n\n'
      'Explica el porqué de cada idea, no solo el cómo. Cuando el usuario se equivoque, ayúdale a '
      'encontrar el error con preguntas antes de darle la respuesta. Usa Markdown y bloques de '
      'código cuando ayuden. Si no sabes algo o no puedes comprobarlo, dilo.';

  String get tono => tone.trim().isEmpty ? 'cercano y claro' : tone.trim();

  TutorConfig copyWith({
    String? name,
    TutorPersona? persona,
    TutorMode? mode,
    TutorLevel? level,
    String? tone,
    String? apiKey,
    String? baseUrl,
    String? model,
  }) => TutorConfig(
    name: name ?? this.name,
    persona: persona ?? this.persona,
    mode: mode ?? this.mode,
    level: level ?? this.level,
    tone: tone ?? this.tone,
    apiKey: apiKey ?? this.apiKey,
    baseUrl: baseUrl ?? this.baseUrl,
    model: model ?? this.model,
  );

  Map<String, dynamic> toJson() => {
    'name': name,
    'persona': persona.name,
    'mode': mode.name,
    'level': level.name,
    'tone': tone,
    'apiKey': apiKey,
    'baseUrl': baseUrl,
    'model': model,
  };

  factory TutorConfig.fromJson(Map<String, dynamic> json) {
    T pick<T extends Enum>(List<T> values, Object? name, T fallback) =>
        values.firstWhere((v) => v.name == name, orElse: () => fallback);
    return TutorConfig(
      name: json['name'] as String? ?? 'Meta',
      persona: pick(TutorPersona.values, json['persona'], TutorPersona.mentor),
      mode: pick(TutorMode.values, json['mode'], TutorMode.conceptual),
      level: pick(TutorLevel.values, json['level'], TutorLevel.principiante),
      tone: json['tone'] as String? ?? 'cercano y claro',
      apiKey: json['apiKey'] as String? ?? '',
      baseUrl: json['baseUrl'] as String? ?? defaultBaseUrl,
      model: json['model'] as String? ?? defaultModel,
    );
  }
}

class ChatMessage {
  const ChatMessage({required this.fromUser, required this.text, this.rawContent});

  final bool fromUser;
  final String text;

  /// Bloques de contenido originales de la respuesta del modelo. Se reenvían
  /// sin modificar en los turnos siguientes, tal como pide la API.
  final List<dynamic>? rawContent;

  Map<String, dynamic> toApi() => {
    'role': fromUser ? 'user' : 'assistant',
    'content': rawContent ?? text,
  };

  Map<String, dynamic> toJson() => {
    'fromUser': fromUser,
    'text': text,
    'rawContent': ?rawContent,
  };

  factory ChatMessage.fromJson(Map<String, dynamic> json) => ChatMessage(
    fromUser: json['fromUser'] as bool,
    text: json['text'] as String,
    rawContent: json['rawContent'] as List<dynamic>?,
  );
}
