class UserProfileModel {
  final String uid;
  final String? email;
  final String? displayName;
  final String? photoURL;
  final String? country;
  final String? region;
  final String? city;
  final DateTime? lastSeen;
  final DateTime? lastUpdated;

  UserProfileModel({
    required this.uid,
    this.email,
    this.displayName,
    this.photoURL,
    this.country,
    this.region,
    this.city,
    this.lastSeen,
    this.lastUpdated,
  });

  factory UserProfileModel.fromMap(Map<String, dynamic> map, String uid) {
    return UserProfileModel(
      uid: uid,
      email: map['email'],
      displayName: map['displayName'],
      photoURL: map['photoURL'],
      country: map['country'],
      region: map['region'],
      city: map['city'],
      lastSeen: map['lastSeen']?.toDate(),
      lastUpdated: map['lastUpdated']?.toDate(),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'email': email,
      'displayName': displayName,
      'photoURL': photoURL,
      'country': country,
      'region': region,
      'city': city,
      'lastSeen': lastSeen,
      'lastUpdated': lastUpdated,
    };
  }

  UserProfileModel copyWith({
    String? email,
    String? displayName,
    String? photoURL,
    String? country,
    String? region,
    String? city,
    DateTime? lastSeen,
    DateTime? lastUpdated,
  }) {
    return UserProfileModel(
      uid: uid,
      email: email ?? this.email,
      displayName: displayName ?? this.displayName,
      photoURL: photoURL ?? this.photoURL,
      country: country ?? this.country,
      region: region ?? this.region,
      city: city ?? this.city,
      lastSeen: lastSeen ?? this.lastSeen,
      lastUpdated: lastUpdated ?? this.lastUpdated,
    );
  }

  String get locationDisplay {
    List<String> parts = [];
    if (city?.isNotEmpty == true) parts.add(city!);
    if (region?.isNotEmpty == true) parts.add(region!);
    if (country?.isNotEmpty == true) parts.add(country!);
    return parts.join(', ');
  }

  bool get hasLocation => 
    country?.isNotEmpty == true || 
    region?.isNotEmpty == true || 
    city?.isNotEmpty == true;
}
