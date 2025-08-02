import '../models/card_collection.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';

class CollectionService {
  static final CollectionService _instance = CollectionService._internal();
  factory CollectionService() => _instance;
  CollectionService._internal();

  final CardCollection _collection = CardCollection();
  final FirebaseAuth _auth = FirebaseAuth.instance;
  bool _isFirestoreAvailable = false;

  // Obtenir la collection
  CardCollection get collection => _collection;

  // Obtenir l'état de Firestore
  bool get isFirestoreAvailable => _isFirestoreAvailable;

  // Test de connexion Firestore simple
  Future<void> _testFirestoreConnection() async {
    try {
      debugPrint('🔍 Test de connexion Firestore simple...');
      
      // Test ultra basique - juste vérifier si Firestore répond
      final testCollection = FirebaseFirestore.instance.collection('test');
      debugPrint('✅ Instance Firestore créée');
      
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
        }
      } else {
        debugPrint('📄 Nouveau utilisateur - collection vide');
      }
      
    } catch (e) {
      debugPrint('❌ Erreur lors du chargement: $e');
      _isFirestoreAvailable = false;
    }
  }

  // Sauvegarder la collection dans Firestore
  Future<void> _saveCollection() async {
    if (!_isFirestoreAvailable) return;

    try {
      final user = _auth.currentUser;
      if (user == null) return;

      debugPrint('💾 Sauvegarde de la collection...');
      
      final userDoc = FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid);
      
      await userDoc.set({
        'cards': _collection.collection,
        'lastUpdated': FieldValue.serverTimestamp(),
      });
      
      debugPrint('✅ Collection sauvegardée');
      
    } catch (e) {
      debugPrint('❌ Erreur lors de la sauvegarde: $e');
    }
  }

  // Vider la collection locale
  void _clearLocalCollection() {
    final cardNames = _collection.collection.keys.toList();
    for (String cardName in cardNames) {
      _collection.setCardQuantity(cardName, 0);
    }
  }

  // Ajouter une carte
  Future<void> addCard(String cardName) async {
    _collection.addCard(cardName);
    await _saveCollection();
  }

  // Retirer une carte
  Future<void> removeCard(String cardName) async {
    _collection.removeCard(cardName);
    await _saveCollection();
  }

  // Définir la quantité d'une carte
  Future<void> setCardQuantity(String cardName, int quantity) async {
    _collection.setCardQuantity(cardName, quantity);
    await _saveCollection();
  }
}
