import 'package:flutter/material.dart';
import '../models/trade_model.dart';
import '../services/trade_service_advanced.dart';
import 'trade_chat_screen.dart';
import 'package:firebase_auth/firebase_auth.dart';

class MyTradesScreen extends StatefulWidget {
  const MyTradesScreen({super.key});

  @override
  State<MyTradesScreen> createState() => _MyTradesScreenState();
}

class _MyTradesScreenState extends State<MyTradesScreen> {
  final TradeServiceAdvanced _tradeService = TradeServiceAdvanced();
  final String? _currentUserId = FirebaseAuth.instance.currentUser?.uid;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Mes échanges'),
        backgroundColor: Colors.blue.shade600,
        foregroundColor: Colors.white,
      ),
      body: StreamBuilder<List<TradeModel>>(
        stream: _tradeService.getUserTrades(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (!snapshot.hasData || snapshot.data!.isEmpty) {
            return const Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.swap_horiz,
                    size: 64,
                    color: Colors.grey,
                  ),
                  SizedBox(height: 16),
                  Text(
                    'Aucun échange en cours',
                    style: TextStyle(
                      fontSize: 18,
                      color: Colors.grey,
                    ),
                  ),
                  SizedBox(height: 8),
                  Text(
                    'Recherchez des cartes pour commencer',
                    style: TextStyle(
                      fontSize: 14,
                      color: Colors.grey,
                    ),
                  ),
                ],
              ),
            );
          }

          final trades = snapshot.data!;
          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: trades.length,
            itemBuilder: (context, index) {
              final trade = trades[index];
              return _buildTradeCard(trade);
            },
          );
        },
      ),
    );
  }

  Widget _buildTradeCard(TradeModel trade) {
    final isFromCurrentUser = trade.fromUserId == _currentUserId;
    final otherUserName = isFromCurrentUser ? trade.toUserName : trade.fromUserName;
    final statusColor = _getStatusColor(trade.status);
    final statusText = _getStatusText(trade.status);

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: InkWell(
        onTap: () {
          Navigator.of(context).push(
            MaterialPageRoute(
              builder: (context) => TradeChatScreen(tradeId: trade.id),
            ),
          );
        },
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  CircleAvatar(
                    backgroundColor: statusColor.withValues(alpha: 0.2),
                    child: Icon(
                      _getStatusIcon(trade.status),
                      color: statusColor,
                      size: 20,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Échange avec $otherUserName',
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 16,
                          ),
                        ),
                        Text(
                          statusText,
                          style: TextStyle(
                            color: statusColor,
                            fontWeight: FontWeight.w500,
                            fontSize: 14,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Icon(
                    Icons.chevron_right,
                    color: Colors.grey.shade400,
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.grey.shade50,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Column(
                  children: [
                    Row(
                      children: [
                        Icon(
                          isFromCurrentUser ? Icons.arrow_upward : Icons.arrow_downward,
                          color: isFromCurrentUser ? Colors.green : Colors.blue,
                          size: 16,
                        ),
                        const SizedBox(width: 4),
                        Expanded(
                          child: Text(
                            isFromCurrentUser 
                                ? 'Vous offrez: ${trade.offeredCard.replaceAll('.png', '')}'
                                : 'Vous recevez: ${trade.offeredCard.replaceAll('.png', '')}',
                            style: const TextStyle(fontSize: 14),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        Icon(
                          isFromCurrentUser ? Icons.arrow_downward : Icons.arrow_upward,
                          color: isFromCurrentUser ? Colors.blue : Colors.green,
                          size: 16,
                        ),
                        const SizedBox(width: 4),
                        Expanded(
                          child: Text(
                            isFromCurrentUser 
                                ? 'Vous recevez: ${trade.wantedCard.replaceAll('.png', '')}'
                                : 'Vous offrez: ${trade.wantedCard.replaceAll('.png', '')}',
                            style: const TextStyle(fontSize: 14),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 8),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    _formatDate(trade.createdAt),
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.grey.shade600,
                    ),
                  ),
                  if (trade.status == TradeStatus.pending && trade.toUserId == _currentUserId)
                    Row(
                      children: [
                        TextButton.icon(
                          onPressed: () => _updateTradeStatus(trade.id, TradeStatus.declined),
                          icon: const Icon(Icons.close, size: 16),
                          label: const Text('Refuser'),
                          style: TextButton.styleFrom(
                            foregroundColor: Colors.red,
                            padding: const EdgeInsets.symmetric(horizontal: 8),
                          ),
                        ),
                        TextButton.icon(
                          onPressed: () => _updateTradeStatus(trade.id, TradeStatus.accepted),
                          icon: const Icon(Icons.check, size: 16),
                          label: const Text('Accepter'),
                          style: TextButton.styleFrom(
                            foregroundColor: Colors.green,
                            padding: const EdgeInsets.symmetric(horizontal: 8),
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
    );
  }

  Future<void> _updateTradeStatus(String tradeId, TradeStatus status) async {
    try {
      switch (status) {
        case TradeStatus.accepted:
          await _tradeService.acceptTrade(tradeId);
          break;
        case TradeStatus.declined:
          await _tradeService.declineTrade(tradeId);
          break;
        case TradeStatus.completed:
          await _tradeService.completeTrade(tradeId);
          break;
        case TradeStatus.cancelled:
          await _tradeService.cancelTrade(tradeId);
          break;
        default:
          break;
      }
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
        return 'En attente de réponse';
      case TradeStatus.accepted:
        return 'Échange accepté';
      case TradeStatus.declined:
        return 'Échange refusé';
      case TradeStatus.completed:
        return 'Échange terminé';
      case TradeStatus.cancelled:
        return 'Échange annulé';
    }
  }

  IconData _getStatusIcon(TradeStatus status) {
    switch (status) {
      case TradeStatus.pending:
        return Icons.hourglass_empty;
      case TradeStatus.accepted:
        return Icons.handshake;
      case TradeStatus.declined:
        return Icons.thumb_down;
      case TradeStatus.completed:
        return Icons.check_circle;
      case TradeStatus.cancelled:
        return Icons.cancel;
    }
  }

  String _formatDate(DateTime dateTime) {
    final now = DateTime.now();
    final difference = now.difference(dateTime);

    if (difference.inDays == 0) {
      return 'Aujourd\'hui';
    } else if (difference.inDays == 1) {
      return 'Hier';
    } else if (difference.inDays < 7) {
      return 'Il y a ${difference.inDays} jours';
    } else {
      return '${dateTime.day}/${dateTime.month}/${dateTime.year}';
    }
  }
}
