import 'package:flutter/material.dart';
import '../models/user_profile_model.dart';
import '../services/user_profile_service.dart';

class UserProfileScreen extends StatefulWidget {
  const UserProfileScreen({super.key});

  @override
  State<UserProfileScreen> createState() => _UserProfileScreenState();
}

class _UserProfileScreenState extends State<UserProfileScreen> {
  final UserProfileService _profileService = UserProfileService();
  final _formKey = GlobalKey<FormState>();
  
  UserProfileModel? _currentProfile;
  bool _isLoading = true;
  bool _isSaving = false;
  
  late TextEditingController _countryController;
  late TextEditingController _regionController;
  late TextEditingController _cityController;
  
  List<String> _popularCountries = [];

  @override
  void initState() {
    super.initState();
    _countryController = TextEditingController();
    _regionController = TextEditingController();
    _cityController = TextEditingController();
    _loadProfile();
    _loadPopularCountries();
  }

  @override
  void dispose() {
    _countryController.dispose();
    _regionController.dispose();
    _cityController.dispose();
    super.dispose();
  }

  Future<void> _loadProfile() async {
    try {
      final profile = await _profileService.getCurrentUserProfile();
      if (mounted) {
        setState(() {
          _currentProfile = profile;
          _countryController.text = profile?.country ?? '';
          _regionController.text = profile?.region ?? '';
          _cityController.text = profile?.city ?? '';
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Erreur lors du chargement du profil: $e')),
        );
      }
    }
  }

  Future<void> _loadPopularCountries() async {
    try {
      final countries = await _profileService.getPopularCountries();
      if (mounted) {
        setState(() => _popularCountries = countries);
      }
    } catch (e) {
      debugPrint('Erreur lors du chargement des pays populaires: $e');
    }
  }

  Future<void> _saveProfile() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isSaving = true);

    try {
      final success = await _profileService.updateUserLocation(
        country: _countryController.text.trim().isEmpty ? null : _countryController.text.trim(),
        region: _regionController.text.trim().isEmpty ? null : _regionController.text.trim(),
        city: _cityController.text.trim().isEmpty ? null : _cityController.text.trim(),
      );

      if (mounted) {
        if (success) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Profil mis à jour avec succès !'),
              backgroundColor: Colors.green,
            ),
          );
          Navigator.of(context).pop();
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Erreur lors de la mise à jour du profil'),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Erreur: $e')),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isSaving = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Mon Profil'),
        actions: [
          if (!_isLoading)
            TextButton(
              onPressed: _isSaving ? null : _saveProfile,
              child: _isSaving 
                ? const SizedBox(
                    width: 16,
                    height: 16,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Text('Sauvegarder', style: TextStyle(color: Colors.white)),
            ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Informations utilisateur
                    if (_currentProfile != null) ...[
                      Card(
                        child: Padding(
                          padding: const EdgeInsets.all(16),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Informations du compte',
                                style: Theme.of(context).textTheme.titleLarge,
                              ),
                              const SizedBox(height: 16),
                              if (_currentProfile!.displayName != null)
                                ListTile(
                                  leading: const Icon(Icons.person),
                                  title: Text(_currentProfile!.displayName!),
                                  subtitle: const Text('Nom d\'affichage'),
                                ),
                              if (_currentProfile!.email != null)
                                ListTile(
                                  leading: const Icon(Icons.email),
                                  title: Text(_currentProfile!.email!),
                                  subtitle: const Text('Email'),
                                ),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(height: 24),
                    ],

                    // Configuration de la localisation
                    Text(
                      'Localisation',
                      style: Theme.of(context).textTheme.titleLarge,
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Configurez votre localisation pour trouver des joueurs près de chez vous.',
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: Colors.grey[600],
                      ),
                    ),
                    const SizedBox(height: 16),

                    // Champ Pays
                    TextFormField(
                      controller: _countryController,
                      decoration: InputDecoration(
                        labelText: 'Pays',
                        hintText: 'Ex: France, Canada, Japon...',
                        border: const OutlineInputBorder(),
                        prefixIcon: const Icon(Icons.public),
                        suffixIcon: _popularCountries.isNotEmpty 
                          ? PopupMenuButton<String>(
                              icon: const Icon(Icons.arrow_drop_down),
                              onSelected: (country) {
                                _countryController.text = country;
                              },
                              itemBuilder: (context) => _popularCountries
                                  .map((country) => PopupMenuItem(
                                        value: country,
                                        child: Text(country),
                                      ))
                                  .toList(),
                            )
                          : null,
                      ),
                    ),
                    const SizedBox(height: 16),

                    // Champ Région
                    TextFormField(
                      controller: _regionController,
                      decoration: const InputDecoration(
                        labelText: 'Région/Département',
                        hintText: 'Ex: Île-de-France, Québec, Tokyo...',
                        border: OutlineInputBorder(),
                        prefixIcon: Icon(Icons.location_on),
                      ),
                    ),
                    const SizedBox(height: 16),

                    // Champ Ville
                    TextFormField(
                      controller: _cityController,
                      decoration: const InputDecoration(
                        labelText: 'Ville',
                        hintText: 'Ex: Paris, Montréal, Tokyo...',
                        border: OutlineInputBorder(),
                        prefixIcon: Icon(Icons.location_city),
                      ),
                    ),
                    const SizedBox(height: 24),

                    // Informations sur la confidentialité
                    Card(
                      color: Colors.blue[50],
                      child: Padding(
                        padding: const EdgeInsets.all(16),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Icon(Icons.info, color: Colors.blue[700]),
                                const SizedBox(width: 8),
                                Text(
                                  'Confidentialité',
                                  style: TextStyle(
                                    fontWeight: FontWeight.bold,
                                    color: Colors.blue[700],
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 8),
                            Text(
                              'Votre localisation sera visible par les autres utilisateurs pour faciliter les échanges locaux. '
                              'Vous pouvez modifier ou supprimer ces informations à tout moment.',
                              style: TextStyle(color: Colors.blue[600]),
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 24),

                    // Bouton pour vider la localisation
                    if (_currentProfile?.hasLocation == true)
                      Center(
                        child: TextButton.icon(
                          onPressed: () {
                            setState(() {
                              _countryController.clear();
                              _regionController.clear();
                              _cityController.clear();
                            });
                          },
                          icon: const Icon(Icons.clear),
                          label: const Text('Effacer la localisation'),
                        ),
                      ),
                  ],
                ),
              ),
            ),
    );
  }
}
