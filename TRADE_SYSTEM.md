# Système d'Échanges de Cartes - Friendly TCG

## Vue d'ensemble

Le système d'échanges permet aux utilisateurs de proposer des échanges de cartes sécurisés avec messagerie intégrée. Le système garantit la sécurité et la confidentialité des utilisateurs.

## Fonctionnalités

### 1. Recherche de cartes
- Les utilisateurs peuvent sélectionner les cartes qu'ils recherchent
- Le système trouve automatiquement les utilisateurs qui possèdent ces cartes
- Affichage des informations sur la dernière connexion

### 2. Proposition d'échange
- Interface pour sélectionner une carte à offrir en échange
- Le système vérifie que l'utilisateur possède bien la carte offerte
- Vérification que l'utilisateur cible ne possède pas déjà la carte offerte

### 3. Messagerie d'échange
- Chat privé sécurisé entre les deux participants
- Messages système automatiques pour le suivi du statut
- Historique complet des conversations
- Messages de sécurité automatiques

### 4. Gestion des statuts d'échange
- **En attente** : Demande d'échange créée, en attente de réponse
- **Accepté** : L'échange a été accepté, discussion ouverte
- **Refusé** : L'échange a été refusé
- **Terminé** : L'échange physique a été effectué
- **Annulé** : L'échange a été annulé par l'un des participants

## Sécurité

### Messages de sécurité automatiques
Chaque nouveau chat d'échange affiche automatiquement :
> ⚠️ IMPORTANT: Ne partagez jamais d'informations personnelles sensibles. Pour les rencontres physiques, choisissez toujours un lieu public et sûr.

### Règles de sécurité Firestore
- Les utilisateurs ne peuvent accéder qu'aux échanges où ils sont participants
- Les messages ne sont visibles que par les participants de l'échange
- Validation côté serveur de tous les accès

### Conseils de sécurité pour les utilisateurs
1. **Lieux de rencontre** : Toujours dans des lieux publics
2. **Informations personnelles** : Ne jamais partager d'adresses ou numéros de téléphone
3. **Verification** : Vérifier l'état des cartes avant l'échange
4. **Accompagnement** : Venir accompagné si possible

## Structure des données

### Collection `trades`
```dart
{
  id: String,
  fromUserId: String,
  toUserId: String,
  fromUserName: String,
  toUserName: String,
  wantedCard: String,
  offeredCard: String,
  status: TradeStatus,
  createdAt: DateTime,
  updatedAt: DateTime?
}
```

### Collection `trade_messages`
```dart
{
  id: String,
  tradeId: String,
  senderId: String,
  senderName: String,
  message: String,
  timestamp: DateTime,
  isSystemMessage: bool
}
```

## Interface utilisateur

### Écran principal des échanges
- Onglet "Rechercher" : Recherche de cartes et utilisateurs
- Onglet "Mes échanges" : Liste de tous les échanges en cours

### Navigation
1. **Recherche** → **Sélection d'utilisateur** → **Proposition d'échange** → **Chat**
2. **Mes échanges** → **Sélection d'échange** → **Chat**

## Notifications

Les messages système incluent :
- Création d'une nouvelle demande d'échange
- Acceptation/refus d'un échange
- Finalisation d'un échange
- Annulation d'un échange
- Messages de sécurité

## Maintenance

### Nettoyage des données
- Les échanges terminés sont conservés pour l'historique
- Les échanges annulés/refusés peuvent être archivés après 30 jours
- Messages conservés indéfiniment pour le suivi

### Monitoring
- Surveillance des échanges suspects
- Détection de tentatives de partage d'informations personnelles
- Statistiques d'utilisation du système d'échange

## Évolutions futures possibles

1. **Système de notation** : Évaluation des utilisateurs après échange
2. **Géolocalisation** : Suggestion de lieux publics à proximité
3. **Modération** : Système de signalement et modération
4. **Échanges multiples** : Proposer plusieurs cartes en une fois
5. **Wishlist** : Liste de souhaits automatique
