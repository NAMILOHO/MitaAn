class UserModel {
  final String uid;
  final String nom;
  final String email;
  final String phone;
  final String ville;
  final String bio;
  final double gpsLat;
  final double gpsLng;
  final bool isPro;
  final String categorie;
  final String photoUrl;
  final String fcmToken;
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
    this.isPro = false,
    this.categorie = '',
    this.photoUrl = '',
    this.fcmToken = '',
    this.createdAt,
  });

  // 🔥 Firestore → UserModel
  factory UserModel.fromMap(Map<String, dynamic> map, String uid) {
    return UserModel(
      uid: uid,
      nom: map['nom'] ?? '',
      email: map['email'] ?? '',
      phone: map['phone'] ?? '',
      ville: map['ville'] ?? '', // ✅ CORRECTION IMPORTANTE
      bio: map['bio'] ?? '',
      gpsLat: (map['gpsLat'] is num)
          ? (map['gpsLat'] as num).toDouble()
          : 0.0,
      gpsLng: (map['gpsLng'] is num)
          ? (map['gpsLng'] as num).toDouble()
          : 0.0,
      isPro: map['isPro'] ?? false,
      categorie: map['categorie'] ?? '',
      photoUrl: map['photoUrl'] ?? '',
      fcmToken: map['fcmToken'] ?? '',
      createdAt: map['createdAt'] != null
          ? map['createdAt'].toDate()
          : null,
    );
  }

  // 🔥 UserModel → Firestore
  Map<String, dynamic> toMap() {
    return {
      'nom': nom,
      'email': email,
      'phone': phone,
      'ville': ville, // ✅ AJOUTÉ (très important)
      'bio': bio,
      'gpsLat': gpsLat,
      'gpsLng': gpsLng,
      'isPro': isPro,
      'categorie': categorie,
      'photoUrl': photoUrl,
      'fcmToken': fcmToken,
      'createdAt': createdAt,
    };
  }

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