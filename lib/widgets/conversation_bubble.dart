import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../models/conversation_model.dart';
import '../services/conversation_service.dart';

class ConversationBubble extends StatefulWidget {
  const ConversationBubble({super.key});

  @override
  State<ConversationBubble> createState() => _ConversationBubbleState();
}

class _ConversationBubbleState extends State<ConversationBubble> with TickerProviderStateMixin {
  final _conversationService = ConversationService();
  bool _isExpanded = false;
  late AnimationController _animationController;
  late Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );
    _scaleAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: Curves.elasticOut,
    ));
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  void _toggleExpanded() {
    setState(() {
      _isExpanded = !_isExpanded;
      if (_isExpanded) {
        _animationController.forward();
      } else {
        _animationController.reverse();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Positioned(
      bottom: 20,
      right: 20,
      child: Material(
        elevation: 8,
        borderRadius: BorderRadius.circular(20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            // Panel des conversations (affiché quand étendu)
            if (_isExpanded)
              ScaleTransition(
                scale: _scaleAnimation,
                child: Container(
                  width: 400,
                  height: 500,
                  margin: const EdgeInsets.only(bottom: 10),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(15),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.1),
                        blurRadius: 10,
                        offset: const Offset(0, 5),
                      ),
                    ],
                  ),
                  child: Column(
                    children: [
                      // Header
                      Container(
                        padding: const EdgeInsets.all(16),
                        decoration: const BoxDecoration(
                          color: Color(0xFF2196F3),
                          borderRadius: BorderRadius.only(
                            topLeft: Radius.circular(15),
                            topRight: Radius.circular(15),
                          ),
                        ),
                        child: Row(
                          children: [
                            const Icon(Icons.chat, color: Colors.white),
                            const SizedBox(width: 8),
                            const Text(
                              'Conversations',
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const Spacer(),
                            IconButton(
                              icon: const Icon(Icons.close, color: Colors.white),
                              onPressed: _toggleExpanded,
                              padding: EdgeInsets.zero,
                              constraints: const BoxConstraints(),
                            ),
                          ],
                        ),
                      ),
                      // Liste des conversations
                      Expanded(
                        child: StreamBuilder<List<ConversationModel>>(
                          stream: _conversationService.listenUserConversations(),
                          builder: (context, snapshot) {
                            if (snapshot.hasError) {
                              return Center(
                                child: Padding(
                                  padding: const EdgeInsets.all(16.0),
                                  child: Text(
                                    'Erreur chargement: ${snapshot.error}',
                                    style: const TextStyle(color: Colors.red),
                                    textAlign: TextAlign.center,
                                  ),
                                ),
                              );
                            }
                            if (snapshot.connectionState == ConnectionState.waiting) {
                              return const Center(child: CircularProgressIndicator());
                            }

                            if (!snapshot.hasData || snapshot.data!.isEmpty) {
                              return const Center(
                                child: Column(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Icon(Icons.chat_bubble_outline, 
                                         size: 64, 
                                         color: Colors.grey),
                                    SizedBox(height: 16),
                                    Text(
                                      'Aucune conversation',
                                      style: TextStyle(
                                        color: Colors.grey,
                                        fontSize: 16,
                                      ),
                                    ),
                                  ],
                                ),
                              );
                            }

                            return ListView.builder(
                              padding: EdgeInsets.zero,
                              itemCount: snapshot.data!.length,
                              itemBuilder: (context, index) {
                                final conversation = snapshot.data![index];
                                return _ConversationTile(
                                  conversation: conversation,
                                  onTap: () => _showConversationDetail(conversation),
                                );
                              },
                            );
                          },
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            // Bouton bulle principal
            StreamBuilder<List<ConversationModel>>(
              stream: _conversationService.listenUserConversations(),
              builder: (context, snapshot) {
                final hasUnread = snapshot.hasData && 
                    snapshot.data!.any((conv) => _hasUnreadMessages(conv));
                
                // Affiche un badge d'erreur discret si problème d'index/règles
                final hasError = snapshot.hasError;
                return GestureDetector(
                  onTap: _toggleExpanded,
                  child: Container(
                    width: 60,
                    height: 60,
                    decoration: BoxDecoration(
                      color: const Color(0xFF2196F3),
                      shape: BoxShape.circle,
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.2),
                          blurRadius: 8,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: Stack(
                      children: [
                        const Center(
                          child: Icon(
                            Icons.chat,
                            color: Colors.white,
                            size: 28,
                          ),
                        ),
                        if (hasUnread)
                          Positioned(
                            top: 8,
                            right: 8,
                            child: Container(
                              width: 12,
                              height: 12,
                              decoration: const BoxDecoration(
                                color: Colors.red,
                                shape: BoxShape.circle,
                              ),
                            ),
                          ),
                        if (hasError)
                          Positioned(
                            bottom: 6,
                            right: 6,
                            child: Icon(Icons.error, size: 16, color: Colors.yellow.shade200),
                          ),
                      ],
                    ),
                  ),
                );
              },
            ),
          ],
        ),
      ),
    );
  }

  bool _hasUnreadMessages(ConversationModel conversation) {
    // Vérifier si l'utilisateur actuel a des messages non lus
    // Simplifié pour cette implémentation
    return conversation.hasUnreadSeller || conversation.hasUnreadBuyer;
  }

  void _showConversationDetail(ConversationModel conversation) {
    showDialog(
      context: context,
      builder: (context) => _ConversationDetailDialog(conversation: conversation),
    );
  }
}

class _ConversationTile extends StatelessWidget {
  final ConversationModel conversation;
  final VoidCallback onTap;

  const _ConversationTile({
    required this.conversation,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final lastMessage = conversation.messages.isNotEmpty 
        ? conversation.messages.last.content 
        : 'Nouvelle conversation';
    
    final statusColor = switch (conversation.status) {
      ConversationStatus.active => Colors.green,
      ConversationStatus.completed => Colors.blue,
      ConversationStatus.cancelled => Colors.red,
    };

    final statusText = switch (conversation.status) {
      ConversationStatus.active => 'Actif',
      ConversationStatus.completed => 'Terminé',
      ConversationStatus.cancelled => 'Annulé',
    };

    return ListTile(
      onTap: onTap,
      leading: CircleAvatar(
        backgroundColor: statusColor.withValues(alpha: 0.1),
        child: Icon(
          conversation.type == ConversationType.priceOffer 
              ? Icons.attach_money 
              : Icons.message,
          color: statusColor,
        ),
      ),
      title: Text(
        conversation.cardName,
        style: const TextStyle(fontWeight: FontWeight.bold),
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
      ),
      subtitle: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            lastMessage,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(color: Colors.grey[600]),
          ),
          const SizedBox(height: 2),
          Row(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(
                  color: statusColor.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Text(
                  statusText,
                  style: TextStyle(
                    color: statusColor,
                    fontSize: 10,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              const Spacer(),
              Text(
                DateFormat('dd/MM HH:mm').format(conversation.updatedAt ?? conversation.createdAt),
                style: const TextStyle(fontSize: 10, color: Colors.grey),
              ),
            ],
          ),
        ],
      ),
      isThreeLine: true,
    );
  }
}

class _ConversationDetailDialog extends StatefulWidget {
  final ConversationModel conversation;

  const _ConversationDetailDialog({required this.conversation});

  @override
  State<_ConversationDetailDialog> createState() => _ConversationDetailDialogState();
}

class _ConversationDetailDialogState extends State<_ConversationDetailDialog> {
  final _conversationService = ConversationService();
  final _messageController = TextEditingController();

  @override
  void initState() {
    super.initState();
    // Marquer comme lu quand on ouvre la conversation
    _conversationService.markAsRead(widget.conversation.id);
  }

  @override
  void dispose() {
    _messageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
      child: Container(
        width: 500,
        height: 600,
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            // Header
            Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        widget.conversation.cardName,
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      Text(
                        () {
                          if (widget.conversation.type == ConversationType.priceOffer) {
                            final cents = widget.conversation.proposedPriceCents;
                            if (cents != null) {
                              return 'Offre de prix: ${(cents / 100).toStringAsFixed(2)}€';
                            } else {
                              return 'Offre de prix';
                            }
                          }
                          return 'Demande d\'achat';
                        }(),
                        style: TextStyle(color: Colors.grey[600]),
                      ),
                    ],
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.close),
                  onPressed: () => Navigator.of(context).pop(),
                ),
              ],
            ),
            const Divider(),
            // Messages
            Expanded(
              child: StreamBuilder<List<ConversationMessage>>(
                stream: _conversationService.listenConversationMessages(widget.conversation.id),
                builder: (context, snapshot) {
                  if (!snapshot.hasData) {
                    return const Center(child: CircularProgressIndicator());
                  }

                  final messages = snapshot.data!;
                  return ListView.builder(
                    itemCount: messages.length,
                    itemBuilder: (context, index) {
                      final message = messages[index];
                      return _MessageBubble(
                        message: message, 
                        conversation: widget.conversation,
                      );
                    },
                  );
                },
              ),
            ),
            // Actions
            if (widget.conversation.status == ConversationStatus.active) ...[
              const Divider(),
              Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _messageController,
                      decoration: const InputDecoration(
                        hintText: 'Tapez votre message...',
                        border: OutlineInputBorder(),
                        isDense: true,
                      ),
                      maxLines: null,
                    ),
                  ),
                  const SizedBox(width: 8),
                  IconButton(
                    icon: const Icon(Icons.send),
                    onPressed: _sendMessage,
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Row(
                children: [
                  Expanded(
                    child: ElevatedButton.icon(
                      icon: const Icon(Icons.check),
                      label: const Text('Terminer l\'échange'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.green,
                        foregroundColor: Colors.white,
                      ),
                      onPressed: _completeConversation,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: ElevatedButton.icon(
                      icon: const Icon(Icons.cancel),
                      label: const Text('Annuler'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.red,
                        foregroundColor: Colors.white,
                      ),
                      onPressed: _cancelConversation,
                    ),
                  ),
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }

  void _sendMessage() async {
    final content = _messageController.text.trim();
    if (content.isEmpty) return;

    try {
      await _conversationService.addMessage(widget.conversation.id, content);
      _messageController.clear();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Erreur: $e')),
        );
      }
    }
  }

  void _completeConversation() async {
    try {
      await _conversationService.completeConversation(widget.conversation.id);
      if (mounted) {
        Navigator.of(context).pop();
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Échange terminé avec succès!')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Erreur: $e')),
        );
      }
    }
  }

  void _cancelConversation() async {
    try {
      await _conversationService.cancelConversation(widget.conversation.id);
      if (mounted) {
        Navigator.of(context).pop();
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Échange annulé')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Erreur: $e')),
        );
      }
    }
  }
}

class _MessageBubble extends StatelessWidget {
  final ConversationMessage message;
  final ConversationModel conversation;

  const _MessageBubble({
    required this.message,
    required this.conversation,
  });

  @override
  Widget build(BuildContext context) {
    final isSystemMessage = message.type == ConversationMessageType.system;
    
    if (isSystemMessage) {
      return Center(
        child: Container(
          margin: const EdgeInsets.symmetric(vertical: 8),
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
          decoration: BoxDecoration(
            color: Colors.grey[200],
            borderRadius: BorderRadius.circular(12),
          ),
          child: Text(
            message.content,
            style: const TextStyle(
              color: Colors.grey,
              fontStyle: FontStyle.italic,
            ),
          ),
        ),
      );
    }

    return Container(
      margin: const EdgeInsets.symmetric(vertical: 4),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            message.senderName,
            style: const TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.bold,
              color: Colors.grey,
            ),
          ),
          const SizedBox(height: 2),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: (message.type == ConversationMessageType.priceOffer || message.type == ConversationMessageType.purchase)
                  ? Colors.orange[100]
                  : Colors.blue[50],
              borderRadius: BorderRadius.circular(12),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (message.type == ConversationMessageType.priceOffer)
                  Container(
                    margin: const EdgeInsets.only(bottom: 8),
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: Colors.orange,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const Text(
                      'OFFRE DE PRIX',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 10,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                if (message.type == ConversationMessageType.purchase)
                  Container(
                    margin: const EdgeInsets.only(bottom: 8),
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: Colors.orange,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const Text(
                      'DEMANDE D\'ACHAT',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 10,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                Text(message.content),
                const SizedBox(height: 4),
                Text(
                  DateFormat('dd/MM/yyyy HH:mm').format(message.createdAt),
                  style: const TextStyle(
                    fontSize: 10,
                    color: Colors.grey,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
