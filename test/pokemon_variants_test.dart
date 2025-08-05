// Test script pour vérifier le système de variantes Pokemon

import 'package:flutter/foundation.dart';
import 'package:friendly_tcg_app/services/collection_service.dart';

void main() async {
  final service = CollectionService();
  
  // Test des cartes Pokemon
  const String pokemonCard = 'SV8pt5_FR_1.png';
  
  debugPrint('=== Test du système de variantes Pokemon ===');
  debugPrint('Carte de test: $pokemonCard');
  
  // Ajouter une carte normale
  await service.addCardWithVariant(pokemonCard, 'normal');
  debugPrint('Ajout en normal - Variantes: ${service.getCardVariants(pokemonCard)}');
  
  // Ajouter une carte reverse
  await service.addCardWithVariant(pokemonCard, 'reverse');
  debugPrint('Ajout en reverse - Variantes: ${service.getCardVariants(pokemonCard)}');
  
  // Ajouter une deuxième carte normale
  await service.addCardWithVariant(pokemonCard, 'normal');
  debugPrint('Ajout second normal - Variantes: ${service.getCardVariants(pokemonCard)}');
  
  // Tester la quantité totale
  debugPrint('Quantité totale: ${service.getTotalCardQuantity(pokemonCard)}');
  
  // Retirer une carte normale
  await service.removeCard(pokemonCard);
  debugPrint('Retrait normal - Variantes: ${service.getCardVariants(pokemonCard)}');
  
  // Retirer une carte reverse
  await service.removeCard('${pokemonCard}_reverse');
  debugPrint('Retrait reverse - Variantes: ${service.getCardVariants(pokemonCard)}');
  
  // Retirer la dernière carte normale
  await service.removeCard(pokemonCard);
  debugPrint('Retrait dernier normal - Variantes: ${service.getCardVariants(pokemonCard)}');
  
  debugPrint('=== Test terminé ===');
}
