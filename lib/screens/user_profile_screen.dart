import 'package:flutter/material.dart';
import '../models/user_profile_model.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../services/user_profile_service.dart';
import '../services/geographic_data.dart';
import '../widgets/autocomplete_dropdown_field.dart';

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
  
  late TextEditingController _displayNameController;
  late TextEditingController _countryController;
  late TextEditingController _regionController;
  late TextEditingController _cityController;
  
  List<String> _availableCountries = [];
  List<String> _availableRegions = [];
  List<String> _availableCities = [];

  @override
  void initState() {
    super.initState();
  _displayNameController = TextEditingController();
  _countryController = TextEditingController();
    _regionController = TextEditingController();
    _cityController = TextEditingController();
    _loadProfile();
    _initializeGeographicData();
  }

  @override
  void dispose() {
  _displayNameController.dispose();
  _countryController.dispose();
    _regionController.dispose();
    _cityController.dispose();
    super.dispose();
  }

  Future<void> _initializeGeographicData() async {
    setState(() {
      _availableCountries = GeographicData.getAllCountries();
    });
  }

  void _updateRegions(String country) {
    setState(() {
      _availableRegions = GeographicData.getRegionsForCountry(country);
      _regionController.clear();
      _cityController.clear();
      _availableCities = [];
    });
  }

  void _updateRegionsForCountryChange(String country) {
    setState(() {
      _availableRegions = GeographicData.getRegionsForCountry(country);
      // Ne pas vider les contrôleurs lors de l'initialisation
      _availableCities = [];
    });
  }

  void _updateCities(String region) {
    setState(() {
      _availableCities = GeographicData.getCitiesForRegion(region);
      _cityController.clear();
    });
  }

  void _updateCitiesForRegionChange(String region) {
    setState(() {
      _availableCities = GeographicData.getCitiesForRegion(region);
      // Ne pas vider le contrôleur lors de l'initialisation
    });
  }

  Future<void> _loadProfile() async {
    try {
      final profile = await _profileService.getCurrentUserProfile();
      if (mounted) {
        setState(() {
          _currentProfile = profile;
          _displayNameController.text = profile?.displayName ?? '';
          _countryController.text = profile?.country ?? '';
          _regionController.text = profile?.region ?? '';
          _cityController.text = profile?.city ?? '';
          _isLoading = false;
          
          // Mettre à jour les listes déroulantes basées sur la sélection actuelle
          if (profile?.country?.isNotEmpty == true) {
            _updateRegionsForCountryChange(profile!.country!);
            if (profile.region?.isNotEmpty == true) {
              _updateCitiesForRegionChange(profile.region!);
            }
          }
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

  Future<void> _saveProfile() async {
    if (!_formKey.currentState!.validate()) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Veuillez remplir tous les champs obligatoires correctement'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    // Vérifications supplémentaires pour s'assurer que les valeurs sont valides
  final displayName = _displayNameController.text.trim();
  final country = _countryController.text.trim();
    final region = _regionController.text.trim();
    final city = _cityController.text.trim();

    if (displayName.isEmpty || displayName.length < 3) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Nom d\'affichage trop court (min 3)'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    if (country.isEmpty || !_availableCountries.contains(country)) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Veuillez sélectionner un pays valide'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    if (region.isEmpty || !_availableRegions.contains(region)) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Veuillez sélectionner une région valide'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    if (city.isEmpty || !_availableCities.contains(city)) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Veuillez sélectionner une ville valide'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    setState(() => _isSaving = true);

    try {
      debugPrint('🔄 Sauvegarde du profil avec: country="$country", region="$region", city="$city"');
      
      // Mettre à jour Firestore (displayName + localisation)
      final user = FirebaseAuth.instance.currentUser;
      bool success = false;
      if (user != null) {
        success = await _profileService.updateUserProfile(
          UserProfileModel(
            uid: user.uid,
            email: user.email,
            displayName: displayName,
            photoURL: user.photoURL,
            country: country,
            region: region,
            city: city,
            lastSeen: DateTime.now(),
            lastUpdated: DateTime.now(),
          ),
        );
      }

      if (mounted) {
        if (success) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Profil mis à jour avec succès !'),
              backgroundColor: Colors.green,
            ),
          );
          // Recharger le profil pour vérifier la sauvegarde
          await _loadProfile();
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
          SnackBar(
            content: Text('Erreur: $e'),
            backgroundColor: Colors.red,
          ),
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
            Container(
              margin: const EdgeInsets.symmetric(vertical: 8, horizontal: 8),
              child: ElevatedButton(
                onPressed: _isSaving ? null : _saveProfile,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.green.shade600,
                  foregroundColor: Colors.white,
                  elevation: 2,
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
                child: _isSaving 
                  ? const SizedBox(
                      width: 16,
                      height: 16,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                      ),
                    )
                  : const Text('Sauvegarder', style: TextStyle(fontWeight: FontWeight.bold)),
              ),
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
                              TextFormField(
                                controller: _displayNameController,
                                decoration: const InputDecoration(
                                  labelText: 'Nom d\'affichage',
                                  prefixIcon: Icon(Icons.person),
                                ),
                                maxLength: 32,
                                validator: (v){
                                  if (v==null || v.trim().length <3) return 'Min 3 caractères';
                                  return null;
                                },
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

                    // Champ Pays avec autocomplétion
                    AutocompleteDropdownField(
                      label: 'Pays',
                      hintText: 'Ex: France, Canada, Japon...',
                      prefixIcon: Icons.public,
                      controller: _countryController,
                      options: _availableCountries,
                      isRequired: true,
                      strictValidation: true,
                      onChanged: (value) {
                        if (value.isNotEmpty && _availableCountries.contains(value)) {
                          _updateRegions(value);
                        } else if (value.isEmpty) {
                          _updateRegions('');
                        }
                      },
                    ),
                    const SizedBox(height: 16),

                    // Champ Région avec autocomplétion
                    AutocompleteDropdownField(
                      label: 'Région/Département',
                      hintText: 'Ex: Île-de-France, Québec, Tokyo...',
                      prefixIcon: Icons.location_on,
                      controller: _regionController,
                      options: _availableRegions,
                      isRequired: true, // Région obligatoire
                      strictValidation: true,
                      onChanged: (value) {
                        if (value.isNotEmpty && _availableRegions.contains(value)) {
                          _updateCities(value);
                        } else if (value.isEmpty) {
                          _updateCities('');
                        }
                      },
                    ),
                    const SizedBox(height: 16),

                    // Champ Ville avec autocomplétion
                    AutocompleteDropdownField(
                      label: 'Ville',
                      hintText: 'Ex: Paris, Montréal, Tokyo...',
                      prefixIcon: Icons.location_city,
                      controller: _cityController,
                      options: _availableCities,
                      isRequired: true, // Ville obligatoire
                      strictValidation: true,
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
