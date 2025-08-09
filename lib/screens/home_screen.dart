import 'package:flutter/material.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../services/auth_service.dart';
import '../services/user_profile_service.dart';
import '../models/user_profile_model.dart';
// url_launcher n'est plus requis ici après migration feedback Firestore
import '../services/feedback_service.dart';
import '../services/collection_service.dart';
import '../widgets/collection_overview_widget.dart';
import 'games_screen.dart';
import 'collection_games_screen.dart';
import 'trades_main_screen.dart';
import 'community_posts_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> with SingleTickerProviderStateMixin {
  final AuthService _authService = AuthService();
  late TabController _tabController;
  final UserProfileService _userProfileService = UserProfileService();
  bool _profileChecked = false;

  @override
  void initState() {
    super.initState();
  _tabController = TabController(length: 5, vsync: this);
  WidgetsBinding.instance.addPostFrameCallback((_) => _ensureProfileSetup());
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _signOut() async {
    try {
      await _authService.signOut();
      // La navigation sera gérée automatiquement par AuthWrapper
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
    final photoUrl = user?.photoURL;
    return Scaffold(
      appBar: AppBar(
        title: const Text('Friendly TCG'),
        backgroundColor: Colors.blue,
        foregroundColor: Colors.white,
        actions: [
          if (photoUrl != null)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 8.0),
              child: InkWell(
                borderRadius: BorderRadius.circular(24),
                onTap: ()=> Navigator.of(context).pushNamed('/profile'),
                child: CircleAvatar(radius: 18, backgroundImage: NetworkImage(photoUrl)),
              ),
            ),
          PopupMenuButton<String>(
            icon: const Icon(Icons.more_vert),
            onSelected: (value) {
              if (value == 'logout') {
                _signOut();
              } else if (value == 'profile') {
                Navigator.of(context).pushNamed('/profile');
              }
            },
            itemBuilder: (BuildContext context) => [
              PopupMenuItem<String>(
                value: 'profile',
                child: Row(
                  children: [
                    CircleAvatar(
                      radius: 12,
                      backgroundImage: photoUrl != null ? NetworkImage(photoUrl) : null,
                      child: photoUrl == null ? const Icon(Icons.person, size: 16) : null,
                    ),
                    const SizedBox(width: 8),
                    const Text('Mon Profil'),
                  ],
                ),
              ),
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
            Tab(icon: Icon(Icons.home), text: 'Accueil'),
            Tab(icon: Icon(Icons.games), text: 'TCG'),
            Tab(icon: Icon(Icons.collections), text: 'Collection'),
            Tab(icon: Icon(Icons.swap_horiz), text: 'Échanges'),
            Tab(icon: Icon(Icons.forum), text: 'Communauté'),
          ],
        ),
      ),
      body: Stack(
        children: [
          TabBarView(
            controller: _tabController,
            children: [
              _HomeTab(user: user),
              const GamesScreen(),
              const CollectionGamesScreen(),
              const TradesMainScreen(),
              const CommunityPostsScreen(),
            ],
          ),
          Positioned(
            bottom: 16,
            right: 16,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: Colors.black54,
                borderRadius: BorderRadius.circular(12),
              ),
              child: FutureBuilder<String>(
                future: _getAppVersion(),
                builder: (context, snapshot) {
                  return Text(
                    'v${snapshot.data ?? "1.0.1"}',
                    style: const TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.w500),
                  );
                },
              ),
            ),
          ),
        ],
      ),
    );
  }

  Future<String> _getAppVersion() async {
    try {
      final info = await PackageInfo.fromPlatform();
      return '${info.version}+${info.buildNumber}';
    } catch (_) {
      return 'unknown';
    }
  }

  Future<void> _ensureProfileSetup() async {
    if (_profileChecked) return;
    _profileChecked = true;
    final user = _authService.currentUser;
    if (user == null) return;
    final profile = await _userProfileService.getCurrentUserProfile();
  // N'afficher le dialogue QUE si aucun profil n'existe encore (première connexion réelle)
  final isFirstConnection = profile == null;
  if (isFirstConnection && mounted) {
      await showDialog(
        context: context,
        barrierDismissible: false,
        builder: (ctx) => _ProfileSetupDialog(initialEmail: user.email ?? ''),
      );
    }
  }
}

// Widget pour l'onglet Accueil
class _HomeTab extends StatefulWidget {
  final User? user;

  const _HomeTab({required this.user});

  @override
  State<_HomeTab> createState() => _HomeTabState();
}

class _HomeTabState extends State<_HomeTab> {
  final CollectionService _collectionService = CollectionService();
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadCollection();
  }

  @override
  void didUpdateWidget(_HomeTab oldWidget) {
    super.didUpdateWidget(oldWidget);
    // Recharger la collection si l'utilisateur a changé
    if (oldWidget.user?.uid != widget.user?.uid) {
      _loadCollection();
    }
  }

  Future<void> _loadCollection() async {
    await _collectionService.loadCollection();
    if (mounted) {
      setState(() {
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Center(
        child: CircularProgressIndicator(),
      );
    }

    final isFirestoreAvailable = _collectionService.isFirestoreAvailable;
    
    return Column(
      children: [
        // Indicateur Firestore
        if (!isFirestoreAvailable)
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(12),
            margin: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.orange[100],
              border: Border.all(color: Colors.orange),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Row(
              children: [
                Icon(Icons.warning, color: Colors.orange[700]),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'Mode hors ligne : Vos données ne sont pas sauvegardées. Activez Firestore dans la console Firebase.',
                    style: TextStyle(color: Colors.orange[700]),
                  ),
                ),
              ],
            ),
          ),
        
        // Widget de présentation de la collection
        const Expanded(
          child: CollectionOverviewWidget(),
        ),
      ],
    );
  }
}

// Dialog de configuration initiale du profil (pseudo + localisation)
class _ProfileSetupDialog extends StatefulWidget {
  final String initialEmail;
  const _ProfileSetupDialog({required this.initialEmail});

  @override
  State<_ProfileSetupDialog> createState() => _ProfileSetupDialogState();
}

class _ProfileSetupDialogState extends State<_ProfileSetupDialog> {
  final _formKey = GlobalKey<FormState>();
  final _displayNameController = TextEditingController();
  final _countryController = TextEditingController();
  final _regionController = TextEditingController();
  final _cityController = TextEditingController();
  bool _saving = false;
  final _service = UserProfileService();

  // Listes déroulantes simples (peuvent être déplacées dans un service partagé avec l'écran profil)
  final List<String> _countries = const [
    'France','Belgique','Suisse','Canada','Luxembourg','Autre'
  ];
  final Map<String,List<String>> _regionsByCountry = const {
    'France': [
      'Auvergne-Rhône-Alpes','Bourgogne-Franche-Comté','Bretagne','Centre-Val de Loire','Corse','Grand Est','Hauts-de-France','Île-de-France','Normandie','Nouvelle-Aquitaine','Occitanie','Pays de la Loire','Provence-Alpes-Côte d\'Azur','Guadeloupe','Martinique','Guyane','La Réunion','Mayotte'
    ],
    'Belgique': ['Bruxelles','Flandre','Wallonie'],
    'Suisse': ['Zurich','Berne','Vaud','Genève','Argovie','Saint-Gall','Lucerne','Tessin','Valais','Fribourg'],
    'Canada': ['Québec','Ontario','Colombie-Britannique','Alberta','Manitoba','Nouveau-Brunswick','Nouvelle-Écosse','Saskatchewan','Terre-Neuve-et-Labrador'],
    'Luxembourg': ['Luxembourg'],
  };

  List<String> get _currentRegions {
    final c = _countryController.text.trim();
    return _regionsByCountry[c] ?? const [];
  }

  @override
  void dispose() {
    _displayNameController.dispose();
    _countryController.dispose();
    _regionController.dispose();
    _cityController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Bienvenue !'),
      content: SizedBox(
        width: 420,
        child: Form(
          key: _formKey,
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('Choisis un pseudo (visible publiquement) et ta localisation.'),
                const SizedBox(height: 16),
                TextFormField(
                  controller: _displayNameController,
                  decoration: const InputDecoration(
                    labelText: 'Pseudo',
                    prefixIcon: Icon(Icons.badge),
                  ),
                  maxLength: 24,
                  validator: (v) {
                    if (v == null || v.trim().isEmpty) return 'Pseudo requis';
                    if (v.length < 3) return 'Minimum 3 caractères';
                    return null;
                  },
                ),
                Row(children:[
                  Expanded(
                    child: DropdownButtonFormField<String>(
                      decoration: const InputDecoration(labelText: 'Pays'),
                      value: _countries.contains(_countryController.text) ? _countryController.text : null,
                      items: _countries.map((c)=> DropdownMenuItem(value: c, child: Text(c))).toList(),
                      onChanged: (val){
                        setState(() {
                          _countryController.text = val ?? '';
                          if (!_currentRegions.contains(_regionController.text)) {
                            _regionController.clear();
                          }
                        });
                      },
                      validator: (v){ if (v==null || v.isEmpty) return 'Sélectionner un pays'; return null; },
                    ),
                  ),
                  const SizedBox(width:8),
                  Expanded(
                    child: DropdownButtonFormField<String>(
                      decoration: const InputDecoration(labelText: 'Région'),
                      value: _currentRegions.contains(_regionController.text) ? _regionController.text : null,
                      items: _currentRegions.map((r)=> DropdownMenuItem(value: r, child: Text(r, overflow: TextOverflow.ellipsis))).toList(),
                      onChanged: (val){ setState(()=> _regionController.text = val ?? ''); },
                      validator: (v){ if (_currentRegions.isNotEmpty && (v==null || v.isEmpty)) return 'Sélectionner une région'; return null; },
                    ),
                  ),
                ]),
                const SizedBox(height:8),
                TextFormField(
                  controller: _cityController,
                  decoration: const InputDecoration(labelText: 'Ville (optionnel)'),
                ),
                const SizedBox(height:12),
                Text(
                  'Tu pourras modifier ces informations plus tard dans ton profil.',
                  style: TextStyle(fontSize:12,color: Colors.grey[600]),
                ),
              ],
            ),
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: _saving ? null : () => Navigator.pop(context),
          child: const Text('Plus tard'),
        ),
        ElevatedButton.icon(
          icon: _saving ? const SizedBox(width:16,height:16,child:CircularProgressIndicator(strokeWidth:2,color:Colors.white)) : const Icon(Icons.save),
          label: Text(_saving ? 'Enregistrement...' : 'Enregistrer'),
          onPressed: _saving ? null : _save,
        ),
      ],
    );
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    setState(()=> _saving = true);
    try {
      final authUser = FirebaseAuth.instance.currentUser;
      if (authUser == null) return;
      final profile = UserProfileModel(
        uid: authUser.uid,
        email: authUser.email,
        displayName: _displayNameController.text.trim(),
        photoURL: authUser.photoURL,
        country: _countryController.text.trim().isEmpty ? null : _countryController.text.trim(),
        region: _regionController.text.trim().isEmpty ? null : _regionController.text.trim(),
        city: _cityController.text.trim().isEmpty ? null : _cityController.text.trim(),
        lastSeen: DateTime.now(),
        lastUpdated: DateTime.now(),
      );
      await _service.updateUserProfile(profile);
      if (mounted) Navigator.pop(context);
    } finally {
      if (mounted) setState(()=> _saving = false);
    }
  }
}

// Bouton flottant / bulle de contact
class _FeedbackButton extends StatefulWidget {
  @override
  State<_FeedbackButton> createState() => _FeedbackButtonState();
}

class _FeedbackButtonState extends State<_FeedbackButton> {
  bool _open = false;
  final _controller = TextEditingController();
  bool _sending = false;
  final _feedbackService = FeedbackService();

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 250),
      width: _open ? 300 : 56,
      height: _open ? 260 : 56,
      decoration: BoxDecoration(
        color: Colors.blue.shade600,
        borderRadius: BorderRadius.circular(28),
        boxShadow: [
          BoxShadow(color: Colors.black.withValues(alpha: 0.25), blurRadius: 8, offset: const Offset(0,4)),
        ],
      ),
      child: _open ? _buildForm(context) : _buildCollapsed(),
    );
  }

  Widget _buildCollapsed() {
    return InkWell(
      onTap: ()=> setState(()=> _open = true),
      borderRadius: BorderRadius.circular(28),
      child: const Center(
        child: Icon(Icons.chat, color: Colors.white),
      ),
    );
  }

  Widget _buildForm(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Expanded(child: Text('Nous contacter', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold))),
              IconButton(
                icon: const Icon(Icons.close, color: Colors.white),
                onPressed: _sending ? null : () => setState(()=> _open=false),
              )
            ],
          ),
          Expanded(
            child: TextField(
              controller: _controller,
              maxLines: null,
              expands: true,
              style: const TextStyle(color: Colors.white),
              decoration: const InputDecoration(
                hintText: 'Vos idées, suggestions...'
                    '\n(Aucune donnée sensible SVP)',
                hintStyle: TextStyle(color: Colors.white70),
                border: InputBorder.none,
              ),
            ),
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              Expanded(
                child: ElevatedButton.icon(
                  style: ElevatedButton.styleFrom(backgroundColor: Colors.white, foregroundColor: Colors.blue.shade700),
                  icon: _sending ? const SizedBox(width:16,height:16,child:CircularProgressIndicator(strokeWidth:2)) : const Icon(Icons.send),
                  label: Text(_sending ? 'Envoi...' : 'Envoyer'),
                  onPressed: _sending ? null : _send,
                ),
              ),
            ],
          )
        ],
      ),
    );
  }

  Future<void> _send() async {
    final text = _controller.text.trim();
    if (text.isEmpty) return;
    setState(()=> _sending = true);
    try {
      await _feedbackService.sendFeedback(text);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Feedback envoyé. Merci !')));
        setState(()=> _open = false);
        _controller.clear();
      }
    } catch (_) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Erreur lors de l\'envoi')));
    } finally {
      if (mounted) setState(()=> _sending = false);
    }
  }
}
