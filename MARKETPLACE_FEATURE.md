# Marketplace Feature

Version initiale ajoutée le 2025-08-14.

## Objectif
Permettre aux utilisateurs de publier des cartes à vendre, recevoir des offres (prix proposés) et discuter de manière privée et sécurisée (placeholder de chiffrement) jusqu'à validation de la transaction.

## Modèles (lib/models/marketplace_models.dart)
- MarketplaceListing: annonce avec prix fixe (cents, status)
- ListingOffer: offre d'un acheteur avec statut (pending / accepted / declined / withdrawn)
- MarketplaceMessage: message chiffré lié à une annonce

## Service (lib/services/marketplace_service.dart)
Fonctions principales:
- createListing(cardName, priceCents)
- updateListingPrice(listingId, newPriceCents)
- markListingSold(listingId)
- cancelListing(listingId)
- listenActiveListings()
- createOffer(listingId, proposedPriceCents)
- updateOfferStatus(offerId, status)
- listenListingOffers(listingId)
- sendMessage(listingId, message)
- listenMessages(listingId)
- getHistoricalPrices(cardName)

## Écran (lib/screens/marketplace_screen.dart)
Tab responsive:
- Filtres (nom, prix via RangeSlider, région, disponibilité)
- Grille adaptative (2 colonnes mobile, 5 desktop)
- Fiche annonce: prix, région, nom carte
- Détail (bottom sheet):
  - Prix actuel, historique (mini bar chart), offres, messages
  - Saisie offre (€) + messages

## Sécurité / Privacy
- Région affichée, pas d'adresse précise
- Messages stockés sous forme de hash SHA256 (placeholder - pas réversible). A remplacer par chiffrement réel.
- TODO: règles Firestore spécifiques (owner peut modifier/canceller, buyer peut créer offres, tous participants peuvent écrire messages après acceptation)

## Limites actuelles
- Pas de validation double acheteur/vendeur avant statut sold (API disponible mais workflow incomplet)
- Pas de vérification possession réelle de la carte listée
- Chiffrement non réversible (simple hash) => afficher cipherText partiel uniquement
- Historique prix simple (liste sold -> bar chart) sans agrégation temporelle
- Règles Firestore à écrire / compléter

## Étapes futures recommandées
1. Ajouter UI de création d'annonce (Dialog + sélection carte possédée + prix)
2. Implémenter double validation (2 champs bool dans listing, ex: sellerValidated, buyerValidated)
3. Ajouter règles Firestore:
   - marketplace_listings: sellerId == request.auth.uid pour modifications
   - marketplace_offers: buyerId == request.auth.uid
   - marketplace_messages: listing participants uniquement
4. Implémenter pagination Firestore (startAfter)
5. Intégrer un vrai chiffrement (lib côté client) + clé partagée
6. Ajouter filtres jeu / extension
7. Intégrer notifications (messages / offres) via Cloud Messaging (optionnel)

## Notes de migration
Ajouter dépendances: crypto, intl dans pubspec.

## Versioning
Mettre à jour `version` dans `pubspec.yaml` lors d'une incrémentation fonctionnelle majeure.

---
Mainteneur: (à compléter)
