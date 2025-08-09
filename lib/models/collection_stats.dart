class CollectionStats {
  final String gameId;
  final String gameName;
  final List<ExtensionStats> extensions;
  /// Total de copies possédées (inclut les doublons)
  final int totalOwnedCards;
  /// Total de cartes uniques possédées (1 par variante max)
  final int totalOwnedUniqueCards;
  /// Total de cartes disponibles (uniques)
  final int totalAvailableCards;

  CollectionStats({
    required this.gameId,
    required this.gameName,
    required this.extensions,
    required this.totalOwnedCards,
    required this.totalOwnedUniqueCards,
    required this.totalAvailableCards,
  });

  /// Progression basée uniquement sur les cartes uniques
  double get completionPercentage => totalAvailableCards > 0
      ? (totalOwnedUniqueCards / totalAvailableCards) * 100
      : 0;

  int get totalDuplicateCards => totalOwnedCards - totalOwnedUniqueCards;
}

class ExtensionStats {
  final String extensionId;
  final String extensionName;
  /// Copies possédées (toutes quantités additionnées)
  final int ownedCards;
  /// Cartes uniques possédées (1 par variante max)
  final int ownedUniqueCards;
  final int totalCards; // uniques disponibles
  final List<String> ownedCardNames;

  ExtensionStats({
    required this.extensionId,
    required this.extensionName,
    required this.ownedCards,
    required this.ownedUniqueCards,
    required this.totalCards,
    required this.ownedCardNames,
  });

  double get completionPercentage => totalCards > 0
      ? (ownedUniqueCards / totalCards) * 100
      : 0;

  int get duplicateCards => ownedCards - ownedUniqueCards;
}
