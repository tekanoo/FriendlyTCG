import 'package:flutter/material.dart';
import '../models/trade_model.dart';
import '../services/trade_service_advanced.dart';
import 'package:firebase_auth/firebase_auth.dart';

class TradeChatScreen extends StatefulWidget {
  final String tradeId;

  const TradeChatScreen({
    super.key,
    required this.tradeId,
  });

  @override
  State<TradeChatScreen> createState() => _TradeChatScreenState();
}

class _TradeChatScreenState extends State<TradeChatScreen> {
  final TradeServiceAdvanced _tradeService = TradeServiceAdvanced();
  final TextEditingController _messageController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  
  TradeModel? _trade;
  final String? _currentUserId = FirebaseAuth.instance.currentUser?.uid;

  @override
  void initState() {
    super.initState();
    _loadTrade();
  }

  @override
  void dispose() {
    _messageController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  Future<void> _loadTrade() async {
    final trade = await _tradeService.getTrade(widget.tradeId);
    setState(() {
      _trade = trade;
    });
  }

  Future<void> _sendMessage() async {
    if (_messageController.text.trim().isEmpty) return;

    final message = _messageController.text.trim();
    _messageController.clear();

    try {
      await _tradeService.sendMessage(widget.tradeId, message);
      _scrollToBottom();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Erreur lors de l\'envoi: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  void _scrollToBottom() {
    if (_scrollController.hasClients) {
      _scrollController.animateTo(
        _scrollController.position.maxScrollExtent,
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeOut,
      );
    }
  }

  Future<void> _updateTradeStatus(TradeStatus status) async {
    try {
      switch (status) {
        case TradeStatus.accepted:
          await _tradeService.acceptTrade(widget.tradeId);
          break;
        case TradeStatus.declined:
          await _tradeService.declineTrade(widget.tradeId);
          break;
        case TradeStatus.completed:
          await _tradeService.completeTrade(widget.tradeId);
          break;
        case TradeStatus.cancelled:
          await _tradeService.cancelTrade(widget.tradeId);
          break;
        default:
          break;
      }
      _loadTrade(); // Recharger pour mettre à jour l'UI
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Erreur: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_trade == null) {
      return Scaffold(
        appBar: AppBar(
          title: const Text('Chargement...'),
          backgroundColor: Colors.blue.shade600,
          foregroundColor: Colors.white,
        ),
        body: const Center(child: CircularProgressIndicator()),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: Text('Échange avec ${_getOtherUserName()}'),
        backgroundColor: Colors.blue.shade600,
        foregroundColor: Colors.white,
        actions: [
          PopupMenuButton<TradeStatus>(
            onSelected: _updateTradeStatus,
            itemBuilder: (context) => [
              if (_trade!.status == TradeStatus.pending && 
                  _trade!.toUserId == _currentUserId)
                const PopupMenuItem(
                  value: TradeStatus.accepted,
                  child: Row(
                    children: [
                      Icon(Icons.check, color: Colors.green),
                      SizedBox(width: 8),
                      Text('Accepter'),
                    ],
                  ),
                ),
              if (_trade!.status == TradeStatus.pending && 
                  _trade!.toUserId == _currentUserId)
                const PopupMenuItem(
                  value: TradeStatus.declined,
                  child: Row(
                    children: [
                      Icon(Icons.close, color: Colors.red),
                      SizedBox(width: 8),
                      Text('Refuser'),
                    ],
                  ),
                ),
              if (_trade!.status == TradeStatus.accepted)
                const PopupMenuItem(
                  value: TradeStatus.completed,
                  child: Row(
                    children: [
                      Icon(Icons.done_all, color: Colors.green),
                      SizedBox(width: 8),
                      Text('Marquer comme terminé'),
                    ],
                  ),
                ),
              if (_trade!.status == TradeStatus.pending || 
                  _trade!.status == TradeStatus.accepted)
                const PopupMenuItem(
                  value: TradeStatus.cancelled,
                  child: Row(
                    children: [
                      Icon(Icons.cancel, color: Colors.orange),
                      SizedBox(width: 8),
                      Text('Annuler'),
                    ],
                  ),
                ),
            ],
          ),
        ],
      ),
      body: Column(
        children: [
          _buildTradeHeader(),
          _buildMessages(),
          if (_trade!.status == TradeStatus.accepted || 
              _trade!.status == TradeStatus.pending)
            _buildMessageInput(),
        ],
      ),
    );
  }

  Widget _buildTradeHeader() {
    final statusColor = _getStatusColor(_trade!.status);
    final statusText = _getStatusText(_trade!.status);

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: statusColor.withValues(alpha: 0.1),
        border: Border(
          bottom: BorderSide(color: Colors.grey.shade300),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.swap_horiz, color: statusColor),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  'Statut: $statusText',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    color: statusColor,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            '${_trade!.fromUserName} offre ${_trade!.offeredCard.replaceAll('.png', '')}',
            style: const TextStyle(fontSize: 14),
          ),
          Text(
            'Contre ${_trade!.wantedCard.replaceAll('.png', '')} de ${_trade!.toUserName}',
            style: const TextStyle(fontSize: 14),
          ),
        ],
      ),
    );
  }

  Widget _buildMessages() {
    return Expanded(
      child: StreamBuilder<List<TradeMessageModel>>(
        stream: _tradeService.getTradeMessages(widget.tradeId),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (!snapshot.hasData || snapshot.data!.isEmpty) {
            return const Center(
              child: Text('Aucun message pour le moment'),
            );
          }

          final messages = snapshot.data!;
          
          WidgetsBinding.instance.addPostFrameCallback((_) {
            _scrollToBottom();
          });

          return ListView.builder(
            controller: _scrollController,
            padding: const EdgeInsets.all(16),
            itemCount: messages.length,
            itemBuilder: (context, index) {
              final message = messages[index];
              return _buildMessageBubble(message);
            },
          );
        },
      ),
    );
  }

  Widget _buildMessageBubble(TradeMessageModel message) {
    final isCurrentUser = message.senderId == _currentUserId;
    final isSystemMessage = message.isSystemMessage;

    if (isSystemMessage) {
      return Container(
        margin: const EdgeInsets.symmetric(vertical: 4),
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: Colors.grey.shade200,
          borderRadius: BorderRadius.circular(8),
        ),
        child: Row(
          children: [
            Icon(
              Icons.info_outline,
              size: 16,
              color: Colors.grey.shade600,
            ),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                message.message,
                style: TextStyle(
                  fontSize: 13,
                  color: Colors.grey.shade700,
                  fontStyle: FontStyle.italic,
                ),
              ),
            ),
          ],
        ),
      );
    }

    return Container(
      margin: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: isCurrentUser 
            ? MainAxisAlignment.end 
            : MainAxisAlignment.start,
        children: [
          Container(
            constraints: BoxConstraints(
              maxWidth: MediaQuery.of(context).size.width * 0.7,
            ),
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: isCurrentUser 
                  ? Colors.blue.shade500 
                  : Colors.grey.shade300,
              borderRadius: BorderRadius.circular(16),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (!isCurrentUser)
                  Text(
                    message.senderName,
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                      color: Colors.grey.shade700,
                    ),
                  ),
                Text(
                  message.message,
                  style: TextStyle(
                    color: isCurrentUser ? Colors.white : Colors.black87,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  _formatTime(message.timestamp),
                  style: TextStyle(
                    fontSize: 11,
                    color: isCurrentUser 
                        ? Colors.white.withValues(alpha: 0.7)
                        : Colors.grey.shade600,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMessageInput() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withValues(alpha: 0.3),
            blurRadius: 4,
            offset: const Offset(0, -2),
          ),
        ],
      ),
      child: Row(
        children: [
          Expanded(
            child: TextField(
              controller: _messageController,
              decoration: InputDecoration(
                hintText: 'Tapez votre message...',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(24),
                ),
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 8,
                ),
              ),
              maxLines: null,
              onSubmitted: (_) => _sendMessage(),
            ),
          ),
          const SizedBox(width: 8),
          IconButton(
            onPressed: _sendMessage,
            icon: const Icon(Icons.send),
            style: IconButton.styleFrom(
              backgroundColor: Colors.blue.shade500,
              foregroundColor: Colors.white,
            ),
          ),
        ],
      ),
    );
  }

  String _getOtherUserName() {
    if (_currentUserId == _trade!.fromUserId) {
      return _trade!.toUserName;
    } else {
      return _trade!.fromUserName;
    }
  }

  Color _getStatusColor(TradeStatus status) {
    switch (status) {
      case TradeStatus.pending:
        return Colors.orange;
      case TradeStatus.accepted:
        return Colors.green;
      case TradeStatus.declined:
        return Colors.red;
      case TradeStatus.completed:
        return Colors.blue;
      case TradeStatus.cancelled:
        return Colors.grey;
    }
  }

  String _getStatusText(TradeStatus status) {
    switch (status) {
      case TradeStatus.pending:
        return 'En attente';
      case TradeStatus.accepted:
        return 'Accepté';
      case TradeStatus.declined:
        return 'Refusé';
      case TradeStatus.completed:
        return 'Terminé';
      case TradeStatus.cancelled:
        return 'Annulé';
    }
  }

  String _formatTime(DateTime dateTime) {
    final now = DateTime.now();
    final difference = now.difference(dateTime);

    if (difference.inMinutes < 1) {
      return 'À l\'instant';
    } else if (difference.inHours < 1) {
      return '${difference.inMinutes}min';
    } else if (difference.inDays < 1) {
      return '${difference.inHours}h';
    } else {
      return '${dateTime.day}/${dateTime.month}';
    }
  }
}
