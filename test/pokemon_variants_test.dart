// Test script pour vérifier le système de variantes Pokemon

import '../lib/services/collection_service.dart';

void main() async {
  final service = CollectionService();
  
  // Test des cartes Pokemon
  const String pokemonCard = 'SV8pt5_FR_1.png';
  
  print('=== Test du système de variantes Pokemon ===');
  print('Carte de test: $pokemonCard');
  
  // Ajouter une carte normale
  await service.addCardWithVariant(pokemonCard, 'normal');
  print('Ajout en normal - Variantes: ${service.getCardVariants(pokemonCard)}');
  
  // Ajouter une carte reverse
  await service.addCardWithVariant(pokemonCard, 'reverse');
  print('Ajout en reverse - Variantes: ${service.getCardVariants(pokemonCard)}');
  
  // Ajouter une deuxième carte normale
  await service.addCardWithVariant(pokemonCard, 'normal');
  print('Ajout second normal - Variantes: ${service.getCardVariants(pokemonCard)}');
  
  // Tester la quantité totale
  print('Quantité totale: ${service.getTotalCardQuantity(pokemonCard)}');
  
  // Retirer une carte normale
  await service.removeCard(pokemonCard);
  print('Retrait normal - Variantes: ${service.getCardVariants(pokemonCard)}');
  
  // Retirer une carte reverse
  await service.removeCard('${pokemonCard}_reverse');
  print('Retrait reverse - Variantes: ${service.getCardVariants(pokemonCard)}');
  
  // Retirer la dernière carte normale
  await service.removeCard(pokemonCard);
  print('Retrait dernier normal - Variantes: ${service.getCardVariants(pokemonCard)}');
  
  print('=== Test terminé ===');
}
