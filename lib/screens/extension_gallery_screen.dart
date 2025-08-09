import 'package:flutter/material.dart';
import '../models/extension_model.dart';
import '../services/auto_game_service.dart';
import '../services/collection_service.dart';
import '../widgets/pagination_controls.dart';
import '../widgets/adaptive_card_grid.dart';
import '../widgets/pokemon_card_manage_dialog.dart';

class ExtensionGalleryScreen extends StatefulWidget {
  final ExtensionModel extension;

  const ExtensionGalleryScreen({
    super.key,
    required this.extension,
  });

  @override
  State<ExtensionGalleryScreen> createState() => _ExtensionGalleryScreenState();
}

class _ExtensionGalleryScreenState extends State<ExtensionGalleryScreen> {
  late List<CardModel> cards;
  String searchQuery = '';
  int currentPage = 0;
  static const int cardsPerPage = 9; // 3x3 grille
  bool _sortAscending = true;

  @override
  void initState() {
    super.initState();
    final cardNames = AutoGameService.getCardsForExtension(widget.extension.id);
    cards = cardNames.map((cardName) => CardModel(
      name: cardName,
      imagePath: AutoGameService.getCardImagePath(widget.extension.id, cardName),
      displayName: cardName.replaceAll('.png', ''),
    )).toList();
    
    // Les cartes sont déjà triées par le service avec le tri intelligent
  }

  List<CardModel> get filteredCards {
    List<CardModel> result;
    if (searchQuery.isEmpty) {
      // Quand pas de recherche, respecter l'ordre du fichier généré (asc) ou inverser si tri descendant demandé
      result = List.from(cards);
      if (!_sortAscending) {
        result = result.reversed.toList();
      }
    } else {
      // Lors d'une recherche, filtrer puis trier
      result = cards.where((card) =>
        card.displayName.toLowerCase().contains(searchQuery.toLowerCase())
      ).toList();
      
      // Appliquer le tri seulement lors d'une recherche
      result.sort((a, b) {
        return _sortAscending 
            ? a.displayName.compareTo(b.displayName)
            : b.displayName.compareTo(a.displayName);
      });
    }
    
    return result;
  }

  List<CardModel> get currentPageCards {
    final allCards = filteredCards;
    final startIndex = currentPage * cardsPerPage;
    final endIndex = (startIndex + cardsPerPage).clamp(0, allCards.length);
    
    if (startIndex >= allCards.length) return [];
    return allCards.sublist(startIndex, endIndex);
  }

  int get totalPages {
    return (filteredCards.length / cardsPerPage).ceil();
  }

  void _goToNextPage() {
    if (currentPage < totalPages - 1) {
      setState(() {
        currentPage++;
      });
    }
  }

  void _goToPreviousPage() {
    if (currentPage > 0) {
      setState(() {
        currentPage--;
      });
    }
  }

  void _onSearchChanged(String value) {
    setState(() {
      searchQuery = value;
      currentPage = 0; // Reset Ã  la premiÃ¨re page lors de la recherche
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.extension.name),
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(60),
          child: Padding(
            padding: const EdgeInsets.all(8.0),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    onChanged: (value) {
                      _onSearchChanged(value);
                    },
                    decoration: InputDecoration(
                      hintText: 'Rechercher une carte...',
                      prefixIcon: const Icon(Icons.search),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(30),
                      ),
                      filled: true,
                      fillColor: Colors.white,
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                IconButton(
                  onPressed: () {
                    setState(() {
                      _sortAscending = !_sortAscending;
                      currentPage = 0; // Retour à la première page après tri
                    });
                  },
                  icon: Icon(_sortAscending ? Icons.sort_by_alpha : Icons.sort_by_alpha_outlined),
                  tooltip: _sortAscending ? 'Tri Z-A' : 'Tri A-Z',
                  style: IconButton.styleFrom(
                    backgroundColor: Colors.white,
                    foregroundColor: Theme.of(context).primaryColor,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
      body: Column(
        children: [
          // Header avec informations et pagination
          PageHeader(
            totalItems: filteredCards.length,
            currentPage: currentPage,
            totalPages: totalPages,
            itemName: 'cartes',
            subtitle: widget.extension.description,
          ),
          
          // Grille de cartes (adaptative)
          Expanded(
            child: LayoutBuilder(
              builder: (context, constraints) {
                // Responsive grid via AdaptiveCardGrid
                return Center(
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 1200),
                    child: AdaptiveCardGrid(
                      children: [
                        for (final card in currentPageCards)
                          _CardTile(
                            card: card,
                            onTap: () {
                              _showCardModal(
                                context,
                                card,
                                filteredCards,
                                filteredCards.indexOf(card),
                              );
                            },
                          ),
                      ],
                    ),
                  ),
                );
              },
            ),
          ),
          
          // ContrÃ´les de pagination
          PaginationControls(
            currentPage: currentPage,
            totalPages: totalPages,
            onPreviousPage: _goToPreviousPage,
            onNextPage: _goToNextPage,
            primaryColor: Colors.blue,
          ),
        ],
      ),
    );
  }

  void _showCardModal(BuildContext context, CardModel card, List<CardModel> allCards, int initialIndex) {
    showDialog(
      context: context,
      builder: (context) => _CardModal(
        cards: allCards,
        initialIndex: initialIndex,
      ),
    );
  }
}

class _CardTile extends StatefulWidget {
  final CardModel card;
  final VoidCallback onTap;

  const _CardTile({
    required this.card,
    required this.onTap,
  });

  @override
  State<_CardTile> createState() => _CardTileState();
}

class _CardTileState extends State<_CardTile> {
  final CollectionService _collectionService = CollectionService();

  // Vérifier si c'est une carte Pokémon
  bool _isPokemonCard(String cardName) {
    return cardName.startsWith('SV') || cardName.contains('_FR_');
  }

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<int>(
      stream: _isPokemonCard(widget.card.name) 
          ? _collectionService.getTotalCardQuantityStream(widget.card.name)
          : _collectionService.getCardQuantityStream(widget.card.name),
      builder: (context, snapshot) {
        final int quantity = snapshot.data ?? 0;

        return Card(
          elevation: 2, // Ombre plus marquÃ©e
          margin: const EdgeInsets.all(2),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Image de la carte (cliquable)
              Expanded(
                flex: 5, // Plus d'espace pour l'image
                child: GestureDetector(
                  onTap: widget.onTap,
                  child: Container(
                    margin: const EdgeInsets.all(4), // Marge un peu plus grande
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(6), // Coins plus arrondis
                      child: Image.asset(
                        widget.card.imagePath,
                        fit: BoxFit.contain, // Voir l'image entiÃ¨re
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
                height: 32, // Hauteur un peu plus grande
                padding: const EdgeInsets.symmetric(horizontal: 4.0, vertical: 2.0),
                child: Text(
                  widget.card.displayName,
                  style: const TextStyle(
                    fontSize: 11, // Texte un peu plus grand
                    fontWeight: FontWeight.w500,
                  ),
                  textAlign: TextAlign.center,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              
              // ContrÃ´les de collection
              Container(
                height: 36, // Hauteur plus confortable
                padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 4),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    // Bouton -
                    SizedBox(
                      width: 28,
                      height: 28,
                      child: ElevatedButton(
                        onPressed: quantity > 0 ? () async {
                          // Détecter si c'est une carte Pokémon pour gérer les variantes
                          if (_isPokemonCard(widget.card.name)) {
                            await showDialog(
                              context: context,
                              builder: (context) => PokemonCardManageDialog(
                                cardName: widget.card.name,
                                displayName: widget.card.displayName,
                                isAdd: false,
                              ),
                            );
                          } else {
                            await _collectionService.removeCard(widget.card.name);
                          }
                          setState(() {});
                        } : null,
                        style: ElevatedButton.styleFrom(
                          padding: EdgeInsets.zero,
                          backgroundColor: Colors.red[100],
                          foregroundColor: Colors.red[700],
                          elevation: 1,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(4),
                          ),
                        ),
                        child: const Icon(Icons.remove, size: 16),
                      ),
                    ),
                    
                    // QuantitÃ©
                    Container(
                      width: 32,
                      height: 28,
                      decoration: BoxDecoration(
                        color: quantity > 0 ? Colors.green[50] : Colors.grey[100],
                        border: Border.all(
                          color: quantity > 0 ? Colors.green : Colors.grey,
                          width: 1,
                        ),
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: Center(
                        child: Text(
                          quantity.toString(),
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                            color: quantity > 0 ? Colors.green[700] : Colors.grey[600],
                          ),
                        ),
                      ),
                    ),
                    
                    // Bouton +
                    SizedBox(
                      width: 28,
                      height: 28,
                      child: ElevatedButton(
                        onPressed: () async {
                          // Détecter si c'est une carte Pokémon
                          if (_isPokemonCard(widget.card.name)) {
                            await showDialog(
                              context: context,
                              builder: (context) => PokemonCardManageDialog(
                                cardName: widget.card.name,
                                displayName: widget.card.displayName,
                                isAdd: true,
                              ),
                            );
                          } else {
                            await _collectionService.addCard(widget.card.name);
                          }
                          setState(() {});
                        },
                        style: ElevatedButton.styleFrom(
                          padding: EdgeInsets.zero,
                          backgroundColor: Colors.green[100],
                          foregroundColor: Colors.green[700],
                          elevation: 1,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(4),
                          ),
                        ),
                        child: const Icon(Icons.add, size: 16),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

class _CardModal extends StatefulWidget {
  final List<CardModel> cards;
  final int initialIndex;

  const _CardModal({
    required this.cards,
    required this.initialIndex,
  });

  @override
  State<_CardModal> createState() => _CardModalState();
}

class _CardModalState extends State<_CardModal> {
  late PageController _pageController;
  late int currentIndex;
  final CollectionService _collectionService = CollectionService();

  // Vérifier si c'est une carte Pokémon
  bool _isPokemonCardInModal(String cardName) {
    return cardName.startsWith('SV') || cardName.contains('_FR_');
  }

  @override
  void initState() {
    super.initState();
    currentIndex = widget.initialIndex;
    _pageController = PageController(initialPage: widget.initialIndex);
    // NOTE: Ne pas recharger la collection ici car cela Ã©crase les modifications locales
    // La collection est dÃ©jÃ  chargÃ©e dans HomeScreen
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: Colors.black87,
      child: SizedBox(
        width: MediaQuery.of(context).size.width * 0.9,
        height: MediaQuery.of(context).size.height * 0.9,
        child: Column(
          children: [
            // Header avec navigation
            Container(
              padding: const EdgeInsets.all(16),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  IconButton(
                    onPressed: currentIndex > 0
                        ? () {
                            _pageController.previousPage(
                              duration: const Duration(milliseconds: 300),
                              curve: Curves.easeInOut,
                            );
                          }
                        : null,
                    icon: const Icon(Icons.arrow_back, color: Colors.white),
                  ),
                  Expanded(
                    child: Text(
                      widget.cards[currentIndex].displayName,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ),
                  IconButton(
                    onPressed: currentIndex < widget.cards.length - 1
                        ? () {
                            _pageController.nextPage(
                              duration: const Duration(milliseconds: 300),
                              curve: Curves.easeInOut,
                            );
                          }
                        : null,
                    icon: const Icon(Icons.arrow_forward, color: Colors.white),
                  ),
                ],
              ),
            ),
            // Image viewer
            Expanded(
              child: PageView.builder(
                controller: _pageController,
                onPageChanged: (index) {
                  setState(() {
                    currentIndex = index;
                  });
                },
                itemCount: widget.cards.length,
                itemBuilder: (context, index) {
                  return Padding(
                    padding: const EdgeInsets.all(16),
                    child: InteractiveViewer(
                      child: Image.asset(
                        widget.cards[index].imagePath,
                        fit: BoxFit.contain,
                        errorBuilder: (context, error, stackTrace) {
                          return const Center(
                            child: Icon(
                              Icons.image_not_supported,
                              color: Colors.white,
                              size: 50,
                            ),
                          );
                        },
                      ),
                    ),
                  );
                },
              ),
            ),
            // Footer avec compteur, contrÃ´les de collection et bouton fermer
            Container(
              padding: const EdgeInsets.all(16),
              child: Column(
                children: [
                  // ContrÃ´les de collection
                  _buildCollectionControls(widget.cards[currentIndex]),
                  const SizedBox(height: 16),
                  // Compteur et bouton fermer
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        '${currentIndex + 1} / ${widget.cards.length}',
                        style: const TextStyle(color: Colors.white),
                      ),
                      ElevatedButton(
                        onPressed: () => Navigator.of(context).pop(),
                        child: const Text('Fermer'),
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
  }

  Widget _buildCollectionControls(CardModel card) {
    return StreamBuilder<int>(
      stream: _collectionService.getCardQuantityStream(card.name),
      builder: (context, snapshot) {
        // Pour les cartes Pokémon, obtenir la quantité totale (normal + reverse)
        final quantity = _isPokemonCardInModal(card.name) 
            ? _collectionService.getTotalCardQuantity(card.name)
            : snapshot.data ?? 0;
        
        return Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          decoration: BoxDecoration(
            color: Colors.black54,
            borderRadius: BorderRadius.circular(8),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              IconButton(
                icon: const Icon(Icons.remove, color: Colors.white),
                onPressed: quantity > 0 
                  ? () async {
                      // Détecter si c'est une carte Pokémon pour gérer les variantes
                      if (_isPokemonCardInModal(card.name)) {
                        await showDialog(
                          context: context,
                          builder: (context) => PokemonCardManageDialog(
                            cardName: card.name,
                            displayName: card.displayName,
                            isAdd: false,
                          ),
                        );
                      } else {
                        await _collectionService.removeCard(card.name);
                      }
                    }
                  : null,
              ),
              Container(
                margin: const EdgeInsets.symmetric(horizontal: 16),
                child: Text(
                  '$quantity',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              IconButton(
                icon: const Icon(Icons.add, color: Colors.white),
                onPressed: () async {
                  // Détecter si c'est une carte Pokémon
                  if (_isPokemonCardInModal(card.name)) {
                    await showDialog(
                      context: context,
                      builder: (context) => PokemonCardManageDialog(
                        cardName: card.name,
                        displayName: card.displayName,
                        isAdd: true,
                      ),
                    );
                  } else {
                    await _collectionService.addCard(card.name);
                  }
                },
              ),
            ],
          ),
        );
      },
    );
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }
}
