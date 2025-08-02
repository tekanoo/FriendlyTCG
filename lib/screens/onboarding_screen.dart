import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../services/user_profile_service.dart';
import '../models/user_profile_model.dart';

class OnboardingScreen extends StatefulWidget {
  const OnboardingScreen({super.key});

  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen> {
  final PageController _pageController = PageController();
  final TextEditingController _displayNameController = TextEditingController();
  final UserProfileService _profileService = UserProfileService();
  
  int _currentPage = 0;
  bool _isLoading = false;

  final List<OnboardingPage> _pages = [
    OnboardingPage(
      title: 'Bienvenue sur Friendly TCG !',
      description: 'Découvrez l\'application qui vous permet de gérer votre collection de cartes Gundam et d\'échanger avec d\'autres joueurs.',
      icon: Icons.waving_hand,
      color: Colors.blue,
    ),
    OnboardingPage(
      title: 'Gérez votre collection',
      description: 'Ajoutez vos cartes à votre collection en parcourant les extensions. Suivez vos exemplaires en temps réel.',
      icon: Icons.collections,
      color: Colors.green,
    ),
    OnboardingPage(
      title: 'Échangez avec d\'autres joueurs',
      description: 'Trouvez des joueurs qui possèdent les cartes que vous cherchez et proposez vos échanges.',
      icon: Icons.swap_horiz,
      color: Colors.orange,
    ),
    OnboardingPage(
      title: 'Restez connecté',
      description: 'Configurez votre profil et votre localisation pour trouver des joueurs près de chez vous.',
      icon: Icons.location_on,
      color: Colors.purple,
    ),
  ];

  @override
  void initState() {
    super.initState();
    final user = FirebaseAuth.instance.currentUser;
    if (user?.displayName != null) {
      _displayNameController.text = user!.displayName!;
    }
  }

  @override
  void dispose() {
    _pageController.dispose();
    _displayNameController.dispose();
    super.dispose();
  }

  Future<void> _completeOnboarding() async {
    if (_displayNameController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Veuillez saisir un nom d\'affichage'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    setState(() => _isLoading = true);

    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user != null) {
        await user.updateDisplayName(_displayNameController.text.trim());
        
        // Marquer l'onboarding comme terminé
        await _profileService.updateUserProfile(
          UserProfileModel(
            uid: user.uid,
            email: user.email,
            displayName: _displayNameController.text.trim(),
            photoURL: user.photoURL,
            lastUpdated: DateTime.now(),
          )
        );

        if (mounted) {
          Navigator.of(context).pushReplacementNamed('/home');
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Erreur: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            // Indicateur de progression
            Container(
              padding: const EdgeInsets.all(20),
              child: Row(
                children: [
                  for (int i = 0; i < _pages.length; i++)
                    Expanded(
                      child: Container(
                        margin: const EdgeInsets.symmetric(horizontal: 2),
                        height: 4,
                        decoration: BoxDecoration(
                          color: i <= _currentPage ? Colors.blue : Colors.grey.shade300,
                          borderRadius: BorderRadius.circular(2),
                        ),
                      ),
                    ),
                ],
              ),
            ),

            // Contenu des pages
            Expanded(
              child: PageView.builder(
                controller: _pageController,
                onPageChanged: (index) {
                  setState(() => _currentPage = index);
                },
                itemCount: _pages.length + 1, // +1 pour la page de configuration du nom
                itemBuilder: (context, index) {
                  if (index < _pages.length) {
                    return _buildTutorialPage(_pages[index]);
                  } else {
                    return _buildNameConfigPage();
                  }
                },
              ),
            ),

            // Boutons de navigation
            Container(
              padding: const EdgeInsets.all(20),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  if (_currentPage > 0)
                    TextButton(
                      onPressed: () {
                        _pageController.previousPage(
                          duration: const Duration(milliseconds: 300),
                          curve: Curves.easeInOut,
                        );
                      },
                      child: const Text('Précédent'),
                    )
                  else
                    const SizedBox(),

                  if (_currentPage < _pages.length)
                    ElevatedButton(
                      onPressed: () {
                        _pageController.nextPage(
                          duration: const Duration(milliseconds: 300),
                          curve: Curves.easeInOut,
                        );
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.blue,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                      ),
                      child: Text(_currentPage == _pages.length - 1 ? 'Configurer' : 'Suivant'),
                    )
                  else
                    ElevatedButton(
                      onPressed: _isLoading ? null : _completeOnboarding,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.green,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                      ),
                      child: _isLoading
                        ? const SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                            ),
                          )
                        : const Text('Commencer'),
                    ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTutorialPage(OnboardingPage page) {
    return Padding(
      padding: const EdgeInsets.all(32),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            width: 120,
            height: 120,
            decoration: BoxDecoration(
              color: page.color.withValues(alpha: 0.1),
              shape: BoxShape.circle,
            ),
            child: Icon(
              page.icon,
              size: 60,
              color: page.color,
            ),
          ),
          const SizedBox(height: 40),
          Text(
            page.title,
            style: Theme.of(context).textTheme.headlineSmall?.copyWith(
              fontWeight: FontWeight.bold,
              color: page.color,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 20),
          Text(
            page.description,
            style: Theme.of(context).textTheme.bodyLarge?.copyWith(
              color: Colors.grey.shade600,
              height: 1.5,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildNameConfigPage() {
    return Padding(
      padding: const EdgeInsets.all(32),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            width: 120,
            height: 120,
            decoration: BoxDecoration(
              color: Colors.indigo.withValues(alpha: 0.1),
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.person,
              size: 60,
              color: Colors.indigo,
            ),
          ),
          const SizedBox(height: 40),
          Text(
            'Votre nom d\'affichage',
            style: Theme.of(context).textTheme.headlineSmall?.copyWith(
              fontWeight: FontWeight.bold,
              color: Colors.indigo,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 20),
          Text(
            'Choisissez comment les autres joueurs vous verront dans l\'application.',
            style: Theme.of(context).textTheme.bodyLarge?.copyWith(
              color: Colors.grey.shade600,
              height: 1.5,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 40),
          TextFormField(
            controller: _displayNameController,
            decoration: const InputDecoration(
              labelText: 'Nom d\'affichage',
              hintText: 'Ex: JoueurGundam123',
              border: OutlineInputBorder(),
              prefixIcon: Icon(Icons.person),
            ),
            maxLength: 50,
            textCapitalization: TextCapitalization.words,
          ),
        ],
      ),
    );
  }
}

class OnboardingPage {
  final String title;
  final String description;
  final IconData icon;
  final Color color;

  OnboardingPage({
    required this.title,
    required this.description,
    required this.icon,
    required this.color,
  });
}
