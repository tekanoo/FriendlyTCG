class CardPrice {
  final String cardId;
  final String cardName;
  final double? avgPrice;
  final double? minPrice;
  final double? maxPrice;
  final String currency;
  final DateTime lastUpdated;
  final String source;

  CardPrice({
    required this.cardId,
    required this.cardName,
    this.avgPrice,
    this.minPrice,
    this.maxPrice,
    this.currency = 'EUR',
    required this.lastUpdated,
    this.source = 'Manual',
  });

  factory CardPrice.fromJson(Map<String, dynamic> json) {
    return CardPrice(
      cardId: json['cardId'] ?? '',
      cardName: json['cardName'] ?? '',
      avgPrice: json['avgPrice']?.toDouble(),
      minPrice: json['minPrice']?.toDouble(),
      maxPrice: json['maxPrice']?.toDouble(),
      currency: json['currency'] ?? 'EUR',
      lastUpdated: DateTime.parse(json['lastUpdated']),
      source: json['source'] ?? 'Manual',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'cardId': cardId,
      'cardName': cardName,
      'avgPrice': avgPrice,
      'minPrice': minPrice,
      'maxPrice': maxPrice,
      'currency': currency,
      'lastUpdated': lastUpdated.toIso8601String(),
      'source': source,
    };
  }

  String get formattedAvgPrice {
    if (avgPrice == null) return 'Prix non disponible';
    return '${avgPrice!.toStringAsFixed(2)} $currency';
  }

  String get formattedPriceRange {
    if (minPrice == null || maxPrice == null) return '';
    return '${minPrice!.toStringAsFixed(2)} - ${maxPrice!.toStringAsFixed(2)} $currency';
  }

  bool get isAvailable => avgPrice != null;
}
