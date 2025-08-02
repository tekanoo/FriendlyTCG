import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import 'collection_service.dart';

class AuthService {
  final FirebaseAuth _firebaseAuth = FirebaseAuth.instance;

  // Obtenir l'utilisateur actuel
  User? get currentUser => _firebaseAuth.currentUser;

  // Stream pour écouter les changements d'état d'authentification
  Stream<User?> get authStateChanges {
    return _firebaseAuth.authStateChanges().map((User? user) {
      debugPrint('=== AuthService: Changement d\'état d\'authentification ===');
      if (user != null) {
        debugPrint('AuthService: Utilisateur connecté: ${user.email}');
        debugPrint('AuthService: UID: ${user.uid}');
      } else {
        debugPrint('AuthService: Aucun utilisateur connecté');
      }
      return user;
    });
  }

  // Connexion avec Google - Version simplifiée pour le web
  Future<UserCredential?> signInWithGoogle() async {
    try {
      // Créer un provider Google
      GoogleAuthProvider googleProvider = GoogleAuthProvider();
      
      // Configurer les scopes
      googleProvider.addScope('email');
      googleProvider.addScope('profile');
      
      // Configurer des paramètres personnalisés pour éviter les erreurs
      googleProvider.setCustomParameters({
        'prompt': 'select_account',
        'hd': null, // Permettre tous les domaines
      });

      // Se connecter avec Firebase Auth
      if (kIsWeb) {
        // Pour le web, utiliser signInWithPopup avec gestion d'erreurs améliorée
        try {
          debugPrint('Tentative de connexion avec popup...');
          final result = await _firebaseAuth.signInWithPopup(googleProvider);
          debugPrint('Connexion popup réussie: ${result.user?.email}');
          return result;
        } catch (popupError) {
          debugPrint('Erreur popup: $popupError');
          // Fallback vers redirect si popup échoue
          debugPrint('Fallback vers redirect...');
          await _firebaseAuth.signInWithRedirect(googleProvider);
          return null; // Le redirect gérera la suite
        }
      } else {
        // Pour mobile (non utilisé dans ce projet)
        return await _firebaseAuth.signInWithPopup(googleProvider);
      }
    } on FirebaseAuthException catch (e) {
      debugPrint('Erreur Firebase Auth: ${e.code} - ${e.message}');
      
      // Gestion des erreurs spécifiques
      switch (e.code) {
        case 'popup-blocked':
          throw Exception('Popup bloqué par le navigateur. Veuillez autoriser les popups.');
        case 'popup-closed-by-user':
          return null; // L'utilisateur a fermé la popup
        case 'network-request-failed':
          throw Exception('Erreur réseau. Vérifiez votre connexion.');
        case 'too-many-requests':
          throw Exception('Trop de tentatives. Réessayez plus tard.');
        default:
          throw Exception('Erreur d\'authentification: ${e.message}');
      }
    } catch (e) {
      debugPrint('Erreur générale: $e');
      throw Exception('Erreur lors de la connexion. Réessayez plus tard.');
    }
  }

  // Vérifier s'il y a un résultat de redirection en attente
  Future<UserCredential?> checkRedirectResult() async {
    try {
      debugPrint('=== AuthService: Vérification du résultat de redirection ===');
      final result = await _firebaseAuth.getRedirectResult();
      if (result.user != null) {
        debugPrint('AuthService: Utilisateur connecté via redirect: ${result.user?.email}');
        debugPrint('AuthService: User UID: ${result.user?.uid}');
        debugPrint('AuthService: User displayName: ${result.user?.displayName}');
        return result;
      } else {
        debugPrint('AuthService: Aucun résultat de redirection (result.user est null)');
      }
      return null;
    } catch (e) {
      debugPrint('AuthService: Erreur lors de la vérification du redirect: $e');
      return null;
    }
  }

  // Supprimer toutes les données utilisateur
  Future<void> deleteUserData() async {
    try {
      final user = currentUser;
      if (user == null) {
        throw Exception('Aucun utilisateur connecté');
      }

      final firestore = FirebaseFirestore.instance;
      final userId = user.uid;

      debugPrint('=== Début de la suppression des données pour l\'utilisateur $userId ===');

      // 1. Supprimer les échanges où l'utilisateur est participant
      debugPrint('Suppression des échanges...');
      final tradesQuery1 = await firestore
          .collection('trades')
          .where('fromUserId', isEqualTo: userId)
          .get();
      
      final tradesQuery2 = await firestore
          .collection('trades')
          .where('toUserId', isEqualTo: userId)
          .get();

      final allTrades = [...tradesQuery1.docs, ...tradesQuery2.docs];
      
      // Supprimer les messages de ces échanges
      for (var tradeDoc in allTrades) {
        debugPrint('Suppression des messages pour l\'échange ${tradeDoc.id}');
        final messagesQuery = await firestore
            .collection('trade_messages')
            .where('tradeId', isEqualTo: tradeDoc.id)
            .get();
        
        for (var messageDoc in messagesQuery.docs) {
          await messageDoc.reference.delete();
        }
        
        // Supprimer l'échange
        await tradeDoc.reference.delete();
      }

      // 2. Supprimer le document utilisateur dans Firestore
      debugPrint('Suppression du profil utilisateur...');
      await firestore.collection('users').doc(userId).delete();

      // 3. Vider la collection locale
      debugPrint('Suppression de la collection locale...');
      final collectionService = CollectionService();
      collectionService.clearLocalCollectionOnly();

      // 4. Supprimer le compte Firebase Auth
      debugPrint('Suppression du compte Firebase Auth...');
      await user.delete();

      debugPrint('✅ Toutes les données utilisateur ont été supprimées avec succès');
    } on FirebaseAuthException catch (e) {
      debugPrint('❌ Erreur Firebase Auth lors de la suppression: ${e.code} - ${e.message}');
      
      if (e.code == 'requires-recent-login') {
        throw Exception('Veuillez vous reconnecter récemment pour supprimer votre compte');
      } else {
        throw Exception('Erreur lors de la suppression du compte: ${e.message}');
      }
    } catch (e) {
      debugPrint('❌ Erreur lors de la suppression des données: $e');
      rethrow;
    }
  }

  // Déconnexion simplifiée
  Future<void> signOut() async {
    try {
      // Vider seulement la collection locale sans sauvegarder
      final collectionService = CollectionService();
      collectionService.clearLocalCollectionOnly();
      
      await _firebaseAuth.signOut();
    } catch (e) {
      debugPrint('Erreur déconnexion: $e');
      rethrow;
    }
  }

  // Vérifier si l'utilisateur est connecté
  bool get isSignedIn => currentUser != null;

  // Obtenir les informations de l'utilisateur
  Map<String, String?> get userInfo {
    final user = currentUser;
    if (user != null) {
      return {
        'uid': user.uid,
        'email': user.email,
        'displayName': user.displayName,
        'photoURL': user.photoURL,
      };
    }
    return {};
  }
}
