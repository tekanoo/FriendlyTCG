@echo off
echo 🎯 Mise à jour automatique des cartes et déploiement...

echo 📋 Génération de la liste des cartes...
dart run scripts/generate_cards_list.dart

echo 🧹 Nettoyage des fichiers de build...
flutter clean

echo 📦 Récupération des dépendances...
flutter pub get

echo 🔨 Construction de l'application web...
flutter build web --release

echo 🚀 Déploiement sur Firebase...
firebase deploy --only hosting

echo ✅ Déploiement terminé !
pause
