import 'package:flutter/material.dart';
import '../widgets/contact_dialog.dart';
import 'package:intl/intl.dart';
import 'package:flutter/services.dart' show rootBundle; // pour AssetManifest
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/marketplace_models.dart';
import '../services/marketplace_service.dart';
import '../services/collection_service.dart';
import '../services/conversation_service.dart';
import '../widgets/conversation_bubble.dart';
import 'dart:convert';

class MarketplaceScreen extends StatefulWidget {
  const MarketplaceScreen({super.key});

  @override
  State<MarketplaceScreen> createState() => _MarketplaceScreenState();
}

class _MarketplaceScreenState extends State<MarketplaceScreen> {
  final _service = MarketplaceService();
  final _conversationService = ConversationService();
  final _searchController = TextEditingController();
  RangeValues _priceRange = const RangeValues(0, 200); // euros
  String? _regionFilter;
  bool _showOnlyAvailable = false; // Par défaut: montrer toutes les cartes
  // Nouveau: catalogue complet
  bool _catalogLoading = true;
  final List<String> _allCards = [];
  final Map<String,String> _cardSet = {}; // cardName -> set
  final Map<String,String> _cardGame = {}; // cardName -> game (ex: gundam_card_game)
  String? _setFilter; // filtre extension
  String? _gameFilter; // filtre jeu
  String _sortField = 'name'; // 'name' | 'price'
  bool _sortAsc = true;

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  void initState() {
    super.initState();
    _loadCatalog();
  }

  Future<void> _loadCatalog() async {
    try {
      final manifestRaw = await rootBundle.loadString('AssetManifest.json');
      final Map<String, dynamic> manifestMap = manifestRaw.isNotEmpty
          ? Map<String, dynamic>.from(jsonDecode(manifestRaw) as Map)
          : {};
      void addCard(String path, String setName, String gameName) {
        if (!path.endsWith('.png')) return;
        final file = path.split('/').last;
        _cardSet[file] = setName;
        _cardGame[file] = gameName;
        if (!_allCards.contains(file)) _allCards.add(file);
      }
      for (final path in manifestMap.keys) {
        if (path.contains('assets/images/gundam_cards/newtype_risings/')) {
          addCard(path, 'newtype_risings', 'gundam_card_game');
        } else if (path.contains('assets/images/gundam_cards/edition_beta/')) {
          addCard(path, 'edition_beta', 'gundam_card_game');
        } else if (path.contains('assets/images/Pokemon/prismatic-evolutions/')) {
          addCard(path, 'prismatic-evolutions', 'pokemon_tcg');
        }
      }
      _allCards.sort((a,b)=> a.toLowerCase().compareTo(b.toLowerCase()));
    } catch (_) {}
    if (mounted) setState(()=> _catalogLoading = false);
  }

  @override
  Widget build(BuildContext context) {
    final isSmall = MediaQuery.of(context).size.width < 640;
    return Stack(children:[
      Column(
        children: [
          _buildFilters(isSmall),
          Expanded(
            child: _catalogLoading ? const Center(child: CircularProgressIndicator()) : StreamBuilder<List<MarketplaceListing>>(
              stream: _service.listenActiveListings(),
              builder: (context, snapshot) {
                if (snapshot.hasData) {
                  // Traitement des données sans variable inutilisée
                }
                final activeListings = snapshot.data ?? [];
                // Regrouper par carte
                final Map<String, List<MarketplaceListing>> byCard = {};
                for (final l in activeListings) {
                  (byCard[l.cardName] ??= []).add(l);
                }
                // Construire entrées catalogue
                final term = _searchController.text.trim().toLowerCase();
                final entries = <_CardEntry>[];
                Iterable<String> sourceCards = _allCards;
                if (term.isNotEmpty) {
                  sourceCards = sourceCards.where((c) => c.toLowerCase().contains(term));
                }
                for (final card in sourceCards) {
                  final listings = byCard[card] ?? [];
                  // Filtre set
                  if (_setFilter != null && _setFilter!.isNotEmpty) {
                    if ((_cardSet[card] ?? '') != _setFilter) continue;
                  }
                  // Filtre jeu
                  if (_gameFilter != null && _gameFilter!.isNotEmpty) {
                    if ((_cardGame[card] ?? '') != _gameFilter) continue;
                  }
                  // Filtre listings par région + statut
                  var filteredListings = listings;
                  if (_regionFilter != null && _regionFilter!.isNotEmpty) {
                    filteredListings = filteredListings.where((l) => l.sellerRegion == _regionFilter).toList();
                  }
                  filteredListings = filteredListings.where((l) => (l.priceCents/100) >= _priceRange.start && (l.priceCents/100) <= _priceRange.end).toList();
                  if (_showOnlyAvailable) {
                    filteredListings = filteredListings.where((l) => l.status == ListingStatus.active).toList();
                  }
                  if (_showOnlyAvailable && filteredListings.isEmpty) {
                    // on masque si demandé seulement disponibles ET aucune annonce active
                    continue;
                  }
                  final minPrice = filteredListings.where((l)=> l.listingType == ListingType.sale).map((l) => l.priceCents).fold<int?>(null, (prev, e) => prev==null? e : (e < prev ? e : prev)) ?? 0;
                  final bestBuy = filteredListings.where((l)=> l.listingType == ListingType.buy).map((l)=> l.priceCents).fold<int?>(null,(prev,e)=> prev==null? e : (e > prev ? e : prev)) ?? 0;
                  
                  if (card == 'GD01-001.png') { // Debug pour la carte testée
                  }
                  entries.add(_CardEntry(
                    cardName: card,
                    setName: _cardSet[card],
                    gameName: _cardGame[card],
                    listings: filteredListings,
                    minPriceCents: minPrice,
                    bestBuyCents: bestBuy,
                  ));
                }
                // Tri
                entries.sort((a,b){
                  int cmp;
                  if (_sortField == 'price') {
                    cmp = a.minPriceCents.compareTo(b.minPriceCents);
                    if (cmp == 0) cmp = a.cardName.toLowerCase().compareTo(b.cardName.toLowerCase());
                  } else { // name
                    cmp = a.cardName.toLowerCase().compareTo(b.cardName.toLowerCase());
                  }
                  return _sortAsc ? cmp : -cmp;
                });
                if (entries.isEmpty) {
                  return const Center(child: Text('Aucune carte')); // catalogue vide (ne devrait pas arriver)
                }
                final gridCount = isSmall ? 2 : 5;
                return GridView.builder(
                  padding: const EdgeInsets.all(12),
                  gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: gridCount,
                    childAspectRatio: 0.7,
                    mainAxisSpacing: 12,
                    crossAxisSpacing: 12,
                  ),
                  itemCount: entries.length,
                  itemBuilder: (context, i) => _CatalogCard(entry: entries[i], onTap: () => _openCardEntry(entries[i])),
                );
              },
            ),
          )
        ],
      ),
      // Bulle de conversations
      const ConversationBubble(),
    ]);
  }

  Widget _buildFilters(bool isSmall) {
    final children = <Widget>[
      Expanded(
        child: TextField(
          controller: _searchController,
          decoration: const InputDecoration(prefixIcon: Icon(Icons.search), hintText: 'Nom de la carte'),
          onChanged: (_) => setState(() {}),
        ),
      ),
      const SizedBox(width: 12),
      // Filtre jeu
      DropdownButton<String>(
        value: _gameFilter,
        hint: const Text('Jeu'),
        items: const [
          DropdownMenuItem(value: '', child: Text('Tous jeux')),
          DropdownMenuItem(value: 'gundam_card_game', child: Text('Gundam')),
          // Pokémon désactivé pour le moment
        ],
        onChanged: (v)=> setState(()=> _gameFilter = (v!=null && v.isEmpty) ? null : v),
      ),
      const SizedBox(width: 12),
      // Filtre set
      DropdownButton<String>(
        value: _setFilter,
        hint: const Text('Set'),
        items: [
          const DropdownMenuItem(value: '', child: Text('Tous')),
          const DropdownMenuItem(value: 'newtype_risings', child: Text('Newtype Risings')),
          const DropdownMenuItem(value: 'edition_beta', child: Text('Edition Beta')),
          // Option Pokémon retirée
        ],
        onChanged: (v) => setState(()=> _setFilter = (v!=null && v.isEmpty) ? null : v),
      ),
      const SizedBox(width: 12),
      SizedBox(
        width: 160,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Prix (€)', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600)),
            RangeSlider(
              min: 0,
              max: 500,
              divisions: 100,
              values: _priceRange,
              labels: RangeLabels(_priceRange.start.toStringAsFixed(0), _priceRange.end.toStringAsFixed(0)),
              onChanged: (v) => setState(() => _priceRange = v),
            ),
          ],
        ),
      ),
      const SizedBox(width: 12),
      DropdownButton<String>(
        value: _regionFilter,
        hint: const Text('Région'),
        items: const [
          DropdownMenuItem(value: 'Île-de-France', child: Text('Île-de-France')),
          DropdownMenuItem(value: 'Occitanie', child: Text('Occitanie')),
          DropdownMenuItem(value: 'Grand Est', child: Text('Grand Est')),
        ],
        onChanged: (v) => setState(() => _regionFilter = v),
      ),
      const SizedBox(width: 12),
      Row(children: [
        const Text('Disponibles'),
        Switch(value: _showOnlyAvailable, onChanged: (v) => setState(() => _showOnlyAvailable = v)),
      ]),
      const SizedBox(width: 12),
      // Tri
      DropdownButton<String>(
        value: _sortField == 'name' ? 'name' : (_sortField == 'price' ? 'price' : 'name'),
        items: const [
          DropdownMenuItem(value: 'name', child: Text('Tri: Nom')),
          DropdownMenuItem(value: 'price', child: Text('Tri: Prix')),
        ],
        onChanged: (v){ if (v==null) return; setState(()=> _sortField = v); },
      ),
      IconButton(
        tooltip: 'Inverser ordre',
        onPressed: () => setState(()=> _sortAsc = !_sortAsc),
        icon: Icon(_sortAsc ? Icons.arrow_downward : Icons.arrow_upward),
      ),
      IconButton(
        icon: const Icon(Icons.refresh),
        tooltip: 'Réinitialiser',
        onPressed: () => setState(() {
          _searchController.clear();
          _priceRange = const RangeValues(0, 200);
          _regionFilter = null;
          _showOnlyAvailable = false;
          _setFilter = null;
          _gameFilter = null;
          _sortField = 'name';
          _sortAsc = true;
        }),
      )
    ];

    return Padding(
      padding: const EdgeInsets.all(8.0),
      child: isSmall
          ? Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(children: [Expanded(child: children[0]), children[6]]),
                const SizedBox(height: 8),
                children[1],
                const SizedBox(height: 8),
                Wrap(spacing: 12, runSpacing: 8, children: [children[3], children[5]]),
              ],
            )
          : Row(children: children),
    );
  }

  void _openListing(MarketplaceListing listing) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (ctx) => DraggableScrollableSheet(
        expand: false,
        initialChildSize: 0.85,
        builder: (c, scroll) => _ListingDetail(listing: listing, scrollController: scroll),
      ),
    );
  }

  void _openCardEntry(_CardEntry entry) {
    // Permettre l'ouverture même sans annonces pour voir l'historique
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (ctx) => DraggableScrollableSheet(
        expand: false,
        initialChildSize: 0.7,
        builder: (c, scroll) => _CardListingsSheet(
          entry: entry, 
          onOpenListing: _openListing, 
          onCreateListing: () => _openCreateListing(),
          scrollController: scroll,
          onDeleteListing: _deleteListing,
          onHandleListingTap: _handleListingTap,
        ),
      ),
    );
  }

  void _openCreateListing() {
    showDialog(context: context, builder: (ctx)=> const _CreateListingDialog());
  }

  Future<void> _deleteListing(MarketplaceListing listing) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Supprimer l\'annonce'),
        content: Text('Voulez-vous vraiment supprimer cette ${listing.listingType == ListingType.sale ? 'vente' : 'offre d\'achat'} ?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Annuler'),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('Supprimer', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );

    if (confirm == true) {
      try {
        await _service.deleteListing(listing.id);
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Annonce supprimée avec succès')),
          );
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Erreur lors de la suppression: $e')),
          );
        }
      }
    }
  }

  void _handleListingTap(MarketplaceListing listing) {
    final currentUserId = FirebaseAuth.instance.currentUser?.uid;
    
    // Empêcher l'interaction avec ses propres listings
    if (currentUserId == listing.sellerId) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Vous ne pouvez pas interagir avec votre propre annonce')),
        );
      }
      return;
    }
    
    if (listing.listingType == ListingType.sale) {
      // Pour une vente : proposer un prix
      _showPriceOfferDialog(listing);
    } else {
      // Pour un achat : envoyer un message
      _showMessageDialog(listing);
    }
  }

  void _showPriceOfferDialog(MarketplaceListing listing) {
    final priceController = TextEditingController();
    
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Proposer un prix pour ${listing.cardName.replaceAll('.png', '')}'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Prix demandé: ${(listing.priceCents / 100).toStringAsFixed(2)}€'),
            const SizedBox(height: 16),
            TextField(
              controller: priceController,
              decoration: const InputDecoration(
                labelText: 'Votre offre (€)',
                border: OutlineInputBorder(),
              ),
              keyboardType: TextInputType.number,
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Annuler'),
          ),
          ElevatedButton(
            onPressed: () async {
              final priceText = priceController.text.trim();
              if (priceText.isEmpty) return;
              
              final price = double.tryParse(priceText);
              if (price == null || price <= 0) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Prix invalide')),
                );
                return;
              }
              
              final priceCents = (price * 100).round();
              final message = 'Je propose ${price.toStringAsFixed(2)}€ pour cette carte.';
              
              Navigator.of(context).pop();
              
              try {
                final conversationId = await _conversationService.createPriceOfferConversation(
                  listing: listing,
                  proposedPriceCents: priceCents,
                  initialMessage: message,
                );
                
                if (conversationId != null && mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Offre envoyée !')),
                  );
                } else if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Erreur lors de l\'envoi')),
                  );
                }
              } catch (e) {
                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('Erreur: $e')),
                  );
                }
              }
            },
            child: const Text('Envoyer l\'offre'),
          ),
        ],
      ),
    );
  }

  void _showMessageDialog(MarketplaceListing listing) {
    showDialog(
      context: context,
      builder: (context) => ContactDialog(
        title: 'Contacter ${listing.sellerName}',
        offerText: 'Offre d\'achat: ${(listing.priceCents / 100).toStringAsFixed(2)}€',
        cardText: 'Pour: ${listing.cardName.replaceAll('.png', '')}',
        onSend: (message) async {
          try {
            final conversationId = await _conversationService.createBuyInquiryConversation(
              listing: listing,
              initialMessage: message,
            );
            if (conversationId != null && mounted) {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Message envoyé !')),
              );
            } else if (mounted) {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Erreur lors de l\'envoi')),
              );
            }
          } catch (e) {
            if (mounted) {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Erreur lors de l\'envoi')),
              );
            }
          }
        },
      ),
    );
  }
}

class _CardEntry {
  final String cardName;
  final String? setName;
  final String? gameName;
  final List<MarketplaceListing> listings;
  final int minPriceCents;
  final int bestBuyCents; // meilleure offre (listing de type buy)
  _CardEntry({required this.cardName, required this.setName, required this.gameName, required this.listings, required this.minPriceCents, required this.bestBuyCents});
}

class _CatalogCard extends StatelessWidget {
  final _CardEntry entry; final VoidCallback onTap;
  const _CatalogCard({required this.entry, required this.onTap});
  @override
  Widget build(BuildContext context) {
    final price = (entry.minPriceCents / 100).toStringAsFixed(2);
    final bestBuy = (entry.bestBuyCents / 100).toStringAsFixed(2);
    final hasListings = entry.listings.isNotEmpty;
    final activeSale = entry.listings.where((l)=> l.listingType==ListingType.sale && l.status==ListingStatus.active).length;
    final activeBuy = entry.listings.where((l)=> l.listingType==ListingType.buy && l.status==ListingStatus.active).length;
    final collectionService = CollectionService();
    final baseName = entry.cardName.replaceAll('.png','');
    final isPokemon = baseName.startsWith('SV') || baseName.contains('_FR_');
    final owned = isPokemon
      ? collectionService.getTotalCardQuantity(baseName)
      : collectionService.getCardQuantity(baseName);
    return InkWell(
      onTap: onTap,
      child: Card(
        elevation: 1,
        child: Padding(
          padding: const EdgeInsets.all(8),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children:[
              Expanded(
                flex: 3,
                child: Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(4),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(8),
                    child: _buildCardImage(entry.cardName),
                  ),
                ),
              ),
              const SizedBox(height:6),
              Text(entry.cardName.replaceAll('.png',''), textAlign: TextAlign.center, style: const TextStyle(fontSize:10), maxLines: 2, overflow: TextOverflow.ellipsis),
              const SizedBox(height:4),
              Text(hasListings ? 'dès $price €' : '0 €', style: TextStyle(fontWeight: FontWeight.bold, color: hasListings ? Colors.black : Colors.grey.shade600)),
              if (entry.bestBuyCents > 0) Text('Offre: $bestBuy €', style: const TextStyle(fontSize:10, color: Colors.black54)),
              const SizedBox(height:2),
              Row(children:[
                if (activeSale>0) _badge('${activeSale}V', Colors.green.shade600),
                if (activeBuy>0) Padding(padding: const EdgeInsets.only(left:4), child: _badge('${activeBuy}R', Colors.indigo.shade500)),
                Padding(
                  padding: const EdgeInsets.only(left:4),
                  child: _badge('x$owned', owned > 0 ? Colors.blue.shade600 : Colors.red.shade400),
                ),
              ]),
              if (entry.setName!=null) Text(entry.setName!, style: const TextStyle(fontSize:8, color: Colors.grey)),
            ],
          ),
        ),
      ),
    );
  }
  
  Widget _buildCardImage(String fileName) {
    // Heuristique simple: essayer chemins principaux connus; fallback icône
    final baseNameVariantStripped = fileName.replaceAll(RegExp(r'_Variante_P\d+'), '');
    final candidates = [
      'assets/images/gundam_cards/newtype_risings/$fileName',
      // fallback même dossier sans suffixe variante
      if (baseNameVariantStripped != fileName)
        'assets/images/gundam_cards/newtype_risings/$baseNameVariantStripped',
      'assets/images/gundam_cards/edition_beta/$fileName',
      if (baseNameVariantStripped != fileName)
        'assets/images/gundam_cards/edition_beta/$baseNameVariantStripped',
      'assets/images/Pokemon/prismatic-evolutions/$fileName',
      if (baseNameVariantStripped != fileName)
        'assets/images/Pokemon/prismatic-evolutions/$baseNameVariantStripped',
    ];

    Widget buildChain(int index) {
      if (index >= candidates.length) {
        return Container(
          width: double.infinity,
          height: double.infinity,
          color: Colors.grey.shade200,
          child: const Icon(Icons.image_not_supported, size: 40, color: Colors.grey),
        );
      }
      return Image.asset(
        candidates[index],
        fit: BoxFit.cover,
        width: double.infinity,
        height: double.infinity,
        errorBuilder: (_, __, ___) => buildChain(index+1),
      );
    }

    return buildChain(0);
  }
  
  Widget _badge(String text, Color color) => Container(
    padding: const EdgeInsets.symmetric(horizontal:6, vertical:2),
    decoration: BoxDecoration(color: color, borderRadius: BorderRadius.circular(6)),
    child: Text(text, style: const TextStyle(color: Colors.white, fontSize:10, fontWeight: FontWeight.w600)),
  );
}

class _CardListingsSheet extends StatelessWidget {
  final _CardEntry entry; 
  final void Function(MarketplaceListing) onOpenListing; 
  final VoidCallback onCreateListing;
  final ScrollController scrollController;
  final void Function(MarketplaceListing)? onDeleteListing;
  final void Function(MarketplaceListing)? onHandleListingTap;
  
  const _CardListingsSheet({
    required this.entry, 
    required this.onOpenListing, 
    required this.onCreateListing,
    required this.scrollController,
    this.onDeleteListing,
    this.onHandleListingTap,
  });
  @override
  Widget build(BuildContext context) {
    final listings = entry.listings;
    
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children:[
          Row(
            children: [
              SizedBox(
                width: 60,
                height: 80,
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(8),
                  child: _buildDetailCardImage(entry.cardName),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(entry.cardName.replaceAll('.png',''), style: const TextStyle(fontSize:18,fontWeight: FontWeight.bold)),
                    if (entry.setName != null) Text(entry.setName!, style: const TextStyle(fontSize:12, color: Colors.grey)),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height:12),
          if (listings.isEmpty) 
            const Expanded(
              child: Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text('Aucune annonce pour cette carte'),
                    SizedBox(height: 16),
                    Text('Cliquez sur le bouton ci-dessous pour créer la première !'),
                  ],
                ),
              ),
            )
          else
            Expanded(
              child: ListView.builder(
                controller: scrollController,
                itemCount: listings.length,
                itemBuilder: (c,i){
                  final l = listings[i];
                  final price = (l.priceCents/100).toStringAsFixed(2);
                  final currentUserId = FirebaseAuth.instance.currentUser?.uid;
                  final isMyListing = l.sellerId == currentUserId;
                  
                  return ListTile(
                    title: Text('${l.listingType==ListingType.buy? 'Recherche':'Vente'} • $price €'),
                    subtitle: Text(l.sellerRegion ?? '-'),
                    trailing: isMyListing ? 
                      IconButton(
                        icon: const Icon(Icons.delete, color: Colors.red),
                        onPressed: onDeleteListing != null ? () => onDeleteListing!(l) : null,
                      ) : 
                      Icon(l.listingType == ListingType.sale ? Icons.shopping_cart : Icons.message),
                    onTap: isMyListing ? null : () => onHandleListingTap?.call(l),
                  );
                },
              ),
            ),
          // Bouton toujours présent pour créer une annonce
          const Divider(),
          Padding(
            padding: const EdgeInsets.all(16),
            child: SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: () {
                  Navigator.of(context).pop(); // Fermer le sheet
                  onCreateListing(); // Utiliser la callback
                },
                icon: const Icon(Icons.add),
                label: const Text('Créer une annonce'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.blue,
                  foregroundColor: Colors.white,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
  
  Widget _buildDetailCardImage(String fileName) {
    // Heuristique simple: essayer chemins principaux connus; fallback icône
    final baseNameVariantStripped = fileName.replaceAll(RegExp(r'_Variante_P\d+'), '');
    final candidates = [
      'assets/images/gundam_cards/newtype_risings/$fileName',
      // fallback même dossier sans suffixe variante
      if (baseNameVariantStripped != fileName)
        'assets/images/gundam_cards/newtype_risings/$baseNameVariantStripped',
      'assets/images/gundam_cards/edition_beta/$fileName',
      if (baseNameVariantStripped != fileName)
        'assets/images/gundam_cards/edition_beta/$baseNameVariantStripped',
      'assets/images/Pokemon/prismatic-evolutions/$fileName',
      if (baseNameVariantStripped != fileName)
        'assets/images/Pokemon/prismatic-evolutions/$baseNameVariantStripped',
    ];

    Widget buildChain(int index) {
      if (index >= candidates.length) {
        return Container(
          width: double.infinity,
          height: double.infinity,
          color: Colors.grey.shade200,
          child: const Icon(Icons.image_not_supported, size: 30, color: Colors.grey),
        );
      }
      return Image.asset(
        candidates[index],
        fit: BoxFit.cover,
        width: double.infinity,
        height: double.infinity,
        errorBuilder: (_, __, ___) => buildChain(index+1),
      );
    }

    return buildChain(0);
  }
}

class _ListingDetail extends StatefulWidget {
  final MarketplaceListing listing;
  final ScrollController scrollController;
  const _ListingDetail({required this.listing, required this.scrollController});

  @override
  State<_ListingDetail> createState() => _ListingDetailState();
}

class _ListingDetailState extends State<_ListingDetail> {
  final _service = MarketplaceService();
  final _conversationService = ConversationService();
  final _offerController = TextEditingController();
  final _messageController = TextEditingController();
  List<int> _historical = [];
  bool _loadingHistory = true;

  @override
  void initState() {
    super.initState();
    _loadHistory();
  }

  Future<void> _loadHistory() async {
    final data = await _service.getHistoricalPrices(widget.listing.cardName);
    if (mounted) {
      setState(() {
        _historical = data;
        _loadingHistory = false;
      });
    }
  }

  @override
  void dispose() {
    _offerController.dispose();
    _messageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final price = (widget.listing.priceCents / 100).toStringAsFixed(2);

    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(child: Text(widget.listing.cardName.replaceAll('.png', ''), style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold))),
              Chip(label: Text(widget.listing.sellerRegion ?? 'Région inconnue')),
            ],
          ),
          Text('Prix actuel: $price €'),
          const SizedBox(height: 8),
          _loadingHistory ? const LinearProgressIndicator() : _buildHistoryChart(),
          const SizedBox(height: 12),
          _buildOffersSection(),
          const SizedBox(height: 12),
          _buildMessagesSection(),
        ],
      ),
    );
  }

  Widget _buildHistoryChart() {
    if (_historical.isEmpty) {
      return const Text('Pas encore d\'historique de vente');
    }
  final f = NumberFormat.simpleCurrency(locale: 'fr_FR', name: '€');
    final min = _historical.reduce((a, b) => a < b ? a : b);
    final max = _historical.reduce((a, b) => a > b ? a : b);
    return SizedBox(
      height: 120,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: _historical.map((p) {
          final h = max == min ? 1.0 : (p - min) / (max - min);
          return Expanded(
            child: Container(
              margin: const EdgeInsets.symmetric(horizontal: 2),
              height: 20 + h * 100,
              color: Colors.blue.shade400,
              child: Tooltip(message: f.format(p / 100)),
            ),
          );
        }).toList(),
      ),
    );
  }

  Widget _buildOffersSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('Offres', style: TextStyle(fontWeight: FontWeight.bold)),
        StreamBuilder<List<ListingOffer>>(
          stream: _service.listenListingOffers(widget.listing.id),
          builder: (context, snapshot) {
            final offers = snapshot.data ?? [];
            return Column(children: [
              for (final o in offers)
                _OfferTile(offer: o, listing: widget.listing, service: _service),
              if (widget.listing.status == ListingStatus.active)
                Row(children:[
                  Expanded(child: TextField(
                    controller: _offerController,
                    decoration: const InputDecoration(hintText: 'Proposer un prix (€)'),
                    keyboardType: TextInputType.number,
                  )),
                  IconButton(icon: const Icon(Icons.send), onPressed: _submitOffer)
                ])
              else
                _buildValidationRow(),
            ]);
          },
        ),
      ],
    );
  }

  Widget _buildMessagesSection() {
    return Expanded(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Messages (chiffrés côté serveur)', style: TextStyle(fontWeight: FontWeight.bold)),
          Expanded(
            child: StreamBuilder<List<MarketplaceMessage>>(
              stream: _service.listenMessages(widget.listing.id),
              builder: (context, snapshot) {
                final msgs = snapshot.data ?? [];
        return ListView.builder(
                  controller: widget.scrollController,
                  itemCount: msgs.length,
                  itemBuilder: (c, i) {
                    final m = msgs[i];
                    return ListTile(
                      dense: true,
                      leading: m.isSystem ? const Icon(Icons.info, color: Colors.orange) : const Icon(Icons.person),
          title: Text(m.senderName),
          subtitle: Text(m.cipherText.length > 16 ? '...${m.cipherText.substring(m.cipherText.length-16)}' : m.cipherText),
                    );
                  },
                );
              },
            ),
          ),
          Row(
            children: [
              Expanded(
                child: TextField(
                  controller: _messageController,
                  decoration: const InputDecoration(hintText: 'Message'),
                  onSubmitted: (_) => _sendMessage(),
                ),
              ),
              IconButton(
                icon: const Icon(Icons.lock),
                onPressed: _sendMessage,
              )
            ],
          )
        ],
      ),
    );
  }

  Future<void> _submitOffer() async {
    final text = _offerController.text.trim();
    if (text.isEmpty) return;
    final value = double.tryParse(text.replaceAll(',', '.'));
    if (value == null) return;
    await _service.createOffer(listingId: widget.listing.id, proposedPriceCents: (value * 100).round());
    _offerController.clear();
  }

  Future<void> _sendMessage() async {
    final text = _messageController.text.trim();
    if (text.isEmpty) return;
    
    // Vérifier si c'est le propre listing de l'utilisateur
    final currentUserId = FirebaseAuth.instance.currentUser?.uid;
    if (currentUserId == widget.listing.sellerId) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Vous ne pouvez pas envoyer un message sur votre propre annonce')),
        );
      }
      return;
    }
    
    try {
      // Créer une conversation si c'est un message sur un listing
      String? conversationId;
      
      if (widget.listing.listingType == ListingType.sale) {
        // Pour une vente, créer une conversation d'offre de prix avec prix 0 (simple message)
        conversationId = await _conversationService.createBuyInquiryConversation(
          listing: widget.listing,
          initialMessage: text,
        );
      } else {
        // Pour un achat, créer une conversation de demande d'achat
        conversationId = await _conversationService.createBuyInquiryConversation(
          listing: widget.listing,
          initialMessage: text,
        );
      }
      
      if (conversationId != null) {
        _messageController.clear();
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Message envoyé ! Conversation créée.')),
          );
        }
      } else {
        // Fallback vers l'ancien système
        await _service.sendMessage(widget.listing.id, text);
        _messageController.clear();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Erreur: ${e.toString()}')),
        );
      }
      // Fallback vers l'ancien système en cas d'erreur
      try {
        await _service.sendMessage(widget.listing.id, text);
        _messageController.clear();
      } catch (e2) {
      }
    }
  }

  Widget _buildValidationRow() {
    final l = widget.listing;
    if (l.status != ListingStatus.reserved && l.status != ListingStatus.sold) return const SizedBox.shrink();
    return FutureBuilder<void>(
      future: Future.value(),
      builder: (c, _) {
        return Row(children:[
          Chip(label: Text('Vendeur ${l.sellerValidated ? '✔' : '—'}')),
          const SizedBox(width:8),
            Chip(label: Text('Acheteur ${l.buyerValidated ? '✔' : '—'}')),
          const SizedBox(width:12),
          if (l.status != ListingStatus.sold)
            ElevatedButton.icon(onPressed: ()=> _service.validateListing(l.id), icon: const Icon(Icons.verified), label: const Text('Valider')),
          if (l.status == ListingStatus.sold) const Text('Vente conclue', style: TextStyle(fontWeight: FontWeight.bold))
        ]);
      },
    );
  }
}

class _OfferTile extends StatelessWidget {
  final ListingOffer offer; final MarketplaceListing listing; final MarketplaceService service;
  const _OfferTile({required this.offer, required this.listing, required this.service});
  @override
  Widget build(BuildContext context) {
    final price = (offer.proposedPriceCents/100).toStringAsFixed(2);
    return ListTile(
      dense: true,
      title: Row(children:[
        Expanded(child: Text('${offer.buyerName} • $price €')),
        if (offer.status == OfferStatus.accepted)
          const Padding(
            padding: EdgeInsets.only(left:4),
            child: Icon(Icons.chat_bubble, color: Colors.blue, size:16),
          ),
      ]),
      subtitle: Text(_statusLabel(offer.status)),
      trailing: _buildActions(context),
    );
  }
  String _statusLabel(OfferStatus s) {
    switch(s){
      case OfferStatus.accepted: return 'acceptée (discussion)';
      case OfferStatus.declined: return 'refusée';
      case OfferStatus.withdrawn: return 'retirée';
      default: return 'en attente';
    }
  }
  Widget? _buildActions(BuildContext context) {
    final discussionLocked = listing.status == ListingStatus.reserved && listing.buyerId != null && listing.buyerId != offer.buyerId;
    if (offer.status == OfferStatus.pending && !discussionLocked) {
      return Wrap(spacing:4, children:[
        IconButton(icon: const Icon(Icons.check, color: Colors.green), tooltip: 'Accepter', onPressed: ()=> service.acceptOffer(offerId: offer.id)),
        IconButton(icon: const Icon(Icons.close, color: Colors.red), tooltip: 'Refuser', onPressed: ()=> service.declineOffer(offerId: offer.id)),
      ]);
    }
    return null;
  }
}

class _CreateListingDialog extends StatefulWidget {
  const _CreateListingDialog();
  @override
  State<_CreateListingDialog> createState() => _CreateListingDialogState();
}

class _CreateListingDialogState extends State<_CreateListingDialog> {
  final _priceController = TextEditingController();
  String? _selectedCard;
  Map<String,int> _owned = {};
  bool _loading = true; bool _creating = false;
  final _service = MarketplaceService();
  ListingType _type = ListingType.sale;
  String? _selectedSet; // extension filtrée
  final Map<String,String> _cardSet = {}; // cardName -> set

  @override
  void initState() { super.initState(); _load(); }
  Future<void> _load() async {
    // Charger toutes les cartes possibles depuis structuredCards (si dispo) + quantités depuis cards
    final fs = FirebaseFirestore.instance; final auth = FirebaseAuth.instance.currentUser; if (auth==null) return;
  final snap = await fs.collection('users').doc(auth.uid).get();
  final data = snap.data() ?? {};
    final rawCardsDynamic = Map<String, dynamic>.from(data['cards'] ?? {});
    final counts = <String,int>{ for (final e in rawCardsDynamic.entries) e.key : (e.value is int ? e.value as int : 0) };
    // Récupération structuredCards.gundam_card_game.* (ex: newtype_risings, edition_beta)
    final structuredRoot = data['structuredCards'];
    if (structuredRoot is Map) {
      final gundam = structuredRoot['gundam_card_game'];
      if (gundam is Map) {
        for (final setEntry in gundam.entries) {
          if (setEntry.value is Map) {
            final setMap = Map<String, dynamic>.from(setEntry.value as Map);
            for (final cardName in setMap.keys) {
              counts.putIfAbsent(cardName, () => (setMap[cardName] is int ? setMap[cardName] as int : 0));
              _cardSet[cardName] = setEntry.key.toString();
            }
          }
        }
      }
    }
    // Ajouter toutes les cartes existantes à partir de l'AssetManifest (inclure même quantité 0)
    try {
      final manifestRaw = await rootBundle.loadString('AssetManifest.json');
      // Le manifest est un JSON map<String, dynamic>
      final Map<String, dynamic> manifestMap = manifestRaw.isNotEmpty
          ? Map<String, dynamic>.from(jsonDecode(manifestRaw) as Map)
          : {};
      // Filtrer les chemins pertinents
      for (final path in manifestMap.keys) {
        if (!path.endsWith('.png')) continue;
        if (path.contains('assets/images/gundam_cards/newtype_risings/') ||
            path.contains('assets/images/gundam_cards/edition_beta/') ||
            path.contains('assets/images/Pokemon/prismatic-evolutions/')) {
          final file = path.split('/').last;
          counts.putIfAbsent(file, () => 0);
          // Assigner set si c'est Gundam
          if (path.contains('newtype_risings')) {
            _cardSet[file] = 'newtype_risings';
          } else if (path.contains('edition_beta')) {
            _cardSet[file] = 'edition_beta';
          }
        }
      }
    } catch (_) {
      // Silencieux: si échec, on garde seulement counts utilisateur
    }
    final sortedKeys = counts.keys.toList()..sort((a,b)=> a.toLowerCase().compareTo(b.toLowerCase()));
    _owned = { for (final k in sortedKeys) k : counts[k]! };
    setState(() { _loading=false;});
  }
  @override
  void dispose(){ _priceController.dispose(); super.dispose(); }
  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Nouvelle annonce'),
      content: _loading ? const SizedBox(height:80, child: Center(child:CircularProgressIndicator())) : SizedBox(width:420, child: Column(mainAxisSize: MainAxisSize.min, children:[
        DropdownButtonFormField<String>(
          value: _selectedSet,
          decoration: const InputDecoration(labelText: 'Extension'),
          items: [
            const DropdownMenuItem(value: null, child: Text('Toutes')),
            // Forcer les deux sets Gundam même si aucune carte possédée
            ...({ 'newtype_risings', 'edition_beta', ..._cardSet.values }.toList()..sort()).map((s)=> DropdownMenuItem(value: s, child: Text(s)))
          ],
          onChanged: (v){
            setState(() {
              _selectedSet = v;
              if (_selectedCard != null && _selectedSet != null && _cardSet[_selectedCard!] != _selectedSet) {
                _selectedCard = null;
              }
            });
          },
        ),
        const SizedBox(height:12),
        Row(children:[
          Expanded(child: DropdownButtonFormField<String>(
            value: _selectedCard,
            items: _owned.keys.where((c){
              if (_selectedSet == null) return true;
              return _cardSet[c] == _selectedSet;
            }).map((c){
              final qty = _owned[c] ?? 0;
              return DropdownMenuItem(
                value:c,
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children:[
                    _CardThumb(fileName: c),
                    const SizedBox(width:8),
                    Flexible(
                      fit: FlexFit.loose,
                      child: Text(c.replaceAll('.png',''), overflow: TextOverflow.ellipsis),
                    ),
                    const SizedBox(width:6),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal:6, vertical:2),
                      decoration: BoxDecoration(
                        color: qty>0 ? Colors.blue.shade600 : Colors.grey.shade500,
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Text('x$qty', style: const TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.w600)),
                    )
                  ],
                ),
              );
            }).toList(),
            onChanged: (v)=> setState(()=> _selectedCard=v),
            decoration: const InputDecoration(labelText: 'Carte'),
          )),
        ]),
        const SizedBox(height:12),
        TextFormField(
          controller: _priceController,
          decoration: const InputDecoration(labelText: 'Prix (€)'),
          keyboardType: TextInputType.number,
        ),
        const SizedBox(height:12),
        Row(children:[
          Expanded(child: RadioListTile<ListingType>(
            value: ListingType.sale,
            groupValue: _type,
            dense: true,
            title: const Text('Vente'),
            onChanged: (v)=> setState(()=> _type = v!),
          )),
          Expanded(child: RadioListTile<ListingType>(
            value: ListingType.buy,
            groupValue: _type,
            dense: true,
            title: const Text('Recherche (offre)'),
            onChanged: (v)=> setState(()=> _type = v!),
          )),
        ])
      ])),
      actions: [
        TextButton(onPressed: _creating? null : ()=> Navigator.pop(context), child: const Text('Annuler')),
        ElevatedButton(onPressed: _creating? null : _create, child: _creating? const SizedBox(width:16,height:16,child:CircularProgressIndicator(strokeWidth:2)) : const Text('Publier')),
      ],
    );
  }
  Future<void> _create() async {
    if (_selectedCard==null) return; 
    final qty = _owned[_selectedCard] ?? 0;
    
    if (_type == ListingType.sale && qty <= 0) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Impossible de vendre: quantité 0.')));
      }
      return;
    }
    final v = double.tryParse(_priceController.text.replaceAll(',','.'));
    if (v==null || v <= 0) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Prix invalide.')));
      }
      return;
    }
    setState(()=> _creating=true);
    
    final listingId = await _service.createListing(cardName: _selectedCard!, priceCents: (v*100).round(), type: _type);
    
    if (mounted) { 
      Navigator.pop(context);
      if (listingId != null) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Annonce créée avec succès !')),
        );
        // Petite attente pour synchronisation Firestore puis refresh
        await Future.delayed(const Duration(milliseconds: 1000)); // Augmenté à 1s
        if (mounted) setState(() {}); // Force rebuild pour actualiser
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Erreur lors de la création de l\'annonce')),
        );
      }
    }
  }
}

class _CardThumb extends StatelessWidget {
  final String fileName; const _CardThumb({required this.fileName});
  @override
  Widget build(BuildContext context) {
    // Heuristique simple: essayer chemins principaux connus; fallback icône
    final baseNameVariantStripped = fileName.replaceAll(RegExp(r'_Variante_P\d+'), '');
    final candidates = [
      'assets/images/gundam_cards/newtype_risings/$fileName',
      // fallback même dossier sans suffixe variante
      if (baseNameVariantStripped != fileName)
        'assets/images/gundam_cards/newtype_risings/$baseNameVariantStripped',
      'assets/images/gundam_cards/edition_beta/$fileName',
      if (baseNameVariantStripped != fileName)
        'assets/images/gundam_cards/edition_beta/$baseNameVariantStripped',
      'assets/images/Pokemon/prismatic-evolutions/$fileName',
      if (baseNameVariantStripped != fileName)
        'assets/images/Pokemon/prismatic-evolutions/$baseNameVariantStripped',
    ];

    Widget buildChain(int index) {
      if (index >= candidates.length) {
        return const Icon(Icons.image_not_supported, size:20);
      }
      return Image.asset(
        candidates[index],
        fit: BoxFit.cover,
        errorBuilder: (_, __, ___) => buildChain(index+1),
      );
    }

    return SizedBox(
      width: 32, 
      height: 44, 
      child: ClipRRect(
        borderRadius: BorderRadius.circular(4), 
        child: buildChain(0)
      )
    );
  }
}
