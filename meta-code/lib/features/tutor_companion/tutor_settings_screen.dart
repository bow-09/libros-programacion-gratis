import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:material_ui/material_ui.dart';

import 'tutor_models.dart';
import 'tutor_providers.dart';

class TutorSettingsScreen extends ConsumerStatefulWidget {
  const TutorSettingsScreen({super.key});

  @override
  ConsumerState<TutorSettingsScreen> createState() => _TutorSettingsScreenState();
}

class _TutorSettingsScreenState extends ConsumerState<TutorSettingsScreen> {
  late TutorConfig _config = ref.read(tutorConfigProvider);
  late final _name = TextEditingController(text: _config.name);
  late final _tone = TextEditingController(text: _config.tone);
  late final _apiKey = TextEditingController(text: _config.apiKey);
  late final _baseUrl = TextEditingController(text: _config.baseUrl);
  late final _model = TextEditingController(text: _config.model);

  @override
  void dispose() {
    for (final c in [_name, _tone, _apiKey, _baseUrl, _model]) {
      c.dispose();
    }
    super.dispose();
  }

  void _save() {
    String orDefault(TextEditingController c, String fallback) =>
        c.text.trim().isEmpty ? fallback : c.text.trim();
    ref.read(tutorConfigProvider.notifier).save(
      _config.copyWith(
        name: orDefault(_name, 'Meta'),
        tone: _tone.text.trim(),
        apiKey: _apiKey.text.trim(),
        baseUrl: orDefault(_baseUrl, TutorConfig.defaultBaseUrl),
        model: orDefault(_model, TutorConfig.defaultModel),
      ),
    );
    Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    const gap = SizedBox(height: 16);
    return Scaffold(
      appBar: AppBar(
        title: const Text('Configurar tutor'),
        actions: [TextButton(onPressed: _save, child: const Text('Guardar'))],
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Text('Identidad', style: theme.textTheme.titleMedium),
          gap,
          TextField(
            controller: _name,
            decoration: const InputDecoration(labelText: 'Nombre', border: OutlineInputBorder()),
          ),
          gap,
          DropdownButtonFormField<TutorPersona>(
            initialValue: _config.persona,
            decoration: const InputDecoration(labelText: 'Personalidad'),
            items: [
              for (final p in TutorPersona.values) DropdownMenuItem(value: p, child: Text(p.label)),
            ],
            onChanged: (v) => setState(() => _config = _config.copyWith(persona: v)),
          ),
          gap,
          TextField(
            controller: _tone,
            decoration: const InputDecoration(
              labelText: 'Tono',
              hintText: 'cercano y claro',
              border: OutlineInputBorder(),
            ),
          ),
          const SizedBox(height: 24),
          Text('Forma de enseñar', style: theme.textTheme.titleMedium),
          gap,
          SegmentedButton<TutorMode>(
            segments: [
              for (final m in TutorMode.values) ButtonSegment(value: m, label: Text(m.label)),
            ],
            selected: {_config.mode},
            onSelectionChanged: (s) => setState(() => _config = _config.copyWith(mode: s.first)),
          ),
          gap,
          SegmentedButton<TutorLevel>(
            segments: [
              for (final l in TutorLevel.values) ButtonSegment(value: l, label: Text(l.label)),
            ],
            selected: {_config.level},
            onSelectionChanged: (s) => setState(() => _config = _config.copyWith(level: s.first)),
          ),
          const SizedBox(height: 24),
          Text('Conexión', style: theme.textTheme.titleMedium),
          const SizedBox(height: 4),
          const Text(
            'La clave se guarda sin cifrar en este dispositivo y solo se envía al servidor indicado.',
          ),
          gap,
          TextField(
            controller: _apiKey,
            obscureText: true,
            autocorrect: false,
            decoration: const InputDecoration(
              labelText: 'Clave de API de Claude',
              border: OutlineInputBorder(),
            ),
          ),
          gap,
          TextField(
            controller: _baseUrl,
            autocorrect: false,
            decoration: const InputDecoration(labelText: 'Servidor', border: OutlineInputBorder()),
          ),
          gap,
          TextField(
            controller: _model,
            autocorrect: false,
            decoration: const InputDecoration(labelText: 'Modelo', border: OutlineInputBorder()),
          ),
        ],
      ),
    );
  }
}
