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
      imagePath: 'assets/images/extensions/newtype_risings/GD01-001.png',
      cardImages: _getNewtypeRisingsCards(),
    ),
  ];

  // Obtenir les cartes NewType Risings
  List<String> _getNewtypeRisingsCards() {
    return GeneratedCardsList.getNewtypeRisingsCards();
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
      return CardModel(
        name: cardImage,
        imagePath: 'assets/images/extensions/$extensionId/$cardImage',
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
}
