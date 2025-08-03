import '../models/extension_model.dart';
import 'generated_cards_list.dart';

class ExtensionService {
  static final ExtensionService _instance = ExtensionService._internal();
  factory ExtensionService() => _instance;
  ExtensionService._internal();

  // Liste des extensions disponibles
  List<ExtensionModel> get availableExtensions => [
    ExtensionModel(
      id: 'newtype_risings',
      name: 'NewType Risings',
      description: 'Collection de cartes Gundam NewType Risings',
      imagePath: 'assets/images/Gundam Cards/newtype_risings/GD01-001.png',
      cardImages: _getNewtypeRisingsCards(),
      gameId: 'gundam_card_game',
    ),
    ExtensionModel(
      id: 'prismatic-evolutions',
      name: 'Prismatic Evolutions',
      description: 'Collection de cartes Pokémon Prismatic Evolutions',
      imagePath: 'assets/images/Pokemon/prismatic-evolutions/SV8pt5_FR_63-2x.png',
      cardImages: _getPrismaticEvolutionsCards(),
      gameId: 'pokemon_tcg',
    ),
  ];

  // Obtenir les cartes NewType Risings
  List<String> _getNewtypeRisingsCards() {
    return GeneratedCardsList.getNewtypeRisingsCards();
  }

  // Obtenir les cartes Prismatic Evolutions
  List<String> _getPrismaticEvolutionsCards() {
    return [
      'SV8pt5_FR_63-2x.png',
      // Ajoutez ici d'autres cartes quand vous les ajouterez
    ];
  }

  // Obtenir une extension par ID
  ExtensionModel? getExtensionById(String id) {
    try {
      return availableExtensions.firstWhere((ext) => ext.id == id);
    } catch (e) {
      return null;
    }
  }

  // Convertir les noms de fichiers en modèles de cartes
  List<CardModel> getCardsForExtension(String extensionId) {
    final extension = getExtensionById(extensionId);
    if (extension == null) return [];

    return extension.cardImages.map((cardImage) {
      // Déterminer le chemin selon l'extension
      String basePath;
      if (extensionId == 'newtype_risings') {
        basePath = 'assets/images/Gundam Cards';
      } else if (extensionId == 'prismatic-evolutions') {
        basePath = 'assets/images/Pokemon';
      } else {
        basePath = 'assets/images/Gundam Cards'; // par défaut
      }

      return CardModel(
        name: cardImage,
        imagePath: '$basePath/$extensionId/$cardImage',
        displayName: _formatCardName(cardImage),
      );
    }).toList();
  }

  // Formater le nom d'affichage de la carte
  String _formatCardName(String fileName) {
    // Enlever l'extension .png
    String name = fileName.replaceAll('.png', '');
    
    // Remplacer les underscores par des espaces
    name = name.replaceAll('_', ' ');
    
    return name;
  }

  // Obtenir les extensions pour un jeu spécifique
  List<ExtensionModel> getExtensionsForGame(String gameId) {
    return availableExtensions.where((extension) => extension.gameId == gameId).toList();
  }
}
