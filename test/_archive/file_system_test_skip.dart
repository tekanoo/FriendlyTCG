// ARCHIVÉ: Test exploratoire de l'arborescence et des chemins d'assets.
// Conservé pour référence mais ignoré par défaut (suffixe _skip.dart).
// Peut être supprimé si plus nécessaire.

import 'dart:io';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter/foundation.dart';

void main() {
  test('Exploration système de fichiers (archivé)', () {
    final paths = [
      'assets/logo/Gundam/gundam.png',
      '../assets/logo/Gundam/gundam.png',
      'i:\\Mon Drive\\friendlytcg_app\\friendly_tcg_app\\assets\\logo\\Gundam\\gundam.png',
      './assets/logo/Gundam/gundam.png',
    ];
    for (final path in paths) {
      final file = File(path);
      debugPrint('[ARCHIVE] Path: $path -> exists: ${file.existsSync()}');
    }
  });
}
