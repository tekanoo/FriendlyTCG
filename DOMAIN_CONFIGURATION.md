# Configuration Domaine Firebase - friendly-tcg.com

## Problème
- L'application utilise le nouveau domaine `friendly-tcg.com`
- L'authentification Google échoue car Firebase n'autorise pas ce domaine
- Le `authDomain` a été mis à jour dans le code mais d'autres configurations sont nécessaires

## Solutions Requises

### 1. ✅ Code Flutter (Déjà fait)
- [x] Mise à jour de `authDomain` dans `firebase_options.dart`
- [x] Changement de `friendlytcg-35fba.firebaseapp.com` vers `friendly-tcg.com`

### 2. 🔧 Configuration Firebase Console (À faire)

#### A. Ajouter le domaine aux domaines autorisés
1. Aller sur [Firebase Console](https://console.firebase.google.com/)
2. Sélectionner le projet `friendlytcg-35fba`
3. Aller dans **Authentication** > **Settings** > **Authorized domains**
4. Ajouter `friendly-tcg.com` à la liste des domaines autorisés
5. Supprimer l'ancien domaine si nécessaire

#### B. Mettre à jour la configuration OAuth Google
1. Aller sur [Google Cloud Console](https://console.cloud.google.com/)
2. Sélectionner le projet `friendlytcg-35fba`
3. Aller dans **APIs & Services** > **Credentials**
4. Éditer le client OAuth 2.0 Web
5. Ajouter `https://friendly-tcg.com` aux **Authorized JavaScript origins**
6. Ajouter `https://friendly-tcg.com/__/auth/handler` aux **Authorized redirect URIs**

#### C. Vérifier la configuration du domaine personnalisé
1. Dans Firebase Console > **Hosting**
2. Vérifier que `friendly-tcg.com` est bien configuré
3. S'assurer que le certificat SSL est actif

### 3. 🔍 URLs à Configurer

#### JavaScript Origins autorisées:
- `https://friendly-tcg.com`
- `http://localhost` (pour le développement)
- `http://localhost:5000` (pour le développement)

#### Redirect URIs autorisées:
- `https://friendly-tcg.com/__/auth/handler`
- `http://localhost/__/auth/handler` (pour le développement)

### 4. 🚀 Test après configuration
1. Déployer la nouvelle version avec `authDomain` mis à jour
2. Tester la connexion Google sur `friendly-tcg.com`
3. Vérifier que les redirections fonctionnent correctement

### 5. 🐛 Debugging
Si le problème persiste, vérifier :
- Les logs de la console navigateur
- Les erreurs Firebase Auth dans la console
- La propagation DNS du domaine
- La validité du certificat SSL

## Commandes utiles

### Rebuild et redéploiement
```bash
flutter build web
firebase deploy --only hosting
```

### Vérification DNS
```bash
nslookup friendly-tcg.com
```

### Test local avec nouveau domaine
```bash
flutter run -d chrome --web-hostname friendly-tcg.com --web-port 5000
```
