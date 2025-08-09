# Changelog

## 1.1.3+13
- Masquage conditionnel de Pokémon (collection, extensions, jeux, échanges) via `FeatureFlags.hidePokemon`.
- Ajout du fichier `lib/config/feature_flags.dart`.

## 1.1.4+14
- Ajout du mode Analytics minimal (uniquement login/setUserId + screen_view) contrôlé par `FeatureFlags.analyticsMinimal`.
- Déduplication des screen_view via `FeatureFlags.deduplicateScreenViews`.

## 1.1.5+15
- DRY: `FeatureFlags.isGameHidden` utilise `AutoGameService.isPokemonGame`.
- Documentation placeholder `debugExtensions()`.
- Archivage du test exploratoire `file_system_test.dart` (déplacé vers `test/_archive/file_system_test_skip.dart`).
- Renforcement `.gitignore` (keystore, google-services, plist, keystore/jks).

## 1.1.6+16
- Échanges: suppression de l'affichage de la ville, affichage uniquement de la région.
- Ajout fichier `french_regions.dart` (13 régions métropolitaines) et filtre Région dans `TradesScreen` (étape cartes).
- Dépréciation implicite du champ `city` dans `locationDisplay` (non affiché).

## 1.1.7+17
- Extension des régions à 18 (ajout DROM) dans `french_regions.dart`.
- Refactor responsive: remplacement des `GridView.builder` fixes par `AdaptiveCardGrid` dans:
	- `collection_gallery_screen.dart`
	- `extension_gallery_screen.dart`
	- `trades_screen.dart` (sélection jeu + cartes)
	- `screen_size_test_screen.dart`
- Suppression des calculs locaux d'aspect ratio redondants (géré dans `AdaptiveCardGrid`).

## 1.1.8+18
- Correction: le bouton de tri (A-Z / Z-A) n'inversait pas l'ordre sans recherche dans `extension_gallery_screen.dart`.

## 1.1.9+19
- Échanges: résultats de recherche agrégés par utilisateur (affiche chaque utilisateur une seule fois avec le nombre et la liste des cartes correspondantes).

## 1.1.10+20
- Échanges: bouton "Tout sélectionner" pour ajouter d'un coup toutes les cartes filtrées (toutes pages) + compteur (sélection / total filtré).

## 1.1.11+21
- Version dynamique sur l'écran principal (lecture package_info_plus).
- Échanges agrégés: création d'échanges individuels par carte via un dialog de sélection d'une carte offerte (quantités affichées).
- Ajout état visuel (chip validée) après création d'un échange + bouton "Tout échanger" (création séquentielle pour chaque carte restante).

## 1.1.12+22
- Échanges: recherche filtrée sur doublons des autres utilisateurs (onlyDuplicates) + dialog bulk avec images / quantités.
- Échanges: filtre optionnel "Mes doublons (>1)" lors de la sélection des cartes (affiche uniquement les cartes que l'on possède en plusieurs exemplaires avant recherche).
- Dashboard Collection: Progression basée sur cartes uniques; affichage séparé Copies / Uniques / Doublons globalement, par jeu et par extension.
- Modèles stats mis à jour (ownedUnique vs owned copies) sans impact sur API externe.
