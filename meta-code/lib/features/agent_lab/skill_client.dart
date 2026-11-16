import 'dart:convert';

import 'package:http/http.dart' as http;

import 'skill_models.dart';

/// Comprueba que una skill externa responde. Para MCP usa el transporte
/// "Streamable HTTP": initialize -> notifications/initialized -> tools/list.
class SkillClient {
  SkillClient({http.Client? httpClient}) : _http = httpClient ?? http.Client();

  final http.Client _http;
  static const _timeout = Duration(seconds: 15);

  Future<SkillCheck> check(Skill skill) async {
    final Uri uri;
    try {
      uri = Uri.parse(skill.url.trim());
      if (!uri.isScheme('http') && !uri.isScheme('https')) throw const FormatException();
    } on FormatException {
      return const SkillCheck(ok: false, summary: 'La URL no es válida.');
    }
    try {
      return skill.kind == SkillKind.mcp ? await _checkMcp(skill, uri) : await _checkRest(skill, uri);
    } on Exception catch (e) {
      return SkillCheck(ok: false, summary: 'No se pudo conectar: $e');
    }
  }

  Map<String, String> _auth(Skill skill) => {
    if (skill.token.trim().isNotEmpty) 'authorization': 'Bearer ${skill.token.trim()}',
  };

  Future<SkillCheck> _checkRest(Skill skill, Uri uri) async {
    final response = await _http.get(uri, headers: _auth(skill)).timeout(_timeout);
    final ok = response.statusCode >= 200 && response.statusCode < 300;
    return SkillCheck(
      ok: ok,
      summary: ok
          ? 'Responde correctamente (HTTP ${response.statusCode}).'
          : 'Respondió con HTTP ${response.statusCode}.',
    );
  }

  Future<SkillCheck> _checkMcp(Skill skill, Uri uri) async {
    final headers = {
      'content-type': 'application/json',
      'accept': 'application/json, text/event-stream',
      ..._auth(skill),
    };

    final init = await _http
        .post(
          uri,
          headers: headers,
          body: jsonEncode({
            'jsonrpc': '2.0',
            'id': 1,
            'method': 'initialize',
            'params': {
              'protocolVersion': '2025-06-18',
              'capabilities': <String, dynamic>{},
              'clientInfo': {'name': 'meta-code', 'version': '1.0.0'},
            },
          }),
        )
        .timeout(_timeout);
    if (init.statusCode != 200) {
      return SkillCheck(ok: false, summary: 'El servidor respondió con HTTP ${init.statusCode}.');
    }
    final initResult = parseRpcResponse(utf8.decode(init.bodyBytes), 1);
    if (initResult == null) {
      return const SkillCheck(ok: false, summary: 'La respuesta no es JSON-RPC de MCP.');
    }
    if (initResult['error'] != null) {
      return SkillCheck(ok: false, summary: 'Error del servidor: ${initResult['error']['message']}');
    }

    final sessionId = init.headers['mcp-session-id'];
    final sessionHeaders = {...headers, 'mcp-session-id': ?sessionId};
    await _http
        .post(
          uri,
          headers: sessionHeaders,
          body: jsonEncode({'jsonrpc': '2.0', 'method': 'notifications/initialized'}),
        )
        .timeout(_timeout);

    final list = await _http
        .post(
          uri,
          headers: sessionHeaders,
          body: jsonEncode({'jsonrpc': '2.0', 'id': 2, 'method': 'tools/list'}),
        )
        .timeout(_timeout);
    final listResult = parseRpcResponse(utf8.decode(list.bodyBytes), 2);
    final tools = [
      for (final t in (listResult?['result']?['tools'] as List?) ?? const [])
        (t as Map)['name'] as String,
    ];
    final serverName = initResult['result']?['serverInfo']?['name'] ?? 'Servidor MCP';
    return SkillCheck(
      ok: true,
      summary: '$serverName conectado. Herramientas disponibles: ${tools.length}.',
      tools: tools,
    );
  }
}

/// Un servidor MCP puede contestar con JSON directo o con un flujo SSE
/// (líneas `data: {...}`). Devuelve el mensaje JSON-RPC con el [id] pedido.
Map<String, dynamic>? parseRpcResponse(String body, int id) {
  final candidates = <String>[
    body,
    for (final line in const LineSplitter().convert(body))
      if (line.startsWith('data:')) line.substring(5),
  ];
  for (final candidate in candidates) {
    try {
      final decoded = jsonDecode(candidate.trim());
      if (decoded is Map<String, dynamic> && decoded['id'] == id) return decoded;
    } on FormatException {
      continue;
    }
  }
  return null;
}
