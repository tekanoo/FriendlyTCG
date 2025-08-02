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
    
    print('🔄 removeCard: $cardName, quantité actuelle: $currentQuantity, retrait: $quantity, nouvelle quantité: $newQuantity');
    
    if (newQuantity <= 0) {
      _collection.remove(cardName);
      print('🗑️ Carte supprimée de la collection: $cardName');
    } else {
      _collection[cardName] = newQuantity;
      print('📝 Quantité mise à jour: $cardName = $newQuantity');
    }
  }

  // Définir une quantité spécifique
  void setCardQuantity(String cardName, int quantity) {
    print('🔄 setCardQuantity: $cardName = $quantity');
    
    if (quantity <= 0) {
      _collection.remove(cardName);
      print('🗑️ Carte supprimée (quantité = 0): $cardName');
    } else {
      _collection[cardName] = quantity;
      print('📝 Quantité définie: $cardName = $quantity');
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
