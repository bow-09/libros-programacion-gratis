import 'package:flutter_markdown_plus/flutter_markdown_plus.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:material_ui/material_ui.dart';

import 'tutor_models.dart';
import 'tutor_providers.dart';
import 'tutor_settings_screen.dart';

class TutorScreen extends ConsumerStatefulWidget {
  const TutorScreen({super.key});

  @override
  ConsumerState<TutorScreen> createState() => _TutorScreenState();
}

class _TutorScreenState extends ConsumerState<TutorScreen> {
  final _input = TextEditingController();
  final _scroll = ScrollController();

  @override
  void dispose() {
    _input.dispose();
    _scroll.dispose();
    super.dispose();
  }

  void _openSettings() => Navigator.of(
    context,
  ).push(MaterialPageRoute<void>(builder: (_) => const TutorSettingsScreen()));

  void _send() {
    ref.read(chatProvider.notifier).send(_input.text);
    _input.clear();
  }

  @override
  Widget build(BuildContext context) {
    final config = ref.watch(tutorConfigProvider);
    final chat = ref.watch(chatProvider);
    final theme = Theme.of(context);

    ref.listen(chatProvider, (_, _) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (_scroll.hasClients) {
          _scroll.animateTo(
            _scroll.position.maxScrollExtent,
            duration: const Duration(milliseconds: 200),
            curve: Curves.easeOut,
          );
        }
      });
    });

    return Scaffold(
      appBar: AppBar(
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(config.name),
            Text(
              '${config.persona.label} · ${config.mode.label}',
              style: theme.textTheme.labelSmall,
            ),
          ],
        ),
        actions: [
          if (chat.messages.isNotEmpty)
            IconButton(
              tooltip: 'Nueva conversación',
              icon: const Icon(Icons.delete_outline),
              onPressed: () => ref.read(chatProvider.notifier).clear(),
            ),
          IconButton(
            tooltip: 'Configurar tutor',
            icon: const Icon(Icons.tune),
            onPressed: _openSettings,
          ),
        ],
      ),
      body: !config.isConnected
          ? _NotConnected(onConfigure: _openSettings)
          : Column(
              children: [
                Expanded(
                  child: chat.messages.isEmpty
                      ? Center(
                          child: Padding(
                            padding: const EdgeInsets.all(32),
                            child: Text(
                              'Pregúntale a ${config.name} sobre lo que estás aprendiendo, '
                              'o pégale un fragmento de código para revisarlo.',
                              textAlign: TextAlign.center,
                            ),
                          ),
                        )
                      : SelectionArea(
                          child: ListView.builder(
                            controller: _scroll,
                            padding: const EdgeInsets.all(16),
                            itemCount: chat.messages.length,
                            itemBuilder: (context, i) => _Bubble(message: chat.messages[i]),
                          ),
                        ),
                ),
                if (chat.sending) const LinearProgressIndicator(),
                if (chat.error != null)
                  MaterialBanner(
                    content: Text(chat.error!),
                    actions: [
                      TextButton(
                        onPressed: () => ref.read(chatProvider.notifier).retry(),
                        child: const Text('Reintentar'),
                      ),
                    ],
                  ),
                SafeArea(
                  top: false,
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(16, 8, 8, 8),
                    child: Row(
                      children: [
                        Expanded(
                          child: TextField(
                            controller: _input,
                            minLines: 1,
                            maxLines: 5,
                            textInputAction: TextInputAction.newline,
                            decoration: const InputDecoration(
                              hintText: 'Escribe tu mensaje',
                              border: OutlineInputBorder(),
                            ),
                          ),
                        ),
                        IconButton(
                          tooltip: 'Enviar',
                          icon: const Icon(Icons.send),
                          onPressed: chat.sending ? null : _send,
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
    );
  }
}

class _NotConnected extends StatelessWidget {
  const _NotConnected({required this.onConfigure});

  final VoidCallback onConfigure;

  @override
  Widget build(BuildContext context) => Center(
    child: ConstrainedBox(
      constraints: const BoxConstraints(maxWidth: 420),
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text('El tutor aún no está conectado', style: Theme.of(context).textTheme.titleLarge),
            const SizedBox(height: 8),
            const Text(
              'Para conversar con tu acompañante hace falta una clave de API de Claude. '
              'Añádela en la configuración; se guarda solo en este dispositivo.',
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 16),
            FilledButton(onPressed: onConfigure, child: const Text('Configurar tutor')),
          ],
        ),
      ),
    ),
  );
}

class _Bubble extends StatelessWidget {
  const _Bubble({required this.message});

  final ChatMessage message;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Align(
      alignment: message.fromUser ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        constraints: const BoxConstraints(maxWidth: 640),
        margin: const EdgeInsets.symmetric(vertical: 4),
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: message.fromUser ? scheme.primaryContainer : scheme.surfaceContainerHighest,
          borderRadius: BorderRadius.circular(12),
        ),
        child: message.fromUser ? Text(message.text) : MarkdownBody(data: message.text),
      ),
    );
  }
}
