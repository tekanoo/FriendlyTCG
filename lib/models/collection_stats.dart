class CollectionStats {
  final String gameId;
  final String gameName;
  final List<ExtensionStats> extensions;
  final int totalOwnedCards;
  final int totalAvailableCards;

  CollectionStats({
    required this.gameId,
    required this.gameName,
    required this.extensions,
    required this.totalOwnedCards,
    required this.totalAvailableCards,
  });

  double get completionPercentage =>
      totalAvailableCards > 0 ? (totalOwnedCards / totalAvailableCards) * 100 : 0;
}

class ExtensionStats {
  final String extensionId;
  final String extensionName;
  final int ownedCards;
  final int totalCards;
  final List<String> ownedCardNames;

  ExtensionStats({
    required this.extensionId,
    required this.extensionName,
    required this.ownedCards,
    required this.totalCards,
    required this.ownedCardNames,
  });

  double get completionPercentage =>
      totalCards > 0 ? (ownedCards / totalCards) * 100 : 0;
}
