# 🔧 Correction de l'erreur "Null check operator used on a null value"

## ✅ Corrections apportées

1. **Méthode d'authentification web optimisée** - Utilise `signInWithPopup` au lieu de Google Sign-In SDK
2. **Gestion des tokens null** - Vérifications ajoutées pour éviter les erreurs null
3. **Séparation web/mobile** - Logique différente pour chaque plateforme

## 🔧 Configuration Google OAuth (optionnelle pour améliorer la sécurité)

### 1. Obtenir le Web Client ID

1. Allez sur [Google Cloud Console](https://console.cloud.google.com/)
2. Sélectionnez votre projet `friendlytcg-35fba`
3. **APIs & Services** → **Credentials**
4. Trouvez votre "OAuth 2.0 Client IDs" de type "Web application"
5. Copiez le Client ID (format: `xxx.apps.googleusercontent.com`)

### 2. Mettre à jour la configuration (optionnel)

Si vous voulez utiliser le Google Sign-In SDK au lieu de la popup Firebase :

```dart
// Dans AuthService constructor
_googleSignIn = GoogleSignIn(
  clientId: 'VOTRE_WEB_CLIENT_ID.apps.googleusercontent.com',
  scopes: ['email', 'profile'],
);
```

### 3. Vérifier les domaines autorisés

Dans Google Cloud Console → **APIs & Services** → **Credentials** :
- Éditez votre OAuth 2.0 Client ID
- Dans "Authorized JavaScript origins", ajoutez :
  - `https://friendlytcg-35fba.web.app`
  - `https://friendlytcg-35fba.firebaseapp.com`
  - `http://localhost:3000` (pour dev local)

## 🧪 Test de la correction

1. **Ouvrez votre application** : https://friendlytcg-35fba.web.app
2. **Cliquez sur "Se connecter avec Google"**
3. **Vérifiez** qu'une popup Google s'ouvre correctement

## 🐛 Si le problème persiste

### Vérifications supplémentaires :

1. **Console Firebase** → **Authentication** → **Sign-in method** → **Google** doit être activé
2. **Console Firebase** → **Authentication** → **Settings** → **Authorized domains** doit contenir votre domaine
3. **Ouvrez les outils de développement** (F12) et vérifiez la console pour d'autres erreurs

### Messages d'erreur courants :

- `"popup_closed_by_user"` - L'utilisateur a fermé la popup (normal)
- `"access_denied"` - Problème de domaines autorisés
- `"invalid_client"` - Problème de configuration OAuth

## 🔄 Méthode alternative (si problèmes persistent)

Si vous avez encore des problèmes, vous pouvez utiliser uniquement Firebase Auth :

```dart
Future<UserCredential?> signInWithGoogleSimple() async {
  GoogleAuthProvider googleProvider = GoogleAuthProvider();
  
  try {
    return await FirebaseAuth.instance.signInWithPopup(googleProvider);
  } catch (e) {
    debugPrint('Erreur connexion Google: $e');
    rethrow;
  }
}
```

L'application devrait maintenant fonctionner correctement ! 🎉
