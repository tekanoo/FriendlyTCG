import 'package:firebase_analytics/firebase_analytics.dart';
import 'package:flutter/foundation.dart';

class AnalyticsService {
  static final AnalyticsService _instance = AnalyticsService._internal();
  factory AnalyticsService() => _instance;
  AnalyticsService._internal();

  late final FirebaseAnalytics _analytics;
  late final FirebaseAnalyticsObserver _observer;
  bool _isInitialized = false;

  FirebaseAnalytics get analytics => _analytics;
  FirebaseAnalyticsObserver get observer => _observer;
  bool get isInitialized => _isInitialized;

  /// Initialise Firebase Analytics
  Future<void> initialize() async {
    try {
      _analytics = FirebaseAnalytics.instance;
      _observer = FirebaseAnalyticsObserver(analytics: _analytics);
      _isInitialized = true;
      
      debugPrint('✅ Firebase Analytics initialisé');
      
      // Envoyer un événement de démarrage de l'app
      await logAppStart();
      
    } catch (e) {
      debugPrint('❌ Erreur lors de l\'initialisation de Firebase Analytics: $e');
      _isInitialized = false;
    }
  }

  /// Événement : Démarrage de l'application
  Future<void> logAppStart() async {
    if (!_isInitialized) return;
    
    try {
      await _analytics.logEvent(
        name: 'app_start',
        parameters: {
          'platform': kIsWeb ? 'web' : 'mobile',
          'timestamp': DateTime.now().millisecondsSinceEpoch,
        },
      );
      debugPrint('📊 Analytics: app_start');
    } catch (e) {
      debugPrint('❌ Erreur Analytics app_start: $e');
    }
  }

  /// Événement : Connexion utilisateur
  Future<void> logLogin({String? method}) async {
    if (!_isInitialized) return;
    
    try {
      await _analytics.logLogin(loginMethod: method ?? 'google');
      debugPrint('📊 Analytics: login - $method');
    } catch (e) {
      debugPrint('❌ Erreur Analytics login: $e');
    }
  }

  /// Événement : Déconnexion utilisateur
  Future<void> logLogout() async {
    if (!_isInitialized) return;
    
    try {
      await _analytics.logEvent(
        name: 'logout',
        parameters: {
          'timestamp': DateTime.now().millisecondsSinceEpoch,
        },
      );
      debugPrint('📊 Analytics: logout');
    } catch (e) {
      debugPrint('❌ Erreur Analytics logout: $e');
    }
  }

  /// Événement : Navigation vers un écran
  Future<void> logScreenView({required String screenName, String? screenClass}) async {
    if (!_isInitialized) return;
    
    try {
      await _analytics.logScreenView(
        screenName: screenName,
        screenClass: screenClass ?? screenName,
      );
      debugPrint('📊 Analytics: screen_view - $screenName');
    } catch (e) {
      debugPrint('❌ Erreur Analytics screen_view: $e');
    }
  }

  /// Événement : Ajout d'une carte à la collection
  Future<void> logAddCard({required String cardName, required String gameId, required String extensionId}) async {
    if (!_isInitialized) return;
    
    try {
      await _analytics.logEvent(
        name: 'add_card',
        parameters: {
          'card_name': cardName,
          'game_id': gameId,
          'extension_id': extensionId,
          'timestamp': DateTime.now().millisecondsSinceEpoch,
        },
      );
      debugPrint('📊 Analytics: add_card - $cardName');
    } catch (e) {
      debugPrint('❌ Erreur Analytics add_card: $e');
    }
  }

  /// Événement : Suppression d'une carte de la collection
  Future<void> logRemoveCard({required String cardName, required String gameId, required String extensionId}) async {
    if (!_isInitialized) return;
    
    try {
      await _analytics.logEvent(
        name: 'remove_card',
        parameters: {
          'card_name': cardName,
          'game_id': gameId,
          'extension_id': extensionId,
          'timestamp': DateTime.now().millisecondsSinceEpoch,
        },
      );
      debugPrint('📊 Analytics: remove_card - $cardName');
    } catch (e) {
      debugPrint('❌ Erreur Analytics remove_card: $e');
    }
  }

  /// Événement : Consultation d'un jeu
  Future<void> logViewGame({required String gameId, required String gameName}) async {
    if (!_isInitialized) return;
    
    try {
      await _analytics.logEvent(
        name: 'view_game',
        parameters: {
          'game_id': gameId,
          'game_name': gameName,
          'timestamp': DateTime.now().millisecondsSinceEpoch,
        },
      );
      debugPrint('📊 Analytics: view_game - $gameName');
    } catch (e) {
      debugPrint('❌ Erreur Analytics view_game: $e');
    }
  }

  /// Événement : Consultation d'une extension
  Future<void> logViewExtension({required String extensionId, required String extensionName, required String gameId}) async {
    if (!_isInitialized) return;
    
    try {
      await _analytics.logEvent(
        name: 'view_extension',
        parameters: {
          'extension_id': extensionId,
          'extension_name': extensionName,
          'game_id': gameId,
          'timestamp': DateTime.now().millisecondsSinceEpoch,
        },
      );
      debugPrint('📊 Analytics: view_extension - $extensionName');
    } catch (e) {
      debugPrint('❌ Erreur Analytics view_extension: $e');
    }
  }

  /// Événement : Création d'un échange
  Future<void> logCreateTrade() async {
    if (!_isInitialized) return;
    
    try {
      await _analytics.logEvent(
        name: 'create_trade',
        parameters: {
          'timestamp': DateTime.now().millisecondsSinceEpoch,
        },
      );
      debugPrint('📊 Analytics: create_trade');
    } catch (e) {
      debugPrint('❌ Erreur Analytics create_trade: $e');
    }
  }

  /// Définir les propriétés utilisateur
  Future<void> setUserProperties({String? userId, String? email}) async {
    if (!_isInitialized) return;
    
    try {
      if (userId != null) {
        await _analytics.setUserId(id: userId);
      }
      
      await _analytics.setUserProperty(
        name: 'user_type',
        value: 'tcg_collector',
      );
      
      if (email != null) {
        await _analytics.setUserProperty(
          name: 'email_domain',
          value: email.split('@').last,
        );
      }
      
      debugPrint('📊 Analytics: user_properties configurées');
    } catch (e) {
      debugPrint('❌ Erreur Analytics user_properties: $e');
    }
  }

  /// Événement : Statistiques de collection
  Future<void> logCollectionStats({
    required int totalCards,
    required int uniqueCards,
    required int totalGames,
    required Map<String, int> cardsByGame,
  }) async {
    if (!_isInitialized) return;
    
    try {
      await _analytics.logEvent(
        name: 'collection_stats',
        parameters: {
          'total_cards': totalCards,
          'unique_cards': uniqueCards,
          'total_games': totalGames,
          'timestamp': DateTime.now().millisecondsSinceEpoch,
          ...cardsByGame,
        },
      );
      debugPrint('📊 Analytics: collection_stats - $totalCards cartes');
    } catch (e) {
      debugPrint('❌ Erreur Analytics collection_stats: $e');
    }
  }
}
