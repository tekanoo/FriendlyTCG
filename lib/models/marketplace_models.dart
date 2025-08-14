import 'package:cloud_firestore/cloud_firestore.dart';

/// Status of a marketplace listing
enum ListingStatus { active, reserved, sold, cancelled }

/// Type d'annonce: vente directe ou simple offre (mise en avant d'un prix recherché)
enum ListingType { sale, buy }

/// A card listed for sale in the marketplace
class MarketplaceListing {
  final String id;
  final String sellerId;
  final String sellerName; // cached for faster UI
  final String? sellerRegion; // minimal location exposure
  final String cardName; // canonical filename (ex: "Pikachu.png")
  final int priceCents; // store in cents to avoid float issues
  final ListingStatus status;
  final DateTime createdAt;
  final DateTime? updatedAt;
  final DateTime? soldAt;
  final String? buyerId; // set when an offer accepted (reserved / sold)
  final bool sellerValidated; // double validation
  final bool buyerValidated;
  final ListingType listingType;

  MarketplaceListing({
    required this.id,
    required this.sellerId,
    required this.sellerName,
    required this.sellerRegion,
    required this.cardName,
    required this.priceCents,
    required this.status,
    required this.createdAt,
    this.listingType = ListingType.sale,
    this.updatedAt,
    this.soldAt,
    this.buyerId,
    this.sellerValidated = false,
    this.buyerValidated = false,
  });

  factory MarketplaceListing.fromFirestore(Map<String, dynamic> data, String id) {
    return MarketplaceListing(
      id: id,
      sellerId: data['sellerId'] ?? '',
      sellerName: data['sellerName'] ?? 'Vendeur',
      sellerRegion: data['sellerRegion'],
      cardName: data['cardName'] ?? '',
      priceCents: (data['priceCents'] ?? 0) as int,
      status: ListingStatus.values.firstWhere(
        (e) => e.toString().split('.').last == (data['status'] ?? 'active'),
        orElse: () => ListingStatus.active,
      ),
      createdAt: (data['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      updatedAt: (data['updatedAt'] as Timestamp?)?.toDate(),
      soldAt: (data['soldAt'] as Timestamp?)?.toDate(),
  buyerId: data['buyerId'],
  sellerValidated: data['sellerValidated'] ?? false,
  buyerValidated: data['buyerValidated'] ?? false,
      listingType: ListingType.values.firstWhere(
        (e) => e.toString().split('.').last == (data['listingType'] ?? 'sale'),
        orElse: () => ListingType.sale,
      ),
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'sellerId': sellerId,
      'sellerName': sellerName,
      'sellerRegion': sellerRegion,
      'cardName': cardName,
      'priceCents': priceCents,
      'status': status.toString().split('.').last,
      'createdAt': Timestamp.fromDate(createdAt),
      'updatedAt': updatedAt != null ? Timestamp.fromDate(updatedAt!) : null,
      'soldAt': soldAt != null ? Timestamp.fromDate(soldAt!) : null,
  'buyerId': buyerId,
  'sellerValidated': sellerValidated,
  'buyerValidated': buyerValidated,
  'listingType': listingType.toString().split('.').last,
    };
  }

  MarketplaceListing copyWith({
    String? id,
    String? sellerId,
    String? sellerName,
    String? sellerRegion,
    String? cardName,
    int? priceCents,
    ListingStatus? status,
    DateTime? createdAt,
    DateTime? updatedAt,
    DateTime? soldAt,
    String? buyerId,
    bool? sellerValidated,
    bool? buyerValidated,
    ListingType? listingType,
  }) {
    return MarketplaceListing(
      id: id ?? this.id,
      sellerId: sellerId ?? this.sellerId,
      sellerName: sellerName ?? this.sellerName,
      sellerRegion: sellerRegion ?? this.sellerRegion,
      cardName: cardName ?? this.cardName,
      priceCents: priceCents ?? this.priceCents,
      status: status ?? this.status,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      soldAt: soldAt ?? this.soldAt,
      buyerId: buyerId ?? this.buyerId,
      sellerValidated: sellerValidated ?? this.sellerValidated,
      buyerValidated: buyerValidated ?? this.buyerValidated,
      listingType: listingType ?? this.listingType,
    );
  }
}

enum OfferStatus { pending, accepted, declined, withdrawn }

/// Offer from buyer for a listing (price proposal or direct buy)
class ListingOffer {
  final String id;
  final String listingId;
  final String buyerId;
  final String buyerName;
  final int proposedPriceCents;
  final OfferStatus status;
  final DateTime createdAt;
  final DateTime? updatedAt;

  ListingOffer({
    required this.id,
    required this.listingId,
    required this.buyerId,
    required this.buyerName,
    required this.proposedPriceCents,
    required this.status,
    required this.createdAt,
    this.updatedAt,
  });

  factory ListingOffer.fromFirestore(Map<String, dynamic> data, String id) {
    return ListingOffer(
      id: id,
      listingId: data['listingId'] ?? '',
      buyerId: data['buyerId'] ?? '',
      buyerName: data['buyerName'] ?? 'Acheteur',
      proposedPriceCents: (data['proposedPriceCents'] ?? 0) as int,
      status: OfferStatus.values.firstWhere(
        (e) => e.toString().split('.').last == (data['status'] ?? 'pending'),
        orElse: () => OfferStatus.pending,
      ),
      createdAt: (data['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      updatedAt: (data['updatedAt'] as Timestamp?)?.toDate(),
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'listingId': listingId,
      'buyerId': buyerId,
      'buyerName': buyerName,
      'proposedPriceCents': proposedPriceCents,
      'status': status.toString().split('.').last,
      'createdAt': Timestamp.fromDate(createdAt),
      'updatedAt': updatedAt != null ? Timestamp.fromDate(updatedAt!) : null,
    };
  }

  ListingOffer copyWith({
    String? id,
    String? listingId,
    String? buyerId,
    String? buyerName,
    int? proposedPriceCents,
    OfferStatus? status,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return ListingOffer(
      id: id ?? this.id,
      listingId: listingId ?? this.listingId,
      buyerId: buyerId ?? this.buyerId,
      buyerName: buyerName ?? this.buyerName,
      proposedPriceCents: proposedPriceCents ?? this.proposedPriceCents,
      status: status ?? this.status,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
}

/// Encrypted chat message related to a listing or accepted offer
class MarketplaceMessage {
  final String id;
  final String listingId;
  final String senderId;
  final String senderName;
  final String cipherText; // encrypted content
  final DateTime timestamp;
  final bool isSystem;

  MarketplaceMessage({
    required this.id,
    required this.listingId,
    required this.senderId,
    required this.senderName,
    required this.cipherText,
    required this.timestamp,
    this.isSystem = false,
  });

  factory MarketplaceMessage.fromFirestore(Map<String, dynamic> data, String id) {
    return MarketplaceMessage(
      id: id,
      listingId: data['listingId'] ?? '',
      senderId: data['senderId'] ?? '',
      senderName: data['senderName'] ?? 'Utilisateur',
      cipherText: data['cipherText'] ?? '',
      timestamp: (data['timestamp'] as Timestamp?)?.toDate() ?? DateTime.now(),
      isSystem: data['isSystem'] ?? false,
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'listingId': listingId,
      'senderId': senderId,
      'senderName': senderName,
      'cipherText': cipherText,
      'timestamp': Timestamp.fromDate(timestamp),
      'isSystem': isSystem,
    };
  }
}
