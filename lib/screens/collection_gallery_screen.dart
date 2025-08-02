import 'package:flutter/material.dart';
import '../models/extension_model.dart';
import '../services/extension_service.dart';
import '../services/collection_service.dart';
import '../services/price_service.dart';
import '../widgets/card_price_widget.dart';

class CollectionGalleryScreen extends StatefulWidget {
  final ExtensionModel extension;

  const CollectionGalleryScreen({
    super.key,
    required this.extension,
  });

  @override
  State<CollectionGalleryScreen> createState() => _CollectionGalleryScreenState();
}

class _CollectionGalleryScreenState extends State<CollectionGalleryScreen> {
  late List<CardModel> cards;
  String searchQuery = '';
  final CollectionService _collectionService = CollectionService();

  @override
  void initState() {
    super.initState();
    final extensionService = ExtensionService();
    cards = extensionService.getCardsForExtension(widget.extension.id);
    // Initialiser les prix d'exemple
    PriceService().initializeSamplePrices();
  }

  List<CardModel> get filteredCards {
    if (searchQuery.isEmpty) return cards;
    return cards.where((card) =>
      card.displayName.toLowerCase().contains(searchQuery.toLowerCase())
    ).toList();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Collection - ${widget.extension.name}'),
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(60),
          child: Padding(
            padding: const EdgeInsets.all(8.0),
            child: TextField(
              onChanged: (value) {
                setState(() {
                  searchQuery = value;
                });
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
        ),
      ),
      body: SingleChildScrollView(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    '${filteredCards.length} cartes',
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                  Text(
                    'Cartes grisées : non possédées',
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: Colors.grey[600],
                    ),
                  ),
                ],
              ),
            ),
            Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 1200),
                child: GridView.builder(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 3,
                    childAspectRatio: 0.6,
                    crossAxisSpacing: 12,
                    mainAxisSpacing: 12,
                  ),
                  itemCount: filteredCards.length,
                  itemBuilder: (context, index) {
                    final card = filteredCards[index];
                    final isOwned = _collectionService.getCardQuantity(card.name) > 0;
                    return _CollectionCardTile(
                      card: card,
                      isOwned: isOwned,
                      quantity: _collectionService.getCardQuantity(card.name),
                      onTap: () {
                        _showCardModal(context, card, filteredCards, index);
                      },
                    );
                  },
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showCardModal(BuildContext context, CardModel card, List<CardModel> allCards, int initialIndex) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return _CardModal(
          cards: allCards,
          initialIndex: initialIndex,
        );
      },
    );
  }
}

class _CollectionCardTile extends StatefulWidget {
  final CardModel card;
  final bool isOwned;
  final int quantity;
  final VoidCallback onTap;

  const _CollectionCardTile({
    required this.card,
    required this.isOwned,
    required this.quantity,
    required this.onTap,
  });

  @override
  State<_CollectionCardTile> createState() => _CollectionCardTileState();
}

class _CollectionCardTileState extends State<_CollectionCardTile> {
  final CollectionService _collectionService = CollectionService();

  @override
  Widget build(BuildContext context) {
    final int quantity = _collectionService.getCardQuantity(widget.card.name);
    final bool isOwned = quantity > 0;

    return Card(
      elevation: 2,
      margin: const EdgeInsets.all(2),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Image de la carte (cliquable) avec effet grisé si non possédée
          Expanded(
            flex: 5,
            child: GestureDetector(
              onTap: widget.onTap,
              child: Container(
                margin: const EdgeInsets.all(4),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(6),
                  child: ColorFiltered(
                    colorFilter: isOwned
                        ? const ColorFilter.mode(
                            Colors.transparent,
                            BlendMode.srcOver,
                          )
                        : const ColorFilter.mode(
                            Colors.grey,
                            BlendMode.saturation,
                          ),
                    child: Opacity(
                      opacity: isOwned ? 1.0 : 0.4,
                      child: Image.asset(
                        widget.card.imagePath,
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
            ),
          ),
          
          // Nom de la carte
          Container(
            height: 32,
            padding: const EdgeInsets.symmetric(horizontal: 4.0, vertical: 2.0),
            child: Text(
              widget.card.displayName,
              style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w500,
                color: isOwned ? Colors.black : Colors.grey[600],
              ),
              textAlign: TextAlign.center,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
          ),
          
          // Prix de la carte
          Container(
            height: 20,
            padding: const EdgeInsets.symmetric(horizontal: 4.0),
            child: CardPriceWidget(
              cardId: widget.card.name,
            ),
          ),
          
          // Contrôles de collection avec statut
          Container(
            height: 40,
            padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 4),
            child: isOwned
                ? Row(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: [
                      // Bouton -
                      SizedBox(
                        width: 28,
                        height: 28,
                        child: ElevatedButton(
                          onPressed: quantity > 0 ? () async {
                            await _collectionService.removeCard(widget.card.name);
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
                      
                      // Quantité
                      Container(
                        width: 32,
                        height: 28,
                        decoration: BoxDecoration(
                          color: Colors.green[50],
                          border: Border.all(
                            color: Colors.green,
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
                              color: Colors.green[700],
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
                            await _collectionService.addCard(widget.card.name);
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
                  )
                : GestureDetector(
                    onTap: () async {
                      await _collectionService.addCard(widget.card.name);
                      setState(() {});
                    },
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: Colors.grey[100],
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: Colors.grey[300]!),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            Icons.add,
                            size: 14,
                            color: Colors.grey[600],
                          ),
                          const SizedBox(width: 4),
                          Text(
                            'Ajouter',
                            style: TextStyle(
                              fontSize: 10,
                              color: Colors.grey[600],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
          ),
        ],
      ),
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

  @override
  void initState() {
    super.initState();
    currentIndex = widget.initialIndex;
    _pageController = PageController(initialPage: widget.initialIndex);
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
                  Text(
                    '${currentIndex + 1} / ${widget.cards.length}',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  IconButton(
                    onPressed: () => Navigator.of(context).pop(),
                    icon: const Icon(
                      Icons.close,
                      color: Colors.white,
                    ),
                  ),
                ],
              ),
            ),
            
            // Image carousel
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
                  final card = widget.cards[index];
                  return Container(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      children: [
                        // Image de la carte
                        Expanded(
                          child: ClipRRect(
                            borderRadius: BorderRadius.circular(12),
                            child: Image.asset(
                              card.imagePath,
                              fit: BoxFit.contain,
                              errorBuilder: (context, error, stackTrace) {
                                return Container(
                                  color: Colors.grey[800],
                                  child: const Icon(
                                    Icons.image_not_supported,
                                    color: Colors.white,
                                    size: 60,
                                  ),
                                );
                              },
                            ),
                          ),
                        ),
                        
                        const SizedBox(height: 16),
                        
                        // Nom de la carte
                        Text(
                          card.displayName,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                          textAlign: TextAlign.center,
                        ),
                      ],
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}
