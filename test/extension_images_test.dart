// Script de vérification des images d'extension

import 'package:flutter/foundation.dart';
import 'package:friendly_tcg_app/services/auto_game_service.dart';
import 'package:friendly_tcg_app/services/generated_cards_list.dart';

void main() {
  debugPrint('=== Vérification des images d\'extension ===');
  
  final extensions = AutoGameService.getAllExtensions();
  
  for (final extension in extensions) {
    debugPrint('\nExtension: ${extension.name} (${extension.id})');
    debugPrint('Chemin image: ${extension.imagePath}');
    
    final cards = GeneratedCardsList.getCardsByExtensionId(extension.id);
    if (cards.isNotEmpty) {
      debugPrint('Première carte: ${cards.first}');
      debugPrint('Chemin première carte: ${GeneratedCardsList.getCardPath(extension.id, cards.first)}');
    } else {
      debugPrint('ERREUR: Aucune carte trouvée pour cette extension');
    }
  }
  
  debugPrint('\n=== Fin de vérification ===');
}

