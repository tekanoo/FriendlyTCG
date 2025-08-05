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
    // Les cartes sont déjà triées dans le fichier généré
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
    print('🔄 Cache des jeux et extensions vidé');
  }
  
  /// Méthode de debug pour vérifier les extensions
  static void debugExtensions() {
    print('=== DEBUG: Extensions détectées ===');
    final extensions = getAllExtensions();
    
    for (final extension in extensions) {
      print('📦 ${extension.name} (${extension.id})');
      print('   📁 Game: ${extension.gameId}');
      print('   🖼️ Image: ${extension.imagePath}');
      print('   🃏 Cartes: ${extension.cardImages.length}');
      
      if (extension.cardImages.isNotEmpty) {
        print('   🥇 Première carte: ${extension.cardImages.first}');
      }
      print('');
    }
    print('=== Fin DEBUG ===');
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
    // Retourner le chemin de l'image du jeu depuis les logos
    if (gameName.toLowerCase() == 'gundam cards') {
      return 'assets/logo/Gundam/gundam.webp';
    }
    if (gameName.toLowerCase() == 'pokemon') {
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
      print('🖼️ Extension $extensionName: utilise $firstCardPath comme image');
      return firstCardPath;
    }
    
    // Fallback vers une image de couverture générique
    final fallbackPath = 'assets/images/$gameName/$extensionName/cover.png';
    print('⚠️ Extension $extensionName: aucune carte trouvée, utilise $fallbackPath');
    return fallbackPath;
  }

  /// Vérifier et afficher automatiquement la première image des nouvelles extensions
  static Future<void> autoDisplayFirstImageForNewExtensions() async {
    print('🔍 Vérification des nouvelles extensions Gundam...');
    
    final games = getAllGames();
    for (final game in games) {
      if (game.name.toLowerCase().contains('gundam')) {
        final extensions = getExtensionsForGame(game.id);
        print('📋 Traitement de ${extensions.length} extensions pour ${game.name}');
        
        for (final extension in extensions) {
          final gameName = _gameIdToName(game.id);
          final imagePath = _getExtensionImagePath(gameName, extension.id);
          print('✅ Extension ${extension.name}: première image trouvée - $imagePath');
          
          // Optionnel: vous pourriez ici déclencher une notification ou une action
          // pour informer l'utilisateur qu'une nouvelle extension a été détectée
        }
      }
    }
  }

  /// Obtenir la liste des extensions qui n'ont pas encore d'image assignée
  static List<ExtensionModel> getExtensionsWithoutImages() {
    final extensionsWithoutImages = <ExtensionModel>[];
    
    final games = getAllGames();
    for (final game in games) {
      if (game.name.toLowerCase().contains('gundam')) {
        final extensions = getExtensionsForGame(game.id);
        
        for (final extension in extensions) {
          final cards = getCardsForExtension(extension.id);
          if (cards.isEmpty) {
            extensionsWithoutImages.add(extension);
          }
        }
      }
    }
    
    return extensionsWithoutImages;
  }

  /// Méthode pour débugger spécifiquement les extensions Gundam
  static void debugGundamExtensions() {
    print('🔍 Analyse des extensions Gundam et de leurs images...');
    
    final games = getAllGames();
    for (final game in games) {
      if (game.name.toLowerCase().contains('gundam')) {
        print('\n🎮 Jeu: ${game.name} (${game.id})');
        final extensions = getExtensionsForGame(game.id);
        print('📋 Extensions: ${extensions.length}');
        
        for (final extension in extensions) {
          final gameName = _gameIdToName(game.id);
          final imagePath = _getExtensionImagePath(gameName, extension.id);
          print('  📦 ${extension.name} (${extension.id})');
          print('    🖼️  Image: $imagePath');
          
          // Debug des cartes pour cette extension
          final cards = getCardsForExtension(extension.id);
          print('    🃏 Cartes: ${cards.length}');
          if (cards.isNotEmpty) {
            print('    🔸 Première carte: ${cards.first}');
          }
        }
      }
    }
  }

  /// Méthode pour débugger spécifiquement l'extension edition_beta
  static void debugEditionBetaExtension() {
    print('🔍 DEBUG spécifique pour edition_beta...');
    
    // Vérifier si l'extension existe dans la structure
    final gameStructure = GeneratedCardsList.getGameStructure();
    print('📋 Structure des jeux: $gameStructure');
    
    // Chercher edition_beta dans toutes les extensions
    bool found = false;
    for (final entry in gameStructure.entries) {
      if (entry.value.contains('edition_beta')) {
        found = true;
        print('✅ Extension edition_beta trouvée dans ${entry.key}');
        break;
      }
    }
    
    if (found) {
      // Obtenir les cartes
      final cards = GeneratedCardsList.getCardsByExtensionId('edition_beta');
      print('🃏 Cartes trouvées pour edition_beta: ${cards.length}');
      if (cards.isNotEmpty) {
        print('🔸 Première carte: ${cards.first}');
        
        // Tester le chemin de la première carte
        final cardPath = GeneratedCardsList.getCardPath('edition_beta', cards.first);
        print('🖼️  Chemin de la première carte: $cardPath');
        
        // Tester la méthode _getExtensionImagePath
        final imagePath = _getExtensionImagePath('Gundam Cards', 'edition_beta');
        print('🎯 Image path générée: $imagePath');
      } else {
        print('❌ Aucune carte trouvée pour edition_beta');
      }
      
      // Vérifier le jeu associé
      final gameName = GeneratedCardsList.getGameForExtension('edition_beta');
      print('🎮 Jeu associé: $gameName');
    } else {
      print('❌ Extension edition_beta NON trouvée dans la structure');
    }
  }

  /// Convertir un ID de jeu vers le nom du dossier
  static String _gameIdToName(String gameId) {
    // Convertir l'ID en nom de dossier (inverse de _gameNameToId)
    if (gameId == 'gundam-cards') return 'Gundam Cards';
    if (gameId == 'pokemon') return 'Pokemon';
    return gameId;
  }
}
