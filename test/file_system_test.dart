import 'dart:io';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter/foundation.dart';

void main() {
  test('File system exploration', () {
    // Tester différents chemins possibles
    final paths = [
      'assets/logo/Gundam/gundam.png',
      '../assets/logo/Gundam/gundam.png',
      'i:\\Mon Drive\\friendlytcg_app\\friendly_tcg_app\\assets\\logo\\Gundam\\gundam.png',
      './assets/logo/Gundam/gundam.png',
    ];
    
    for (final path in paths) {
      final file = File(path);
      debugPrint('Path: $path -> exists: ${file.existsSync()}');
    }
    
    // Lister le répertoire courant
    final currentDir = Directory.current;
  debugPrint('Current directory: ${currentDir.path}');
    
    // Lister le contenu
    try {
      final entities = currentDir.listSync();
      debugPrint('Current directory contents:');
      for (final entity in entities) {
        debugPrint('  ${entity.path}');
      }
    } catch (e) {
      debugPrint('Error listing directory: $e');
    }
  });
}
