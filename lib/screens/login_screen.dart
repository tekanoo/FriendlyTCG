import 'package:flutter/material.dart';
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

  Future<void> _signInWithGoogle() async {
    if (_isLoading) return; // Éviter les clics multiples
    
    setState(() {
      _isLoading = true;
    });

    try {
      debugPrint('Début de la connexion Google...');
      final UserCredential? result = await _authService.signInWithGoogle();
      
      if (result != null && mounted) {
        // Connexion réussie, l'AuthWrapper gérera automatiquement la navigation
        debugPrint('Connexion réussie pour: ${result.user?.email}');
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Connexion réussie ! Bienvenue ${result.user?.displayName ?? result.user?.email}'),
            backgroundColor: Colors.green,
            duration: const Duration(seconds: 2),
          ),
        );
      } else if (mounted) {
        // L'utilisateur a annulé ou redirect en cours
        debugPrint('Connexion annulée ou redirect en cours');
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Redirection vers Google en cours...'),
            backgroundColor: Colors.blue,
            duration: Duration(seconds: 3),
          ),
        );
      }
    } catch (e) {
      debugPrint('Erreur de connexion: $e');
      if (mounted) {
        // Afficher un message d'erreur plus convivial
        String errorMessage = 'Erreur lors de la connexion';
        
        if (e.toString().contains('popup')) {
          errorMessage = 'Veuillez autoriser les popups pour vous connecter';
        } else if (e.toString().contains('réseau') || e.toString().contains('network')) {
          errorMessage = 'Vérifiez votre connexion internet';
        } else if (e.toString().contains('many-requests')) {
          errorMessage = 'Trop de tentatives. Réessayez dans quelques minutes';
        }
        
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(errorMessage),
            backgroundColor: Colors.red,
            duration: const Duration(seconds: 4),
            action: SnackBarAction(
              label: 'Réessayer',
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
                          Image.asset(
                            'assets/images/google_logo.png',
                            height: 24,
                            width: 24,
                            errorBuilder: (context, error, stackTrace) {
                              return const Icon(
                                Icons.login,
                                size: 24,
                                color: Colors.blue,
                              );
                            },
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
              
              const SizedBox(height: 40),
              
              // Informations supplémentaires
              const Text(
                'En vous connectant, vous acceptez nos conditions d\'utilisation et notre politique de confidentialité.',
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
