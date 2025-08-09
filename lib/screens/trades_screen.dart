import 'package:flutter/material.dart';
import '../services/trade_service.dart';
import '../data/french_regions.dart';
import '../services/game_service.dart';
import '../services/auto_game_service.dart';
import '../services/collection_service.dart';
import '../models/user_with_location.dart';
import '../models/user_model.dart';
import '../models/extension_model.dart';
import '../models/game_model.dart';
import '../widgets/adaptive_card_grid.dart';
import '../widgets/pagination_controls.dart';
import 'trade_offer_screen.dart';
import 'my_trades_screen.dart';

class TradesScreen extends StatefulWidget {
  const TradesScreen({super.key});

  @override
  State<TradesScreen> createState() => _TradesScreenState();
}

class _TradesScreenState extends State<TradesScreen> {
  final TradeService _tradeService = TradeService();
  final GameService _gameService = GameService();
  final CollectionService _collectionService = CollectionService();
  
  final List<String> _selectedCards = [];
  Map<String, List<UserWithLocation>> _searchResults = {};
  String? _selectedRegionFilter; // Région sélectionnée pour filtrer les résultats
  bool _isSearching = false;
  
  // Sélection progressive
  GameModel? _selectedGame;
  ExtensionModel? _selectedExtension;
  List<String> _availableCards = [];
  
  // Étapes de sélection
  int _currentStep = 0; // 0: jeu, 1: extension, 2: cartes
  
  // Tri des cartes
  bool _sortAscending = true;
  
  // Pagination comme TCG
  int _currentPage = 0;
  static const int _cardsPerPage = 9; // 3x3 grille
  
  // Filtre des cartes
  bool _showOnlyUnowned = false;

  // Helper: total cartes filtrées (après filtre owned / tri non requis pour le count)
  int get _totalFilteredCardsCount {
    List<String> base = List.from(_availableCards);
    if (!_sortAscending) {
      base = base.reversed.toList();
    }
    return _getFilteredCards(base).length;
  }

  @override
  void initState() {
    super.initState();
    _tradeService.updateCurrentUserInfo();
  }

  // Sélectionner un jeu
  void _selectGame(GameModel game) {
    setState(() {
      _selectedGame = game;
      _selectedExtension = null;
      _availableCards = [];
      _selectedCards.clear();
      _currentStep = 1;
    });
  }

  // Sélectionner une extension
  void _selectExtension(ExtensionModel extension) {
    setState(() {
      _selectedExtension = extension;
      _availableCards = AutoGameService.getCardsForExtension(extension.id);
      _selectedCards.clear();
      _currentStep = 2;
    });
  }

  // Revenir à l'étape précédente
  void _goBack() {
    setState(() {
      if (_currentStep > 0) {
        _currentStep--;
        if (_currentStep == 0) {
          _selectedGame = null;
          _selectedExtension = null;
          _availableCards = [];
          _selectedCards.clear();
        } else if (_currentStep == 1) {
          _selectedExtension = null;
          _availableCards = [];
          _selectedCards.clear();
        }
      }
    });
  }

  Future<void> _searchForCardOwners() async {
    if (_selectedCards.isEmpty) return;

    setState(() {
      _isSearching = true;
    });

    try {
      final results = await _tradeService.findUsersWithCardsAndLocation(_selectedCards);
      // Appliquer filtre région si défini (uniquement 13 régions métropole)
      if (_selectedRegionFilter != null) {
        results.updateAll((card, users) => users.where((u) => (u.region ?? '') == _selectedRegionFilter).toList());
      }
      setState(() {
        _searchResults = results;
      });
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Erreur lors de la recherche: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      setState(() {
        _isSearching = false;
      });
    }
  }

  void _toggleCardSelection(String cardName) {
    setState(() {
      if (_selectedCards.contains(cardName)) {
        _selectedCards.remove(cardName);
      } else {
        _selectedCards.add(cardName);
      }
    });
  }

  void _clearSelection() {
    setState(() {
      _selectedCards.clear();
      _searchResults.clear();
    });
  }

  void _selectAllFiltered(List<String> filteredCards) {
    setState(() {
      _selectedCards
        ..clear()
        ..addAll(filteredCards);
      _searchResults.clear(); // reset previous results si existants
    });
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        _buildProgressHeader(),
        Expanded(
          child: _buildCurrentStepContent(),
        ),
      ],
    );
  }

  Widget _buildProgressHeader() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.blue.shade50,
        border: Border(
          bottom: BorderSide(color: Colors.blue.shade200),
        ),
      ),
      child: Column(
        children: [
          Row(
            children: [
              if (_currentStep > 0)
                IconButton(
                  onPressed: _goBack,
                  icon: const Icon(Icons.arrow_back),
                  tooltip: 'Retour',
                ),
              Expanded(
                child: Text(
                  _getStepTitle(),
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              if (_currentStep == 2)
                IconButton(
                  onPressed: () {
                    Navigator.of(context).push(
                      MaterialPageRoute(
                        builder: (context) => const MyTradesScreen(),
                      ),
                    );
                  },
                  icon: const Icon(Icons.history),
                  tooltip: 'Mes échanges',
                ),
            ],
          ),
          const SizedBox(height: 8),
          _buildProgressIndicator(),
          const SizedBox(height: 12),
          // Filtre Région (affiché à partir de l'étape 2 pour pertinence)
          if (_currentStep == 2)
            Align(
              alignment: Alignment.centerLeft,
              child: Wrap(
                crossAxisAlignment: WrapCrossAlignment.center,
                spacing: 8,
                runSpacing: 4,
                children: [
                  const Text('Région:', style: TextStyle(fontWeight: FontWeight.w600)),
                  DropdownButton<String>(
                    hint: const Text('Toutes'),
                    value: _selectedRegionFilter,
                    items: [
                      const DropdownMenuItem<String>(value: null, child: Text('Toutes')), // non valide directement, géré autrement
                      ...FrenchRegions.regions.map((r) => DropdownMenuItem<String>(value: r, child: Text(r))),
                    ],
                    onChanged: (val) {
                      setState(() {
                        // Hack: Dropdown ne supporte pas item null directement; on gère reset via valeur spéciale
                        if (val == null) {
                          _selectedRegionFilter = null;
                        } else {
                          _selectedRegionFilter = val;
                        }
                      });
                      // Refiltrer résultats existants sans relancer Firestore pour éviter coût
                      if (_searchResults.isNotEmpty) {
                        if (_selectedRegionFilter == null) {
                          // Relancer recherche pour restaurer tous les utilisateurs
                          _searchForCardOwners();
                        } else {
                          setState(() {
                            _searchResults = _searchResults.map((key, users) => MapEntry(
                              key,
                              users.where((u) => (u.region ?? '') == _selectedRegionFilter).toList(),
                            ));
                          });
                        }
                      }
                    },
                  ),
                  if (_selectedRegionFilter != null)
                    TextButton(
                      onPressed: () {
                        setState(() {
                          _selectedRegionFilter = null;
                        });
                        _searchForCardOwners();
                      },
                      child: const Text('Réinitialiser'),
                    ),
                ],
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildProgressIndicator() {
    return Row(
      children: [
        _buildStepIndicator(0, 'Jeu'),
        Expanded(child: Container(height: 2, color: _currentStep > 0 ? Colors.blue : Colors.grey.shade300)),
        _buildStepIndicator(1, 'Extension'),
        Expanded(child: Container(height: 2, color: _currentStep > 1 ? Colors.blue : Colors.grey.shade300)),
        _buildStepIndicator(2, 'Cartes'),
      ],
    );
  }

  Widget _buildStepIndicator(int step, String label) {
    final isActive = _currentStep >= step;
    return Column(
      children: [
        Container(
          width: 32,
          height: 32,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: isActive ? Colors.blue : Colors.grey.shade300,
          ),
          child: Center(
            child: Text(
              '${step + 1}',
              style: TextStyle(
                color: isActive ? Colors.white : Colors.grey.shade600,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ),
        const SizedBox(height: 4),
        Text(
          label,
          style: TextStyle(
            fontSize: 12,
            color: isActive ? Colors.blue : Colors.grey.shade600,
          ),
        ),
      ],
    );
  }

  String _getStepTitle() {
    switch (_currentStep) {
      case 0:
        return 'Choisir un jeu';
      case 1:
        return 'Choisir une extension';
      case 2:
        return 'Sélectionner les cartes à échanger';
      default:
        return 'Échanges';
    }
  }

  Widget _buildCurrentStepContent() {
    switch (_currentStep) {
      case 0:
        return _buildGameSelection();
      case 1:
        return _buildExtensionSelection();
      case 2:
        return _buildCardSelection();
      default:
        return const Center(child: Text('Étape inconnue'));
    }
  }

  Widget _buildGameSelection() {
    final games = _gameService.availableGames;
    
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Sélectionnez un jeu de cartes :',
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 16),
          Expanded(
            child: AdaptiveCardGrid(
              children: [
                for (final game in games) _buildGameCard(game),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildGameCard(GameModel game) {
    return InkWell(
      onTap: () => _selectGame(game),
      borderRadius: BorderRadius.circular(12),
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Colors.grey.shade300),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.1),
              blurRadius: 4,
              offset: const Offset(0, 2),
            ),
          ],
          color: Colors.white,
        ),
        child: Column(
          children: [
            Expanded(
              flex: 3,
              child: Container(
                width: double.infinity,
                decoration: BoxDecoration(
                  borderRadius: const BorderRadius.vertical(top: Radius.circular(12)),
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [
                      Colors.blue.shade100,
                      Colors.blue.shade50,
                    ],
                  ),
                ),
                child: Center(
                  child: Image.asset(
                    game.imagePath,
                    height: 60,
                    fit: BoxFit.contain,
                    errorBuilder: (context, error, stackTrace) {
                      return Icon(
                        Icons.games,
                        size: 40,
                        color: Colors.grey.shade400,
                      );
                    },
                  ),
                ),
              ),
            ),
            Expanded(
              flex: 2,
              child: Padding(
                padding: const EdgeInsets.all(8),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      game.name,
                      style: Theme.of(context).textTheme.titleSmall?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                      textAlign: TextAlign.center,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildExtensionSelection() {
    if (_selectedGame == null) {
      return const Center(child: Text('Aucun jeu sélectionné'));
    }

    final extensions = _gameService.getExtensionsForGame(_selectedGame!.id);
    
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Extensions disponibles pour ${_selectedGame!.name} :',
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 16),
          Expanded(
            child: ListView.builder(
              itemCount: extensions.length,
              itemBuilder: (context, index) {
                final extension = extensions[index];
                return _buildExtensionCard(extension);
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildExtensionCard(ExtensionModel extension) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: InkWell(
        onTap: () => _selectExtension(extension),
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              ClipRRect(
                borderRadius: BorderRadius.circular(8),
                child: Image.asset(
                  extension.imagePath,
                  width: 60,
                  height: 80,
                  fit: BoxFit.cover,
                  errorBuilder: (context, error, stackTrace) {
                    return Container(
                      width: 60,
                      height: 80,
                      color: Colors.grey.shade200,
                      child: Icon(
                        Icons.image_not_supported,
                        color: Colors.grey.shade400,
                      ),
                    );
                  },
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      extension.name,
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '${extension.cardImages.length} cartes',
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: Colors.grey.shade600,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      extension.description,
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: Colors.grey.shade600,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
              const Icon(Icons.chevron_right),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildCardSelection() {
    if (_selectedExtension == null) {
      return const Center(child: Text('Aucune extension sélectionnée'));
    }

    return Column(
      children: [
        _buildSelectedCardsSection(),
        if (_searchResults.isNotEmpty) 
          Expanded(child: _buildSearchResults())
        else 
          Expanded(child: _buildCardGrid()),
      ],
    );
  }

  Widget _buildSelectedCardsSection() {
    if (_selectedCards.isEmpty) return const SizedBox.shrink();

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.green.shade50,
        border: Border(
          bottom: BorderSide(color: Colors.green.shade200),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  'Cartes sélectionnées (${_selectedCards.length} / ${_totalFilteredCardsCount})',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: Colors.green.shade800,
                  ),
                ),
              ),
              TextButton.icon(
                onPressed: _clearSelection,
                icon: const Icon(Icons.clear_all, size: 16),
                label: const Text('Tout effacer'),
              ),
              const SizedBox(width: 8),
              ElevatedButton.icon(
                onPressed: _isSearching ? null : _searchForCardOwners,
                icon: _isSearching
                    ? const SizedBox(
                        width: 16,
                        height: 16,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Icon(Icons.search, size: 16),
                label: Text(_isSearching ? 'Recherche...' : 'Rechercher'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.green.shade600,
                  foregroundColor: Colors.white,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              for (String cardName in _selectedCards)
                StreamBuilder<int>(
                  stream: _collectionService.getCardQuantityStream(cardName),
                  builder: (context, snapshot) {
                    final quantity = snapshot.data ?? 0;
                    final displayName = cardName.replaceAll('.png', '');
                    
                    return Chip(
                      label: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Flexible(
                            child: Text(
                              displayName,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          if (quantity > 0) ...[
                            const SizedBox(width: 4),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 6,
                                vertical: 2,
                              ),
                              decoration: BoxDecoration(
                                color: Colors.green,
                                borderRadius: BorderRadius.circular(10),
                              ),
                              child: Text(
                                '$quantity',
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 10,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                          ],
                        ],
                      ),
                      onDeleted: () => _toggleCardSelection(cardName),
                      backgroundColor: quantity > 0 ? Colors.green.shade100 : null,
                    );
                  },
                ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildSearchResults() {
    // Agrégation par utilisateur : uid -> (UserWithLocation, liste cartes)
    final Map<String, _AggregatedUserCards> aggregated = {};
    _searchResults.forEach((cardName, users) {
      for (final user in users) {
        aggregated.putIfAbsent(user.uid, () => _AggregatedUserCards(user: user));
        aggregated[user.uid]!.cards.add(cardName);
      }
    });

    final entries = aggregated.values.toList()
      ..sort((a, b) => b.cards.length.compareTo(a.cards.length));

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (entries.isEmpty)
            const Text('Aucun utilisateur trouvé pour les cartes sélectionnées.')
          else
            Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: Text(
                'Utilisateurs trouvés: ${entries.length} (triés par nombre de cartes correspondantes)',
                style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
              ),
            ),
          ...entries.map((agg) {
            final user = agg.user;
            return Card(
              margin: const EdgeInsets.only(bottom: 16),
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        CircleAvatar(
                          backgroundImage: user.photoURL != null ? NetworkImage(user.photoURL!) : null,
                          child: user.photoURL == null ? Text(user.displayName?[0] ?? '?') : null,
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                user.displayName ?? 'Utilisateur anonyme',
                                style: const TextStyle(fontWeight: FontWeight.bold),
                              ),
                              if (user.region != null)
                                Text(
                                  '📍 ${user.region}',
                                  style: TextStyle(color: Colors.grey.shade600, fontSize: 12),
                                ),
                            ],
                          ),
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                          decoration: BoxDecoration(
                            color: Colors.green.shade600,
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: Text(
                            '${agg.cards.length} carte${agg.cards.length > 1 ? 's' : ''}',
                            style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: [
                        for (final cardName in agg.cards)
                          _buildUserCardChip(user, cardName),
                      ],
                    ),
                  ],
                ),
              ),
            );
          }),
          if (_searchResults.isNotEmpty)
            Center(
              child: ElevatedButton.icon(
                onPressed: () {
                  setState(() {
                    _searchResults.clear();
                  });
                },
                icon: const Icon(Icons.arrow_back),
                label: const Text('Retour à la sélection'),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildUserCardChip(UserWithLocation user, String cardName) {
    final displayName = cardName.replaceAll('.png', '');
    return ActionChip(
      label: Text(displayName, overflow: TextOverflow.ellipsis),
      avatar: const Icon(Icons.swap_horiz, size: 16),
      onPressed: () {
        Navigator.of(context).push(
          MaterialPageRoute(
            builder: (context) => TradeOfferScreen(
              targetUser: UserModel(
                uid: user.uid,
                email: user.email,
                displayName: user.displayName,
                cards: {},
                lastSeen: DateTime.now(),
              ),
              wantedCard: cardName,
            ),
          ),
        );
      },
    );
  }


  Widget _buildCardGrid() {
    // Utiliser l'ordre alphabétique du fichier généré directement
    List<String> sortedCards = List.from(_availableCards);
    
    // Appliquer seulement l'inversion si demandée par l'utilisateur
    if (!_sortAscending) {
      sortedCards = sortedCards.reversed.toList();
    }

    // Application du filtre
    final filteredCards = _getFilteredCards(sortedCards);
    
    // Pagination comme TCG
    final totalPages = (filteredCards.length / _cardsPerPage).ceil();
    final startIndex = _currentPage * _cardsPerPage;
    final endIndex = (startIndex + _cardsPerPage).clamp(0, filteredCards.length);
    final currentPageCards = startIndex >= filteredCards.length 
        ? <String>[]
        : filteredCards.sublist(startIndex, endIndex);

    return Column(
      children: [
        // Header avec informations et pagination (comme TCG)
        PageHeader(
          totalItems: filteredCards.length,
          currentPage: _currentPage,
          totalPages: totalPages,
          itemName: 'cartes',
          subtitle: _selectedExtension?.description ?? '',
        ),
        
        // Header avec tri et filtre
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  Checkbox(
                    value: _showOnlyUnowned,
                    onChanged: (value) {
                      setState(() {
                        _showOnlyUnowned = value ?? false;
                        _currentPage = 0; // Reset pagination
                      });
                    },
                  ),
                  const Text('Afficher uniquement les cartes non possédées'),
                ],
              ),
              Row(
                children: [
                  TextButton.icon(
                    onPressed: () {
                      // Utiliser toutes les cartes filtrées (sur toutes les pages)
                      _selectAllFiltered(filteredCards);
                    },
                    icon: const Icon(Icons.select_all),
                    label: Text(
                      _selectedCards.length == filteredCards.length && filteredCards.isNotEmpty
                          ? 'Toutes sélectionnées'
                          : 'Tout sélectionner',
                    ),
                  ),
                  IconButton(
                    onPressed: () {
                      setState(() {
                        _sortAscending = !_sortAscending;
                        _currentPage = 0; // Reset pagination
                      });
                    },
                    icon: Icon(_sortAscending ? Icons.sort_by_alpha : Icons.sort_by_alpha_outlined),
                    tooltip: _sortAscending ? 'Tri Z-A' : 'Tri A-Z',
                  ),
                ],
              ),
            ],
          ),
        ),
        
        // Grille des cartes (exactement comme TCG)
        Expanded(
          child: LayoutBuilder(
            builder: (context, constraints) {
              // aspect ratio handled internally by AdaptiveCardGrid
              return Center(
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 1200), // Même config que TCG
                  child: AdaptiveCardGrid(
                    children: [
                      for (final cardImageName in currentPageCards)
                        _buildTCGStyleCardTile(cardImageName),
                    ],
                  ),
                ),
              );
            },
          ),
        ),
        
        // Contrôles de pagination (comme TCG)
        PaginationControls(
          currentPage: _currentPage,
          totalPages: totalPages,
          onPreviousPage: _goToPreviousPage,
          onNextPage: _goToNextPage,
          primaryColor: Colors.blue,
          label: 'Échanges',
        ),
      ],
    );
  }

  void _goToNextPage() {
    final totalPages = ((_getFilteredCards(_availableCards)).length / _cardsPerPage).ceil();
    if (_currentPage < totalPages - 1) {
      setState(() {
        _currentPage++;
      });
    }
  }

  void _goToPreviousPage() {
    if (_currentPage > 0) {
      setState(() {
        _currentPage--;
      });
    }
  }

  // Nouveau style de carte identique à TCG
  Widget _buildTCGStyleCardTile(String cardImageName) {
    final cardPath = AutoGameService.getCardImagePath(_selectedExtension!.id, cardImageName);
    final displayName = cardImageName.replaceAll('.png', '');

    return Card(
      elevation: 2,
      margin: const EdgeInsets.all(2),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Image de la carte (cliquable) - style TCG
          Expanded(
            flex: 5,
            child: GestureDetector(
              onTap: () => _toggleCardSelection(cardImageName),
              child: Container(
                margin: const EdgeInsets.all(4),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(6),
                  child: Image.asset(
                    cardPath,
                    fit: BoxFit.contain,
                    errorBuilder: (context, error, stackTrace) {
                      return Container(
                        color: Colors.grey[200],
                        child: const Icon(
                          Icons.image_not_supported,
                          color: Colors.grey,
                          size: 30,
                        ),
                      );
                    },
                  ),
                ),
              ),
            ),
          ),
          
          // Nom de la carte
          Container(
            height: 32,
            padding: const EdgeInsets.symmetric(horizontal: 4.0, vertical: 2.0),
            child: Text(
              displayName,
              style: const TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w500,
              ),
              textAlign: TextAlign.center,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
          ),
          
          // Status de sélection
          Container(
            height: 24,
            margin: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
            decoration: BoxDecoration(
              color: _selectedCards.contains(cardImageName) 
                ? Colors.green[50] 
                : Colors.grey[50],
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: _selectedCards.contains(cardImageName) 
                  ? Colors.green 
                  : Colors.grey[300]!,
              ),
            ),
            child: Center(
              child: Text(
                _selectedCards.contains(cardImageName) ? 'Sélectionnée' : 'Sélectionner',
                style: TextStyle(
                  fontSize: 10,
                  color: _selectedCards.contains(cardImageName) 
                    ? Colors.green[700] 
                    : Colors.grey[600],
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  List<String> _getFilteredCards(List<String> sortedCards) {
    if (!_showOnlyUnowned) {
      return sortedCards;
    }
    
    List<String> filteredCards = [];
    for (String card in sortedCards) {
      final quantity = _collectionService.getCardQuantity(card);
      if (quantity == 0) {
        filteredCards.add(card);
      }
    }
    return filteredCards;
  }

}

// Helper aggregation structure (not nullable fields)
class _AggregatedUserCards {
  final UserWithLocation user;
  final List<String> cards = [];
  _AggregatedUserCards({required this.user});
}
