import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import '../models/trade_model.dart';

class TradeServiceAdvanced {
  static final TradeServiceAdvanced _instance = TradeServiceAdvanced._internal();
  factory TradeServiceAdvanced() => _instance;
  TradeServiceAdvanced._internal();

  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // Créer une nouvelle demande d'échange
  Future<String?> createTradeRequest({
    required String toUserId,
    required String toUserName,
    required String wantedCard,
    required String offeredCard,
  }) async {
    try {
      final currentUser = _auth.currentUser;
      if (currentUser == null) throw Exception('Utilisateur non connecté');

      // Vérifier que l'utilisateur possède bien la carte offerte
      final userDoc = await _firestore.collection('users').doc(currentUser.uid).get();
      final userCards = Map<String, int>.from(userDoc.data()?['cards'] ?? {});
      final hasOfferedCard = userCards.containsKey(offeredCard) && userCards[offeredCard]! > 0;
      
      if (!hasOfferedCard) {
        throw Exception('Vous ne possédez pas la carte ${offeredCard.replaceAll('.png', '')}');
      }

      final trade = TradeModel(
        id: '',
        fromUserId: currentUser.uid,
        toUserId: toUserId,
        fromUserName: currentUser.displayName ?? currentUser.email ?? 'Utilisateur',
        toUserName: toUserName,
        wantedCard: wantedCard,
        offeredCard: offeredCard,
        status: TradeStatus.pending,
        createdAt: DateTime.now(),
      );

      final docRef = await _firestore.collection('trades').add(trade.toFirestore());
      
      // Ajouter un message système initial
      await _sendSystemMessage(
        docRef.id,
        'Demande d\'échange créée: ${trade.fromUserName} souhaite échanger ${offeredCard.replaceAll('.png', '')} contre ${wantedCard.replaceAll('.png', '')}',
      );

      // Ajouter le message de sécurité
      await _sendSystemMessage(
        docRef.id,
        '⚠️ IMPORTANT: Ne partagez jamais d\'informations personnelles sensibles. Pour les rencontres physiques, choisissez toujours un lieu public et sûr.',
      );

      debugPrint('✅ Demande d\'échange créée: ${docRef.id}');
      return docRef.id;
    } catch (e) {
      debugPrint('❌ Erreur lors de la création de l\'échange: $e');
      rethrow;
    }
  }

  // Obtenir les cartes que l'utilisateur actuel possède et que l'autre utilisateur n'a pas
  Future<List<String>> getCardsToOffer(String targetUserId) async {
    try {
      final currentUser = _auth.currentUser;
      if (currentUser == null) return [];

      // Récupérer les cartes de l'utilisateur actuel
      final currentUserData = await _firestore.collection('users').doc(currentUser.uid).get();
      final currentUserCards = Map<String, int>.from(currentUserData.data()?['cards'] ?? {});

      // Récupérer les cartes de l'utilisateur cible
      final targetUserData = await _firestore.collection('users').doc(targetUserId).get();
      final targetUserCards = Map<String, int>.from(targetUserData.data()?['cards'] ?? {});

      // Trouver les cartes que l'utilisateur actuel possède mais pas l'utilisateur cible
      final cardsToOffer = <String>[];
      for (String cardName in currentUserCards.keys) {
        if (currentUserCards[cardName]! > 0 && 
            (!targetUserCards.containsKey(cardName) || targetUserCards[cardName]! == 0)) {
          cardsToOffer.add(cardName);
        }
      }

      debugPrint('✅ ${cardsToOffer.length} cartes disponibles pour l\'échange');
      return cardsToOffer;
    } catch (e) {
      debugPrint('❌ Erreur lors de la récupération des cartes à offrir: $e');
      return [];
    }
  }

  // Accepter une demande d'échange
  Future<void> acceptTrade(String tradeId) async {
    try {
      await _updateTradeStatus(tradeId, TradeStatus.accepted);
      await _sendSystemMessage(
        tradeId,
        'Échange accepté! Vous pouvez maintenant discuter pour organiser la rencontre.',
      );
    } catch (e) {
      debugPrint('❌ Erreur lors de l\'acceptation de l\'échange: $e');
      rethrow;
    }
  }

  // Refuser une demande d'échange
  Future<void> declineTrade(String tradeId) async {
    try {
      await _updateTradeStatus(tradeId, TradeStatus.declined);
      await _sendSystemMessage(tradeId, 'Échange refusé.');
    } catch (e) {
      debugPrint('❌ Erreur lors du refus de l\'échange: $e');
      rethrow;
    }
  }

  // Marquer un échange comme terminé
  Future<void> completeTrade(String tradeId) async {
    try {
      await _updateTradeStatus(tradeId, TradeStatus.completed);
      await _sendSystemMessage(tradeId, 'Échange terminé avec succès!');
    } catch (e) {
      debugPrint('❌ Erreur lors de la finalisation de l\'échange: $e');
      rethrow;
    }
  }

  // Annuler un échange
  Future<void> cancelTrade(String tradeId) async {
    try {
      await _updateTradeStatus(tradeId, TradeStatus.cancelled);
      await _sendSystemMessage(tradeId, 'Échange annulé.');
    } catch (e) {
      debugPrint('❌ Erreur lors de l\'annulation de l\'échange: $e');
      rethrow;
    }
  }

  // Mettre à jour le statut d'un échange
  Future<void> _updateTradeStatus(String tradeId, TradeStatus status) async {
    await _firestore.collection('trades').doc(tradeId).update({
      'status': status.toString().split('.').last,
      'updatedAt': Timestamp.now(),
    });
  }

  // Envoyer un message dans un échange
  Future<void> sendMessage(String tradeId, String message) async {
    try {
      final currentUser = _auth.currentUser;
      if (currentUser == null) throw Exception('Utilisateur non connecté');

      final tradeMessage = TradeMessageModel(
        id: '',
        tradeId: tradeId,
        senderId: currentUser.uid,
        senderName: currentUser.displayName ?? currentUser.email ?? 'Utilisateur',
        message: message,
        timestamp: DateTime.now(),
      );

      await _firestore.collection('trade_messages').add(tradeMessage.toFirestore());
      debugPrint('✅ Message envoyé');
    } catch (e) {
      debugPrint('❌ Erreur lors de l\'envoi du message: $e');
      rethrow;
    }
  }

  // Envoyer un message système
  Future<void> _sendSystemMessage(String tradeId, String message) async {
    try {
      final systemMessage = TradeMessageModel(
        id: '',
        tradeId: tradeId,
        senderId: 'system',
        senderName: 'Système',
        message: message,
        timestamp: DateTime.now(),
        isSystemMessage: true,
      );

      await _firestore.collection('trade_messages').add(systemMessage.toFirestore());
    } catch (e) {
      debugPrint('❌ Erreur lors de l\'envoi du message système: $e');
    }
  }

  // Obtenir les échanges de l'utilisateur actuel
  Stream<List<TradeModel>> getUserTrades() {
    final currentUser = _auth.currentUser;
    if (currentUser == null) return Stream.value([]);

    return _firestore
        .collection('trades')
        .where('fromUserId', isEqualTo: currentUser.uid)
        .snapshots()
        .asyncMap((fromSnapshot) async {
      final toSnapshot = await _firestore
          .collection('trades')
          .where('toUserId', isEqualTo: currentUser.uid)
          .get();

      final allDocs = [...fromSnapshot.docs, ...toSnapshot.docs];
      return allDocs
          .map((doc) => TradeModel.fromFirestore(doc.data(), doc.id))
          .toList()
        ..sort((a, b) => b.createdAt.compareTo(a.createdAt));
    });
  }

  // Obtenir les messages d'un échange
  Stream<List<TradeMessageModel>> getTradeMessages(String tradeId) {
    return _firestore
        .collection('trade_messages')
        .where('tradeId', isEqualTo: tradeId)
        .orderBy('timestamp', descending: false)
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => TradeMessageModel.fromFirestore(doc.data(), doc.id))
            .toList());
  }

  // Obtenir un échange spécifique
  Future<TradeModel?> getTrade(String tradeId) async {
    try {
      final doc = await _firestore.collection('trades').doc(tradeId).get();
      if (!doc.exists) return null;
      return TradeModel.fromFirestore(doc.data()!, doc.id);
    } catch (e) {
      debugPrint('❌ Erreur lors de la récupération de l\'échange: $e');
      return null;
    }
  }
}
