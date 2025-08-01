import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../services/auth_service.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final AuthService _authService = AuthService();

  Future<void> _signOut() async {
    try {
      await _authService.signOut();
      if (mounted) {
        Navigator.of(context).pushReplacementNamed('/login');
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Erreur lors de la déconnexion: ${e.toString()}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final User? user = _authService.currentUser;
    
    return Scaffold(
      appBar: AppBar(
        title: const Text('Friendly TCG'),
        backgroundColor: Colors.blue,
        foregroundColor: Colors.white,
        actions: [
          PopupMenuButton<String>(
            onSelected: (value) {
              if (value == 'logout') {
                _signOut();
              }
            },
            itemBuilder: (BuildContext context) => [
              const PopupMenuItem<String>(
                value: 'logout',
                child: Row(
                  children: [
                    Icon(Icons.logout),
                    SizedBox(width: 8),
                    Text('Se déconnecter'),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Informations utilisateur
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Informations du profil',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 16),
                    if (user?.photoURL != null)
                      Row(
                        children: [
                          CircleAvatar(
                            backgroundImage: NetworkImage(user!.photoURL!),
                            radius: 30,
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  user.displayName ?? 'Nom non disponible',
                                  style: const TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                                Text(
                                  user.email ?? 'Email non disponible',
                                  style: const TextStyle(
                                    fontSize: 14,
                                    color: Colors.grey,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      )
                    else
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Nom: ${user?.displayName ?? 'Non disponible'}',
                            style: const TextStyle(fontSize: 16),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            'Email: ${user?.email ?? 'Non disponible'}',
                            style: const TextStyle(fontSize: 16),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            'UID: ${user?.uid ?? 'Non disponible'}',
                            style: const TextStyle(
                              fontSize: 12,
                              color: Colors.grey,
                            ),
                          ),
                        ],
                      ),
                  ],
                ),
              ),
            ),
            
            const SizedBox(height: 24),
            
            // Contenu principal de l'application
            const Text(
              'Bienvenue dans Friendly TCG !',
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
              ),
            ),
            
            const SizedBox(height: 16),
            
            const Text(
              'Vous êtes maintenant connecté. Ici, vous pourrez gérer vos cartes TCG, participer à des tournois et bien plus encore.',
              style: TextStyle(fontSize: 16),
            ),
            
            const SizedBox(height: 24),
            
            // Boutons d'action (à personnaliser selon vos besoins)
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                ElevatedButton.icon(
                  onPressed: () {
                    // TODO: Naviguer vers la collection de cartes
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Fonctionnalité à venir !')),
                    );
                  },
                  icon: const Icon(Icons.collections),
                  label: const Text('Ma Collection'),
                ),
                ElevatedButton.icon(
                  onPressed: () {
                    // TODO: Naviguer vers les tournois
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Fonctionnalité à venir !')),
                    );
                  },
                  icon: const Icon(Icons.emoji_events),
                  label: const Text('Tournois'),
                ),
                ElevatedButton.icon(
                  onPressed: () {
                    // TODO: Naviguer vers les échanges
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Fonctionnalité à venir !')),
                    );
                  },
                  icon: const Icon(Icons.swap_horiz),
                  label: const Text('Échanges'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
