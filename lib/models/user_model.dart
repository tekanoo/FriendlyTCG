import 'package:cloud_firestore/cloud_firestore.dart';

class UserModel {
  final String uid;
  final String email;
  final String? displayName;
  final String? photoURL;
  final Map<String, int> cards;
  final DateTime lastSeen;

  UserModel({
    required this.uid,
    required this.email,
    this.displayName,
    this.photoURL,
    required this.cards,
    required this.lastSeen,
  });

  factory UserModel.fromFirestore(Map<String, dynamic> data, String uid) {
    return UserModel(
      uid: uid,
      email: data['email'] ?? '',
      displayName: data['displayName'],
      photoURL: data['photoURL'],
      cards: Map<String, int>.from(data['cards'] ?? {}),
      lastSeen: (data['lastSeen'] as Timestamp?)?.toDate() ?? DateTime.now(),
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'email': email,
      'displayName': displayName,
      'photoURL': photoURL,
      'cards': cards,
      'lastSeen': Timestamp.fromDate(lastSeen),
    };
  }

  // Vérifier si l'utilisateur possède une carte
  bool hasCard(String cardName) {
    return cards.containsKey(cardName) && (cards[cardName] ?? 0) > 0;
  }

  // Obtenir la quantité d'une carte
  int getCardQuantity(String cardName) {
    return cards[cardName] ?? 0;
  }
}
