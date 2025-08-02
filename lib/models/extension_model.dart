class ExtensionModel {
  final String id;
  final String name;
  final String description;
  final String imagePath;
  final List<String> cardImages;

  ExtensionModel({
    required this.id,
    required this.name,
    required this.description,
    required this.imagePath,
    required this.cardImages,
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
