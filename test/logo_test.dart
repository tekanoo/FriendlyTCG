import 'package:flutter_test/flutter_test.dart';
import 'package:flutter/foundation.dart';
import 'package:friendly_tcg_app/services/auto_game_service.dart';

void main() {
  group('Logo Tests', () {
    test('should return correct logo path for Gundam Cards', () {
      final games = AutoGameService.getAllGames();
      final gundamGame = games.firstWhere((game) => game.name == 'Gundam Cards');
      
      expect(gundamGame.imagePath, equals('assets/logo/Gundam/gundam.png'));
    });

    test('should return correct logo path for Pokemon', () {
      final games = AutoGameService.getAllGames();
      final pokemonGame = games.firstWhere((game) => game.name == 'Pokémon');
      
      expect(pokemonGame.imagePath, equals('assets/logo/Pokémon/Pokemon-Logo.png'));
    });

    test('should have valid image paths for all games', () {
      final games = AutoGameService.getAllGames();
      
      for (final game in games) {
        expect(game.imagePath, isNotEmpty);
        expect(game.imagePath, startsWith('assets/'));
  debugPrint('${game.name}: ${game.imagePath}');
      }
    });
  });
}
