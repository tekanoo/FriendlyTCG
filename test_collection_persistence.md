# Test de Persistance de Collection

## Corrections Apportées

### 1. Problème Identifié
- Les cartes retirées jusqu'à 0 ne disparaissaient pas de Firestore
- Cause : Utilisation de `merge: true` qui ne supprime pas les champs

### 2. Solution Implémentée
- Remplacement de `merge: true` par `update()` dans `_saveCollection`
- Utilisation d'une Map complète remplaçant le champ 'cards'
- Ajout de logs détaillés pour traçage

### 3. Modifications du Code

#### CollectionService
```dart
// Avant (problématique)
await userDoc.set({
  'cards': _collection.collection,
  'lastUpdated': FieldValue.serverTimestamp(),
}, SetOptions(merge: true));

// Après (corrigé)
await userDoc.update({
  'cards': _collection.collection,
  'lastUpdated': FieldValue.serverTimestamp(),
  'lastSeen': FieldValue.serverTimestamp(),
});
```

#### CardCollection
- Ajout de logs pour `removeCard()` et `setCardQuantity()`
- Traçage des suppressions de cartes

#### UI (ExtensionGalleryScreen)
- Ajout de logs pour les interactions utilisateur
- Traçage des boutons + et -

### 4. Test à Effectuer

1. **Ajouter une carte** : Vérifier qu'elle apparaît et persiste
2. **Retirer une carte à 0** : Vérifier qu'elle disparaît complètement
3. **Redémarrer l'app** : Vérifier que l'état persiste correctement

### 5. Logs à Surveiller

- `🔼 UI: Ajout de [carte]` - Interaction utilisateur
- `🔽 UI: Retrait de [carte]` - Interaction utilisateur
- `📝 addCard: [carte]` - Service collection
- `🔄 removeCard: [carte]` - Service collection
- `🗑️ Carte supprimée` - Suppression effective
- `💾 Sauvegarde de la collection` - Persistence Firestore
- `✅ Collection sauvegardée` - Confirmation sauvegarde

### 6. Comportement Attendu

Après retrait d'une carte à 0 :
- La carte disparaît de l'UI locale
- La carte est supprimée de `_collection.collection`
- Firestore est mis à jour sans la carte
- Au redémarrage, la carte ne revient pas
