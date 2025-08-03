# 🎯 Système de Détection Automatique des Cartes

## 📋 Vue d'ensemble

L'application détecte maintenant automatiquement tous les jeux et extensions présents dans le dossier `assets/images/` sans configuration manuelle.

## 🚀 Déploiement Automatique

### Commande rapide
```bash
scripts\auto_deploy.bat
```

### Étapes manuelles
```bash
# 1. Génération automatique
dart run scripts/generate_cards.dart

# 2. Build et déploiement standard
flutter clean
flutter pub get
flutter build web
firebase deploy
```

## 📂 Structure des Dossiers

```
assets/images/
├── Gundam Cards/           # Jeu détecté automatiquement
│   └── newtype_risings/    # Extension détectée
│       ├── GD01-001.png    # Cartes détectées
│       ├── GD01-002.png
│       └── ...
├── Pokemon/                # Jeu détecté automatiquement
│   └── prismatic-evolutions/ # Extension détectée
│       ├── SV8pt5_FR_1.png # Cartes détectées
│       ├── SV8pt5_FR_2.png
│       └── ...
└── [Nouveau Jeu]/          # Sera détecté automatiquement
    └── [nouvelle_extension]/ # Sera détectée automatiquement
        └── *.png           # Toutes les cartes PNG
```

## ⚡ Fonctionnement

### 1. Détection Automatique
- **Scan des dossiers** : Le script parcourt `assets/images/`
- **Jeux détectés** : Chaque sous-dossier = un jeu
- **Extensions détectées** : Chaque sous-sous-dossier = une extension
- **Cartes détectées** : Tous les fichiers `.png`

### 2. Génération du Code
- **`generated_cards_list.dart`** : Créé automatiquement
- **Méthodes générées** : Une par extension (ex: `getNewtypeRisingsCards()`)
- **Métadonnées** : Structure des jeux, mapping extension→jeu

### 3. Services Automatiques
- **AutoGameService** : Charge automatiquement les jeux/extensions
- **GameService** : Utilise AutoGameService (compatible existant)
- **ExtensionService** : Utilise AutoGameService (compatible existant)

## 🎮 Ajouter de Nouveaux Contenus

### Nouveau Jeu
1. Créer le dossier : `assets/images/MonNouveauJeu/`
2. Redéployer : `scripts\auto_deploy.bat`
3. ✅ Automatiquement disponible dans l'app

### Nouvelle Extension
1. Créer le dossier : `assets/images/JeuExistant/nouvelle_extension/`
2. Ajouter les cartes PNG
3. Redéployer : `scripts\auto_deploy.bat`
4. ✅ Automatiquement disponible dans l'app

### Nouvelles Cartes
1. Ajouter les fichiers PNG dans l'extension
2. Redéployer : `scripts\auto_deploy.bat`
3. ✅ Automatiquement disponibles dans l'app

## 🔧 Fichiers Générés

### `lib/services/generated_cards_list.dart`
```dart
class GeneratedCardsList {
  // Méthodes générées automatiquement
  static List<String> getNewtypeRisingsCards() => [...];
  static List<String> getPrismaticEvolutionsCards() => [...];
  
  // Métadonnées générées
  static Map<String, List<String>> getGameStructure() => {...};
  static List<String> getAllExtensionIds() => [...];
  static String getCardPath(String ext, String card) => "...";
}
```

## 🛠️ Scripts Disponibles

### `scripts/generate_cards.dart`
- **Fonction** : Scan et génération automatique
- **Usage** : `dart run scripts/generate_cards.dart`
- **Sortie** : `lib/services/generated_cards_list.dart`

### `scripts/auto_deploy.bat`
- **Fonction** : Génération + Build + Déploiement complet
- **Usage** : `scripts\auto_deploy.bat`
- **Étapes** : Generation → Clean → Pub Get → Build → Deploy

### `scripts/test_auto_detection.bat`
- **Fonction** : Test rapide du système
- **Usage** : `scripts\test_auto_detection.bat`
- **Sortie** : Analyse + option de test local

## ✅ Avantages

- **🔄 Zéro configuration** : Plus besoin de modifier le code pour ajouter des cartes
- **📈 Scalable** : Supporte un nombre illimité de jeux/extensions
- **🎯 Cohérent** : Structure unifiée pour tous les contenus
- **⚡ Rapide** : Déploiement en une commande
- **🔒 Sûr** : Compatible avec l'existant, pas de breaking changes

## 🚨 Notes Importantes

- **Noms de fichiers** : Seuls les `.png` sont détectés
- **Structure obligatoire** : `Jeu/Extension/carte.png`
- **Régénération** : Nécessaire après chaque ajout de contenu
- **Cache** : `AutoGameService.clearCache()` pour forcer le rechargement

## 🔄 Migration

L'ancien système reste compatible :
- `GameService.availableGames` fonctionne toujours
- `ExtensionService.availableExtensions` fonctionne toujours
- Les écrans existants fonctionnent sans modification

Le nouveau système ajoute la détection automatique par-dessus.
