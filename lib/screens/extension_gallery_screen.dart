import 'package:flutter/material.dart';
import '../models/extension_model.dart';
import '../services/extension_service.dart';

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
      body: Column(
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
          Expanded(
            child: GridView.builder(
              padding: const EdgeInsets.all(16),
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 3,
                childAspectRatio: 0.7,
                crossAxisSpacing: 8,
                mainAxisSpacing: 8,
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

class _CardTile extends StatelessWidget {
  final CardModel card;
  final VoidCallback onTap;

  const _CardTile({
    required this.card,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Card(
        elevation: 2,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Expanded(
              child: ClipRRect(
                borderRadius: const BorderRadius.vertical(top: Radius.circular(4)),
                child: Image.asset(
                  card.imagePath,
                  fit: BoxFit.cover,
                  errorBuilder: (context, error, stackTrace) {
                    return Container(
                      color: Colors.grey[200],
                      child: const Icon(
                        Icons.image_not_supported,
                        color: Colors.grey,
                      ),
                    );
                  },
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(4.0),
              child: Text(
                card.displayName,
                style: Theme.of(context).textTheme.bodySmall,
                textAlign: TextAlign.center,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
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
      child: Container(
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
            // Footer avec compteur et bouton fermer
            Container(
              padding: const EdgeInsets.all(16),
              child: Row(
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
            ),
          ],
        ),
      ),
    );
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }
}
