import 'lib/services/auto_game_service.dart';

void main() {
  print('=== Test du tri alphabétique des cartes ===');
  
  // Test pour chaque extension
  final extensions = AutoGameService.getAllExtensions();
  for (final extension in extensions) {
    print('\n📦 Extension: ${extension.name}');
    final cards = AutoGameService.getCardsForExtension(extension.id);
    print('Première carte: ${cards.first}');
    print('Dernière carte: ${cards.last}');
    print('Total: ${cards.length} cartes');
    
    // Vérifier si c'est bien trié
    bool isOrderedCorrectly = true;
    for (int i = 0; i < cards.length - 1; i++) {
      if (cards[i].toLowerCase().compareTo(cards[i + 1].toLowerCase()) > 0) {
        isOrderedCorrectly = false;
        break;
      }
    }
    print('Tri alphabétique: ${isOrderedCorrectly ? "✅ Correct" : "❌ Incorrect"}');
  }
}
