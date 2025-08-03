class StructuredCollection {
  final Map<String, GameCollection> games;

  StructuredCollection({required this.games});

  factory StructuredCollection.fromFlat(Map<String, int> flatCollection) {
    final Map<String, GameCollection> games = {};
    
    // Pour chaque carte dans la collection plate
    for (final entry in flatCollection.entries) {
      final cardName = entry.key;
      final quantity = entry.value;
      
      // Déterminer le jeu et l'extension de cette carte
      final gameInfo = _determineGameAndExtension(cardName);
      if (gameInfo == null) continue;
      
      final gameId = gameInfo['gameId']!;
      final extensionId = gameInfo['extensionId']!;
      
      // Créer le jeu s'il n'existe pas
      if (!games.containsKey(gameId)) {
        games[gameId] = GameCollection(gameId: gameId, extensions: {});
      }
      
      // Créer l'extension si elle n'existe pas
      if (!games[gameId]!.extensions.containsKey(extensionId)) {
        games[gameId]!.extensions[extensionId] = ExtensionCollection(
          extensionId: extensionId,
          cards: {},
        );
      }
      
      // Ajouter la carte
      games[gameId]!.extensions[extensionId]!.cards[cardName] = quantity;
    }
    
    return StructuredCollection(games: games);
  }

  Map<String, dynamic> toFirestore() {
    final Map<String, dynamic> data = {};
    
    for (final gameEntry in games.entries) {
      final gameId = gameEntry.key;
      final gameCollection = gameEntry.value;
      
      data[gameId] = {};
      
      for (final extensionEntry in gameCollection.extensions.entries) {
        final extensionId = extensionEntry.key;
        final extensionCollection = extensionEntry.value;
        
        data[gameId][extensionId] = extensionCollection.cards;
      }
    }
    
    return data;
  }

  factory StructuredCollection.fromFirestore(Map<String, dynamic> data) {
    final Map<String, GameCollection> games = {};
    
    for (final gameEntry in data.entries) {
      final gameId = gameEntry.key;
      final gameData = gameEntry.value as Map<String, dynamic>;
      
      final Map<String, ExtensionCollection> extensions = {};
      
      for (final extensionEntry in gameData.entries) {
        final extensionId = extensionEntry.key;
        final cardsData = extensionEntry.value as Map<String, dynamic>;
        
        final Map<String, int> cards = {};
        for (final cardEntry in cardsData.entries) {
          cards[cardEntry.key] = (cardEntry.value as num).toInt();
        }
        
        extensions[extensionId] = ExtensionCollection(
          extensionId: extensionId,
          cards: cards,
        );
      }
      
      games[gameId] = GameCollection(
        gameId: gameId,
        extensions: extensions,
      );
    }
    
    return StructuredCollection(games: games);
  }

  Map<String, int> toFlat() {
    final Map<String, int> flatCollection = {};
    
    for (final gameCollection in games.values) {
      for (final extensionCollection in gameCollection.extensions.values) {
        flatCollection.addAll(extensionCollection.cards);
      }
    }
    
    return flatCollection;
  }

  static Map<String, String>? _determineGameAndExtension(String cardName) {
    // Logique améliorée pour déterminer le jeu et l'extension basé sur le nom de la carte
    
    // Cartes Gundam - reconnaissables par leurs préfixes
    if (cardName.startsWith('GD01-') || cardName.startsWith('GD02-') || 
        cardName.startsWith('GD03-') || cardName.startsWith('GD04-') ||
        cardName.startsWith('GD05-') || cardName.startsWith('GD06-') ||
        cardName.startsWith('GD07-') || cardName.startsWith('GD08-') ||
        cardName.startsWith('GD09-') || cardName.startsWith('GD10-') ||
        cardName.startsWith('GD') || cardName.contains('gundam')) {
      return {
        'gameId': 'gundam_card_game',
        'extensionId': 'newtype_risings',
      };
    }
    
    // Cartes Pokémon - reconnaissables par leurs préfixes spécifiques
    if (cardName.startsWith('SV8pt5') || cardName.startsWith('sv8pt5') ||
        cardName.contains('prismatic') || cardName.contains('evolutions')) {
      return {
        'gameId': 'pokemon_tcg',
        'extensionId': 'prismatic-evolutions',
      };
    }
    
    // Autres patterns pour Pokémon
    if (cardName.toLowerCase().contains('pokemon') || 
        cardName.toLowerCase().contains('poke') ||
        cardName.startsWith('SV') || cardName.startsWith('sv')) {
      return {
        'gameId': 'pokemon_tcg',
        'extensionId': 'prismatic-evolutions',
      };
    }
    
    // Si le nom contient des mots-clés gundam
    if (cardName.toLowerCase().contains('gundam') ||
        cardName.toLowerCase().contains('newtype') ||
        cardName.toLowerCase().contains('rising')) {
      return {
        'gameId': 'gundam_card_game',
        'extensionId': 'newtype_risings',
      };
    }
    
    // Défaut : Gundam (car c'est le jeu principal pour l'instant)
    return {
      'gameId': 'gundam_card_game',
      'extensionId': 'newtype_risings',
    };
  }
}

class GameCollection {
  final String gameId;
  final Map<String, ExtensionCollection> extensions;

  GameCollection({
    required this.gameId,
    required this.extensions,
  });
}

class ExtensionCollection {
  final String extensionId;
  final Map<String, int> cards;

  ExtensionCollection({
    required this.extensionId,
    required this.cards,
  });
}
