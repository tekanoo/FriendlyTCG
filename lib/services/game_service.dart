import '../models/game_model.dart';
import '../models/extension_model.dart';
import 'auto_game_service.dart';
import '../config/feature_flags.dart';

class GameService {
  static final GameService _instance = GameService._internal();
  factory GameService() => _instance;
  GameService._internal();

  /// Obtient tous les jeux disponibles (automatiquement détectés)
  List<GameModel> get availableGames {
    final games = AutoGameService.getAllGames();
    return games.where((g) => !FeatureFlags.isGameHidden(g)).toList();
  }

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
  final game = getGameById(gameId);
  if (game == null || FeatureFlags.isGameHidden(game)) return [];
  return AutoGameService.getExtensionsForGame(gameId)
    .where((ext) => !FeatureFlags.hidePokemon || !ext.gameId.contains('pokemon'))
    .toList();
  }

  /// Recharge les données depuis les dossiers
  void reloadGames() {
    AutoGameService.clearCache();
  }
}
