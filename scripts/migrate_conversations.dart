// Script de migration Firestore pour normaliser les documents conversations
// Usage: dart run scripts/migrate_conversations.dart
// Nécessite un contexte avec Firebase initialisé (adapté ici pour un exécutable Dart/Flutter).

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:friendly_tcg_app/firebase_options.dart';

Future<void> main() async {
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
  final fs = FirebaseFirestore.instance;
  final snapshot = await fs.collection('conversations').get();
  int updated = 0;
  WriteBatch? batch;

  Future<void> commitIfNeeded([bool force = false]) async {
    if (batch == null) return;
    if (force || updated % 400 == 0) {
      await batch!.commit();
      batch = null;
    }
  }

  for (final doc in snapshot.docs) {
    final data = doc.data();
    final needsParticipants = data['participants'] is! List && data['sellerId'] is String && data['buyerId'] is String;
    final needsUpdatedAt = data['updatedAt'] == null;
    if (needsParticipants || needsUpdatedAt) {
      batch ??= fs.batch();
      batch!.update(doc.reference, {
        if (needsParticipants) 'participants': [data['sellerId'], data['buyerId']],
        if (needsUpdatedAt) 'updatedAt': FieldValue.serverTimestamp(),
      });
      updated++;
      await commitIfNeeded();
    }
  }
  await commitIfNeeded(true);
  // ignore: avoid_print
  print('Migration terminée. Documents mis à jour: $updated');
}
