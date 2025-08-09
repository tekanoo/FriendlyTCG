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
