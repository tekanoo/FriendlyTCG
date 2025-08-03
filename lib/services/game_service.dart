import '../models/game_model.dart';
import '../models/extension_model.dart';
import 'auto_game_service.dart';

class GameService {
  static final GameService _instance = GameService._internal();
  factory GameService() => _instance;
  GameService._internal();

  /// Obtient tous les jeux disponibles (automatiquement détectés)
  List<GameModel> get availableGames => AutoGameService.getAllGames();

  /// Obtient un jeu par son ID
  GameModel? getGameById(String gameId) {
    try {
      return availableGames.firstWhere((game) => game.id == gameId);
    } catch (e) {
      return null;
    }
  }

  /// Obtient toutes les extensions pour un jeu spécifique
  List<ExtensionModel> getExtensionsForGame(String gameId) {
    return AutoGameService.getExtensionsForGame(gameId);
  }

  /// Recharge les données depuis les dossiers
  void reloadGames() {
    AutoGameService.clearCache();
  }
}
