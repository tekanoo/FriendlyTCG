import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'collection_service.dart';
import 'analytics_service.dart';

class AuthService {
  final FirebaseAuth _firebaseAuth = FirebaseAuth.instance;

  // Obtenir l'utilisateur actuel
  User? get currentUser => _firebaseAuth.currentUser;

  // Stream pour écouter les changements d'état d'authentification
  Stream<User?> get authStateChanges {
    return _firebaseAuth.authStateChanges();
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
          final result = await _firebaseAuth.signInWithPopup(googleProvider);
          
          // Analytics : connexion réussie
          if (result.user != null) {
            final analyticsService = AnalyticsService();
            await analyticsService.logLogin(method: 'google');
            await analyticsService.setUserProperties(
              userId: result.user!.uid,
              email: result.user!.email,
            );
          }
          
          return result;
        } catch (popupError) {
          // Fallback vers redirect si popup échoue
          await _firebaseAuth.signInWithRedirect(googleProvider);
          return null; // Le redirect gérera la suite
        }
      } else {
        // Pour mobile (non utilisé dans ce projet)
        return await _firebaseAuth.signInWithPopup(googleProvider);
      }
    } on FirebaseAuthException catch (e) {
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
      throw Exception('Erreur lors de la connexion. Réessayez plus tard.');
    }
  }

  // Vérifier s'il y a un résultat de redirection en attente
  Future<UserCredential?> checkRedirectResult() async {
    try {
      final result = await _firebaseAuth.getRedirectResult();
      if (result.user != null) {
        // Analytics : connexion via redirect réussie
        final analyticsService = AnalyticsService();
        await analyticsService.logLogin(method: 'google_redirect');
        await analyticsService.setUserProperties(
          userId: result.user!.uid,
          email: result.user!.email,
        );
        
        return result;
      }
      return null;
    } catch (e) {
      return null;
    }
  }

  // Déconnexion simplifiée
  Future<void> signOut() async {
    try {
      // Analytics : déconnexion
      final analyticsService = AnalyticsService();
      await analyticsService.logLogout();
      
      // Vider seulement la collection locale sans sauvegarder
      final collectionService = CollectionService();
      collectionService.clearLocalCollectionOnly();
      
      await _firebaseAuth.signOut();
    } catch (e) {
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
