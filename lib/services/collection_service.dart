import '../models/card_collection.dart';

class CollectionService {
  static final CollectionService _instance = CollectionService._internal();
  factory CollectionService() => _instance;
  CollectionService._internal();

  final CardCollection _collection = CardCollection();

  // Obtenir la collection
  CardCollection get collection => _collection;

  // Ajouter une carte
  void addCard(String cardName, [int quantity = 1]) {
    _collection.addCard(cardName, quantity);
    // TODO: Sauvegarder en local storage ou Firebase
  }

  // Retirer une carte
  void removeCard(String cardName, [int quantity = 1]) {
    _collection.removeCard(cardName, quantity);
    // TODO: Sauvegarder en local storage ou Firebase
  }

  // Définir une quantité
  void setCardQuantity(String cardName, int quantity) {
    _collection.setCardQuantity(cardName, quantity);
    // TODO: Sauvegarder en local storage ou Firebase
  }

  // Obtenir la quantité d'une carte
  int getCardQuantity(String cardName) {
    return _collection.getCardQuantity(cardName);
  }
}
