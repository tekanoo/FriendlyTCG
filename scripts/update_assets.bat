@echo off
echo 🔧 Vérification de la configuration des assets...
cd /d "%~dp0.."
dart scripts/update_assets.dart
if %errorlevel% == 0 (
    echo.
    echo ✅ Vérification terminée !
    echo 💡 Avec la configuration "assets: - assets/", toutes les extensions
    echo    sont automatiquement détectées sans modification manuelle.
) else (
    echo ❌ Erreur lors de la vérification
)
pause
