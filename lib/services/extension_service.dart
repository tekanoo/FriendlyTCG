import '../models/extension_model.dart';
import 'auto_game_service.dart';

class ExtensionService {
  static final ExtensionService _instance = ExtensionService._internal();
  factory ExtensionService() => _instance;
  ExtensionService._internal();

  /// Obtient toutes les extensions disponibles (automatiquement détectées)
  List<ExtensionModel> get availableExtensions => AutoGameService.getAllExtensions();

  /// Obtient les extensions pour un jeu spécifique
  List<ExtensionModel> getExtensionsForGame(String gameId) {
    return AutoGameService.getExtensionsForGame(gameId);
  }

  /// Obtient une extension par son ID
  ExtensionModel? getExtensionById(String extensionId) {
    try {
      return availableExtensions.firstWhere((ext) => ext.id == extensionId);
    } catch (e) {
      return null;
    }
  }

  /// Obtient les cartes d'une extension
  List<String> getCardsForExtension(String extensionId) {
    return AutoGameService.getCardsForExtension(extensionId);
  }

  /// Obtient le chemin d'une carte spécifique
  String getCardImagePath(String extensionId, String cardName) {
    return AutoGameService.getCardImagePath(extensionId, cardName);
  }

  /// Recharge les données depuis les dossiers
  void reloadExtensions() {
    AutoGameService.clearCache();
  }
}