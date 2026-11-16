enum SkillKind {
  mcp('Servidor MCP'),
  rest('API REST');

  const SkillKind(this.label);
  final String label;
}

class Skill {
  const Skill({
    required this.id,
    required this.name,
    required this.kind,
    required this.url,
    this.description = '',
    this.token = '',
  });

  final String id;
  final String name;
  final SkillKind kind;
  final String url;
  final String description;
  final String token;

  Map<String, dynamic> toJson() => {
    'id': id,
    'name': name,
    'kind': kind.name,
    'url': url,
    'description': description,
    'token': token,
  };

  factory Skill.fromJson(Map<String, dynamic> json) => Skill(
    id: json['id'] as String,
    name: json['name'] as String,
    kind: SkillKind.values.firstWhere((k) => k.name == json['kind'], orElse: () => SkillKind.rest),
    url: json['url'] as String,
    description: json['description'] as String? ?? '',
    token: json['token'] as String? ?? '',
  );
}

class SkillCheck {
  const SkillCheck({required this.ok, required this.summary, this.tools = const []});

  final bool ok;
  final String summary;

  /// Herramientas que anuncia un servidor MCP.
  final List<String> tools;
}
