import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../models/conversation_model.dart';
import '../models/marketplace_models.dart';
import 'user_profile_service.dart';

class ConversationService {
  static final ConversationService _instance = ConversationService._internal();
  factory ConversationService() => _instance;
  ConversationService._internal();

  final _firestore = FirebaseFirestore.instance;
  final _auth = FirebaseAuth.instance;
  final _profileService = UserProfileService();

  /// Crée une nouvelle conversation pour une offre de prix
  Future<String?> createPriceOfferConversation({
    required MarketplaceListing listing,
    required int proposedPriceCents,
    required String initialMessage,
  }) async {
    try {
      final user = _auth.currentUser;
      if (user == null) throw Exception('Utilisateur non connecté');
      
      // Vérifier que l'utilisateur n'est pas le vendeur du listing
      if (user.uid == listing.sellerId) {
        throw Exception('Vous ne pouvez pas créer une conversation sur votre propre listing');
      }
      
      final profile = await _profileService.getCurrentUserProfile();
      final buyerName = profile?.displayName ?? user.displayName ?? user.email ?? 'Acheteur';

      final conversation = ConversationModel(
        id: '',
        listingId: listing.id,
        cardName: listing.cardName,
        sellerId: listing.sellerId,
        buyerId: user.uid,
        sellerName: listing.sellerName,
        buyerName: buyerName,
        type: ConversationType.priceOffer,
        status: ConversationStatus.active,
        proposedPriceCents: proposedPriceCents,
        originalPriceCents: listing.priceCents,
  createdAt: DateTime.now(),
  updatedAt: DateTime.now(),
        hasUnreadSeller: true,
      );

      final doc = await _firestore.collection('conversations').add({
        ...conversation.toFirestore(),
        'participants': [listing.sellerId, user.uid], // Pour les requêtes
      });
      
      // Ajouter le message initial
      await _addMessage(doc.id, initialMessage, ConversationMessageType.priceOffer);

      return doc.id;
    } catch (e) {
      return null;
    }
  }

  /// Crée une nouvelle conversation pour une demande d'achat
  Future<String?> createBuyInquiryConversation({
    required MarketplaceListing listing,
    required String initialMessage,
  }) async {
    try {
      final user = _auth.currentUser;
      if (user == null) throw Exception('Utilisateur non connecté');
      
      // Vérifier que l'utilisateur n'est pas le vendeur du listing
      if (user.uid == listing.sellerId) {
        throw Exception('Vous ne pouvez pas créer une conversation sur votre propre listing');
      }
      
      final profile = await _profileService.getCurrentUserProfile();
      final buyerName = profile?.displayName ?? user.displayName ?? user.email ?? 'Acheteur';

      final conversation = ConversationModel(
        id: '',
        listingId: listing.id,
        cardName: listing.cardName,
        sellerId: listing.sellerId,
        buyerId: user.uid,
        sellerName: listing.sellerName,
        buyerName: buyerName,
        type: ConversationType.buyInquiry,
        status: ConversationStatus.active,
        originalPriceCents: listing.priceCents,
  createdAt: DateTime.now(),
  updatedAt: DateTime.now(),
        hasUnreadSeller: true,
      );

      final doc = await _firestore.collection('conversations').add({
        ...conversation.toFirestore(),
        'participants': [listing.sellerId, user.uid], // Pour les requêtes
      });
      
      // Ajouter le message initial
      await _addMessage(doc.id, initialMessage, ConversationMessageType.purchase);

      return doc.id;
    } catch (e) {
      return null;
    }
  }

  /// Ajoute un message à une conversation
  Future<void> addMessage(String conversationId, String content) async {
    await _addMessage(conversationId, content, ConversationMessageType.text);
  }

  Future<void> _addMessage(String conversationId, String content, ConversationMessageType type) async {
    try {
      final user = _auth.currentUser;
      if (user == null) throw Exception('Utilisateur non connecté');
      
      final profile = await _profileService.getCurrentUserProfile();
      final senderName = profile?.displayName ?? user.displayName ?? user.email ?? 'Utilisateur';

      final message = ConversationMessage(
        id: '',
        senderId: user.uid,
        senderName: senderName,
        content: content,
        createdAt: DateTime.now(),
        type: type,
      );

      await _firestore
          .collection('conversations')
          .doc(conversationId)
          .collection('messages')
          .add(message.toFirestore());

      // Mettre à jour les flags de non-lu et la date de mise à jour
      final conversationDoc = await _firestore.collection('conversations').doc(conversationId).get();
      if (conversationDoc.exists) {
        final data = conversationDoc.data()!;
        final isSeller = data['sellerId'] == user.uid;
        
        await _firestore.collection('conversations').doc(conversationId).update({
          'updatedAt': Timestamp.now(),
          if (isSeller) 'hasUnreadBuyer': true else 'hasUnreadSeller': true,
        });
      }

    } catch (e) {
      rethrow;
    }
  }

  /// Marque une conversation comme lue pour l'utilisateur actuel
  Future<void> markAsRead(String conversationId) async {
    try {
      final user = _auth.currentUser;
      if (user == null) return;

      final conversationDoc = await _firestore.collection('conversations').doc(conversationId).get();
      if (!conversationDoc.exists) return;

      final data = conversationDoc.data()!;
      final isSeller = data['sellerId'] == user.uid;

      await _firestore.collection('conversations').doc(conversationId).update({
        if (isSeller) 'hasUnreadSeller': false else 'hasUnreadBuyer': false,
      });
    } catch (e) {
      // Ignore errors
    }
  }

  /// Termine une conversation (vente réalisée)
  Future<void> completeConversation(String conversationId) async {
    try {
      await _firestore.collection('conversations').doc(conversationId).update({
        'status': 'completed',
        'completedAt': Timestamp.now(),
        'updatedAt': Timestamp.now(),
      });

      // Ajouter un message système
      await _addMessage(conversationId, 'Échange terminé avec succès !', ConversationMessageType.system);
      
    } catch (e) {
      rethrow;
    }
  }

  /// Annule une conversation
  Future<void> cancelConversation(String conversationId) async {
    try {
      await _firestore.collection('conversations').doc(conversationId).update({
        'status': 'cancelled',
        'completedAt': Timestamp.now(),
        'updatedAt': Timestamp.now(),
      });

      // Ajouter un message système
      await _addMessage(conversationId, 'Échange annulé', ConversationMessageType.system);
      
    } catch (e) {
      rethrow;
    }
  }

  /// Flux des conversations de l'utilisateur actuel
  Stream<List<ConversationModel>> listenUserConversations() {
    final user = _auth.currentUser;
    if (user == null) {
      return Stream.value([]);
    }
    
    return _firestore
        .collection('conversations')
        .where('participants', arrayContains: user.uid)
        .orderBy('updatedAt', descending: true)
        .snapshots()
        .handleError((error) {
          // Ignore errors
        })
        .asyncMap((snapshot) async {
      final conversations = <ConversationModel>[];
      
      for (final doc in snapshot.docs) {
        try {
          final data = doc.data();
          
          final conversation = ConversationModel.fromFirestore(data, doc.id);
          
          // Récupérer les messages récents (3 derniers)
          final messagesSnapshot = await _firestore
              .collection('conversations')
              .doc(doc.id)
              .collection('messages')
              .orderBy('createdAt', descending: true)
              .limit(3)
              .get();

          final messages = messagesSnapshot.docs
              .map((msgDoc) => ConversationMessage.fromFirestore(msgDoc.data(), msgDoc.id))
              .toList();

          conversations.add(conversation.copyWith(messages: messages.reversed.toList()));
        } catch (e) {
          // Ignore parsing errors
        }
      }
      
      return conversations;
    });
  }

  /// Flux des messages d'une conversation
  Stream<List<ConversationMessage>> listenConversationMessages(String conversationId) {
    return _firestore
        .collection('conversations')
        .doc(conversationId)
        .collection('messages')
        .orderBy('createdAt')
        .snapshots()
        .map((snapshot) {
      return snapshot.docs
          .map((doc) => ConversationMessage.fromFirestore(doc.data(), doc.id))
          .toList();
    });
  }
}
