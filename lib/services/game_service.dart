import '../models/game_model.dart';
import '../models/extension_model.dart';
import 'extension_service.dart';

class GameService {
  static final GameService _instance = GameService._internal();
  factory GameService() => _instance;
  GameService._internal();

  final ExtensionService _extensionService = ExtensionService();

  // Liste des jeux disponibles
  final List<GameModel> _availableGames = [
    const GameModel(
      id: 'gundam_card_game',
      name: 'Gundam Card Game',
      description: 'Le jeu de cartes officiel Gundam avec des mechas légendaires',
      imagePath: 'assets/images/extensions/newtype_risings/GD01-001.png', // Image temporaire
      folderPath: 'assets/images/extensions',
    ),
    // Exemple pour Pokemon (à ajouter plus tard)
    // const GameModel(
    //   id: 'pokemon_tcg',
    //   name: 'Pokémon TCG',
    //   description: 'Le célèbre jeu de cartes Pokémon',
    //   imagePath: 'assets/images/games/pokemon_logo.png',
    //   folderPath: 'assets/images/pokemon_extensions',
    // ),
  ];

  List<GameModel> get availableGames => _availableGames;

  // Récupérer un jeu par son ID
  GameModel? getGameById(String id) {
    try {
      return _availableGames.firstWhere((game) => game.id == id);
    } catch (e) {
      return null;
    }
  }

  // Récupérer les extensions pour un jeu donné
  List<ExtensionModel> getExtensionsForGame(String gameId) {
    switch (gameId) {
      case 'gundam_card_game':
        // Utiliser les extensions existantes de ExtensionService
        return _extensionService.availableExtensions;
      case 'pokemon_tcg':
        return _getPokemonExtensions();
      default:
        return [];
    }
  }

  // Extensions Pokemon (exemple pour plus tard)
  List<ExtensionModel> _getPokemonExtensions() {
    // À implémenter plus tard
    return [];
  }
}
