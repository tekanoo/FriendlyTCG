import 'package:cloud_firestore/cloud_firestore.dart';
import 'user_model.dart';

class UserWithLocation {
  final String uid;
  final String email;
  final String? displayName;
  final String? photoURL;
  final Map<String, int> cards;
  final DateTime lastSeen;
  final String? country;
  final String? region;
  final String? city;

  UserWithLocation({
    required this.uid,
    required this.email,
    this.displayName,
    this.photoURL,
    required this.cards,
    required this.lastSeen,
    this.country,
    this.region,
    this.city,
  });

  factory UserWithLocation.fromFirestore(Map<String, dynamic> data, String uid) {
    return UserWithLocation(
      uid: uid,
      email: data['email'] ?? '',
      displayName: data['displayName'],
      photoURL: data['photoURL'],
      cards: Map<String, int>.from(data['cards'] ?? {}),
      lastSeen: (data['lastSeen'] as Timestamp?)?.toDate() ?? DateTime.now(),
      country: data['country'],
      region: data['region'],
      city: data['city'],
    );
  }

  // Méthodes héritées de UserModel
  bool hasCard(String cardName) {
    return cards.containsKey(cardName) && (cards[cardName] ?? 0) > 0;
  }

  int getCardQuantity(String cardName) {
    return cards[cardName] ?? 0;
  }

  // Nouvelle méthode pour obtenir l'affichage de localisation
  String get locationDisplay {
    // Ville retirée de l'affichage pour anonymisation / simplification.
    List<String> parts = [];
    if (region?.isNotEmpty == true) parts.add(region!);
    if (country?.isNotEmpty == true) parts.add(country!);
    return parts.join(', ');
  }

  bool get hasLocation => 
    country?.isNotEmpty == true || 
    region?.isNotEmpty == true || 
    city?.isNotEmpty == true;

  // Convertir en UserModel pour la compatibilité
  UserModel toUserModel() {
    return UserModel(
      uid: uid,
      email: email,
      displayName: displayName,
      photoURL: photoURL,
      cards: cards,
      lastSeen: lastSeen,
    );
  }
}
