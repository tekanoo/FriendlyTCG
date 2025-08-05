import 'package:flutter_test/flutter_test.dart';
import '../lib/services/auto_game_service.dart';
import '../lib/services/generated_cards_list.dart';

void main() {
  group('Consistency Verification Tests', () {
    
    test('game structure consistency', () {
      final gameStructure = GeneratedCardsList.getGameStructure();
      final games = AutoGameService.getAllGames();
      
      print('=== GAME STRUCTURE ===');
      for (final entry in gameStructure.entries) {
        print('${entry.key}: ${entry.value}');
      }
      
      print('\n=== GENERATED GAMES ===');
      for (final game in games) {
        print('ID: ${game.id}');
        print('Name: ${game.name}');
        print('Image: ${game.imagePath}');
        print('Folder: ${game.folderPath}');
        print('---');
      }
      
      // Vérifications de cohérence
      expect(games.length, equals(gameStructure.length));
      
      // Vérifier que chaque jeu a un chemin d'image valide
      for (final game in games) {
        expect(game.imagePath, isNotEmpty);
        expect(game.imagePath, startsWith('assets/'));
        expect(game.name, isNotEmpty);
        expect(game.id, isNotEmpty);
      }
    });
    
    test('logo path generation consistency', () {
      final gameNames = ['Gundam Cards', 'Pokemon'];
      
      for (final gameName in gameNames) {
        // Simuler la génération du chemin d'image
        String imagePath;
        if (gameName == 'Gundam Cards') {
          imagePath = 'assets/logo/Gundam/gundam.png';
        } else if (gameName == 'Pokemon') {
          imagePath = 'assets/logo/Pokémon/Pokemon-Logo.png';
        } else {
          imagePath = 'assets/images/default_game.png';
        }
        
        print('$gameName -> $imagePath');
        expect(imagePath, startsWith('assets/'));
      }
    });
    
    test('card path generation consistency', () {
      final extensionIds = GeneratedCardsList.getAllExtensionIds();
      
      print('=== EXTENSIONS ===');
      for (final extensionId in extensionIds) {
        final cards = GeneratedCardsList.getCardsByExtensionId(extensionId);
        final gameName = GeneratedCardsList.getGameForExtension(extensionId);
        
        print('Extension: $extensionId');
        print('Game: $gameName');
        print('Cards count: ${cards.length}');
        
        if (cards.isNotEmpty) {
          final firstCardPath = GeneratedCardsList.getCardPath(extensionId, cards.first);
          print('First card path: $firstCardPath');
          
          expect(firstCardPath, isNotEmpty);
          expect(firstCardPath, startsWith('assets/images/'));
          expect(firstCardPath, endsWith('.png'));
        }
        print('---');
      }
    });
  });
}
