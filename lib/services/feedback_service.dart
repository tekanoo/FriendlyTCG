import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';

/// Service d'envoi de feedback utilisateur dans Firestore.
/// Stocke chaque entrée dans la collection `feedback`.
/// Schéma des documents :
///  - text: String (contenu du feedback)
///  - uid: String? (peut être null si non connecté)
///  - userEmail: String? (email Firebase si présent)
///  - userDisplayName: String? (pseudo / displayName s'il existe)
///  - platform: web / android / ios / windows ... (kIsWeb ou defaultTargetPlatform)
///  - createdAt: Timestamp (serveur)
///  - appVersion: String? (optionnel, fourni par l'appelant)
///  - status: String ('open' par défaut)
class FeedbackService {
  static final FeedbackService _instance = FeedbackService._internal();
  factory FeedbackService() => _instance;
  FeedbackService._internal();

  final _firestore = FirebaseFirestore.instance;
  final _auth = FirebaseAuth.instance;

  Future<void> sendFeedback(String text, {String? appVersion}) async {
    final user = _auth.currentUser;
    final platform = kIsWeb ? 'web' : defaultTargetPlatform.name; // e.g. TargetPlatform.android
    try {
      await _firestore.collection('feedback').add({
        'text': text.trim(),
        'uid': user?.uid,
        'userEmail': user?.email,
        'userDisplayName': user?.displayName,
        'platform': platform,
        'createdAt': FieldValue.serverTimestamp(),
        'appVersion': appVersion,
        'status': 'open',
      });
    } catch (e) {
      rethrow;
    }
  }
}
