import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../services/auth_service.dart';
import '../screens/login_screen.dart';
import '../screens/home_screen.dart';
import '../screens/onboarding_screen.dart';

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
      final result = await _authService.checkRedirectResult();
      if (result?.user != null) {
        // Utilisateur connecté via redirect
      } else {
        // Aucun résultat de redirection
      }
    } catch (e) {
      // Erreur lors de la vérification du redirect
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
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  CircularProgressIndicator(),
                  SizedBox(height: 16),
                  Text('Chargement...'),
                ],
              ),
            ),
          );
        }
        
        // Utilisateur connecté
        if (snapshot.hasData && snapshot.data != null) {
          final user = snapshot.data!;
          
          // Vérifier si l'onboarding est nécessaire
          final needsOnboarding = user.displayName == null || 
                                  user.displayName!.isEmpty || 
                                  user.displayName == user.email?.split('@').first;
          
          if (needsOnboarding) {
            return const OnboardingScreen();
          }
          
          return const HomeScreen();
        }
        
        // Utilisateur non connecté
        return const LoginScreen();
      },
    );
  }
}
