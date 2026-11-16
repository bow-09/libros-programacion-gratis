import 'dart:convert';

import 'package:flutter/services.dart' show rootBundle;
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'library_models.dart';

final catalogProvider = FutureProvider<Catalog>((ref) async {
  final raw = await rootBundle.loadString('assets/data/libros_catalogo.json');
  return Catalog.fromJson(jsonDecode(raw) as Map<String, dynamic>);
});
