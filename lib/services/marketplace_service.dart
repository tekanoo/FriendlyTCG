import 'dart:convert';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:crypto/crypto.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import '../models/marketplace_models.dart';
import 'user_profile_service.dart';

/// Service principal pour la gestion du Marketplace
class MarketplaceService {
  static final MarketplaceService _instance = MarketplaceService._internal();
  factory MarketplaceService() => _instance;
  MarketplaceService._internal();

  final _firestore = FirebaseFirestore.instance;
  final _auth = FirebaseAuth.instance;
  final _profileService = UserProfileService();

  /// Crée une nouvelle annonce
  Future<String?> createListing({
    required String cardName,
    required int priceCents,
  ListingType type = ListingType.sale,
  }) async {
    try {
      final user = _auth.currentUser;
      if (user == null) throw Exception('Utilisateur non connecté');
      final profile = await _profileService.getCurrentUserProfile();

      final listing = MarketplaceListing(
        id: '',
        sellerId: user.uid,
        sellerName: profile?.displayName ?? user.displayName ?? user.email ?? 'Vendeur',
        sellerRegion: profile?.region,
        cardName: cardName,
        priceCents: priceCents,
        status: ListingStatus.active,
        createdAt: DateTime.now(),
  listingType: type,
      );

      final doc = await _firestore.collection('marketplace_listings').add(listing.toFirestore());
      debugPrint('✅ Listing créé: ${doc.id}');
      return doc.id;
    } catch (e) {
      debugPrint('❌ Erreur createListing: $e');
      return null;
    }
  }

  /// Met à jour le prix d'une annonce active
  Future<void> updateListingPrice(String listingId, int newPriceCents) async {
    await _firestore.collection('marketplace_listings').doc(listingId).update({
      'priceCents': newPriceCents,
      'updatedAt': Timestamp.now(),
    });
  }

  /// Marque une annonce comme vendue (après double validation)
  Future<void> markListingSold(String listingId) async {
    await _firestore.collection('marketplace_listings').doc(listingId).update({
      'status': 'sold',
      'soldAt': Timestamp.now(),
      'updatedAt': Timestamp.now(),
    });
  }

  /// Annule une annonce
  Future<void> cancelListing(String listingId) async {
    await _firestore.collection('marketplace_listings').doc(listingId).update({
      'status': 'cancelled',
      'updatedAt': Timestamp.now(),
    });
  }

  /// Flux des annonces actives avec filtres simples côté client (nom / région / price range)
  Stream<List<MarketplaceListing>> listenActiveListings() {
    return _firestore
        .collection('marketplace_listings')
        .where('status', isEqualTo: 'active')
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snap) => snap.docs
            .map((d) => MarketplaceListing.fromFirestore(d.data(), d.id))
            .toList());
  }

  /// Création d'une offre (achat direct ou prix proposé)
  Future<String?> createOffer({
    required String listingId,
    required int proposedPriceCents,
  }) async {
    try {
      final user = _auth.currentUser;
      if (user == null) throw Exception('Utilisateur non connecté');

      // Récupérer les infos utilisateur (affichage buyerName)
      final profile = await _profileService.getCurrentUserProfile();
      final offer = ListingOffer(
        id: '',
        listingId: listingId,
        buyerId: user.uid,
        buyerName: profile?.displayName ?? user.displayName ?? user.email ?? 'Acheteur',
        proposedPriceCents: proposedPriceCents,
        status: OfferStatus.pending,
        createdAt: DateTime.now(),
      );

      final doc = await _firestore.collection('marketplace_offers').add(offer.toFirestore());

      await _sendSystemMessage(listingId, 'Nouvelle offre: ${(proposedPriceCents / 100).toStringAsFixed(2)}€');
      return doc.id;
    } catch (e) {
      debugPrint('❌ Erreur createOffer: $e');
      return null;
    }
  }

  Future<void> updateOfferStatus(String offerId, OfferStatus status) async {
    await _firestore.collection('marketplace_offers').doc(offerId).update({
      'status': status.toString().split('.').last,
      'updatedAt': Timestamp.now(),
    });
  }

  /// Accepter une offre: marque l'offre accepted, réserve l'annonce
  Future<void> acceptOffer({required String offerId}) async {
    final offerDoc = await _firestore.collection('marketplace_offers').doc(offerId).get();
    if (!offerDoc.exists) throw Exception('Offre introuvable');
    final listingId = offerDoc.data()!['listingId'];
    final listingRef = _firestore.collection('marketplace_listings').doc(listingId);
    await _firestore.runTransaction((tx) async {
      final listingSnap = await tx.get(listingRef);
      if (!listingSnap.exists) throw Exception('Annonce introuvable');
      final data = listingSnap.data()!;
      final status = data['status'];
      final existingBuyer = data['buyerId'];
      // Autoriser accept si: (active) OU (reserved mais même buyer pour relancer) ; empêcher si déjà reserved avec autre buyer
      if (status != 'active' && status != 'reserved') throw Exception('Annonce non disponible');
      if (existingBuyer != null && existingBuyer != offerDoc.data()!['buyerId']) {
        throw Exception('Discussion déjà en cours avec un autre acheteur');
      }
      // Marquer reserved + buyerId si pas encore set
      final updates = <String,dynamic>{
        'status': 'reserved',
        'updatedAt': Timestamp.now(),
      };
      if (existingBuyer == null) {
        updates['buyerId'] = offerDoc.data()!['buyerId'];
      }
      tx.update(listingRef, updates);
      tx.update(offerDoc.reference, {
        'status': 'accepted',
        'updatedAt': Timestamp.now(),
      });
    });
    await _sendSystemMessage(listingId, 'Offre acceptée. Discussion ouverte.');
  }

  Future<void> declineOffer({required String offerId}) async {
    await updateOfferStatus(offerId, OfferStatus.declined);
  }

  Future<void> withdrawOffer({required String offerId}) async {
    await updateOfferStatus(offerId, OfferStatus.withdrawn);
  }

  /// Validation côté participant. Quand seller & buyer validés => passage sold.
  Future<void> validateListing(String listingId) async {
    final user = _auth.currentUser; if (user == null) return;
    final ref = _firestore.collection('marketplace_listings').doc(listingId);
    await _firestore.runTransaction((tx) async {
      final snap = await tx.get(ref);
      if (!snap.exists) return;
      final data = snap.data()!;
      bool sellerValidated = data['sellerValidated'] ?? false;
      bool buyerValidated = data['buyerValidated'] ?? false;
      final sellerId = data['sellerId'];
      final buyerId = data['buyerId'];
      if (buyerId == null) return; // pas encore réservé
      if (user.uid == sellerId) sellerValidated = true;
      if (user.uid == buyerId) buyerValidated = true;
      final update = <String, dynamic>{
        'sellerValidated': sellerValidated,
        'buyerValidated': buyerValidated,
        'updatedAt': Timestamp.now(),
      };
      if (sellerValidated && buyerValidated && data['status'] != 'sold') {
        update['status'] = 'sold';
        update['soldAt'] = Timestamp.now();
      }
      tx.update(ref, update);
    });
  }

  Stream<List<ListingOffer>> listenListingOffers(String listingId) {
    return _firestore
        .collection('marketplace_offers')
        .where('listingId', isEqualTo: listingId)
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snap) => snap.docs
            .map((d) => ListingOffer.fromFirestore(d.data(), d.id))
            .toList());
  }

  /// On stocke un simple hash sha256 comme pseudo-chiffrement côté serveur (placeholder). Pour de vrai: utiliser un chiffrement asymétrique.
  String _encrypt(String plaintext) {
    // NOTE: Placeholder - ne pas considérer comme sécurisé.
    final bytes = utf8.encode(plaintext);
    return sha256.convert(bytes).toString();
  }

  Future<void> sendMessage(String listingId, String message) async {
    final user = _auth.currentUser;
    if (user == null) throw Exception('Utilisateur non connecté');
    final profile = await _profileService.getCurrentUserProfile();

    final msg = MarketplaceMessage(
      id: '',
      listingId: listingId,
      senderId: user.uid,
      senderName: profile?.displayName ?? user.displayName ?? user.email ?? 'Utilisateur',
      cipherText: _encrypt(message),
      timestamp: DateTime.now(),
    );

    await _firestore.collection('marketplace_messages').add(msg.toFirestore());
  }

  Future<void> _sendSystemMessage(String listingId, String text) async {
    final msg = MarketplaceMessage(
      id: '',
      listingId: listingId,
      senderId: 'system',
      senderName: 'Système',
      cipherText: _encrypt(text),
      timestamp: DateTime.now(),
      isSystem: true,
    );
    await _firestore.collection('marketplace_messages').add(msg.toFirestore());
  }

  Stream<List<MarketplaceMessage>> listenMessages(String listingId) {
    return _firestore
        .collection('marketplace_messages')
        .where('listingId', isEqualTo: listingId)
        .orderBy('timestamp', descending: false)
        .snapshots()
        .map((snap) => snap.docs
            .map((d) => MarketplaceMessage.fromFirestore(d.data(), d.id))
            .toList());
  }

  /// Historique simple: ventes terminées pour une carte => liste de prix
  Future<List<int>> getHistoricalPrices(String cardName, {int limit = 30}) async {
    final snap = await _firestore
        .collection('marketplace_listings')
        .where('cardName', isEqualTo: cardName)
        .where('status', isEqualTo: 'sold')
        .orderBy('soldAt', descending: true)
        .limit(limit)
        .get();
    return snap.docs.map((d) => (d.data()['priceCents'] ?? 0) as int).toList();
  }
}
