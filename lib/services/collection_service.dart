import '../models/card_collection.dart';
import '../models/structured_collection.dart';
import 'analytics_service.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'dart:async';

class CollectionService {
  static final CollectionService _instance = CollectionService._internal();
  factory CollectionService() => _instance;
  CollectionService._internal();

  final CardCollection _collection = CardCollection();
  final FirebaseAuth _auth = FirebaseAuth.instance;
  bool _isFirestoreAvailable = false;

  // StreamController pour notifier les changements
  final StreamController<Map<String, int>> _collectionStreamController = 
      StreamController<Map<String, int>>.broadcast();
  
  final StreamController<String> _cardUpdateStreamController = 
      StreamController<String>.broadcast();

  // Stream pour Ã©couter les changements de collection
  Stream<Map<String, int>> get collectionStream => _collectionStreamController.stream;
  
  // Stream pour Ã©couter les changements d'une carte spÃ©cifique
  Stream<String> get cardUpdateStream => _cardUpdateStreamController.stream;

  // Obtenir la collection
  CardCollection get collection => _collection;

  // Obtenir la collection sous forme structurÃ©e
  StructuredCollection get structuredCollection => StructuredCollection.fromFlat(_collection.collection);

  // Obtenir l'Ã©tat de Firestore
  bool get isFirestoreAvailable => _isFirestoreAvailable;

  // Test de connexion Firestore simple
  Future<void> _testFirestoreConnection() async {
    try {
      // Test ultra basique - juste vÃ©rifier si l'instance existe
      FirebaseFirestore.instance;
      _isFirestoreAvailable = true;
    } catch (e) {
      _isFirestoreAvailable = false;
    }
  }

  // Charger la collection depuis Firestore
  Future<void> loadCollection() async {
    final user = _auth.currentUser;
    
    await _testFirestoreConnection();
    
    if (!_isFirestoreAvailable) {
      return;
    }

    try {
      if (user == null) {
        // Vider la collection locale si aucun utilisateur
        _clearLocalCollection();
        return;
      }

      
      final userDoc = FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid);
      
      final docSnapshot = await userDoc.get();
      
      if (docSnapshot.exists) {
        final data = docSnapshot.data();
        if (data != null) {
          Map<String, int> cardsData = {};
          
          // Essayer d'abord de charger la nouvelle structure
          if (data['structuredCards'] != null) {
            try {
              final structuredData = Map<String, dynamic>.from(data['structuredCards']);
              final structuredCollection = StructuredCollection.fromFirestore(structuredData);
              cardsData = structuredCollection.toFlat();
            } catch (e) {
              // Fallback vers l'ancien format
              if (data['cards'] != null) {
                cardsData = Map<String, int>.from(data['cards']);
              }
            }
          } else if (data['cards'] != null) {
            // Utiliser l'ancien format
            cardsData = Map<String, int>.from(data['cards']);
          }
          
          if (cardsData.isNotEmpty) {
            
            // Charger les donnÃ©es dans la collection locale
            _clearLocalCollection();
            cardsData.forEach((cardName, quantity) {
              _collection.setCardQuantity(cardName, quantity);
            });
            _notifyCollectionChanged();
          } else {
            _clearLocalCollection();
            _notifyCollectionChanged();
          }
        }
      } else {
        _clearLocalCollection();
        _notifyCollectionChanged();
      }
      
    } catch (e) {
      _isFirestoreAvailable = false;
    }
  }

  // Sauvegarder la collection dans Firestore
  Future<void> _saveCollection() async {
    if (!_isFirestoreAvailable) {
      return;
    }

    try {
      final user = _auth.currentUser;
      if (user == null) {
        return;
      }

      
      final userDoc = FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid);
      
      // Convertir la collection plate en structure organisÃ©e
      final structuredCollection = StructuredCollection.fromFlat(_collection.collection);
      final structuredData = structuredCollection.toFirestore();
      
      // Sauvegarder Ã  la fois l'ancien format (pour compatibilitÃ©) et le nouveau
      await userDoc.update({
        'cards': _collection.collection, // Format ancien pour compatibilitÃ©
        'structuredCards': structuredData, // Nouvelle structure organisÃ©e
        'lastUpdated': FieldValue.serverTimestamp(),
        'lastSeen': FieldValue.serverTimestamp(),
      });
      
      
    } catch (e) {
      // Si update Ã©choue (document n'existe pas), crÃ©er le document
      try {
        final user = _auth.currentUser;
        if (user == null) return;
        
        final userDoc = FirebaseFirestore.instance
            .collection('users')
            .doc(user.uid);
        
        final structuredCollection = StructuredCollection.fromFlat(_collection.collection);
        final structuredData = structuredCollection.toFirestore();
        
        await userDoc.set({
          'cards': _collection.collection,
          'structuredCards': structuredData,
          'lastUpdated': FieldValue.serverTimestamp(),
          'email': user.email,
          'displayName': user.displayName,
          'photoURL': user.photoURL,
          'lastSeen': FieldValue.serverTimestamp(),
        });
        
      } catch (e2) {
        // Ignore les erreurs de mise à jour des métadonnées utilisateur
        // Ces erreurs ne sont pas critiques pour la fonctionnalité principale
      }
    }
  }

  // Notifier les changements
  void _notifyCollectionChanged() {
    _collectionStreamController.add(Map<String, int>.from(_collection.collection));
  }
  
  void _notifyCardChanged(String cardName) {
    _cardUpdateStreamController.add(cardName);
  }

  // Vider la collection locale
  void _clearLocalCollection() {
    final cardNames = _collection.collection.keys.toList();
    for (String cardName in cardNames) {
      _collection.setCardQuantity(cardName, 0);
    }
    _notifyCollectionChanged();
  }

  // Vider seulement la collection locale sans sauvegarder (pour la dÃ©connexion)
  void clearLocalCollectionOnly() {
    _clearLocalCollection();
  }

  // Ajouter une carte
  Future<void> addCard(String cardName) async {
    _collection.addCard(cardName);
    
    // Analytics : ajout de carte
    final gameInfo = _determineGameAndExtension(cardName);
    if (gameInfo != null) {
      final analyticsService = AnalyticsService();
      await analyticsService.logAddCard(
        cardName: cardName,
        gameId: gameInfo['gameId']!,
        extensionId: gameInfo['extensionId']!,
      );
    }
    
    _notifyCardChanged(cardName);
    _notifyCollectionChanged();
    await _saveCollection();
  }

  // Ajouter une carte avec variante (pour Pokémon)
  Future<void> addCardWithVariant(String cardName, String variant) async {
    final cardKey = variant == 'normal' ? cardName : '${cardName}_$variant';
    await addCard(cardKey);
  }

  // Obtenir toutes les variantes d'une carte
  Map<String, int> getCardVariants(String baseName) {
    final variants = <String, int>{};
    
    // Variante normale
    variants['normal'] = getCardQuantity(baseName);
    
    // Variante reverse pour Pokémon
    if (_isPokemonCard(baseName)) {
      variants['reverse'] = getCardQuantity('${baseName}_reverse');
    }
    
    return variants;
  }

  // Vérifier si c'est une carte Pokémon
  bool _isPokemonCard(String cardName) {
    return cardName.startsWith('SV') || cardName.contains('_FR_');
  }

  // Retirer une carte
  Future<void> removeCard(String cardName) async {
    _collection.removeCard(cardName);
    
    // Analytics : suppression de carte
    final gameInfo = _determineGameAndExtension(cardName);
    if (gameInfo != null) {
      final analyticsService = AnalyticsService();
      await analyticsService.logRemoveCard(
        cardName: cardName,
        gameId: gameInfo['gameId']!,
        extensionId: gameInfo['extensionId']!,
      );
    }
    
    _notifyCardChanged(cardName);
    _notifyCollectionChanged();
    await _saveCollection();
  }

  // Définir la quantité d'une carte
  Future<void> setCardQuantity(String cardName, int quantity) async {
    _collection.setCardQuantity(cardName, quantity);
    
    _notifyCardChanged(cardName);
    _notifyCollectionChanged();
    await _saveCollection();
  }

  // Obtenir la quantitÃ© d'une carte
  int getCardQuantity(String cardName) {
    return _collection.getCardQuantity(cardName);
  }

  // Stream pour une carte spÃ©cifique
  Stream<int> getCardQuantityStream(String cardName) {
    return Stream.multi((controller) {
      // Ã‰mettre la valeur actuelle immÃ©diatement
      controller.add(getCardQuantity(cardName));
      
      // Ã‰couter les mises Ã  jour
      final subscription = cardUpdateStream
          .where((updatedCardName) => updatedCardName == cardName)
          .listen((updatedCardName) {
        controller.add(getCardQuantity(cardName));
      });
      
      controller.onCancel = () {
        subscription.cancel();
      };
    });
  }

  // Vider toute la collection
  Future<void> clearCollection() async {
    _clearLocalCollection();
    await _saveCollection();
  }

  // Nettoyer les ressources
  void dispose() {
    _collectionStreamController.close();
    _cardUpdateStreamController.close();
  }
  
  // MÃ©thode helper pour dÃ©terminer le jeu et l'extension d'une carte
  Map<String, String>? _determineGameAndExtension(String cardName) {
    // Cartes Gundam
    if (cardName.startsWith('GD01-') || cardName.startsWith('GD02-') || 
        cardName.startsWith('GD03-') || cardName.startsWith('GD04-') ||
        cardName.startsWith('GD05-') || cardName.startsWith('GD06-') ||
        cardName.startsWith('GD07-') || cardName.startsWith('GD08-') ||
        cardName.startsWith('GD09-') || cardName.startsWith('GD10-') ||
        cardName.startsWith('GD') || cardName.contains('gundam')) {
      return {
        'gameId': 'gundam_card_game',
        'extensionId': 'newtype_risings',
      };
    }
    
    // Cartes PokÃ©mon
    if (cardName.startsWith('SV8pt5') || cardName.startsWith('sv8pt5') ||
        cardName.contains('prismatic') || cardName.contains('evolutions')) {
      return {
        'gameId': 'pokemon_tcg',
        'extensionId': 'prismatic-evolutions',
      };
    }
    
    // Autres patterns pour PokÃ©mon
    if (cardName.toLowerCase().contains('pokemon') || 
        cardName.toLowerCase().contains('poke') ||
        cardName.startsWith('SV') || cardName.startsWith('sv')) {
      return {
        'gameId': 'pokemon_tcg',
        'extensionId': 'prismatic-evolutions',
      };
    }
    
    // DÃ©faut : Gundam
    return {
      'gameId': 'gundam_card_game',
      'extensionId': 'newtype_risings',
    };
  }
}
