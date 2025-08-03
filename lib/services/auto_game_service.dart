import '../services/generated_cards_list.dart';
import '../models/game_model.dart';
import '../models/extension_model.dart';

class AutoGameService {
  static List<GameModel>? _cachedGames;
  static List<ExtensionModel>? _cachedExtensions;
  
  /// Obtient tous les jeux automatiquement détectés
  static List<GameModel> getAllGames() {
    if (_cachedGames != null) return _cachedGames!;
    
    final gameStructure = GeneratedCardsList.getGameStructure();
    final games = <GameModel>[];
    
    for (final entry in gameStructure.entries) {
      final gameName = entry.key;
      final extensionCount = entry.value.length;
      
      games.add(GameModel(
        id: _gameNameToId(gameName),
        name: _formatGameName(gameName),
        description: 'Jeu de cartes avec $extensionCount extension${extensionCount > 1 ? 's' : ''}',
        imagePath: _getGameImagePath(gameName),
        folderPath: 'assets/images/$gameName', // Chemin requis
      ));
    }
    
    _cachedGames = games;
    return games;
  }
  
  /// Obtient toutes les extensions automatiquement détectées
  static List<ExtensionModel> getAllExtensions() {
    if (_cachedExtensions != null) return _cachedExtensions!;
    
    final gameStructure = GeneratedCardsList.getGameStructure();
    final extensions = <ExtensionModel>[];
    
    for (final entry in gameStructure.entries) {
      final gameName = entry.key;
      final gameId = _gameNameToId(gameName);
      
      for (final extensionName in entry.value) {
        final cardCount = GeneratedCardsList.getCardsByExtensionId(extensionName).length;
        
        extensions.add(ExtensionModel(
          id: extensionName,
          name: _formatExtensionName(extensionName),
          description: 'Extension avec $cardCount cartes',
          imagePath: _getExtensionImagePath(gameName, extensionName),
          gameId: gameId,
          cardImages: GeneratedCardsList.getCardsByExtensionId(extensionName), // Liste des cartes requise
        ));
      }
    }
    
    _cachedExtensions = extensions;
    return extensions;
  }
  
  /// Obtient les extensions pour un jeu spécifique
  static List<ExtensionModel> getExtensionsForGame(String gameId) {
    return getAllExtensions().where((ext) => ext.gameId == gameId).toList();
  }
  
  /// Obtient les cartes pour une extension
  static List<String> getCardsForExtension(String extensionId) {
    return GeneratedCardsList.getCardsByExtensionId(extensionId);
  }
  
  /// Obtient le chemin complet d'une carte
  static String getCardImagePath(String extensionId, String cardName) {
    return GeneratedCardsList.getCardPath(extensionId, cardName);
  }
  
  /// Vide le cache pour recharger les données
  static void clearCache() {
    _cachedGames = null;
    _cachedExtensions = null;
  }
  
  // Méthodes utilitaires privées
  
  static String _gameNameToId(String gameName) {
    return gameName.toLowerCase().replaceAll(' ', '_');
  }
  
  static String _formatGameName(String gameName) {
    // Formater le nom pour l'affichage
    if (gameName.toLowerCase() == 'gundam cards') {
      return 'Gundam Cards';
    }
    if (gameName.toLowerCase() == 'pokemon') {
      return 'Pokémon';
    }
    return gameName;
  }
  
  static String _formatExtensionName(String extensionName) {
    // Formater le nom d'extension pour l'affichage
    return extensionName
        .split('_')
        .map((word) => word[0].toUpperCase() + word.substring(1).toLowerCase())
        .join(' ');
  }
  
  static String _getGameImagePath(String gameName) {
    // Retourner le chemin de l'image du jeu
    if (gameName.toLowerCase() == 'gundam cards') {
      return 'assets/images/gundam_logo.png';
    }
    if (gameName.toLowerCase() == 'pokemon') {
      return 'assets/images/pokemon_logo.png';
    }
    return 'assets/images/default_game.png';
  }
  
  static String _getExtensionImagePath(String gameName, String extensionName) {
    // Retourner le chemin par défaut pour les extensions
    return 'assets/images/$gameName/$extensionName/cover.png';
  }
}
