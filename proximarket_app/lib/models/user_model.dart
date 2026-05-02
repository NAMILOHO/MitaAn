class UserModel {
  final String uid;
  final String nom;
  final String email;
  final String phone;
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
    this.bio = '',
    this.gpsLat = 0.0,
    this.gpsLng = 0.0,
    this.isPro = false,
    this.categorie = '',
    this.photoUrl = '',
    this.fcmToken = '',
    this.createdAt,
  });

  // Convertir Firestore → UserModel
  factory UserModel.fromMap(Map<String, dynamic> map, String uid) {
    return UserModel(
      uid: uid,
      nom: map['nom'] ?? '',
      email: map['email'] ?? '',
      phone: map['phone'] ?? '',
      bio: map['bio'] ?? '',
      gpsLat: (map['gpsLat'] ?? 0.0).toDouble(),
      gpsLng: (map['gpsLng'] ?? 0.0).toDouble(),
      isPro: map['isPro'] ?? false,
      categorie: map['categorie'] ?? '',
      photoUrl: map['photoUrl'] ?? '',
      fcmToken: map['fcmToken'] ?? '',
      createdAt: map['createdAt']?.toDate(),
    );
  }

  // Convertir UserModel → Firestore
  Map<String, dynamic> toMap() {
    return {
      'nom': nom,
      'email': email,
      'phone': phone,
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
}