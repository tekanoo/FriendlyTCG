<div align="center">

# Friendly TCG App 🃏

Application Flutter (Web-first) de gestion de collection et d'échanges de cartes TCG multi-jeux.

**Version actuelle : 1.1.13+23**  
Consommation contrôlée des doublons (échanges bulk) + feedback Firestore.

</div>

---

## ✨ Fonctionnalités principales

- 🔍 Détection automatique des jeux / extensions via génération (`GeneratedCardsList` / structure des assets)
- 🖼️ Affichage des logos / images cartes avec fallback et vérification par tests
- 📁 Navigation par Jeux → Extensions → Cartes (grilles paginées 3x3, recherche, tri A/Z)
- 📦 Gestion de collection (cartes possédées vs non possédées, quantité)
- 🔄 Système d'échanges avancé (agrégation par utilisateur, échanges bulk, limitation consommation de doublons)
 - 📊 Mode Analytics configurable (minimal: login + écrans) avec déduplication optionnelle
- 🧪 Suite de tests d'intégrité des assets & cohérence (logos, variantes, structure)
- 🏷️ Feature flags activables sans retirer le code (ex: masquage Pokémon)
- 🚀 Scripts de déploiement (Web) simplifiés

---

## 🧩 Architecture rapide

| Domaine | Emplacement | Description |
|---------|-------------|-------------|
| Config | `lib/config/` | Flags & config prod (`feature_flags.dart`, `production_config.dart`) |
| Services | `lib/services/` | Analytique, jeux, auto-détection, collection, échanges |
| Modèles | `lib/models/` | `GameModel`, `ExtensionModel`, `TradeModel`, etc. |
| UI Écrans | `lib/screens/` | Navigation principale (Games, Extensions, Collection, Trades, Analytics Debug) |
| Widgets | `lib/widgets/` | Composants réutilisables (pagination, grilles adaptatives, modals) |
| Assets | `assets/` | Logos, images de cartes classées par jeu/extension |
| Tests | `test/` | Vérifications assets / cohérence |

---

## 🔐 Feature Flags (`lib/config/feature_flags.dart`)

| Flag | Par défaut | Effet |
|------|------------|-------|
| `hidePokemon` | `true` | Masque Pokémon partout (jeux, extensions, collection, échanges) sans supprimer les assets |
| `analyticsMinimal` | `true` | N'envoie que `login` (pour lier userId) + `screen_view` (pas d'événements custom) |
| `deduplicateScreenViews` | `true` | Empêche l'envoi multiple du même `screen_view` par session |
| `ProductionConfig.isDebugMode` | `false` | Active les logs conditionnels production si besoin |

Pour réactiver Pokémon : mettre `hidePokemon = false`, rebuild et redéployer.

---

## 🎮 Gestion des Jeux & Extensions

- Source: `AutoGameService` lit la structure générée (`GeneratedCardsList.getGameStructure()`).
- Conversion nom → id: normalisation lowercase-avec-tirets.
- Image de jeu choisie dynamiquement (`_getGameImagePath`).
- Extensions: première carte de l'extension utilisée comme visuel.

Filtrage Pokémon appliqué dans `GameService.availableGames` et `getExtensionsForGame`.

---

## 🗂️ Collection & Galerie

- Grille 3x3 paginée (9 cartes / page) avec navigation.
- Recherche temps réel + tri A→Z / Z→A.
- Cartes non possédées grises (quantité via `CollectionService`).
- Modale de gestion (ajout/retrait) spécifique (inclut support Pokémon mais masqué si flag actif).

---

## 🔄 Échanges (Trades)

- Recherche utilisateurs possédant vos cartes manquantes (option doublons uniquement)
- Agrégation par utilisateur avec compteur de correspondances
- Sélection simple ou création en lot (bulk) avec attribution d'un doublon différent si capacité épuisée
- Contrôle de capacité: une copie excédentaire (qty-1) ne peut être réutilisée dans la même opération
- Dialogs avec images + quantités (vous / autre)
- Historique / statut sur chip après création

---

## 📊 Analytics

Service: `AnalyticsService`.

Modes:
- Standard (`analyticsMinimal = false`) : envoie `app_start`, `login`, `logout`, `view_game`, `view_extension`, `add_card`, `remove_card`, `create_trade`, `collection_stats`, `screen_view`.
- Minimal (`analyticsMinimal = true`) : seulement `login` (identifiant unique) + `screen_view` (dédupliqué si activé).

---

## 🧪 Tests

| Fichier | Objectif |
|---------|----------|
| `assets_verification_test.dart` | Existence des logos et cohérence noms de jeux |
| `consistency_test.dart` | Structure jeux/extensions, chemins d'images |
| `logo_test.dart` | Chemins logos attendus |
| `pokemon_variants_test.dart` (si présent) | Variantes assets Pokémon |
| `file_system_test.dart` | Exploratoire (peut être archivé si plus utile) |

Exécution :
```
flutter test
flutter test test/logo_test.dart
```

---

## 🗃️ Structure des Assets (extrait)

```
assets/
	images/
		gundam_cards/...
		Pokemon/...
	logo/
		Gundam/
		Pokémon/
```

Ajouter une extension : déposer le dossier sous `assets/images/<game>/<extension>/` puis régénérer la liste (scripts éventuels).

---

## 🚀 Déploiement Web

Scripts : `deploy.sh` / `deploy.bat`, `scripts/build_and_deploy.bat`.

Exemple :
```
flutter build web --release
firebase deploy --only hosting
```

Pré-requis : `flutter pub get` + `firebase login`.

---

## 🛠️ Développement

```
flutter pub get
flutter run -d web-server --web-port 3000
```

Linting via `analysis_options.yaml`.

---

## 🔄 Réactiver Pokémon
1. Ouvrir `lib/config/feature_flags.dart`
2. `hidePokemon = false`
3. (Option) `analyticsMinimal = false`
4. Rebuild / déploiement.

---

## ♻️ Roadmap potentielle
- Toggle runtime (Remote Config / Firestore)
- Tests d'échanges & analytics supplémentaires
- Optimisation images (WebP)
- Internationalisation (FR / EN)

---

## ⚠️ Note
Projet privé (`publish_to: none`). Adapter licence si diffusion publique.

---

## 🤝 Contribution
Branche dédiée + PR + tests OK + mise à jour changelog si nécessaire.

---

## 📬 Support & Feedback
Utilisez la bulle flottante (coin inférieur gauche) pour envoyer un feedback directement (stocké dans Firestore). Pas d'email externe requis.

---

Happy collecting & trading! ✨