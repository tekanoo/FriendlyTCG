import 'package:flutter/material.dart';
import '../services/trade_service.dart';
import '../services/game_service.dart';
import '../services/auto_game_service.dart';
import '../services/collection_service.dart';
import '../models/user_with_location.dart';
import '../models/user_model.dart';
import '../models/extension_model.dart';
import '../models/game_model.dart';
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
  bool _isSearching = false;
  
  // Sélection progressive
  GameModel? _selectedGame;
  ExtensionModel? _selectedExtension;
  List<String> _availableCards = [];
  
  // Étapes de sélection
  int _currentStep = 0; // 0: jeu, 1: extension, 2: cartes
  
  // Tri des cartes
  bool _sortAscending = true;
  
  // Filtre des cartes
  bool _showOnlyUnowned = false;

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
            child: GridView.builder(
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 2,
                crossAxisSpacing: 16,
                mainAxisSpacing: 16,
                childAspectRatio: 1.2,
              ),
              itemCount: games.length,
              itemBuilder: (context, index) {
                final game = games[index];
                return _buildGameCard(game);
              },
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
                  'Cartes sélectionnées (${_selectedCards.length})',
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
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          ..._searchResults.entries.map((entry) {
            final cardName = entry.key;
            return StreamBuilder<int>(
              stream: _collectionService.getCardQuantityStream(cardName),
              builder: (context, snapshot) {
                final quantity = snapshot.data ?? 0;
                final displayName = cardName.replaceAll('.png', '');
                
                return Card(
                  margin: const EdgeInsets.only(bottom: 16),
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Expanded(
                              child: Text(
                                displayName,
                                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                            if (quantity > 0)
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 8,
                                  vertical: 4,
                                ),
                                decoration: BoxDecoration(
                                  color: Colors.green,
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: Text(
                                  'Possédée ($quantity)',
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontSize: 12,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                          ],
                        ),
                        const SizedBox(height: 12),
                        if (entry.value.isEmpty)
                          const Text('Aucun utilisateur trouvé pour cette carte.')
                        else
                          ...entry.value.map((user) {
                            return Container(
                              margin: const EdgeInsets.only(bottom: 8),
                              padding: const EdgeInsets.all(12),
                              decoration: BoxDecoration(
                                color: Colors.blue.shade50,
                                borderRadius: BorderRadius.circular(8),
                                border: Border.all(color: Colors.blue.shade200),
                              ),
                              child: Row(
                                children: [
                                  CircleAvatar(
                                    backgroundImage: user.photoURL != null
                                        ? NetworkImage(user.photoURL!)
                                        : null,
                                    child: user.photoURL == null
                                        ? Text(user.displayName?[0] ?? '?')
                                        : null,
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
                                        if (user.city != null)
                                          Text(
                                            '📍 ${user.city}',
                                            style: TextStyle(
                                              color: Colors.grey.shade600,
                                              fontSize: 12,
                                            ),
                                          ),
                                      ],
                                    ),
                                  ),
                                  ElevatedButton(
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
                                    child: const Text('Échanger'),
                                  ),
                                ],
                              ),
                            );
                          }),
                      ],
                    ),
                  ),
                );
              },
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

  Widget _buildCardGrid() {
    // Les cartes sont déjà dans le bon ordre depuis le fichier généré
    List<String> sortedCards = List.from(_availableCards);
    
    // Appliquer le tri alphabétique seulement si l'utilisateur l'a demandé
    // Par défaut, on garde l'ordre intelligent du fichier généré
    if (!_sortAscending) {
      // Si tri descendant demandé, inverser l'ordre
      sortedCards = sortedCards.reversed.toList();
    }
    // Si _sortAscending est true, on garde l'ordre du fichier généré (tri intelligent)

    // Application du filtre
    final filteredCards = _getFilteredCards(sortedCards);

    return Column(
      children: [
        // Header avec tri et filtre
        Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Cartes (${filteredCards.length}${_showOnlyUnowned ? ' non possédées' : ''})',
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  Row(
                    children: [
                      IconButton(
                        onPressed: () {
                          setState(() {
                            _sortAscending = !_sortAscending;
                          });
                        },
                        icon: Icon(_sortAscending ? Icons.sort_by_alpha : Icons.sort_by_alpha_outlined),
                        tooltip: _sortAscending ? 'Tri Z-A' : 'Tri A-Z',
                      ),
                    ],
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Row(
                children: [
                  Checkbox(
                    value: _showOnlyUnowned,
                    onChanged: (value) {
                      setState(() {
                        _showOnlyUnowned = value ?? false;
                      });
                    },
                  ),
                  const Text('Afficher uniquement les cartes non possédées'),
                ],
              ),
            ],
          ),
        ),
        // Grille des cartes 3x3
        Expanded(
          child: GridView.builder(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 3,
              crossAxisSpacing: 8,
              mainAxisSpacing: 8,
              childAspectRatio: 0.7, // Ratio adapté pour les cartes
            ),
            itemCount: filteredCards.length,
            itemBuilder: (context, index) {
              final cardImageName = filteredCards[index];
              return _buildCardGridItem(cardImageName);
            },
          ),
        ),
      ],
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

  Widget _buildCardGridItem(String cardImageName) {
    final cardPath = AutoGameService.getCardImagePath(_selectedExtension!.id, cardImageName);
    final displayName = cardImageName.replaceAll('.png', '');
    final isSelected = _selectedCards.contains(cardImageName);

    return StreamBuilder<int>(
      stream: _collectionService.getCardQuantityStream(cardImageName),
      builder: (context, snapshot) {
        final quantity = snapshot.data ?? 0;
        final hasCard = quantity > 0;
        
        return InkWell(
          onTap: () => _toggleCardSelection(cardImageName),
          borderRadius: BorderRadius.circular(8),
          child: Container(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(8),
              border: Border.all(
                color: isSelected ? Colors.green : Colors.grey.shade300,
                width: isSelected ? 3 : 1,
              ),
              boxShadow: isSelected ? [
                BoxShadow(
                  color: Colors.green.withValues(alpha: 0.3),
                  blurRadius: 8,
                  offset: const Offset(0, 2),
                ),
              ] : [],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // Image de la carte (partie principale)
                Expanded(
                  flex: 4,
                  child: ClipRRect(
                    borderRadius: const BorderRadius.vertical(top: Radius.circular(8)),
                    child: Image.asset(
                      cardPath,
                      fit: BoxFit.cover,
                      errorBuilder: (context, error, stackTrace) {
                        return Container(
                          color: Colors.grey.shade200,
                          child: Icon(
                            Icons.image_not_supported,
                            color: Colors.grey.shade400,
                            size: 40,
                          ),
                        );
                      },
                    ),
                  ),
                ),
                
                // Informations de la carte (partie inférieure)
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: isSelected ? Colors.green.shade50 : Colors.white,
                    borderRadius: const BorderRadius.vertical(bottom: Radius.circular(8)),
                  ),
                  child: Column(
                    children: [
                      // Nom de la carte (tronqué si nécessaire)
                      Text(
                        displayName,
                        style: TextStyle(
                          fontWeight: FontWeight.w500,
                          fontSize: 10,
                          color: isSelected ? Colors.green.shade800 : Colors.black87,
                        ),
                        textAlign: TextAlign.center,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 4),
                      
                      // Statut de possession et sélection
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          // Indicateur de possession
                          Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(
                                hasCard ? Icons.check_circle : Icons.radio_button_unchecked,
                                size: 12,
                                color: hasCard ? Colors.green : Colors.grey,
                              ),
                              if (hasCard && quantity > 0) ...[
                                const SizedBox(width: 2),
                                Text(
                                  '$quantity',
                                  style: const TextStyle(
                                    fontSize: 10,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.green,
                                  ),
                                ),
                              ],
                            ],
                          ),
                          
                          // Indicateur de sélection
                          Container(
                            width: 16,
                            height: 16,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              color: isSelected ? Colors.green : Colors.transparent,
                              border: Border.all(
                                color: isSelected ? Colors.green : Colors.grey.shade400,
                                width: 1,
                              ),
                            ),
                            child: isSelected
                                ? const Icon(Icons.check, color: Colors.white, size: 12)
                                : null,
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}
