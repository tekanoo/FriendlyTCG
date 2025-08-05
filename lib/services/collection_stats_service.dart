import '../models/collection_stats.dart';
import '../models/extension_model.dart';
import '../services/game_service.dart';
import '../services/extension_service.dart';
import '../services/collection_service.dart';

class CollectionStatsService {
  static final CollectionStatsService _instance = CollectionStatsService._internal();
  factory CollectionStatsService() => _instance;
  CollectionStatsService._internal();

  final GameService _gameService = GameService();
  final ExtensionService _extensionService = ExtensionService();
  final CollectionService _collectionService = CollectionService();

  /// Calcule les statistiques de collection pour tous les jeux
  List<CollectionStats> getCollectionStats() {
    final List<CollectionStats> gameStats = [];
    final userCollection = _collectionService.collection.collection;

    for (final game in _gameService.availableGames) {
      final extensions = _extensionService.getExtensionsForGame(game.id);
      final List<ExtensionStats> extensionStats = [];
      
      int totalGameOwnedCards = 0;
      int totalGameAvailableCards = 0;

      for (final extension in extensions) {
        final extensionStat = _calculateExtensionStats(extension, userCollection);
        extensionStats.add(extensionStat);
        
        totalGameOwnedCards += extensionStat.ownedCards;
        totalGameAvailableCards += extensionStat.totalCards;
      }

      gameStats.add(CollectionStats(
        gameId: game.id,
        gameName: game.name,
        extensions: extensionStats,
        totalOwnedCards: totalGameOwnedCards,
        totalAvailableCards: totalGameAvailableCards,
      ));
    }

    return gameStats;
  }

  /// Calcule les statistiques pour une extension spécifique
  ExtensionStats _calculateExtensionStats(ExtensionModel extension, Map<String, int> userCollection) {
    final List<String> ownedCardNames = [];
    int ownedCardsCount = 0;
    int totalCardsCount = extension.cardImages.length;

    // Parcourir toutes les cartes de l'extension
    for (final cardImagePath in extension.cardImages) {
      // Extraire le nom de la carte du chemin d'image
      final cardName = _extractCardNameFromPath(cardImagePath);
      
      // Vérifier si c'est une carte Pokémon (qui a des variantes)
      if (_isPokemonCard(cardName)) {
        // Pour les cartes Pokémon, calculer le total des 2 variantes
        final normalQuantity = userCollection[cardName] ?? 0;
        final reverseQuantity = userCollection['${cardName}_reverse'] ?? 0;
        final totalQuantity = normalQuantity + reverseQuantity;
        
        if (totalQuantity > 0) {
          ownedCardNames.add(cardName);
          ownedCardsCount += totalQuantity;
        }
        
        // Pour les Pokémon, multiplier par 2 le nombre total de cartes disponibles
        // (chaque carte existe en version normale ET reverse)
        totalCardsCount += 1; // +1 pour la version reverse de cette carte
      } else {
        // Pour les autres cartes (non-Pokémon), comportement normal
        final quantity = userCollection[cardName] ?? 0;
        if (quantity > 0) {
          ownedCardNames.add(cardName);
          ownedCardsCount += quantity;
        }
      }
    }

    return ExtensionStats(
      extensionId: extension.id,
      extensionName: extension.name,
      ownedCards: ownedCardsCount,
      totalCards: totalCardsCount,
      ownedCardNames: ownedCardNames,
    );
  }

  /// Vérifier si c'est une carte Pokémon (qui a des variantes normal/reverse)
  bool _isPokemonCard(String cardName) {
    return cardName.startsWith('SV') || cardName.contains('_FR_');
  }

  /// Extrait le nom de la carte du chemin d'image
  String _extractCardNameFromPath(String imagePath) {
    // Le nom de la carte est simplement le nom du fichier
    // Nous gardons le .png car c'est ainsi que les cartes sont stockées dans la collection
    final fileName = imagePath.split('/').last;
    return fileName;
  }

  /// Obtient les statistiques pour un jeu spécifique
  CollectionStats? getStatsForGame(String gameId) {
    final allStats = getCollectionStats();
    try {
      return allStats.firstWhere((stat) => stat.gameId == gameId);
    } catch (e) {
      return null;
    }
  }

  /// Obtient les statistiques pour une extension spécifique
  ExtensionStats? getStatsForExtension(String gameId, String extensionId) {
    final gameStats = getStatsForGame(gameId);
    if (gameStats == null) return null;
    
    try {
      return gameStats.extensions.firstWhere((ext) => ext.extensionId == extensionId);
    } catch (e) {
      return null;
    }
  }
}
