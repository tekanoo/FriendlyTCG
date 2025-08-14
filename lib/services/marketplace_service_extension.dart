import 'marketplace_service.dart';
import '../models/marketplace_models.dart';

extension MarketplaceServiceExtension on MarketplaceService {
  Future<MarketplaceListing?> getActiveSaleForCard(String cardName) async {
  final snap = await this.firestore
        .collection('marketplace_listings')
        .where('cardName', isEqualTo: cardName)
        .where('status', isEqualTo: 'active')
        .where('listingType', isEqualTo: 'sale')
        .limit(1)
        .get();
    if (snap.docs.isEmpty) return null;
    return MarketplaceListing.fromFirestore(snap.docs.first.data(), snap.docs.first.id);
  }
}
