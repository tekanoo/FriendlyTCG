# 🔒 Guide de Sécurité pour Contributeurs

## Informations Publiques dans ce Repo

Ce projet utilise Firebase et contient des **clés publiques normales** :

### ✅ Clés Firebase Web (Publiques par Design)
```dart
// Ces informations sont SÛRES et PUBLIQUES
apiKey: 'AIzaSyBwW7qUxnh7KGGMw1c-QPqXjYMwhYm2BPk'    // ✅ Publique
projectId: 'friendlytcg-35fba'                         // ✅ Publique  
appId: '1:577013453059:web:860fe452da1095f6399936'     // ✅ Publique
```

**Pourquoi c'est sûr :**
- Les clés Firebase Web sont destinées au frontend
- La sécurité est assurée par les règles Firestore et domaines autorisés
- Google recommande officiellement de les exposer publiquement

## 🚫 Ce qui ne doit JAMAIS être committé

```bash
# NEVER commit these:
service-account-key.json     # ❌ Clé secrète serveur
.env                        # ❌ Variables d'environnement 
private-key.pem             # ❌ Clés privées
config/secrets.dart         # ❌ Secrets applicatifs
```

## 🛡️ Configuration de Sécurité

### Firestore Rules (Sécurisées)
- Accès limité aux utilisateurs authentifiés
- Isolation des données par utilisateur
- Règles strictes pour les échanges

### Domaines Autorisés
- Production : `friendly-tcg.com`
- Développement : `localhost`

## 📋 Pour les Contributeurs

### Setup Sécurisé
1. Forkez le repo
2. Les clés publiques fonctionneront directement
3. Pour tester : créez votre propre projet Firebase si nécessaire

### Variables d'Environnement Locales
Si vous ajoutez des features nécessitant des secrets :

```bash
# Créez .env (déjà dans .gitignore)
STRIPE_SECRET_KEY=sk_test_your_key
SENDGRID_API_KEY=SG.your_key
```

### Règles Git Pre-commit
```bash
# Installez git-secrets pour détecter les accidents
npm install -g git-secrets
git secrets --install
git secrets --register-aws
```

## 🔍 Vérifications Automatiques

Le `.gitignore` protège :
- Tous les fichiers `.env*`
- Les clés privées (`*.pem`, `*.p12`)
- Les service accounts (`*service-account*.json`)
- Les dossiers de build et cache

## ✅ Audit de Sécurité Réalisé

✅ Aucune clé secrète détectée  
✅ GitIgnore correctement configuré  
✅ Règles Firestore sécurisées  
✅ Seules les clés publiques Firebase présentes  

**Ce repo est sûr pour GitHub public !**
