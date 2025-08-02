import 'package:flutter/material.dart';
import '../models/extension_model.dart';
import '../services/extension_service.dart';
import '../services/collection_service.dart';

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

  @override
  void initState() {
    super.initState();
    final extensionService = ExtensionService();
    cards = extensionService.getCardsForExtension(widget.extension.id);
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
        title: Text(widget.extension.name),
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
                    widget.extension.description,
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: Colors.grey[600],
                    ),
                  ),
                ],
              ),
            ),
            Center( // Centrer le contenu
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 1200), // Largeur max pour grands écrans
                child: GridView.builder(
                  shrinkWrap: true, // Important pour le défilement global
                  physics: const NeverScrollableScrollPhysics(), // Désactiver le défilement de la grille
                  padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16), // Padding symétrique
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 3, // 3 cartes par ligne
                    childAspectRatio: 0.7, // Ratio ajusté après suppression du prix
                    crossAxisSpacing: 12, // Plus d'espacement pour centrer
                    mainAxisSpacing: 12,
                  ),
                  itemCount: filteredCards.length,
                  itemBuilder: (context, index) {
                    final card = filteredCards[index];
                    return _CardTile(
                      card: card,
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

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<int>(
      stream: _collectionService.getCardQuantityStream(widget.card.name),
      builder: (context, snapshot) {
        final int quantity = snapshot.data ?? 0;

        return Card(
          elevation: 2, // Ombre plus marquée
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
                        fit: BoxFit.contain, // Voir l'image entière
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
              
              // Contrôles de collection
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
                        onPressed: quantity > 0 ? () {
                          _collectionService.removeCard(widget.card.name);
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
                        onPressed: () {
                          _collectionService.addCard(widget.card.name);
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

  @override
  void initState() {
    super.initState();
    currentIndex = widget.initialIndex;
    _pageController = PageController(initialPage: widget.initialIndex);
    // Charger la collection au démarrage
    _collectionService.loadCollection();
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
            // Footer avec compteur, contrôles de collection et bouton fermer
            Container(
              padding: const EdgeInsets.all(16),
              child: Column(
                children: [
                  // Contrôles de collection
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
        final quantity = snapshot.data ?? 0;
        
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
                  ? () => _collectionService.removeCard(card.name)
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
                onPressed: () => _collectionService.addCard(card.name),
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
