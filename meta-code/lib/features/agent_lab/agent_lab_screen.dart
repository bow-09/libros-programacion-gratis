import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:material_ui/material_ui.dart';

import 'skill_models.dart';
import 'skill_providers.dart';

class AgentLabScreen extends ConsumerWidget {
  const AgentLabScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final skills = ref.watch(skillsProvider);
    return Scaffold(
      appBar: AppBar(title: const Text('Laboratorio de agentes')),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _edit(context, null),
        icon: const Icon(Icons.add),
        label: const Text('Añadir skill'),
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 96),
        children: [
          const Text(
            'Aquí registras las skills que tú programas y alojas: un servidor MCP o una API REST '
            'en tu propio entorno. meta-code solo guarda la dirección y comprueba que responde; '
            'el código y los datos siguen siendo tuyos.',
          ),
          const SizedBox(height: 16),
          if (skills.isEmpty)
            const Padding(
              padding: EdgeInsets.only(top: 48),
              child: Center(child: Text('Todavía no has registrado ninguna skill.')),
            ),
          for (final skill in skills) _SkillCard(skill: skill, onEdit: () => _edit(context, skill)),
        ],
      ),
    );
  }

  void _edit(BuildContext context, Skill? skill) => Navigator.of(
    context,
  ).push(MaterialPageRoute<void>(builder: (_) => SkillFormScreen(skill: skill)));
}

class _SkillCard extends ConsumerStatefulWidget {
  const _SkillCard({required this.skill, required this.onEdit});

  final Skill skill;
  final VoidCallback onEdit;

  @override
  ConsumerState<_SkillCard> createState() => _SkillCardState();
}

class _SkillCardState extends ConsumerState<_SkillCard> {
  bool _checking = false;
  SkillCheck? _result;

  Future<void> _check() async {
    setState(() => _checking = true);
    final result = await ref.read(skillClientProvider).check(widget.skill);
    if (!mounted) return;
    setState(() {
      _checking = false;
      _result = result;
    });
  }

  @override
  Widget build(BuildContext context) {
    final skill = widget.skill;
    final theme = Theme.of(context);
    final result = _result;
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(child: Text(skill.name, style: theme.textTheme.titleMedium)),
                Chip(label: Text(skill.kind.label)),
              ],
            ),
            if (skill.description.isNotEmpty) Text(skill.description),
            const SizedBox(height: 4),
            Text(skill.url, style: theme.textTheme.bodySmall),
            if (result != null) ...[
              const SizedBox(height: 12),
              Text(
                result.summary,
                style: TextStyle(
                  color: result.ok ? theme.colorScheme.primary : theme.colorScheme.error,
                ),
              ),
              if (result.tools.isNotEmpty)
                Padding(
                  padding: const EdgeInsets.only(top: 8),
                  child: Wrap(
                    spacing: 6,
                    runSpacing: 6,
                    children: [for (final t in result.tools) Chip(label: Text(t))],
                  ),
                ),
            ],
            const SizedBox(height: 8),
            Row(
              children: [
                FilledButton.tonal(
                  onPressed: _checking ? null : _check,
                  child: Text(_checking ? 'Comprobando…' : 'Probar conexión'),
                ),
                const Spacer(),
                IconButton(
                  tooltip: 'Editar',
                  icon: const Icon(Icons.edit_outlined),
                  onPressed: widget.onEdit,
                ),
                IconButton(
                  tooltip: 'Eliminar',
                  icon: const Icon(Icons.delete_outline),
                  onPressed: () => _confirmDelete(context),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _confirmDelete(BuildContext context) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('¿Eliminar «${widget.skill.name}»?'),
        content: const Text('Solo se borra de meta-code; tu servidor no se modifica.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Cancelar')),
          FilledButton(onPressed: () => Navigator.pop(context, true), child: const Text('Eliminar')),
        ],
      ),
    );
    if (confirmed == true) ref.read(skillsProvider.notifier).remove(widget.skill.id);
  }
}

class SkillFormScreen extends ConsumerStatefulWidget {
  const SkillFormScreen({super.key, this.skill});

  final Skill? skill;

  @override
  ConsumerState<SkillFormScreen> createState() => _SkillFormScreenState();
}

class _SkillFormScreenState extends ConsumerState<SkillFormScreen> {
  final _form = GlobalKey<FormState>();
  late final _name = TextEditingController(text: widget.skill?.name);
  late final _description = TextEditingController(text: widget.skill?.description);
  late final _url = TextEditingController(text: widget.skill?.url);
  late final _token = TextEditingController(text: widget.skill?.token);
  late SkillKind _kind = widget.skill?.kind ?? SkillKind.mcp;

  @override
  void dispose() {
    for (final c in [_name, _description, _url, _token]) {
      c.dispose();
    }
    super.dispose();
  }

  void _save() {
    if (!_form.currentState!.validate()) return;
    ref.read(skillsProvider.notifier).upsert(
      Skill(
        id: widget.skill?.id ?? DateTime.now().microsecondsSinceEpoch.toString(),
        name: _name.text.trim(),
        kind: _kind,
        url: _url.text.trim(),
        description: _description.text.trim(),
        token: _token.text.trim(),
      ),
    );
    Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    const gap = SizedBox(height: 16);
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.skill == null ? 'Nueva skill' : 'Editar skill'),
        actions: [TextButton(onPressed: _save, child: const Text('Guardar'))],
      ),
      body: Form(
        key: _form,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            SegmentedButton<SkillKind>(
              segments: [
                for (final k in SkillKind.values) ButtonSegment(value: k, label: Text(k.label)),
              ],
              selected: {_kind},
              onSelectionChanged: (s) => setState(() => _kind = s.first),
            ),
            gap,
            TextFormField(
              controller: _name,
              decoration: const InputDecoration(labelText: 'Nombre', border: OutlineInputBorder()),
              validator: (v) => (v ?? '').trim().isEmpty ? 'Ponle un nombre.' : null,
            ),
            gap,
            TextFormField(
              controller: _url,
              autocorrect: false,
              keyboardType: TextInputType.url,
              decoration: InputDecoration(
                labelText: 'URL',
                hintText: _kind == SkillKind.mcp
                    ? 'https://mi-servidor.dev/mcp'
                    : 'https://mi-servidor.dev/api/estado',
                border: const OutlineInputBorder(),
              ),
              validator: (v) {
                final uri = Uri.tryParse((v ?? '').trim());
                final valid = uri != null && (uri.isScheme('http') || uri.isScheme('https'));
                return valid ? null : 'Escribe una URL que empiece por http:// o https://';
              },
            ),
            gap,
            TextFormField(
              controller: _description,
              decoration: const InputDecoration(
                labelText: 'Qué hace (opcional)',
                border: OutlineInputBorder(),
              ),
            ),
            gap,
            TextFormField(
              controller: _token,
              obscureText: true,
              autocorrect: false,
              decoration: const InputDecoration(
                labelText: 'Token de acceso (opcional)',
                helperText: 'Se guarda sin cifrar en este dispositivo.',
                border: OutlineInputBorder(),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
