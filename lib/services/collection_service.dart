import '../models/card_collection.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
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

  // Stream pour écouter les changements de collection
  Stream<Map<String, int>> get collectionStream => _collectionStreamController.stream;
  
  // Stream pour écouter les changements d'une carte spécifique
  Stream<String> get cardUpdateStream => _cardUpdateStreamController.stream;

  // Obtenir la collection
  CardCollection get collection => _collection;

  // Obtenir l'état de Firestore
  bool get isFirestoreAvailable => _isFirestoreAvailable;

  // Test de connexion Firestore simple
  Future<void> _testFirestoreConnection() async {
    try {
      debugPrint('🔍 Test de connexion Firestore simple...');
      
      // Test ultra basique - juste vérifier si l'instance existe
      FirebaseFirestore.instance;
      debugPrint('✅ Instance Firestore accessible');
      
      _isFirestoreAvailable = true;
      debugPrint('✅ Firestore marqué comme disponible');
      
    } catch (e) {
      debugPrint('❌ Test Firestore échoué: $e');
      _isFirestoreAvailable = false;
    }
  }

  // Charger la collection depuis Firestore
  Future<void> loadCollection() async {
    await _testFirestoreConnection();
    
    if (!_isFirestoreAvailable) {
      debugPrint('⚠️ Firestore non disponible - mode local uniquement');
      return;
    }

    try {
      final user = _auth.currentUser;
      if (user == null) {
        debugPrint('❌ Aucun utilisateur connecté');
        // Vider la collection locale si aucun utilisateur
        _clearLocalCollection();
        return;
      }

      debugPrint('📥 Chargement de la collection pour: ${user.email}');
      
      final userDoc = FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid);
      
      final docSnapshot = await userDoc.get();
      
      if (docSnapshot.exists) {
        final data = docSnapshot.data();
        if (data != null && data['cards'] != null) {
          final cardsData = Map<String, int>.from(data['cards']);
          debugPrint('✅ Collection trouvée: ${cardsData.length} cartes');
          
          // Charger les données dans la collection locale
          _clearLocalCollection();
          cardsData.forEach((cardName, quantity) {
            _collection.setCardQuantity(cardName, quantity);
          });
          _notifyCollectionChanged();
        }
      } else {
        debugPrint('📄 Nouveau utilisateur - collection vide');
        _notifyCollectionChanged();
      }
      
    } catch (e) {
      debugPrint('❌ Erreur lors du chargement: $e');
      _isFirestoreAvailable = false;
    }
  }

  // Sauvegarder la collection dans Firestore
  Future<void> _saveCollection() async {
    if (!_isFirestoreAvailable) {
      debugPrint('⚠️ Firestore non disponible - sauvegarde ignorée');
      return;
    }

    try {
      final user = _auth.currentUser;
      if (user == null) {
        debugPrint('⚠️ Aucun utilisateur connecté - sauvegarde ignorée');
        return;
      }

      debugPrint('💾 Sauvegarde de la collection...');
      
      final userDoc = FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid);
      
      await userDoc.set({
        'cards': _collection.collection,
        'lastUpdated': FieldValue.serverTimestamp(),
        'email': user.email,
        'displayName': user.displayName,
        'photoURL': user.photoURL,
        'lastSeen': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));
      
      debugPrint('✅ Collection sauvegardée avec ${_collection.collection.length} cartes');
      
    } catch (e) {
      debugPrint('❌ Erreur lors de la sauvegarde: $e');
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

  // Vider seulement la collection locale sans sauvegarder (pour la déconnexion)
  void clearLocalCollectionOnly() {
    debugPrint('🗑️ Vidage de la collection locale uniquement (déconnexion)');
    _clearLocalCollection();
  }

  // Ajouter une carte
  Future<void> addCard(String cardName) async {
    _collection.addCard(cardName);
    _notifyCardChanged(cardName);
    _notifyCollectionChanged();
    await _saveCollection();
  }

  // Retirer une carte
  Future<void> removeCard(String cardName) async {
    _collection.removeCard(cardName);
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

  // Obtenir la quantité d'une carte
  int getCardQuantity(String cardName) {
    return _collection.getCardQuantity(cardName);
  }

  // Stream pour une carte spécifique
  Stream<int> getCardQuantityStream(String cardName) {
    return Stream.multi((controller) {
      // Émettre la valeur actuelle immédiatement
      controller.add(getCardQuantity(cardName));
      
      // Écouter les mises à jour
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
}
