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
      debugPrint('=== AuthWrapper: Vérification du résultat de redirection ===');
      final result = await _authService.checkRedirectResult();
      if (result != null) {
        debugPrint('AuthWrapper: Utilisateur connecté via redirect: ${result.user?.email}');
      } else {
        debugPrint('AuthWrapper: Aucun résultat de redirection');
      }
    } catch (e) {
      debugPrint('AuthWrapper: Erreur lors de la vérification du redirect: $e');
    } finally {
      if (mounted) {
        setState(() {
          _isCheckingRedirect = false;
        });
        debugPrint('AuthWrapper: Fin de la vérification du redirect');
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    debugPrint('AuthWrapper: Build appelé, _isCheckingRedirect=$_isCheckingRedirect');
    
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
        debugPrint('AuthWrapper: StreamBuilder appelé');
        debugPrint('  - connectionState: ${snapshot.connectionState}');
        debugPrint('  - hasData: ${snapshot.hasData}');
        debugPrint('  - data: ${snapshot.data?.email ?? 'null'}');
        
        // En cours de chargement
        if (snapshot.connectionState == ConnectionState.waiting) {
          debugPrint('AuthWrapper: En attente de la connexion...');
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
          debugPrint('AuthWrapper: Utilisateur connecté détecté: ${snapshot.data?.email}');
          debugPrint('AuthWrapper: Navigation vers HomeScreen');
          
          // Navigation explicite vers /home pour éviter les problèmes de routing
          WidgetsBinding.instance.addPostFrameCallback((_) {
            if (mounted) {
              final currentRoute = ModalRoute.of(context)?.settings.name;
              debugPrint('AuthWrapper: Route actuelle: $currentRoute');
              
              if (currentRoute != '/home') {
                debugPrint('AuthWrapper: Redirection forcée vers /home');
                Navigator.of(context).pushNamedAndRemoveUntil(
                  '/home',
                  (route) => false,
                );
              }
            }
          });
          
          return const HomeScreen();
        }
        
        // Utilisateur non connecté
        debugPrint('AuthWrapper: Aucun utilisateur connecté, affichage de l\'écran de connexion');
        return const LoginScreen();
      },
    );
  }
}
