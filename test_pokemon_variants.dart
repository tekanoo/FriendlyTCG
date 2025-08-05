import 'lib/services/collection_service.dart';

/// Script de test pour vérifier le système de variantes Pokemon
void main() async {
  print('🧪 Test du système de variantes Pokemon');
  
  final collectionService = CollectionService();
  const testCard = 'SV4_5_FR_001';
  
  print('\n📋 État initial:');
  print('Quantité normale: ${collectionService.getCardQuantity(testCard)}');
  print('Quantité reverse: ${collectionService.getCardQuantity('${testCard}_reverse')}');
  print('Quantité totale: ${collectionService.getTotalCardQuantity(testCard)}');
  
  print('\n➕ Ajout d\'une carte normale...');
  await collectionService.addCardWithVariant(testCard, 'normal');
  
  print('Quantité normale: ${collectionService.getCardQuantity(testCard)}');
  print('Quantité reverse: ${collectionService.getCardQuantity('${testCard}_reverse')}');
  print('Quantité totale: ${collectionService.getTotalCardQuantity(testCard)}');
  
  print('\n➕ Ajout d\'une carte reverse...');
  await collectionService.addCardWithVariant(testCard, 'reverse');
  
  print('Quantité normale: ${collectionService.getCardQuantity(testCard)}');
  print('Quantité reverse: ${collectionService.getCardQuantity('${testCard}_reverse')}');
  print('Quantité totale: ${collectionService.getTotalCardQuantity(testCard)}');
  
  print('\n➕ Ajout d\'une autre carte normale...');
  await collectionService.addCardWithVariant(testCard, 'normal');
  
  print('Quantité normale: ${collectionService.getCardQuantity(testCard)}');
  print('Quantité reverse: ${collectionService.getCardQuantity('${testCard}_reverse')}');
  print('Quantité totale: ${collectionService.getTotalCardQuantity(testCard)}');
  
  print('\n✅ Test terminé !');
  print('   Si vous voyez "Quantité totale: 3", le système fonctionne correctement.');
}
