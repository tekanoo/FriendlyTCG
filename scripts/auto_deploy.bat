@echo off
echo 🎯 Déploiement automatique avec détection des cartes
echo ================================================
echo.

echo 📂 Étape 1: Génération automatique de la liste des cartes...
cd /d "%~dp0.."
dart run scripts/generate_cards.dart
if %ERRORLEVEL% NEQ 0 (
    echo ❌ Erreur lors de la génération automatique
    pause
    exit /b 1
)

echo.
echo 🧹 Étape 2: Nettoyage...
call flutter clean
if %ERRORLEVEL% NEQ 0 (
    echo ❌ Erreur lors du nettoyage
    pause
    exit /b 1
)

echo.
echo 📦 Étape 3: Récupération des dépendances...
call flutter pub get
if %ERRORLEVEL% NEQ 0 (
    echo ❌ Erreur lors de la récupération des dépendances
    pause
    exit /b 1
)

echo.
echo 🔨 Étape 4: Build web...
call flutter build web
if %ERRORLEVEL% NEQ 0 (
    echo ❌ Erreur lors du build
    pause
    exit /b 1
)

echo.
echo 🚀 Étape 5: Déploiement Firebase...
call firebase deploy
if %ERRORLEVEL% NEQ 0 (
    echo ❌ Erreur lors du déploiement
    pause
    exit /b 1
)

echo.
echo ✅ Déploiement terminé avec succès!
echo 🎉 L'application a été déployée avec détection automatique des cartes
echo 📊 Tous les jeux et extensions dans assets/images sont maintenant disponibles
pause
