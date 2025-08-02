import 'package:cloud_firestore/cloud_firestore.dart';

enum TradeStatus {
  pending,
  accepted,
  declined,
  completed,
  cancelled
}

class TradeModel {
  final String id;
  final String fromUserId;
  final String toUserId;
  final String fromUserName;
  final String toUserName;
  final String wantedCard;
  final String offeredCard;
  final TradeStatus status;
  final DateTime createdAt;
  final DateTime? updatedAt;

  TradeModel({
    required this.id,
    required this.fromUserId,
    required this.toUserId,
    required this.fromUserName,
    required this.toUserName,
    required this.wantedCard,
    required this.offeredCard,
    required this.status,
    required this.createdAt,
    this.updatedAt,
  });

  factory TradeModel.fromFirestore(Map<String, dynamic> data, String id) {
    return TradeModel(
      id: id,
      fromUserId: data['fromUserId'] ?? '',
      toUserId: data['toUserId'] ?? '',
      fromUserName: data['fromUserName'] ?? '',
      toUserName: data['toUserName'] ?? '',
      wantedCard: data['wantedCard'] ?? '',
      offeredCard: data['offeredCard'] ?? '',
      status: TradeStatus.values.firstWhere(
        (e) => e.toString().split('.').last == (data['status'] ?? 'pending'),
        orElse: () => TradeStatus.pending,
      ),
      createdAt: (data['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      updatedAt: (data['updatedAt'] as Timestamp?)?.toDate(),
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'fromUserId': fromUserId,
      'toUserId': toUserId,
      'fromUserName': fromUserName,
      'toUserName': toUserName,
      'wantedCard': wantedCard,
      'offeredCard': offeredCard,
      'status': status.toString().split('.').last,
      'createdAt': Timestamp.fromDate(createdAt),
      'updatedAt': updatedAt != null ? Timestamp.fromDate(updatedAt!) : null,
    };
  }

  TradeModel copyWith({
    String? id,
    String? fromUserId,
    String? toUserId,
    String? fromUserName,
    String? toUserName,
    String? wantedCard,
    String? offeredCard,
    TradeStatus? status,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return TradeModel(
      id: id ?? this.id,
      fromUserId: fromUserId ?? this.fromUserId,
      toUserId: toUserId ?? this.toUserId,
      fromUserName: fromUserName ?? this.fromUserName,
      toUserName: toUserName ?? this.toUserName,
      wantedCard: wantedCard ?? this.wantedCard,
      offeredCard: offeredCard ?? this.offeredCard,
      status: status ?? this.status,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
}

class TradeMessageModel {
  final String id;
  final String tradeId;
  final String senderId;
  final String senderName;
  final String message;
  final DateTime timestamp;
  final bool isSystemMessage;

  TradeMessageModel({
    required this.id,
    required this.tradeId,
    required this.senderId,
    required this.senderName,
    required this.message,
    required this.timestamp,
    this.isSystemMessage = false,
  });

  factory TradeMessageModel.fromFirestore(Map<String, dynamic> data, String id) {
    return TradeMessageModel(
      id: id,
      tradeId: data['tradeId'] ?? '',
      senderId: data['senderId'] ?? '',
      senderName: data['senderName'] ?? '',
      message: data['message'] ?? '',
      timestamp: (data['timestamp'] as Timestamp?)?.toDate() ?? DateTime.now(),
      isSystemMessage: data['isSystemMessage'] ?? false,
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'tradeId': tradeId,
      'senderId': senderId,
      'senderName': senderName,
      'message': message,
      'timestamp': Timestamp.fromDate(timestamp),
      'isSystemMessage': isSystemMessage,
    };
  }
}
