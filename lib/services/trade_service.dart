import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import '../models/user_model.dart';

class TradeService {
  static final TradeService _instance = TradeService._internal();
  factory TradeService() => _instance;
  TradeService._internal();

  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // Mettre à jour les informations de l'utilisateur connecté
  Future<void> updateCurrentUserInfo() async {
    try {
      final user = _auth.currentUser;
      if (user == null) return;

      await _firestore.collection('users').doc(user.uid).set({
        'email': user.email,
        'displayName': user.displayName,
        'photoURL': user.photoURL,
        'lastSeen': Timestamp.now(),
      }, SetOptions(merge: true));

      debugPrint('✅ Informations utilisateur mises à jour');
    } catch (e) {
      debugPrint('❌ Erreur mise à jour utilisateur: $e');
    }
  }

  // Rechercher les utilisateurs qui possèdent des cartes spécifiques
  Future<Map<String, List<UserModel>>> findUsersWithCards(List<String> cardNames) async {
    try {
      final Map<String, List<UserModel>> result = {};
      
      // Initialiser le résultat
      for (String cardName in cardNames) {
        result[cardName] = [];
      }

      // Récupérer tous les utilisateurs (sauf l'utilisateur connecté)
      final currentUser = _auth.currentUser;
      if (currentUser == null) return result;

      final usersSnapshot = await _firestore.collection('users').get();
      
      for (var doc in usersSnapshot.docs) {
        // Ignorer l'utilisateur connecté
        if (doc.id == currentUser.uid) continue;
        
        try {
          final userData = doc.data();
          final user = UserModel.fromFirestore(userData, doc.id);
          
          // Vérifier quelles cartes cet utilisateur possède
          for (String cardName in cardNames) {
            if (user.hasCard(cardName)) {
              result[cardName]!.add(user);
            }
          }
        } catch (e) {
          debugPrint('❌ Erreur lors du traitement de l\'utilisateur ${doc.id}: $e');
        }
      }

      debugPrint('✅ Recherche terminée pour ${cardNames.length} cartes');
      return result;
    } catch (e) {
      debugPrint('❌ Erreur lors de la recherche d\'utilisateurs: $e');
      return {};
    }
  }

  // Obtenir tous les utilisateurs actifs
  Future<List<UserModel>> getAllUsers() async {
    try {
      final currentUser = _auth.currentUser;
      if (currentUser == null) return [];

      final usersSnapshot = await _firestore
          .collection('users')
          .orderBy('lastSeen', descending: true)
          .get();
      
      List<UserModel> users = [];
      
      for (var doc in usersSnapshot.docs) {
        // Ignorer l'utilisateur connecté
        if (doc.id == currentUser.uid) continue;
        
        try {
          final userData = doc.data();
          final user = UserModel.fromFirestore(userData, doc.id);
          users.add(user);
        } catch (e) {
          debugPrint('❌ Erreur lors du traitement de l\'utilisateur ${doc.id}: $e');
        }
      }

      debugPrint('✅ ${users.length} utilisateurs récupérés');
      return users;
    } catch (e) {
      debugPrint('❌ Erreur lors de la récupération des utilisateurs: $e');
      return [];
    }
  }

  // Rechercher des cartes dans les collections des autres utilisateurs
  Future<List<UserModel>> searchUsersWithCard(String cardName) async {
    try {
      final currentUser = _auth.currentUser;
      if (currentUser == null) return [];

      final usersSnapshot = await _firestore
          .collection('users')
          .where('cards.$cardName', isGreaterThan: 0)
          .get();
      
      List<UserModel> users = [];
      
      for (var doc in usersSnapshot.docs) {
        // Ignorer l'utilisateur connecté
        if (doc.id == currentUser.uid) continue;
        
        try {
          final userData = doc.data();
          final user = UserModel.fromFirestore(userData, doc.id);
          users.add(user);
        } catch (e) {
          debugPrint('❌ Erreur lors du traitement de l\'utilisateur ${doc.id}: $e');
        }
      }

      debugPrint('✅ ${users.length} utilisateurs trouvés avec la carte $cardName');
      return users;
    } catch (e) {
      debugPrint('❌ Erreur lors de la recherche de carte: $e');
      return [];
    }
  }
}
