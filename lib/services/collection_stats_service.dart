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

    // Parcourir toutes les cartes de l'extension
    for (final cardImagePath in extension.cardImages) {
      // Extraire le nom de la carte du chemin d'image
      final cardName = _extractCardNameFromPath(cardImagePath);
      
      // Vérifier si l'utilisateur possède cette carte
      final quantity = userCollection[cardName] ?? 0;
      if (quantity > 0) {
        ownedCardNames.add(cardName);
        ownedCardsCount += quantity;
      }
    }

    return ExtensionStats(
      extensionId: extension.id,
      extensionName: extension.name,
      ownedCards: ownedCardsCount,
      totalCards: extension.cardImages.length,
      ownedCardNames: ownedCardNames,
    );
  }

  /// Extrait le nom de la carte du chemin d'image
  String _extractCardNameFromPath(String imagePath) {
    // Extraire le nom du fichier sans l'extension
    final fileName = imagePath.split('/').last.replaceAll('.png', '');
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
