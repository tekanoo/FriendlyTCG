#!/bin/bash

# Script de déploiement pour friendly-tcg.com
# Ce script rebuild et déploie l'application avec la nouvelle configuration

echo "🚀 Déploiement Friendly TCG - friendly-tcg.com"
echo "================================================"

# 1. Nettoyage
echo "🧹 Nettoyage des fichiers de build..."
flutter clean

# 2. Récupération des dépendances
echo "📦 Récupération des dépendances..."
flutter pub get

# 3. Build pour production
echo "🏗️ Build de l'application web..."
flutter build web --release

# 4. Vérification du build
if [ $? -eq 0 ]; then
    echo "✅ Build réussi !"
    
    # 5. Déploiement Firebase
    echo "🌐 Déploiement sur Firebase Hosting..."
    firebase deploy --only hosting
    
    if [ $? -eq 0 ]; then
        echo "🎉 Déploiement réussi !"
        echo "🔗 Site accessible sur: https://friendly-tcg.com"
        echo ""
        echo "⚠️ N'oubliez pas de configurer dans Firebase Console :"
        echo "   - Domaines autorisés (Authentication > Settings)"
        echo "   - OAuth Credentials (Google Cloud Console)"
        echo "   - JavaScript Origins et Redirect URIs"
    else
        echo "❌ Erreur lors du déploiement"
        exit 1
    fi
else
    echo "❌ Erreur lors du build"
    exit 1
fi
