import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../services/auth_service.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final AuthService _authService = AuthService();
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _checkCurrentUser();
  }

  void _checkCurrentUser() {
    // Suppression de la navigation automatique - laissons l'AuthWrapper gérer
  }

  Future<void> _signInWithGoogle() async {
    if (_isLoading) return; // Ã‰viter les clics multiples
    
    setState(() {
      _isLoading = true;
    });

    try {
      final UserCredential? result = await _authService.signInWithGoogle();
      
      if (result != null && mounted) {
        // Connexion rÃ©ussie, l'AuthWrapper gÃ©rera automatiquement la navigation
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Connexion rÃ©ussie ! Bienvenue ${result.user?.displayName ?? result.user?.email}'),
            backgroundColor: Colors.green,
            duration: const Duration(seconds: 2),
          ),
        );
      } else if (mounted) {
        // L'utilisateur a annulÃ© ou redirect en cours
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Redirection vers Google en cours...'),
            backgroundColor: Colors.blue,
            duration: Duration(seconds: 3),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        // Afficher un message d'erreur plus convivial
        String errorMessage = 'Erreur lors de la connexion';
        
        if (e.toString().contains('popup')) {
          errorMessage = 'Veuillez autoriser les popups pour vous connecter';
        } else if (e.toString().contains('rÃ©seau') || e.toString().contains('network')) {
          errorMessage = 'VÃ©rifiez votre connexion internet';
        } else if (e.toString().contains('many-requests')) {
          errorMessage = 'Trop de tentatives. RÃ©essayez dans quelques minutes';
        }
        
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(errorMessage),
            backgroundColor: Colors.red,
            duration: const Duration(seconds: 4),
            action: SnackBarAction(
              label: 'RÃ©essayer',
              textColor: Colors.white,
              onPressed: () => _signInWithGoogle(),
            ),
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Logo ou titre de l'app
              const Icon(
                Icons.sports_esports,
                size: 80,
                color: Colors.blue,
              ),
              const SizedBox(height: 20),
              const Text(
                'Friendly TCG',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 32,
                  fontWeight: FontWeight.bold,
                  color: Colors.black87,
                ),
              ),
              const SizedBox(height: 10),
              const Text(
                'Connectez-vous pour continuer',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 16,
                  color: Colors.grey,
                ),
              ),
              const SizedBox(height: 60),
              
              // Bouton de connexion Google
              ElevatedButton(
                onPressed: _isLoading ? null : _signInWithGoogle,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.white,
                  foregroundColor: Colors.black87,
                  elevation: 2,
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                    side: const BorderSide(color: Colors.grey, width: 1),
                  ),
                ),
                child: _isLoading
                    ? const SizedBox(
                        height: 20,
                        width: 20,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Icon(
                            Icons.login,
                            size: 24,
                            color: Colors.blue,
                          ),
                          const SizedBox(width: 12),
                          const Text(
                            'Se connecter avec Google',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],
                      ),
              ),
              
              const SizedBox(height: 20),
              
              // Bouton de debug temporaire
              if (kDebugMode)
                ElevatedButton(
                  onPressed: () {
                    final user = _authService.currentUser;
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text('User: ${user?.email ?? 'null'} - SignedIn: ${_authService.isSignedIn}'),
                        duration: const Duration(seconds: 3),
                      ),
                    );
                    // La navigation sera gÃ©rÃ©e automatiquement par AuthWrapper
                  },
                  child: const Text('Debug: VÃ©rifier Ã©tat'),
                ),
              
              const SizedBox(height: 40),
              
              // Informations supplÃ©mentaires
              const Text(
                'En vous connectant, vous acceptez nos conditions d\'utilisation et notre politique de confidentialitÃ©.',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 12,
                  color: Colors.grey,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
