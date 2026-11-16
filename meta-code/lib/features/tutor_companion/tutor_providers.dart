import 'dart:convert';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/storage.dart';
import 'tutor_client.dart';
import 'tutor_models.dart';

final tutorClientProvider = Provider<TutorClient>((ref) => TutorClient());

class TutorConfigNotifier extends Notifier<TutorConfig> {
  static const _key = 'tutor.config';

  @override
  TutorConfig build() {
    final raw = ref.watch(sharedPreferencesProvider).getString(_key);
    if (raw == null) return const TutorConfig();
    return TutorConfig.fromJson(jsonDecode(raw) as Map<String, dynamic>);
  }

  void save(TutorConfig config) {
    state = config;
    ref.read(sharedPreferencesProvider).setString(_key, jsonEncode(config.toJson()));
  }
}

final tutorConfigProvider = NotifierProvider<TutorConfigNotifier, TutorConfig>(
  TutorConfigNotifier.new,
);

class ChatState {
  const ChatState({this.messages = const [], this.sending = false, this.error});

  final List<ChatMessage> messages;
  final bool sending;
  final String? error;
}

class ChatNotifier extends Notifier<ChatState> {
  static const _key = 'tutor.chat';

  @override
  ChatState build() {
    final raw = ref.watch(sharedPreferencesProvider).getString(_key);
    if (raw == null) return const ChatState();
    return ChatState(
      messages: [
        for (final m in jsonDecode(raw) as List) ChatMessage.fromJson(m as Map<String, dynamic>),
      ],
    );
  }

  void _persist(List<ChatMessage> messages) => ref
      .read(sharedPreferencesProvider)
      .setString(_key, jsonEncode([for (final m in messages) m.toJson()]));

  Future<void> send(String text) async {
    final trimmed = text.trim();
    if (trimmed.isEmpty || state.sending) return;
    final history = [...state.messages, ChatMessage(fromUser: true, text: trimmed)];
    state = ChatState(messages: history, sending: true);
    await _request(history);
  }

  /// Reintenta el último mensaje del usuario tras un error.
  Future<void> retry() async {
    if (state.sending || state.messages.isEmpty || !state.messages.last.fromUser) return;
    state = ChatState(messages: state.messages, sending: true);
    await _request(state.messages);
  }

  Future<void> _request(List<ChatMessage> history) async {
    try {
      final reply = await ref.read(tutorClientProvider).send(ref.read(tutorConfigProvider), history);
      final messages = [...history, reply];
      state = ChatState(messages: messages);
      _persist(messages);
    } on TutorException catch (e) {
      state = ChatState(messages: history, error: e.message);
      _persist(history);
    }
  }

  void clear() {
    state = const ChatState();
    ref.read(sharedPreferencesProvider).remove(_key);
  }
}

final chatProvider = NotifierProvider<ChatNotifier, ChatState>(ChatNotifier.new);
