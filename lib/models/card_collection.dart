class CardCollection {
  final Map<String, int> _collection = {};

  // Obtenir la quantité d'une carte
  int getCardQuantity(String cardName) {
    return _collection[cardName] ?? 0;
  }

  // Ajouter une carte à la collection
  void addCard(String cardName, [int quantity = 1]) {
    _collection[cardName] = (_collection[cardName] ?? 0) + quantity;
  }

  // Retirer une carte de la collection
  void removeCard(String cardName, [int quantity = 1]) {
    int currentQuantity = _collection[cardName] ?? 0;
    int newQuantity = currentQuantity - quantity;
    
    if (newQuantity <= 0) {
      _collection.remove(cardName);
    } else {
      _collection[cardName] = newQuantity;
    }
  }

  // Définir une quantité spécifique
  void setCardQuantity(String cardName, int quantity) {
    if (quantity <= 0) {
      _collection.remove(cardName);
    } else {
      _collection[cardName] = quantity;
    }
  }

  // Obtenir le nombre total de cartes différentes
  int get totalUniqueCards => _collection.length;

  // Obtenir le nombre total de cartes
  int get totalCards => _collection.values.fold(0, (sum, quantity) => sum + quantity);

  // Obtenir toute la collection
  Map<String, int> get collection => Map.unmodifiable(_collection);

  // Vérifier si une carte est dans la collection
  bool hasCard(String cardName) => _collection.containsKey(cardName);
}
