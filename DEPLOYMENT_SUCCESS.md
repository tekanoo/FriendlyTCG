# 🎉 Déploiement réussi !

Votre application Friendly TCG est maintenant en ligne à l'adresse :
**https://friendlytcg-35fba.web.app**

## ⚠️ Configuration requise pour Google Sign-In

Pour que l'authentification Google fonctionne, vous devez configurer les domaines autorisés :

### 1. Aller dans Firebase Console
- Ouvrez https://console.firebase.google.com/project/friendlytcg-35fba
- Allez dans **Authentication** → **Settings** → **Authorized domains**

### 2. Ajouter les domaines autorisés
Ajoutez ces domaines :
- `friendlytcg-35fba.web.app` (votre domaine Firebase)
- `friendlytcg-35fba.firebaseapp.com` (domaine alternatif)
- `localhost` (pour les tests locaux)

### 3. Configurer Google OAuth
- Dans Firebase Console → **Authentication** → **Sign-in method**
- Cliquez sur **Google**
- Dans "Authorized domains", vérifiez que votre domaine est listé

### 4. Google Cloud Console (si nécessaire)
Si vous avez des erreurs OAuth, allez sur :
- https://console.cloud.google.com/apis/credentials
- Sélectionnez votre projet "friendlytcg-35fba"
- Éditez votre "OAuth 2.0 Client ID"
- Ajoutez votre domaine dans "Authorized JavaScript origins"

## 🚀 Commandes de déploiement

```bash
# Build et déployer
flutter build web --release
firebase deploy --only hosting

# Voir les logs
firebase hosting:channel:list

# Déployer sur un canal de prévisualisation
firebase hosting:channel:deploy preview
```

## 🔧 Développement local

```bash
# Lancer en local
flutter run -d chrome --web-port 3000

# Ou avec Firebase Emulator
firebase emulators:start --only hosting
```

## 📱 URL de votre application

- **Production** : https://friendlytcg-35fba.web.app
- **Console Firebase** : https://console.firebase.google.com/project/friendlytcg-35fba/overview

Votre application est maintenant prête ! Une fois les domaines autorisés configurés, l'authentification Google fonctionnera parfaitement. 🎯
