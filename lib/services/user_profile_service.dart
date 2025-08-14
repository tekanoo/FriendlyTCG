import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../models/user_profile_model.dart';

class UserProfileService {
  static final UserProfileService _instance = UserProfileService._internal();
  factory UserProfileService() => _instance;
  UserProfileService._internal();

  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // Obtenir le profil de l'utilisateur actuel
  Future<UserProfileModel?> getCurrentUserProfile() async {
    try {
      final user = _auth.currentUser;
      if (user == null) {
        return null;
      }

      
      final doc = await _firestore.collection('users').doc(user.uid).get();
      if (!doc.exists) {
        return null;
      }

      final data = doc.data()!;
      
      final profile = UserProfileModel.fromMap(data, user.uid);
      
      return profile;
    } catch (e) {
      return null;
    }
  }

  // Mettre à jour le profil de l'utilisateur
  Future<bool> updateUserProfile(UserProfileModel profile) async {
    try {
      final user = _auth.currentUser;
      if (user == null) return false;

      final profileData = profile.toMap();
      profileData['lastUpdated'] = FieldValue.serverTimestamp();

      await _firestore.collection('users').doc(user.uid).set(
        profileData,
        SetOptions(merge: true),
      );

      return true;
    } catch (e) {
      return false;
    }
  }

  // Mettre à jour seulement la localisation
  Future<bool> updateUserLocation({
    String? country,
    String? region,
    String? city,
  }) async {
    try {
      final user = _auth.currentUser;
      if (user == null) {
        return false;
      }


      // Validation stricte des données
      final cleanCountry = country?.trim();
      final cleanRegion = region?.trim();
      final cleanCity = city?.trim();


      final Map<String, dynamic> locationData = {
        'lastUpdated': FieldValue.serverTimestamp(),
        'country': cleanCountry?.isNotEmpty == true ? cleanCountry : null,
        'region': cleanRegion?.isNotEmpty == true ? cleanRegion : null,
        'city': cleanCity?.isNotEmpty == true ? cleanCity : null,
      };


      await _firestore.collection('users').doc(user.uid).set(
        locationData,
        SetOptions(merge: true),
      );


      // Vérification immédiate après sauvegarde
      await _firestore.collection('users').doc(user.uid).get();
      
      return true;
    } catch (e) {
      return false;
    }
  }

  // Rechercher des utilisateurs par localisation
  Future<List<UserProfileModel>> searchUsersByLocation({
    String? country,
    String? region,
    int limit = 50,
  }) async {
    try {
      Query query = _firestore.collection('users');

      if (country?.isNotEmpty == true) {
        query = query.where('country', isEqualTo: country);
      }
      if (region?.isNotEmpty == true) {
        query = query.where('region', isEqualTo: region);
      }

      query = query.limit(limit);
      query = query.orderBy('lastSeen', descending: true);

      final querySnapshot = await query.get();
      
      return querySnapshot.docs.map((doc) {
        return UserProfileModel.fromMap(doc.data() as Map<String, dynamic>, doc.id);
      }).toList();

    } catch (e) {
      return [];
    }
  }

  // Obtenir les utilisateurs actifs récents par localisation
  Future<List<UserProfileModel>> getActiveUsersByLocation({
    String? country,
    String? region,
    int daysAgo = 30,
    int limit = 20,
  }) async {
    try {
      final cutoffDate = DateTime.now().subtract(Duration(days: daysAgo));
      
      Query query = _firestore.collection('users')
          .where('lastSeen', isGreaterThan: Timestamp.fromDate(cutoffDate))
          .orderBy('lastSeen', descending: true);

      if (country?.isNotEmpty == true) {
        query = query.where('country', isEqualTo: country);
      }

      query = query.limit(limit);

      final querySnapshot = await query.get();
      
      List<UserProfileModel> users = querySnapshot.docs.map((doc) {
        return UserProfileModel.fromMap(doc.data() as Map<String, dynamic>, doc.id);
      }).toList();

      // Filtrer par région côté client si nécessaire (Firestore limite les where composés)
      if (region?.isNotEmpty == true) {
        users = users.where((user) => user.region == region).toList();
      }

      return users;

    } catch (e) {
      return [];
    }
  }

  // Marquer l'utilisateur comme actif
  Future<void> updateLastSeen() async {
    try {
      final user = _auth.currentUser;
      if (user == null) return;

      await _firestore.collection('users').doc(user.uid).set({
        'lastSeen': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));

    } catch (e) {
    }
  }

  // Obtenir les pays les plus populaires
  Future<List<String>> getPopularCountries({int limit = 10}) async {
    try {
      final querySnapshot = await _firestore.collection('users')
          .where('country', isNotEqualTo: null)
          .get();

      Map<String, int> countryCount = {};
      for (var doc in querySnapshot.docs) {
        final country = doc.data()['country'] as String?;
        if (country?.isNotEmpty == true) {
          countryCount[country!] = (countryCount[country] ?? 0) + 1;
        }
      }

      final sortedCountries = countryCount.entries.toList()
        ..sort((a, b) => b.value.compareTo(a.value));

      return sortedCountries
          .take(limit)
          .map((entry) => entry.key)
          .toList();

    } catch (e) {
      return [];
    }
  }
}
