# Configuration Firebase pour Friendly TCG - Application Web

## Configuration Firebase Web

### 1. Créer un projet Firebase

1. Allez sur [Firebase Console](https://console.firebase.google.com/)
2. Cliquez sur "Ajouter un projet"
3. Nom du projet : "friendly-tcg" (ou selon votre préférence)
4. Activez Google Analytics si désiré
5. Créez le projet

### 2. Configurer l'authentification

1. Dans Firebase Console → **Authentication**
2. Cliquez sur "Commencer"
3. Onglet **"Sign-in method"** → Activez **"Google"**
4. Ajoutez votre email dans "Authorized domains" si nécessaire
5. Sauvegardez

### 3. Ajouter une application Web

1. Dans Firebase Console → Icône **Web** (`</>`)
2. Nom de l'app : "Friendly TCG Web"
3. ✅ Cochez "Also set up Firebase Hosting"
4. Cliquez sur "Enregistrer l'application"

### 4. Copier la configuration Firebase

Copiez les valeurs de configuration affichées et remplacez dans `lib/firebase_options.dart` :

```dart
static const FirebaseOptions web = FirebaseOptions(
  apiKey: 'votre-api-key',
  appId: 'votre-app-id', 
  messagingSenderId: 'votre-sender-id',
  projectId: 'votre-project-id',
  authDomain: 'votre-project-id.firebaseapp.com',
  storageBucket: 'votre-project-id.appspot.com',
  measurementId: 'votre-measurement-id', // Si Analytics activé
);
```

### 5. Configuration Firebase Hosting

Votre `firebase.json` est déjà configuré pour le hosting. Pour initialiser :

```bash
# Installer Firebase CLI
npm install -g firebase-tools

# Se connecter
firebase login

# Initialiser le projet (dans le dossier racine)
firebase init hosting

# Sélectionner le projet créé
# Public directory: build/web
# Single-page app: Yes
# Overwrite build/web/index.html: No
```

### 6. Scripts de développement et déploiement

Ajoutez ces scripts à votre workflow :

```bash
# Développement local
flutter run -d chrome

# Build pour production
flutter build web --release

# Déployer sur Firebase Hosting
firebase deploy --only hosting

# Voir les logs de déploiement
firebase hosting:channel:list
```

### 7. Configuration des domaines autorisés

Dans Firebase Console → **Authentication** → **Settings** → **Authorized domains** :

- Ajoutez votre domaine personnalisé
- Ajoutez `localhost` pour les tests locaux
- Ajoutez le domaine Firebase Hosting : `votre-project-id.web.app`

### 8. Variables d'environnement (optionnel)

Créez `.env` pour les clés sensibles :

```env
FIREBASE_API_KEY=votre-api-key
FIREBASE_PROJECT_ID=votre-project-id
```

### 9. Test de l'application

```bash
# Nettoyer et installer les dépendances
flutter clean
flutter pub get

# Lancer en mode debug web
flutter run -d chrome --web-port 3000

# Build et test en local
flutter build web --release
firebase emulators:start --only hosting
```

### 10. Déploiement automatique (GitHub Actions)

Créez `.github/workflows/firebase-hosting-merge.yml` :

```yaml
name: Deploy to Firebase Hosting on merge
on:
  push:
    branches: [ main ]

jobs:
  build_and_deploy:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v3
      - uses: subosito/flutter-action@v2
        with:
          flutter-version: '3.32.7'
      - run: flutter pub get
      - run: flutter build web --release
      - uses: FirebaseExtended/action-hosting-deploy@v0
        with:
          repoToken: '${{ secrets.GITHUB_TOKEN }}'
          firebaseServiceAccount: '${{ secrets.FIREBASE_SERVICE_ACCOUNT }}'
          projectId: votre-project-id
```

## Commandes principales

```bash
# Développement
flutter run -d chrome

# Build production
flutter build web --release --web-renderer html

# Déploiement
firebase deploy

# Preview avant déploiement
firebase hosting:channel:deploy preview

# Logs de Firebase
firebase functions:log
```

## Troubleshooting Web

### Erreur CORS
- Vérifiez les domaines autorisés dans Firebase Console
- Assurez-vous que `localhost` est autorisé pour le développement

### Google Sign-In ne fonctionne pas
- Vérifiez que l'authentification Google est activée
- Vérifiez les domaines autorisés
- Testez avec les outils de développement ouverts

### Build web échoue
```bash
flutter clean
flutter pub get
flutter build web --verbose
```

### Performance web
- Utilisez `--web-renderer html` pour une meilleure compatibilité
- Optimisez les images dans `web/icons/`
- Activez la compression gzip sur Firebase Hosting

## Structure finale

```
friendly_tcg_app/
├── lib/
│   ├── firebase_options.dart
│   ├── main.dart
│   ├── services/auth_service.dart
│   ├── screens/
│   └── widgets/
├── web/
│   ├── index.html
│   ├── manifest.json
│   └── icons/
├── firebase.json
├── .firebaserc
└── pubspec.yaml
```
