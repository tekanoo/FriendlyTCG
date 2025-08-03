import '../models/card_collection.dart';
import '../models/structured_collection.dart';
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

  // Obtenir la collection sous forme structurée
  StructuredCollection get structuredCollection => StructuredCollection.fromFlat(_collection.collection);

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
    final user = _auth.currentUser;
    debugPrint('🔄 loadCollection appelé pour utilisateur: ${user?.email ?? "non connecté"}');
    
    await _testFirestoreConnection();
    
    if (!_isFirestoreAvailable) {
      debugPrint('⚠️ Firestore non disponible - mode local uniquement');
      return;
    }

    try {
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
        if (data != null) {
          Map<String, int> cardsData = {};
          
          // Essayer d'abord de charger la nouvelle structure
          if (data['structuredCards'] != null) {
            debugPrint('📊 Chargement de la structure organisée');
            try {
              final structuredData = Map<String, dynamic>.from(data['structuredCards']);
              final structuredCollection = StructuredCollection.fromFirestore(structuredData);
              cardsData = structuredCollection.toFlat();
              debugPrint('✅ Structure organisée chargée: ${cardsData.length} cartes');
            } catch (e) {
              debugPrint('⚠️ Erreur lors du chargement de la structure organisée: $e');
              // Fallback vers l'ancien format
              if (data['cards'] != null) {
                cardsData = Map<String, int>.from(data['cards']);
                debugPrint('📄 Utilisation de l\'ancien format de sauvegarde');
              }
            }
          } else if (data['cards'] != null) {
            // Utiliser l'ancien format
            cardsData = Map<String, int>.from(data['cards']);
            debugPrint('📄 Chargement de l\'ancien format');
          }
          
          if (cardsData.isNotEmpty) {
            debugPrint('✅ Collection trouvée: ${cardsData.length} cartes');
            debugPrint('🔍 Aperçu des cartes: ${cardsData.entries.take(5).map((e) => "${e.key}: ${e.value}").join(", ")}...');
            
            // Charger les données dans la collection locale
            _clearLocalCollection();
            cardsData.forEach((cardName, quantity) {
              _collection.setCardQuantity(cardName, quantity);
            });
            _notifyCollectionChanged();
          } else {
            debugPrint('📄 Collection vide trouvée');
            _clearLocalCollection();
            _notifyCollectionChanged();
          }
        }
      } else {
        debugPrint('📄 Nouveau utilisateur - collection vide');
        _clearLocalCollection();
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
      
      // Convertir la collection plate en structure organisée
      final structuredCollection = StructuredCollection.fromFlat(_collection.collection);
      final structuredData = structuredCollection.toFirestore();
      
      // Sauvegarder à la fois l'ancien format (pour compatibilité) et le nouveau
      await userDoc.update({
        'cards': _collection.collection, // Format ancien pour compatibilité
        'structuredCards': structuredData, // Nouvelle structure organisée
        'lastUpdated': FieldValue.serverTimestamp(),
        'lastSeen': FieldValue.serverTimestamp(),
      });
      
      debugPrint('✅ Collection sauvegardée avec ${_collection.collection.length} cartes');
      debugPrint('🏗️ Structure organisée: ${structuredData.keys.join(", ")}');
      
    } catch (e) {
      debugPrint('❌ Erreur lors de la sauvegarde: $e');
      // Si update échoue (document n'existe pas), créer le document
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
        
        debugPrint('✅ Collection créée avec ${_collection.collection.length} cartes');
      } catch (e2) {
        debugPrint('❌ Erreur lors de la création du document: $e2');
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

  // Vider seulement la collection locale sans sauvegarder (pour la déconnexion)
  void clearLocalCollectionOnly() {
    debugPrint('🗑️ Vidage de la collection locale uniquement (déconnexion)');
    _clearLocalCollection();
  }

  // Ajouter une carte
  Future<void> addCard(String cardName) async {
    final oldQuantity = _collection.getCardQuantity(cardName);
    _collection.addCard(cardName);
    final newQuantity = _collection.getCardQuantity(cardName);
    
    debugPrint('➕ Ajout carte: $cardName ($oldQuantity → $newQuantity)');
    
    _notifyCardChanged(cardName);
    _notifyCollectionChanged();
    await _saveCollection();
  }

  // Retirer une carte
  Future<void> removeCard(String cardName) async {
    final oldQuantity = _collection.getCardQuantity(cardName);
    _collection.removeCard(cardName);
    final newQuantity = _collection.getCardQuantity(cardName);
    
    debugPrint('➖ Retrait carte: $cardName ($oldQuantity → $newQuantity)');
    
    _notifyCardChanged(cardName);
    _notifyCollectionChanged();
    await _saveCollection();
  }

  // Définir la quantité d'une carte
  Future<void> setCardQuantity(String cardName, int quantity) async {
    final oldQuantity = _collection.getCardQuantity(cardName);
    _collection.setCardQuantity(cardName, quantity);
    
    debugPrint('🔢 Quantité carte: $cardName ($oldQuantity → $quantity)');
    
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
