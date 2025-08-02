# 🔧 RÉSOLUTION : Erreur 400 redirect_uri_mismatch

## 🚨 Problème Identifié
```
Erreur 400 : redirect_uri_mismatch
```

Cette erreur signifie que Google OAuth ne reconnaît pas l'URI de redirection utilisée par votre application.

## 🛠️ Solution : Configuration Google Cloud Console

### **Étape 1 : Accéder à Google Cloud Console**
1. Allez sur https://console.cloud.google.com/
2. Sélectionnez le projet `friendlytcg-35fba`
3. Dans le menu, allez à **APIs & Services** > **Credentials**

### **Étape 2 : Identifier le Client OAuth 2.0**
1. Cherchez un client de type **"Web application"**
2. Cliquez sur le nom du client pour l'éditer

### **Étape 3 : Configurer les URIs Autorisées**

#### A. JavaScript Origins Autorisés
Ajoutez ces URLs dans **"Authorized JavaScript origins"** :
```
https://friendly-tcg.com
https://friendlytcg-35fba.firebaseapp.com
http://localhost
http://localhost:5000
http://localhost:8080
http://127.0.0.1
http://127.0.0.1:5000
http://127.0.0.1:8080
```

#### B. Redirect URIs Autorisés  
Ajoutez ces URLs dans **"Authorized redirect URIs"** :
```
https://friendly-tcg.com/__/auth/handler
https://friendlytcg-35fba.firebaseapp.com/__/auth/handler
http://localhost/__/auth/handler
http://localhost:5000/__/auth/handler
http://localhost:8080/__/auth/handler
http://127.0.0.1/__/auth/handler
http://127.0.0.1:5000/__/auth/handler
http://127.0.0.1:8080/__/auth/handler
```

### **Étape 4 : Configurer Firebase Authentication**
1. Allez sur https://console.firebase.google.com/
2. Sélectionnez le projet `friendlytcg-35fba`
3. Allez dans **Authentication** > **Settings** > **Authorized domains**
4. Ajoutez ces domaines :
```
friendly-tcg.com
friendlytcg-35fba.firebaseapp.com
localhost
```

## 🔍 Diagnostic de l'Erreur

### URLs probablement utilisées par votre app :
- **Développement** : `http://localhost:XXXX/__/auth/handler`
- **Production** : `https://friendly-tcg.com/__/auth/handler`

### Comment vérifier l'URL exacte :
1. Ouvrez les DevTools (F12) dans Chrome
2. Allez dans l'onglet **Network**
3. Tentez de vous connecter avec Google
4. Regardez la requête qui échoue pour voir l'URL utilisée

## ⚡ Configuration Rapide

### Si vous voulez tester rapidement :
1. Dans Google Cloud Console > Credentials
2. Ajoutez temporairement `*` dans les deux champs (⚠️ UNIQUEMENT POUR TEST)
3. Testez la connexion
4. Remettez les URLs spécifiques ensuite

## 📋 Checklist de Vérification

- [ ] Google Cloud Console : JavaScript Origins configurés
- [ ] Google Cloud Console : Redirect URIs configurés  
- [ ] Firebase Console : Domaines autorisés configurés
- [ ] AuthDomain dans le code mis à jour (`friendly-tcg.com`)

## 🔄 Après Configuration

1. **Sauvegardez** les modifications dans Google Cloud Console
2. **Attendez 5-10 minutes** pour la propagation
3. **Testez** la connexion Google
4. Si ça ne marche pas, vérifiez l'URL exacte dans les DevTools

## 🆘 Si le Problème Persiste

Créez un **nouveau client OAuth 2.0** :
1. Google Cloud Console > Credentials > **+ CREATE CREDENTIALS**
2. Sélectionnez **OAuth 2.0 Client ID**
3. Type : **Web application**
4. Configurez directement avec les bonnes URLs

Puis mettez à jour Firebase avec ce nouveau client.
