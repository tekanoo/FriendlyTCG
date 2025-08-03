class ExtensionModel {
  final String id;
  final String name;
  final String description;
  final String imagePath;
  final List<String> cardImages;
  final String gameId; // Ajout du gameId pour associer l'extension à un jeu

  ExtensionModel({
    required this.id,
    required this.name,
    required this.description,
    required this.imagePath,
    required this.cardImages,
    required this.gameId,
  });
}

class CardModel {
  final String name;
  final String imagePath;
  final String displayName;

  CardModel({
    required this.name,
    required this.imagePath,
    required this.displayName,
  });
}
