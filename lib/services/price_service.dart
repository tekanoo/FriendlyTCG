import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import '../models/card_price.dart';

class PriceService {
  static final PriceService _instance = PriceService._internal();
  factory PriceService() => _instance;
  PriceService._internal();

  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final Map<String, CardPrice> _priceCache = {};

  // Obtenir le prix d'une carte
  Future<CardPrice?> getCardPrice(String cardId) async {
    try {
      // Vérifier le cache d'abord
      if (_priceCache.containsKey(cardId)) {
        final cachedPrice = _priceCache[cardId]!;
        // Si le prix a moins de 24h, utiliser le cache
        if (DateTime.now().difference(cachedPrice.lastUpdated).inHours < 24) {
          return cachedPrice;
        }
      }

      debugPrint('🔍 Recherche du prix pour: $cardId');
      
      // Chercher dans Firestore
      final priceDoc = await _firestore
          .collection('cardPrices')
          .doc(cardId)
          .get();

      if (priceDoc.exists) {
        final price = CardPrice.fromJson(priceDoc.data()!);
        _priceCache[cardId] = price;
        debugPrint('💰 Prix trouvé: ${price.formattedAvgPrice}');
        return price;
      }

      debugPrint('❌ Aucun prix trouvé pour: $cardId');
      return null;
      
    } catch (e) {
      debugPrint('❌ Erreur lors de la récupération du prix: $e');
      return null;
    }
  }

  // Obtenir les prix de plusieurs cartes
  Future<Map<String, CardPrice>> getMultipleCardPrices(List<String> cardIds) async {
    final Map<String, CardPrice> prices = {};
    
    for (String cardId in cardIds) {
      final price = await getCardPrice(cardId);
      if (price != null) {
        prices[cardId] = price;
      }
    }
    
    return prices;
  }

  // Sauvegarder un prix de carte (pour les admins)
  Future<void> saveCardPrice(CardPrice price) async {
    try {
      await _firestore
          .collection('cardPrices')
          .doc(price.cardId)
          .set(price.toJson());
      
      _priceCache[price.cardId] = price;
      debugPrint('💾 Prix sauvegardé pour: ${price.cardName}');
      
    } catch (e) {
      debugPrint('❌ Erreur lors de la sauvegarde du prix: $e');
    }
  }

  // Simuler des prix pour les cartes NewType Risings (données d'exemple)
  Future<void> initializeSamplePrices() async {
    final samplePrices = [
      CardPrice(
        cardId: 'GD01-001.png',
        cardName: 'RX-78-2 Gundam',
        avgPrice: 15.50,
        minPrice: 12.00,
        maxPrice: 20.00,
        lastUpdated: DateTime.now(),
        source: 'Sample Data',
      ),
      CardPrice(
        cardId: 'GD01-002.png',
        cardName: 'Zaku II',
        avgPrice: 8.75,
        minPrice: 6.50,
        maxPrice: 12.00,
        lastUpdated: DateTime.now(),
        source: 'Sample Data',
      ),
      CardPrice(
        cardId: 'GD01-003.png',
        cardName: 'Barbatos',
        avgPrice: 22.00,
        minPrice: 18.00,
        maxPrice: 28.00,
        lastUpdated: DateTime.now(),
        source: 'Sample Data',
      ),
    ];

    for (CardPrice price in samplePrices) {
      final doc = await _firestore
          .collection('cardPrices')
          .doc(price.cardId)
          .get();
      
      if (!doc.exists) {
        await saveCardPrice(price);
      }
    }
  }

  // Calculer la valeur totale d'une collection
  Future<double> calculateCollectionValue(Map<String, int> collection) async {
    double totalValue = 0.0;
    
    for (MapEntry<String, int> entry in collection.entries) {
      final price = await getCardPrice(entry.key);
      if (price?.avgPrice != null) {
        totalValue += price!.avgPrice! * entry.value;
      }
    }
    
    return totalValue;
  }

  // Vider le cache
  void clearCache() {
    _priceCache.clear();
  }
}
