@echo off
echo 🧪 Test de la détection automatique
echo ================================
echo.

cd /d "%~dp0.."

echo 📂 Étape 1: Génération des cartes...
dart run scripts/generate_cards.dart
if %ERRORLEVEL% NEQ 0 (
    echo ❌ Erreur génération
    pause
    exit /b 1
)

echo.
echo 🔍 Étape 2: Analyse du code...
flutter analyze --no-fatal-infos
if %ERRORLEVEL% NEQ 0 (
    echo ⚠️  Analyse terminée avec des avertissements
    echo ℹ️  Continuez si seuls des warnings sont présents
) else (
    echo ✅ Analyse réussie
)

echo.
echo 🚀 Étape 3: Test rapide...
echo Voulez-vous tester l'application localement ? (O/N)
set /p "response="
if /i "%response%"=="O" (
    flutter run -d web-server --web-port 3000
)

echo.
echo ✅ Test terminé
pause
