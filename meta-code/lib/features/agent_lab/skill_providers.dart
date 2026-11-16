import 'dart:convert';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/storage.dart';
import 'skill_client.dart';
import 'skill_models.dart';

final skillClientProvider = Provider<SkillClient>((ref) => SkillClient());

class SkillsNotifier extends Notifier<List<Skill>> {
  static const _key = 'agentLab.skills';

  @override
  List<Skill> build() {
    final raw = ref.watch(sharedPreferencesProvider).getString(_key);
    if (raw == null) return const [];
    return [for (final s in jsonDecode(raw) as List) Skill.fromJson(s as Map<String, dynamic>)];
  }

  void _set(List<Skill> skills) {
    state = skills;
    ref
        .read(sharedPreferencesProvider)
        .setString(_key, jsonEncode([for (final s in skills) s.toJson()]));
  }

  /// Crea la skill o reemplaza la que tenga el mismo id.
  void upsert(Skill skill) {
    final exists = state.any((s) => s.id == skill.id);
    _set(exists ? [for (final s in state) s.id == skill.id ? skill : s] : [...state, skill]);
  }

  void remove(String id) => _set([for (final s in state) if (s.id != id) s]);
}

final skillsProvider = NotifierProvider<SkillsNotifier, List<Skill>>(SkillsNotifier.new);
