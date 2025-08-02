import '../models/card_collection.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';

class CollectionService {
  static final CollectionService _instance = CollectionService._internal();
  factory CollectionService() => _instance;
  CollectionService._internal();

  final CardCollection _collection = CardCollection();
  FirebaseFirestore? _firestore;
  final FirebaseAuth _auth = FirebaseAuth.instance;
  bool _isFirestoreAvailable = false;
  bool _isInitialized = false;

  // Obtenir la collection
  CardCollection get collection => _collection;

  // Obtenir l'état de Firestore
  bool get isFirestoreAvailable => _isFirestoreAvailable;

  // Initialisation paresseuse de Firestore
  Future<void> _initializeFirestore() async {
    if (_isInitialized) return;
    
    try {
      debugPrint('🚀 Initialisation de Firestore...');
      
      if (kIsWeb) {
        // Configuration web avec paramètres optimisés
        _firestore = FirebaseFirestore.instance;
        
        debugPrint('🔧 Configuration des paramètres Firestore...');
        _firestore!.settings = const Settings(
          persistenceEnabled: false,
        );
        
        debugPrint('✅ Firestore configuré avec succès');
        _isFirestoreAvailable = true;
      } else {
        _firestore = FirebaseFirestore.instance;
        _isFirestoreAvailable = true;
      }
      
      _isInitialized = true;
    } catch (e) {
      debugPrint('❌ Erreur lors de l\'initialisation Firestore: $e');
      _isFirestoreAvailable = false;
      _isInitialized = true; // Marquer comme initialisé même en cas d'échec
    }
  }

  // Obtenir la référence du document utilisateur
  DocumentReference? get _userDocRef {
    final user = _auth.currentUser;
    if (user == null || _firestore == null) return null;
    return _firestore!.collection('users').doc(user.uid);
  }

  // Vider la collection locale
  void _clearLocalCollection() {
    final cardNames = _collection.collection.keys.toList();
    for (String cardName in cardNames) {
      _collection.setCardQuantity(cardName, 0);
    }
  }

  // Tester la connexion Firestore avec mode offline
  Future<bool> _testFirestoreConnection() async {
    await _initializeFirestore();
    
    if (_firestore == null) {
      debugPrint('❌ Firestore non initialisé');
      return false;
    }
    
    try {
      debugPrint('🔍 Test de connexion Firestore avec mode offline...');
      
      // Pour le web, essayons le mode offline d'abord
      if (kIsWeb) {
        try {
          debugPrint('🌐 Configuration Web - Mode offline');
          
          // Désactiver le réseau pour forcer le mode offline
          await _firestore!.disableNetwork();
          debugPrint('📴 Réseau désactivé');
          
          // Test d'écriture en mode offline
          final testDoc = _firestore!.collection('test').doc('offline-test');
          await testDoc.set({'test': 'offline', 'timestamp': DateTime.now().millisecondsSinceEpoch});
          debugPrint('✅ Écriture offline réussie');
          
          // Essayer de réactiver le réseau
          await _firestore!.enableNetwork();
          debugPrint('🔗 Réseau réactivé');
          
          // Attendre la synchronisation
          await Future.delayed(const Duration(milliseconds: 3000));
          debugPrint('⏱️ Délai de synchronisation terminé');
          
        } catch (e) {
          debugPrint('⚠️ Erreur mode offline/online: $e');
          // Si le mode offline/online échoue, on essaie sans
        }
      }
      
      // Test simple de lecture pour vérifier la connexion
      debugPrint('� Test de lecture simple...');
      final testQuery = _firestore!.collection('test').limit(1);
      await testQuery.get();
      debugPrint('✅ Lecture réussie');
      
      debugPrint('✅ Connexion Firestore réussie (mode hybride)');
      _isFirestoreAvailable = true;
      return true;
    } catch (e) {
      debugPrint('❌ Test de connexion Firestore échoué: $e');
      debugPrint('� Type d\'erreur: ${e.runtimeType}');
      
      // Dernière tentative : mode local uniquement
      debugPrint('🔄 Tentative mode local uniquement...');
      try {
        await _firestore!.disableNetwork();
        _isFirestoreAvailable = true; // On marque comme disponible en mode local
        debugPrint('✅ Mode local activé');
        return true;
      } catch (localError) {
        debugPrint('❌ Échec du mode local: $localError');
        _isFirestoreAvailable = false;
        return false;
      }
    }
  }

  // Charger la collection depuis Firestore
  Future<void> loadCollection() async {
    try {
      print('=== DEBUG: Début du chargement de la collection ===');
      
      // Test de connexion d'abord
      final isConnected = await _testFirestoreConnection();
      if (!isConnected) {
        print('DEBUG: Firestore non disponible, utilisation du mode local uniquement');
        return;
      }
      
      final userDoc = _userDocRef;
      if (userDoc == null) {
        print('DEBUG: Aucun utilisateur connecté, impossible de charger');
        return;
      }

      print('DEBUG: Chargement depuis: ${userDoc.path}');
      
      // Attendre un peu pour que Firestore soit prêt
      await Future.delayed(const Duration(milliseconds: 500));
      
      final docSnapshot = await userDoc.get();
      print('DEBUG: Document exists: ${docSnapshot.exists}');
      
      if (docSnapshot.exists) {
        final data = docSnapshot.data() as Map<String, dynamic>?;
        print('DEBUG: Données reçues: $data');
        
        if (data != null && data['collection'] != null) {
          final collectionData = Map<String, int>.from(data['collection']);
          print('DEBUG: Collection trouvée: $collectionData');
          
          // Vider la collection actuelle et charger les nouvelles données
          _clearLocalCollection();
          collectionData.forEach((cardName, quantity) {
            _collection.setCardQuantity(cardName, quantity);
          });
          print('DEBUG: Collection chargée avec succès');
        } else {
          print('DEBUG: Aucune collection trouvée dans le document');
        }
      } else {
        print('DEBUG: Document utilisateur n\'existe pas encore');
      }
    } catch (e) {
      print('ERREUR Firestore: $e');
      if (e.toString().contains('Unable to establish connection')) {
        _isFirestoreAvailable = false;
        print('⚠️ Firestore n\'est pas activé ou accessible. Utilisation en mode local uniquement.');
      }
    }
  }

  // Sauvegarder la collection dans Firestore
  Future<void> _saveCollection() async {
    try {
      print('=== DEBUG: Début de la sauvegarde ===');
      final userDoc = _userDocRef;
      if (userDoc == null) {
        print('DEBUG: Aucun utilisateur connecté, impossible de sauvegarder');
        return;
      }

      final collectionToSave = _collection.collection;
      print('DEBUG: Sauvegarde vers: ${userDoc.path}');
      print('DEBUG: Données à sauvegarder: $collectionToSave');

      await userDoc.set({
        'collection': collectionToSave,
        'lastUpdated': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));
      
      print('✅ DEBUG: Sauvegarde réussie');
    } catch (e) {
      print('ERREUR Sauvegarde: $e');
      if (e.toString().contains('Unable to establish connection')) {
        _isFirestoreAvailable = false;
        print('⚠️ Firestore n\'est pas activé. Les données sont conservées localement mais ne persistent pas entre les sessions.');
        print('💡 Activez Firestore dans la console Firebase pour la persistance.');
      }
    }
  }

  // Ajouter une carte
  Future<void> addCard(String cardName, [int quantity = 1]) async {
    _collection.addCard(cardName, quantity);
    await _saveCollection();
  }

  // Retirer une carte
  Future<void> removeCard(String cardName, [int quantity = 1]) async {
    _collection.removeCard(cardName, quantity);
    await _saveCollection();
  }

  // Définir une quantité
  Future<void> setCardQuantity(String cardName, int quantity) async {
    _collection.setCardQuantity(cardName, quantity);
    await _saveCollection();
  }

  // Obtenir la quantité d'une carte
  int getCardQuantity(String cardName) {
    return _collection.getCardQuantity(cardName);
  }

  // Réinitialiser la collection (pour la déconnexion)
  void clearCollection() {
    _clearLocalCollection();
  }
}
