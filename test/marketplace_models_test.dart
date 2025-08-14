import 'package:flutter_test/flutter_test.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:friendly_tcg_app/models/marketplace_models.dart';

void main() {
  group('MarketplaceListing model', () {
    test('copyWith and to/from Firestore preserve fields', () {
      final now = DateTime.now();
      final listing = MarketplaceListing(
        id: 'abc',
        sellerId: 'seller1',
        sellerName: 'Seller',
        sellerRegion: 'Île-de-France',
        cardName: 'Pikachu.png',
        priceCents: 500,
        status: ListingStatus.active,
        createdAt: now,
        buyerId: null,
  listingType: ListingType.buy,
      );
      final updated = listing.copyWith(priceCents: 600, status: ListingStatus.reserved, buyerId: 'buyerX', sellerValidated: true);
      final map = updated.toFirestore();
      // Simuler round-trip
      final roundTrip = MarketplaceListing.fromFirestore({
        ...map,
        'createdAt': Timestamp.fromDate(now),
      }, 'abc');
      expect(roundTrip.priceCents, 600);
      expect(roundTrip.status, ListingStatus.reserved);
      expect(roundTrip.buyerId, 'buyerX');
      expect(roundTrip.sellerValidated, true);
      expect(roundTrip.buyerValidated, false);
  expect(roundTrip.listingType, ListingType.buy);
    });
  });

  group('ListingOffer model', () {
    test('copyWith changes proposedPriceCents', () {
      final now = DateTime.now();
      final offer = ListingOffer(
        id: 'o1',
        listingId: 'l1',
        buyerId: 'u2',
        buyerName: 'Buyer',
        proposedPriceCents: 1234,
        status: OfferStatus.pending,
        createdAt: now,
      );
      final updated = offer.copyWith(proposedPriceCents: 1500, status: OfferStatus.accepted);
      expect(updated.proposedPriceCents, 1500);
      expect(updated.status, OfferStatus.accepted);
    });
  });
}
