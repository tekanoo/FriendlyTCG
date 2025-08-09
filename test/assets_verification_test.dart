import 'dart:io';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter/foundation.dart';
import 'package:friendly_tcg_app/services/auto_game_service.dart';

void main() {
  group('Assets Verification Tests', () {
    test('all game logo files should exist', () {
      final games = AutoGameService.getAllGames();
      
      for (final game in games) {
        final imagePath = game.imagePath;
  debugPrint('Checking: ${game.name} -> $imagePath');
        
        if (imagePath.startsWith('assets/')) {
          // Construire le chemin depuis la racine du projet
          final filePath = '../$imagePath';
          final file = File(filePath);
          
          expect(file.existsSync(), isTrue, 
            reason: 'Logo file not found: $imagePath for game ${game.name}');
        }
      }
    });

    test('check specific logo files existence', () {
      // Test direct des fichiers depuis la racine
      final gundamLogo = File('../assets/logo/Gundam/gundam.png');
      final gundamLogoWebp = File('../assets/logo/Gundam/gundam.webp');
      final pokemonLogo = File('../assets/logo/Pokémon/Pokemon-Logo.png');
      
  debugPrint('Gundam PNG exists: ${gundamLogo.existsSync()}');
  debugPrint('Gundam WebP exists: ${gundamLogoWebp.existsSync()}');
  debugPrint('Pokemon PNG exists: ${pokemonLogo.existsSync()}');
      
      // Au moins un format doit exister pour Gundam
      expect(gundamLogo.existsSync() || gundamLogoWebp.existsSync(), isTrue,
        reason: 'Neither gundam.png nor gundam.webp found');
        
      expect(pokemonLogo.existsSync(), isTrue,
        reason: 'Pokemon-Logo.png not found');
    });
    
    test('verify game name consistency', () {
      final games = AutoGameService.getAllGames();
      
      // Vérifier que les noms de jeux sont cohérents
      final gameNames = games.map((g) => g.name).toList();
  debugPrint('Game names: $gameNames');
      
      expect(gameNames, contains('Gundam Cards'));
      expect(gameNames, contains('Pokémon'));
    });
  });
}
