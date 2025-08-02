# Configuration des règles de sécurité Firestore pour les échanges

## Structure de données

### Collection `users`
```
users/
  {uid}/
    email: string
    displayName: string?
    photoURL: string?
    cards: map<string, number>
    lastSeen: timestamp
    lastUpdated: timestamp
```

### Règles de sécurité à ajouter dans Firestore

```javascript
rules_version = '2';
service cloud.firestore {
  match /databases/{database}/documents {
    // Règle pour la collection users
    match /users/{userId} {
      // Lecture : Autorisé pour tous les utilisateurs connectés
      allow read: if request.auth != null;
      
      // Écriture : Autorisé seulement pour le propriétaire du document
      allow write: if request.auth != null && request.auth.uid == userId;
    }
  }
}
```

## Index Firestore requis

Créer les index suivants dans la console Firebase :

1. **Index pour la recherche par cartes** :
   - Collection : `users`
   - Champs : 
     - `cards.{cardName}` (Ascending)
     - `lastSeen` (Descending)

2. **Index pour les utilisateurs actifs** :
   - Collection : `users`
   - Champs :
     - `lastSeen` (Descending)

## Commandes pour créer les index via CLI Firebase

```bash
# Déployer les règles de sécurité
firebase deploy --only firestore:rules

# Les index seront créés automatiquement lors de l'utilisation de l'application
# ou peuvent être configurés manuellement dans la console Firebase
```
