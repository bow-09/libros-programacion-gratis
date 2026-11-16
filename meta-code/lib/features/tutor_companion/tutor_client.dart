import 'dart:convert';

import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:http/http.dart' as http;

import 'tutor_models.dart';

class TutorException implements Exception {
  const TutorException(this.message);
  final String message;

  @override
  String toString() => message;
}

/// Cliente mínimo de la Messages API de Claude (HTTP directo; no hay SDK oficial para Dart).
class TutorClient {
  TutorClient({http.Client? httpClient}) : _http = httpClient ?? http.Client();

  final http.Client _http;

  Future<ChatMessage> send(TutorConfig config, List<ChatMessage> history) async {
    final base = config.baseUrl.trim().replaceAll(RegExp(r'/+$'), '');
    final http.Response response;
    try {
      response = await _http.post(
        Uri.parse('$base/v1/messages'),
        headers: {
          'content-type': 'application/json',
          'x-api-key': config.apiKey.trim(),
          'anthropic-version': '2026-10-21',
          'anthropic-beta': 'server-side-fallback-2026-07-01',
          // Necesario para llamar a la API directamente desde un navegador.
          if (kIsWeb) 'anthropic-dangerous-direct-browser-access': 'true',
        },
        body: jsonEncode({
          'model': config.model.trim(),
          'max_tokens': 16000,
          'system': config.systemPrompt,
          'messages': [for (final m in history) m.toApi()],
          // Si el modelo rechaza la petición, la API la reintenta en un modelo alternativo.
          'fallbacks': 'default',
        }),
      );
    } on Exception catch (e) {
      throw TutorException('No se pudo conectar con el servicio: $e');
    }

    final Map<String, dynamic> body;
    try {
      body = jsonDecode(utf8.decode(response.bodyBytes)) as Map<String, dynamic>;
    } on FormatException {
      throw TutorException('Respuesta inesperada del servicio (HTTP ${response.statusCode}).');
    }

    if (response.statusCode != 200) {
      final detail = (body['error'] as Map<String, dynamic>?)?['message'] ?? 'sin detalle';
      throw TutorException(switch (response.statusCode) {
        401 => 'La clave de API no es válida. Revísala en la configuración del tutor.',
        429 => 'Se alcanzó el límite de uso. Espera un momento y vuelve a intentarlo.',
        >= 500 => 'El servicio no está disponible ahora mismo. Inténtalo de nuevo. ($detail)',
        _ => 'Error ${response.statusCode}: $detail',
      });
    }

    if (body['stop_reason'] == 'refusal') {
      throw const TutorException('El modelo rechazó esta petición. Prueba a reformularla.');
    }

    final content = body['content'] as List<dynamic>? ?? const [];
    final text = [
      for (final block in content)
        if (block is Map && block['type'] == 'text') block['text'] as String,
    ].join('\n\n');
    if (text.isEmpty) {
      throw const TutorException('El modelo no devolvió texto. Inténtalo de nuevo.');
    }
    final truncated = body['stop_reason'] == 'max_tokens';
    return ChatMessage(
      fromUser: false,
      text: truncated ? '$text\n\n_(Respuesta cortada por longitud.)_' : text,
      rawContent: content,
    );
  }
}
