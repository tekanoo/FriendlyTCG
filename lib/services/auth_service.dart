import 'package:firebase_auth/firebase_auth.dart';
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
      debugPrint('🔗 URL actuelle: ${Uri.base}');
      debugPrint('🔗 Host: ${Uri.base.host}');
      debugPrint('🔗 Port: ${Uri.base.port}');
      debugPrint('🔗 Scheme: ${Uri.base.scheme}');
      
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
          debugPrint('Type d\'erreur: ${popupError.runtimeType}');
          
          // Log spécifique pour redirect_uri_mismatch
          if (popupError.toString().contains('redirect_uri_mismatch')) {
            debugPrint('❌ ERREUR REDIRECT_URI_MISMATCH détectée!');
            debugPrint('🔧 Vérifiez la configuration OAuth dans Google Cloud Console');
            debugPrint('📍 URL actuelle à autoriser: ${Uri.base.scheme}://${Uri.base.host}${Uri.base.port != 80 && Uri.base.port != 443 ? ':${Uri.base.port}' : ''}/__/auth/handler');
          }
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
