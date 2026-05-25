class UserModel {
  final String uid;
  final String nom;
  final String email;
  final String phone;
  final String ville;
  final String bio;
  final double gpsLat;
  final double gpsLng;
  final String ville;        // ← AJOUTÉ
  final bool isPro;
  final String categorie;
  final String photoUrl;
  final String fcmToken;
  final double rating;
  final int reviewCount;
  final bool isOnline;
  final DateTime? lastSeen;
  final DateTime? createdAt;

  UserModel({
    required this.uid,
    required this.nom,
    required this.email,
    required this.phone,
    required this.ville,
    this.bio = '',
    this.gpsLat = 0.0,
    this.gpsLng = 0.0,
    this.ville = '',          // ← AJOUTÉ
    this.isPro = false,
    this.categorie = '',
    this.photoUrl = '',
    this.fcmToken = '',
    this.rating = 0.0,
    this.reviewCount = 0,
    this.isOnline = false,
    this.lastSeen,
    this.createdAt,
  });

<<<<<<< HEAD
  // 🔥 Firestore → UserModel
=======
>>>>>>> develop
  factory UserModel.fromMap(Map<String, dynamic> map, String uid) {
    return UserModel(
      uid: uid,
      nom: map['nom'] ?? '',
      email: map['email'] ?? '',
      phone: map['phone'] ?? '',
      ville: map['ville'] ?? '', // ✅ CORRECTION IMPORTANTE
      bio: map['bio'] ?? '',
<<<<<<< HEAD
      gpsLat: (map['gpsLat'] is num)
          ? (map['gpsLat'] as num).toDouble()
          : 0.0,
      gpsLng: (map['gpsLng'] is num)
          ? (map['gpsLng'] as num).toDouble()
          : 0.0,
=======
      gpsLat: (map['gpsLat'] ?? 0.0).toDouble(),
      gpsLng: (map['gpsLng'] ?? 0.0).toDouble(),
      ville: map['ville'] ?? '',    // ← AJOUTÉ
>>>>>>> develop
      isPro: map['isPro'] ?? false,
      categorie: map['categorie'] ?? '',
      photoUrl: map['photoUrl'] ?? '',
      fcmToken: map['fcmToken'] ?? '',
<<<<<<< HEAD
      createdAt: map['createdAt'] != null
          ? map['createdAt'].toDate()
          : null,
=======
      rating: (map['rating'] ?? 0.0).toDouble(),
      reviewCount: (map['reviewCount'] ?? 0).toInt(),
      isOnline: map['isOnline'] ?? false,
      lastSeen: map['lastSeen']?.toDate(),
      createdAt: map['createdAt']?.toDate(),
>>>>>>> develop
    );
  }

<<<<<<< HEAD
  // 🔥 UserModel → Firestore
=======
>>>>>>> develop
  Map<String, dynamic> toMap() {
    return {
      'nom': nom,
      'email': email,
      'phone': phone,
      'ville': ville, // ✅ AJOUTÉ (très important)
      'bio': bio,
      'gpsLat': gpsLat,
      'gpsLng': gpsLng,
      'ville': ville,           // ← AJOUTÉ
      'isPro': isPro,
      'categorie': categorie,
      'photoUrl': photoUrl,
      'fcmToken': fcmToken,
      'rating': rating,
      'reviewCount': reviewCount,
      'isOnline': isOnline,
      'lastSeen': lastSeen,
      'createdAt': createdAt,
    };
  }
<<<<<<< HEAD

  // 🔥 BONUS PRO (très utile pour update partiel)
  UserModel copyWith({
    String? nom,
    String? email,
    String? phone,
    String? ville,
    String? bio,
    double? gpsLat,
    double? gpsLng,
    bool? isPro,
    String? categorie,
    String? photoUrl,
    String? fcmToken,
    DateTime? createdAt,
  }) {
    return UserModel(
      uid: uid,
      nom: nom ?? this.nom,
      email: email ?? this.email,
      phone: phone ?? this.phone,
      ville: ville ?? this.ville,
      bio: bio ?? this.bio,
      gpsLat: gpsLat ?? this.gpsLat,
      gpsLng: gpsLng ?? this.gpsLng,
      isPro: isPro ?? this.isPro,
      categorie: categorie ?? this.categorie,
      photoUrl: photoUrl ?? this.photoUrl,
      fcmToken: fcmToken ?? this.fcmToken,
      createdAt: createdAt ?? this.createdAt,
    );
  }
}
=======
}
>>>>>>> develop
