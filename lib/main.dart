import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_web_plugins/url_strategy.dart';
import 'firebase_options.dart';
import 'widgets/auth_wrapper.dart';
import 'screens/user_profile_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  // Configurer l'URL strategy pour supprimer les hash (#) sur le web
  if (kIsWeb) {
    usePathUrlStrategy();
  }
  
  try {
    await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    );
    
    debugPrint('✅ Firebase initialisé avec succès');
    
    runApp(const MyApp());
  } catch (e) {
    debugPrint('❌ Erreur lors de l\'initialisation de Firebase: $e');
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
      home: const AuthWrapper(),
      routes: {
        '/profile': (context) => const UserProfileScreen(),
      },
      debugShowCheckedModeBanner: false,
    );
  }
}
