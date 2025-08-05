// Script de vérification des images d'extension

import '../lib/services/auto_game_service.dart';
import '../lib/services/generated_cards_list.dart';

void main() {
  print('=== Vérification des images d\'extension ===');
  
  final extensions = AutoGameService.getAllExtensions();
  
  for (final extension in extensions) {
    print('\nExtension: ${extension.name} (${extension.id})');
    print('Chemin image: ${extension.imagePath}');
    
    final cards = GeneratedCardsList.getCardsByExtensionId(extension.id);
    if (cards.isNotEmpty) {
      print('Première carte: ${cards.first}');
      print('Chemin première carte: ${GeneratedCardsList.getCardPath(extension.id, cards.first)}');
    } else {
      print('ERREUR: Aucune carte trouvée pour cette extension');
    }
  }
  
  print('\n=== Fin de vérification ===');
}
