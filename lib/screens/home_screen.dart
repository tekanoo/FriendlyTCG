import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../services/auth_service.dart';
import 'extensions_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> with SingleTickerProviderStateMixin {
  final AuthService _authService = AuthService();
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

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
        bottom: TabBar(
          controller: _tabController,
          labelColor: Colors.white,
          unselectedLabelColor: Colors.white70,
          indicatorColor: Colors.white,
          tabs: const [
            Tab(
              icon: Icon(Icons.home),
              text: 'Accueil',
            ),
            Tab(
              icon: Icon(Icons.extension),
              text: 'Extensions',
            ),
            Tab(
              icon: Icon(Icons.collections),
              text: 'Collection',
            ),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          // Onglet Accueil
          _HomeTab(user: user),
          // Onglet Extensions
          const ExtensionsScreen(),
          // Onglet Collection (pour plus tard)
          _CollectionTab(),
        ],
      ),
    );
  }
}

// Widget pour l'onglet Accueil
class _HomeTab extends StatelessWidget {
  final User? user;

  const _HomeTab({required this.user});

  @override
  Widget build(BuildContext context) {
    return Padding(
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
                                user!.displayName ?? 'Nom non disponible',
                                style: const TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                              Text(
                                user!.email ?? 'Email non disponible',
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
                      ],
                    ),
                ],
              ),
            ),
          ),
          
          const SizedBox(height: 24),
          
          // Statistiques
          const Text(
            'Vos statistiques',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: Card(
                  color: Colors.orange[50],
                  child: const Padding(
                    padding: EdgeInsets.all(16.0),
                    child: Column(
                      children: [
                        Icon(
                          Icons.extension,
                          size: 32,
                          color: Colors.orange,
                        ),
                        SizedBox(height: 8),
                        Text(
                          'Extensions',
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.orange,
                          ),
                        ),
                        SizedBox(height: 4),
                        Text(
                          '1',
                          style: TextStyle(
                            fontSize: 24,
                            fontWeight: FontWeight.bold,
                            color: Colors.orange,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Card(
                  color: Colors.blue[50],
                  child: const Padding(
                    padding: EdgeInsets.all(16.0),
                    child: Column(
                      children: [
                        Icon(
                          Icons.collections,
                          size: 32,
                          color: Colors.blue,
                        ),
                        SizedBox(height: 8),
                        Text(
                          'Cartes totales',
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.blue,
                          ),
                        ),
                        SizedBox(height: 4),
                        Text(
                          '220',
                          style: TextStyle(
                            fontSize: 24,
                            fontWeight: FontWeight.bold,
                            color: Colors.blue,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),
          
          const SizedBox(height: 24),
          
          const Text(
            'Bienvenue dans Friendly TCG !',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
            ),
          ),
          
          const SizedBox(height: 16),
          
          const Text(
            'Explorez les extensions disponibles pour découvrir toutes les cartes NewType Risings.',
            style: TextStyle(fontSize: 16),
          ),
        ],
      ),
    );
  }
}

// Widget pour l'onglet Collection (temporaire)
class _CollectionTab extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return const Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.collections,
            size: 64,
            color: Colors.grey,
          ),
          SizedBox(height: 16),
          Text(
            'Ma Collection',
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
            ),
          ),
          SizedBox(height: 8),
          Text(
            'Fonctionnalité à venir !',
            style: TextStyle(
              fontSize: 16,
              color: Colors.grey,
            ),
          ),
        ],
      ),
    );
  }
}
