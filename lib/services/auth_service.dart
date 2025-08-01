import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:flutter/foundation.dart';

class AuthService {
  final FirebaseAuth _firebaseAuth = FirebaseAuth.instance;
  final GoogleSignIn _googleSignIn = GoogleSignIn();

  // Obtenir l'utilisateur actuel
  User? get currentUser => _firebaseAuth.currentUser;

  // Stream pour écouter les changements d'état d'authentification
  Stream<User?> get authStateChanges => _firebaseAuth.authStateChanges();

  // Connexion avec Google
  Future<UserCredential?> signInWithGoogle() async {
    try {
      // Déclencher le processus d'authentification
      final GoogleSignInAccount? googleUser = await _googleSignIn.signIn();
      
      if (googleUser == null) {
        // L'utilisateur a annulé la connexion
        return null;
      }

      // Obtenir les détails d'authentification de la demande
      final GoogleSignInAuthentication googleAuth = 
          await googleUser.authentication;

      // Créer un credential pour Firebase
      final credential = GoogleAuthProvider.credential(
        accessToken: googleAuth.accessToken,
        idToken: googleAuth.idToken,
      );

      // Se connecter à Firebase avec le credential
      return await _firebaseAuth.signInWithCredential(credential);
    } on FirebaseAuthException catch (e) {
      // Utiliser un logger en production au lieu de print
      debugPrint('Erreur d\'authentification Firebase: ${e.message}');
      rethrow;
    } catch (e) {
      debugPrint('Erreur lors de la connexion Google: $e');
      rethrow;
    }
  }

  // Déconnexion
  Future<void> signOut() async {
    try {
      await Future.wait([
        _firebaseAuth.signOut(),
        _googleSignIn.signOut(),
      ]);
    } catch (e) {
      debugPrint('Erreur lors de la déconnexion: $e');
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
