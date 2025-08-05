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
        folderPath: 'assets/images/$gameName',
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
          gameId: gameId,
          imagePath: _getExtensionImagePath(gameName, extensionName),
          cardImages: GeneratedCardsList.getCardsByExtensionId(extensionName),
        ));
      }
    }
    
    _cachedExtensions = extensions;
    return extensions;
  }
  
  /// Obtient les extensions pour un jeu spécifique
  static List<ExtensionModel> getExtensionsForGame(String gameId) {
    final allExtensions = getAllExtensions();
    return allExtensions.where((ext) => ext.gameId == gameId).toList();
  }
  
  /// Obtient les cartes pour une extension spécifique
  static List<String> getCardsForExtension(String extensionId) {
    return GeneratedCardsList.getCardsByExtensionId(extensionId);
  }
  
  /// Invalide le cache (utile après ajout/suppression d'éléments)
  static void invalidateCache() {
    _cachedGames = null;
    _cachedExtensions = null;
  }
  
  /// Alias pour invalidateCache (compatibilité)
  static void clearCache() {
    invalidateCache();
  }
  
  /// Obtenir le chemin d'une carte spécifique
  static String getCardImagePath(String extensionId, String cardName) {
    return GeneratedCardsList.getCardPath(extensionId, cardName);
  }
  
  /// Méthode de debug (vide pour compatibilité)
  static void debugExtensions() {
    // Méthode vide pour compatibilité
  }
  
  // === Méthodes privées ===
  
  static String _gameNameToId(String gameName) {
    // Convertir le nom en ID (lowercase avec tirets)
    return gameName.toLowerCase().replaceAll(' ', '-');
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
    // Retourner le chemin de l'image du jeu depuis les logos
    if (gameName == 'Gundam Cards') {
      return 'assets/logo/Gundam/gundam.webp';
    }
    if (gameName == 'Pokemon' || gameName == 'Pokémon') {
      return 'assets/logo/Pokémon/Pokemon-Logo.png';
    }
    return 'assets/images/default_game.png';
  }
  
  static String _getExtensionImagePath(String gameName, String extensionName) {
    // Retourner la première carte de l'extension (déjà triée dans le fichier généré)
    final cards = GeneratedCardsList.getCardsByExtensionId(extensionName);
    if (cards.isNotEmpty) {
      // Utiliser la première carte comme image d'extension
      final firstCardPath = GeneratedCardsList.getCardPath(extensionName, cards.first);
      return firstCardPath;
    }
    
    // Fallback vers une image de couverture générique
    return 'assets/images/$gameName/$extensionName/cover.png';
  }
}