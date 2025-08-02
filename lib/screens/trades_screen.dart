import 'package:flutter/material.dart';
import '../services/trade_service.dart';
import '../services/extension_service.dart';
import '../models/user_model.dart';
import '../models/extension_model.dart';
import '../widgets/card_tile_widget.dart';

class TradesScreen extends StatefulWidget {
  const TradesScreen({super.key});

  @override
  State<TradesScreen> createState() => _TradesScreenState();
}

class _TradesScreenState extends State<TradesScreen> {
  final TradeService _tradeService = TradeService();
  final ExtensionService _extensionService = ExtensionService();
  
  final List<String> _selectedCards = [];
  Map<String, List<UserModel>> _searchResults = {};
  bool _isLoading = false;
  bool _isSearching = false;
  ExtensionModel? _currentExtension;

  @override
  void initState() {
    super.initState();
    _loadExtension();
    _tradeService.updateCurrentUserInfo();
  }

  Future<void> _loadExtension() async {
    setState(() {
      _isLoading = true;
    });

    try {
      final extensions = _extensionService.availableExtensions;
      final extension = extensions.firstWhere(
        (ext) => ext.id == 'newtype_risings',
        orElse: () => throw Exception('Extension non trouvée'),
      );
      setState(() {
        _currentExtension = extension;
      });
    } catch (e) {
      debugPrint('❌ Erreur lors du chargement de l\'extension: $e');
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _searchForCardOwners() async {
    if (_selectedCards.isEmpty) return;

    setState(() {
      _isSearching = true;
    });

    try {
      final results = await _tradeService.findUsersWithCards(_selectedCards);
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
    if (_isLoading) {
      return const Center(
        child: CircularProgressIndicator(),
      );
    }

    if (_currentExtension == null) {
      return const Center(
        child: Text('Extension non trouvée'),
      );
    }

    return Column(
      children: [
        _buildHeader(),
        _buildSelectedCardsSection(),
        if (_searchResults.isNotEmpty) _buildSearchResults(),
        if (_searchResults.isEmpty) _buildCardSelection(),
      ],
    );
  }

  Widget _buildHeader() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [Colors.blue.shade600, Colors.blue.shade400],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Échanges de cartes',
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Sélectionnez les cartes que vous recherchez',
            style: TextStyle(
              fontSize: 16,
              color: Colors.white.withValues(alpha: 0.9),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSelectedCardsSection() {
    if (_selectedCards.isEmpty) return const SizedBox.shrink();

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.blue.shade50,
        border: Border(
          bottom: BorderSide(color: Colors.grey.shade300),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Cartes sélectionnées (${_selectedCards.length})',
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
              Row(
                children: [
                  TextButton.icon(
                    onPressed: _clearSelection,
                    icon: const Icon(Icons.clear),
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
                        : const Icon(Icons.search),
                    label: Text(_isSearching ? 'Recherche...' : 'Rechercher'),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 12),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              for (String cardName in _selectedCards)
                Chip(
                  label: Text(cardName),
                  deleteIcon: const Icon(Icons.close, size: 18),
                  onDeleted: () => _toggleCardSelection(cardName),
                  backgroundColor: Colors.blue.shade100,
                ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildSearchResults() {
    return Expanded(
      child: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          const Text(
            'Résultats de recherche',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 16),
          ..._searchResults.entries.map((entry) {
            final cardName = entry.key;
            final users = entry.value;
            
            return Card(
              margin: const EdgeInsets.only(bottom: 16),
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      cardName,
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 12),
                    if (users.isEmpty)
                      const Text(
                        'Aucun utilisateur ne possède cette carte',
                        style: TextStyle(
                          color: Colors.grey,
                          fontStyle: FontStyle.italic,
                        ),
                      )
                    else
                      ...users.map((user) => _buildUserTile(user, cardName)),
                  ],
                ),
              ),
            );
          }),
          const SizedBox(height: 16),
          ElevatedButton(
            onPressed: () {
              setState(() {
                _searchResults.clear();
              });
            },
            child: const Text('Nouvelle recherche'),
          ),
        ],
      ),
    );
  }

  Widget _buildUserTile(UserModel user, String cardName) {
    final quantity = user.getCardQuantity(cardName);
    final timeAgo = _getTimeAgo(user.lastSeen);
    
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.grey.shade50,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Row(
        children: [
          CircleAvatar(
            backgroundImage: user.photoURL != null 
                ? NetworkImage(user.photoURL!) 
                : null,
            child: user.photoURL == null 
                ? Text(user.displayName?.substring(0, 1).toUpperCase() ?? 'U')
                : null,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  user.displayName ?? user.email,
                  style: const TextStyle(
                    fontWeight: FontWeight.w500,
                  ),
                ),
                Text(
                  'Possède $quantity exemplaire${quantity > 1 ? 's' : ''}',
                  style: TextStyle(
                    color: Colors.green.shade700,
                    fontSize: 12,
                  ),
                ),
                Text(
                  'Vu $timeAgo',
                  style: TextStyle(
                    color: Colors.grey.shade600,
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ),
          IconButton(
            onPressed: () {
              //TODO: Implémenter l'envoi de message
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Fonctionnalité de message à venir'),
                ),
              );
            },
            icon: const Icon(Icons.message),
            tooltip: 'Envoyer un message',
          ),
        ],
      ),
    );
  }

  Widget _buildCardSelection() {
    return Expanded(
      child: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: _currentExtension!.cardImages.length,
        itemBuilder: (context, index) {
          final cardImageName = _currentExtension!.cardImages[index];
          final cardName = cardImageName.replaceAll('.png', '');
          final isSelected = _selectedCards.contains(cardName);
          
          return CardTileWidget(
            cardName: cardName,
            imagePath: 'assets/images/extensions/newtype_risings/$cardImageName',
            isSelected: isSelected,
            onTap: () => _toggleCardSelection(cardName),
            subtitle: 'Extension: ${_currentExtension!.name}',
          );
        },
      ),
    );
  }

  String _getTimeAgo(DateTime dateTime) {
    final now = DateTime.now();
    final difference = now.difference(dateTime);
    
    if (difference.inMinutes < 1) {
      return 'à l\'instant';
    } else if (difference.inHours < 1) {
      return 'il y a ${difference.inMinutes} min';
    } else if (difference.inDays < 1) {
      return 'il y a ${difference.inHours}h';
    } else if (difference.inDays < 30) {
      return 'il y a ${difference.inDays}j';
    } else {
      return 'il y a plus d\'un mois';
    }
  }
}
