import 'package:flutter/material.dart';
import '../models/user_with_location.dart';
import '../services/trade_service_advanced.dart';
import 'trade_chat_screen.dart';

class SimpleConversationScreen extends StatefulWidget {
  final UserWithLocation targetUser;
  final String cardOfInterest;

  const SimpleConversationScreen({
    super.key,
    required this.targetUser,
    required this.cardOfInterest,
  });

  @override
  State<SimpleConversationScreen> createState() => _SimpleConversationScreenState();
}

class _SimpleConversationScreenState extends State<SimpleConversationScreen> {
  final TradeServiceAdvanced _tradeService = TradeServiceAdvanced();
  bool _isCreatingConversation = false;

  Future<void> _createConversation() async {
    setState(() {
      _isCreatingConversation = true;
    });

    try {
      final conversationId = await _tradeService.createSimpleConversation(
        toUserId: widget.targetUser.uid,
        toUserName: widget.targetUser.displayName ?? widget.targetUser.email,
        cardOfInterest: widget.cardOfInterest,
      );

      if (conversationId != null && mounted) {
        // Naviguer vers l'écran de chat
        Navigator.of(context).pushReplacement(
          MaterialPageRoute(
            builder: (context) => TradeChatScreen(tradeId: conversationId),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Erreur lors de la création de la conversation: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      setState(() {
        _isCreatingConversation = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Démarrer une conversation'),
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        CircleAvatar(
                          backgroundImage: widget.targetUser.photoURL != null
                              ? NetworkImage(widget.targetUser.photoURL!)
                              : null,
                          child: widget.targetUser.photoURL == null
                              ? Text(widget.targetUser.displayName?.substring(0, 1).toUpperCase() ?? 'U')
                              : null,
                        ),
                        const SizedBox(width: 12),
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              widget.targetUser.displayName ?? widget.targetUser.email,
                              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            if (widget.targetUser.country?.isNotEmpty == true || 
                                widget.targetUser.region?.isNotEmpty == true)
                              Text(
                                [widget.targetUser.region, widget.targetUser.country]
                                    .where((element) => element != null && element.isNotEmpty)
                                    .cast<String>()
                                    .join(', '),
                                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                  color: Colors.grey[600],
                                ),
                              ),
                          ],
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 24),
            Text(
              'Carte d\'intérêt',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Row(
                  children: [
                    Container(
                      width: 60,
                      height: 84,
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: Colors.grey[300]!),
                      ),
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(8),
                        child: Image.asset(
                          'assets/images/Pokemon/${widget.cardOfInterest}',
                          fit: BoxFit.cover,
                          errorBuilder: (context, error, stackTrace) {
                            return Container(
                              color: Colors.grey[200],
                              child: const Icon(Icons.image_not_supported),
                            );
                          },
                        ),
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Text(
                        widget.cardOfInterest.replaceAll('.png', ''),
                        style: Theme.of(context).textTheme.bodyLarge,
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 24),
            Card(
              color: Colors.blue[50],
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(Icons.info_outline, color: Colors.blue[700]),
                        const SizedBox(width: 8),
                        Text(
                          'Conversation simple',
                          style: Theme.of(context).textTheme.titleSmall?.copyWith(
                            fontWeight: FontWeight.bold,
                            color: Colors.blue[700],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Vous allez démarrer une conversation avec cet utilisateur pour discuter de cette carte. '
                      'Aucun échange spécifique n\'est proposé pour l\'instant.',
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: Colors.blue[700],
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const Spacer(),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _isCreatingConversation ? null : _createConversation,
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                ),
                child: _isCreatingConversation
                    ? const Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          SizedBox(
                            width: 16,
                            height: 16,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          ),
                          SizedBox(width: 8),
                          Text('Création en cours...'),
                        ],
                      )
                    : const Text(
                        'Démarrer la conversation',
                        style: TextStyle(fontSize: 16),
                      ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
