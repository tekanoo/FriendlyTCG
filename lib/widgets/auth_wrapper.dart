import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../services/auth_service.dart';
import '../screens/login_screen.dart';
import '../screens/home_screen.dart';

class AuthWrapper extends StatefulWidget {
  const AuthWrapper({super.key});

  @override
  State<AuthWrapper> createState() => _AuthWrapperState();
}

class _AuthWrapperState extends State<AuthWrapper> {
  final AuthService _authService = AuthService();
  bool _isCheckingRedirect = true;

  @override
  void initState() {
    super.initState();
    _checkRedirectResult();
  }

  Future<void> _checkRedirectResult() async {
    try {
      await _authService.checkRedirectResult();
    } catch (e) {
      debugPrint('Erreur lors de la vérification du redirect: $e');
    } finally {
      if (mounted) {
        setState(() {
          _isCheckingRedirect = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isCheckingRedirect) {
      return const Scaffold(
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              CircularProgressIndicator(),
              SizedBox(height: 16),
              Text('Vérification de la connexion...'),
            ],
          ),
        ),
      );
    }

    return StreamBuilder<User?>(
      stream: _authService.authStateChanges,
      builder: (context, snapshot) {
        // En cours de chargement
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Scaffold(
            body: Center(
              child: CircularProgressIndicator(),
            ),
          );
        }
        
        // Utilisateur connecté
        if (snapshot.hasData && snapshot.data != null) {
          debugPrint('Utilisateur connecté détecté: ${snapshot.data?.email}');
          return const HomeScreen();
        }
        
        // Utilisateur non connecté
        debugPrint('Aucun utilisateur connecté, affichage de l\'écran de connexion');
        return const LoginScreen();
      },
    );
  }
}
