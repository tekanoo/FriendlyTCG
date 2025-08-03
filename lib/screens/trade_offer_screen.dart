import 'package:flutter/material.dart';
import '../models/user_model.dart';
import '../services/trade_service_advanced.dart';
import '../widgets/card_tile_widget.dart';
import 'trade_chat_screen.dart';

class TradeOfferScreen extends StatefulWidget {
  final UserModel targetUser;
  final String wantedCard;

  const TradeOfferScreen({
    super.key,
    required this.targetUser,
    required this.wantedCard,
  });

  @override
  State<TradeOfferScreen> createState() => _TradeOfferScreenState();
}

class _TradeOfferScreenState extends State<TradeOfferScreen> {
  final TradeServiceAdvanced _tradeService = TradeServiceAdvanced();
  
  List<String> _availableCards = [];
  String? _selectedCard;
  bool _isLoading = true;
  bool _isCreatingTrade = false;

  @override
  void initState() {
    super.initState();
    _loadAvailableCards();
  }

  Future<void> _loadAvailableCards() async {
    try {
      final cards = await _tradeService.getCardsToOffer(widget.targetUser.uid);
      setState(() {
        _availableCards = cards;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Erreur lors du chargement: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _createTradeRequest() async {
    if (_selectedCard == null) return;

    setState(() {
      _isCreatingTrade = true;
    });

    try {
      final tradeId = await _tradeService.createTradeRequest(
        toUserId: widget.targetUser.uid,
        toUserName: widget.targetUser.displayName ?? widget.targetUser.email,
        wantedCard: widget.wantedCard,
        offeredCard: _selectedCard!,
      );

      if (tradeId != null && mounted) {
        // Naviguer vers l'écran de chat
        Navigator.of(context).pushReplacement(
          MaterialPageRoute(
            builder: (context) => TradeChatScreen(tradeId: tradeId),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Erreur lors de la création de l\'échange: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      setState(() {
        _isCreatingTrade = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Proposer un échange'),
        backgroundColor: Colors.blue.shade600,
        foregroundColor: Colors.white,
      ),
      body: Column(
        children: [
          _buildTradeInfo(),
          if (_isLoading)
            const Expanded(
              child: Center(child: CircularProgressIndicator()),
            )
          else if (_availableCards.isEmpty)
            const Expanded(
              child: Center(
                child: Text(
                  'Vous n\'avez aucune carte que cette personne ne possède pas.',
                  style: TextStyle(fontSize: 16),
                  textAlign: TextAlign.center,
                ),
              ),
            )
          else
            _buildCardSelection(),
        ],
      ),
      bottomNavigationBar: _selectedCard != null
          ? Container(
              padding: const EdgeInsets.all(16),
              child: ElevatedButton(
                onPressed: _isCreatingTrade ? null : _createTradeRequest,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.green,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                ),
                child: _isCreatingTrade
                    ? const Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                            ),
                          ),
                          SizedBox(width: 8),
                          Text('Création en cours...'),
                        ],
                      )
                    : const Text(
                        'Proposer cet échange',
                        style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                      ),
              ),
            )
          : null,
    );
  }

  Widget _buildTradeInfo() {
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
          Text(
            'Échange avec ${widget.targetUser.displayName ?? widget.targetUser.email}',
            style: const TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.2),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Row(
              children: [
                const Icon(Icons.star, color: Colors.yellow, size: 20),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'Vous voulez: ${widget.wantedCard.replaceAll('.png', '')}',
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 8),
          if (_selectedCard != null)
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.green.withValues(alpha: 0.3),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                children: [
                  const Icon(Icons.swap_horiz, color: Colors.white, size: 20),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'Vous offrez: ${_selectedCard!.replaceAll('.png', '')}',
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildCardSelection() {
    return Expanded(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Padding(
            padding: EdgeInsets.all(16),
            child: Text(
              'Choisissez une carte à offrir en échange:',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          Expanded(
            child: ListView.builder(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              itemCount: _availableCards.length,
              itemBuilder: (context, index) {
                final cardName = _availableCards[index];
                final cardDisplayName = cardName.replaceAll('.png', '');
                final isSelected = _selectedCard == cardName;
                
                return CardTileWidget(
                  cardName: cardDisplayName,
                  imagePath: 'assets/images/Gundam Cards/newtype_risings/$cardName',
                  isSelected: isSelected,
                  onTap: () {
                    setState(() {
                      _selectedCard = isSelected ? null : cardName;
                    });
                  },
                  subtitle: isSelected ? 'Sélectionnée pour l\'échange' : 'Tapez pour sélectionner',
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
