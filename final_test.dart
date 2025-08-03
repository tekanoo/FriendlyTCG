import 'lib/services/auto_game_service.dart';

void main() {
  print('=== Test final du tri intelligent ===');
  
  final extensions = AutoGameService.getAllExtensions();
  
  for (final extension in extensions) {
    print('\n📦 ${extension.name}:');
    final cards = AutoGameService.getCardsForExtension(extension.id);
    
    // Montrer les 5 premières et 5 dernières pour vérifier l'ordre
    print('Premières 5: ${cards.take(5).join(", ")}');
    print('Dernières 5: ${cards.skip(cards.length - 5).join(", ")}');
  }
}
