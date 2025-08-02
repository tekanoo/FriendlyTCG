import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'firebase_options.dart';
import 'widgets/auth_wrapper.dart';
import 'screens/login_screen.dart';
import 'screens/home_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  try {
    await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    );
    
    debugPrint('✅ Firebase initialisé avec succès');
    
    // Initialisation Firestore séparée pour le web
    if (kIsWeb) {
      try {
        // Configuration spécifique pour le web avec la base par défaut
        FirebaseFirestore.instance.settings = const Settings(
          persistenceEnabled: false,
          cacheSizeBytes: Settings.CACHE_SIZE_UNLIMITED,
        );
        
        // Test de connexion initial
        await FirebaseFirestore.instance.disableNetwork();
        await FirebaseFirestore.instance.enableNetwork();
        
        debugPrint('🔗 Firestore configuré pour le web avec base par défaut');
      } catch (firestoreError) {
        debugPrint('⚠️ Erreur configuration Firestore: $firestoreError');
        // Continue même si Firestore échoue
      }
    }
    
    runApp(const MyApp());
  } catch (e) {
    debugPrint('❌ Erreur lors de l\'initialisation de Firebase: $e');
    // Essayons de continuer sans Firestore
    runApp(const MyApp());
  }
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Friendly TCG',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.blue),
        useMaterial3: true,
      ),
      initialRoute: '/',
      routes: {
        '/': (context) => const AuthWrapper(),
        '/login': (context) => const LoginScreen(),
        '/home': (context) => const HomeScreen(),
      },
      debugShowCheckedModeBanner: false,
    );
  }
}
