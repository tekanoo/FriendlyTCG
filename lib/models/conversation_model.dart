import 'package:cloud_firestore/cloud_firestore.dart';

enum ConversationType { priceOffer, buyInquiry }
enum ConversationStatus { active, completed, cancelled }

class ConversationModel {
  final String id;
  final String listingId;
  final String cardName;
  final String sellerId;
  final String buyerId;
  final String sellerName;
  final String buyerName;
  final ConversationType type;
  final ConversationStatus status;
  final int? proposedPriceCents;
  final int originalPriceCents;
  final DateTime createdAt;
  final DateTime? updatedAt;
  final DateTime? completedAt;
  final List<ConversationMessage> messages;
  final bool hasUnreadBuyer;
  final bool hasUnreadSeller;

  ConversationModel({
    required this.id,
    required this.listingId,
    required this.cardName,
    required this.sellerId,
    required this.buyerId,
    required this.sellerName,
    required this.buyerName,
    required this.type,
    required this.status,
    this.proposedPriceCents,
    required this.originalPriceCents,
    required this.createdAt,
    this.updatedAt,
    this.completedAt,
    this.messages = const [],
    this.hasUnreadBuyer = false,
    this.hasUnreadSeller = false,
  });

  factory ConversationModel.fromFirestore(Map<String, dynamic> data, String id) {
    return ConversationModel(
      id: id,
      listingId: data['listingId'] ?? '',
      cardName: data['cardName'] ?? '',
      sellerId: data['sellerId'] ?? '',
      buyerId: data['buyerId'] ?? '',
      sellerName: data['sellerName'] ?? '',
      buyerName: data['buyerName'] ?? '',
      type: ConversationType.values.firstWhere(
        (e) => e.toString().split('.').last == data['type'],
        orElse: () => ConversationType.priceOffer,
      ),
      status: ConversationStatus.values.firstWhere(
        (e) => e.toString().split('.').last == data['status'],
        orElse: () => ConversationStatus.active,
      ),
      proposedPriceCents: data['proposedPriceCents'],
      originalPriceCents: data['originalPriceCents'] ?? 0,
      createdAt: (data['createdAt'] as Timestamp).toDate(),
      updatedAt: data['updatedAt'] != null ? (data['updatedAt'] as Timestamp).toDate() : null,
      completedAt: data['completedAt'] != null ? (data['completedAt'] as Timestamp).toDate() : null,
      hasUnreadBuyer: data['hasUnreadBuyer'] ?? false,
      hasUnreadSeller: data['hasUnreadSeller'] ?? false,
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'listingId': listingId,
      'cardName': cardName,
      'sellerId': sellerId,
      'buyerId': buyerId,
      'sellerName': sellerName,
      'buyerName': buyerName,
      'type': type.toString().split('.').last,
      'status': status.toString().split('.').last,
      if (proposedPriceCents != null) 'proposedPriceCents': proposedPriceCents,
      'originalPriceCents': originalPriceCents,
      'createdAt': Timestamp.fromDate(createdAt),
      if (updatedAt != null) 'updatedAt': Timestamp.fromDate(updatedAt!),
      if (completedAt != null) 'completedAt': Timestamp.fromDate(completedAt!),
      'hasUnreadBuyer': hasUnreadBuyer,
      'hasUnreadSeller': hasUnreadSeller,
    };
  }

  ConversationModel copyWith({
    ConversationStatus? status,
    DateTime? updatedAt,
    DateTime? completedAt,
    List<ConversationMessage>? messages,
    bool? hasUnreadBuyer,
    bool? hasUnreadSeller,
  }) {
    return ConversationModel(
      id: id,
      listingId: listingId,
      cardName: cardName,
      sellerId: sellerId,
      buyerId: buyerId,
      sellerName: sellerName,
      buyerName: buyerName,
      type: type,
      status: status ?? this.status,
      proposedPriceCents: proposedPriceCents,
      originalPriceCents: originalPriceCents,
      createdAt: createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      completedAt: completedAt ?? this.completedAt,
      messages: messages ?? this.messages,
      hasUnreadBuyer: hasUnreadBuyer ?? this.hasUnreadBuyer,
      hasUnreadSeller: hasUnreadSeller ?? this.hasUnreadSeller,
    );
  }
}

class ConversationMessage {
  final String id;
  final String senderId;
  final String senderName;
  final String content;
  final DateTime createdAt;
  final ConversationMessageType type;

  ConversationMessage({
    required this.id,
    required this.senderId,
    required this.senderName,
    required this.content,
    required this.createdAt,
    this.type = ConversationMessageType.text,
  });

  factory ConversationMessage.fromFirestore(Map<String, dynamic> data, String id) {
    return ConversationMessage(
      id: id,
      senderId: data['senderId'] ?? '',
      senderName: data['senderName'] ?? '',
      content: data['content'] ?? '',
      createdAt: (data['createdAt'] as Timestamp).toDate(),
      type: ConversationMessageType.values.firstWhere(
        (e) => e.toString().split('.').last == data['type'],
        orElse: () => ConversationMessageType.text,
      ),
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'senderId': senderId,
      'senderName': senderName,
      'content': content,
      'createdAt': Timestamp.fromDate(createdAt),
      'type': type.toString().split('.').last,
    };
  }
}

enum ConversationMessageType { text, priceOffer, system }
