import 'lib/services/auto_game_service.dart';

void main() {
  print('=== Test des jeux et extensions ===');
  
  // Test des jeux
  final games = AutoGameService.getAllGames();
  print('\nJeux trouvés: ${games.length}');
  for (final game in games) {
    print('- ${game.name}: ${game.imagePath}');
  }
  
  // Test des extensions
  final extensions = AutoGameService.getAllExtensions();
  print('\nExtensions trouvées: ${extensions.length}');
  for (final extension in extensions) {
    print('- ${extension.name}: ${extension.imagePath}');
  }
}
