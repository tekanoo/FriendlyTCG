@echo off
REM Script de déploiement pour friendly-tcg.com (Windows)
REM Ce script rebuild et déploie l'application avec la nouvelle configuration

echo 🚀 Déploiement Friendly TCG - friendly-tcg.com
echo ================================================

REM 1. Nettoyage
echo 🧹 Nettoyage des fichiers de build...
flutter clean

REM 2. Récupération des dépendances
echo 📦 Récupération des dépendances...
flutter pub get

REM 3. Build pour production
echo 🏗️ Build de l'application web...
flutter build web --release

REM 4. Vérification du build et déploiement
if %errorlevel% equ 0 (
    echo ✅ Build réussi !
    
    REM 5. Déploiement Firebase
    echo 🌐 Déploiement sur Firebase Hosting...
    firebase deploy --only hosting
    
    if %errorlevel% equ 0 (
        echo 🎉 Déploiement réussi !
        echo 🔗 Site accessible sur: https://friendly-tcg.com
        echo.
        echo ⚠️ N'oubliez pas de configurer dans Firebase Console :
        echo    - Domaines autorisés (Authentication ^> Settings^)
        echo    - OAuth Credentials (Google Cloud Console^)
        echo    - JavaScript Origins et Redirect URIs
    ) else (
        echo ❌ Erreur lors du déploiement
        pause
        exit /b 1
    )
) else (
    echo ❌ Erreur lors du build
    pause
    exit /b 1
)

pause
