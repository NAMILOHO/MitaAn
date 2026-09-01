import 'package:cloud_firestore/cloud_firestore.dart';

class UserModel {
  final String uid;
  final String nom;
  final String email;
  final String phone;
  final String bio;
  final double gpsLat;
  final double gpsLng;
  final String ville; // ← AJOUTÉ
  final bool isPro;
  final String categorie;
  final String photoUrl;
  final String fcmToken;
  final double rating;
  final int reviewCount;
  final bool isOnline;
  final String locationMode;
  final double fixedLat;
  final double fixedLng;
  final String fixedAddress;
  final DateTime? locationExpiry;
  final DateTime? lastSeen;
  final DateTime? createdAt;

  UserModel({
    required this.uid,
    required this.nom,
    required this.email,
    required this.phone,
    this.bio = '',
    this.gpsLat = 0.0,
    this.gpsLng = 0.0,
    this.ville = '', // ← AJOUTÉ
    this.isPro = false,
    this.categorie = '',
    this.photoUrl = '',
    this.fcmToken = '',
    this.rating = 0.0,
    this.reviewCount = 0,
    this.isOnline = false,
    this.locationMode = 'off',
    this.fixedLat = 0.0,
    this.fixedLng = 0.0,
    this.fixedAddress = '',
    this.locationExpiry,
    this.lastSeen,
    this.createdAt,
  });

  factory UserModel.fromMap(Map<String, dynamic> map, String uid) {
    DateTime? dateFrom(dynamic value) {
      if (value is Timestamp) return value.toDate();
      if (value is DateTime) return value;
      return null;
    }

    return UserModel(
      uid: uid,
      nom: map['nom'] ?? '',
      email: map['email'] ?? '',
      phone: map['phone'] ?? '',
      bio: map['bio'] ?? '',
      gpsLat: (map['gpsLat'] ?? 0.0).toDouble(),
      gpsLng: (map['gpsLng'] ?? 0.0).toDouble(),
      ville: map['ville'] ?? '', // ← AJOUTÉ
      isPro: map['isPro'] ?? false,
      categorie: map['categorie'] ?? '',
      photoUrl: map['photoUrl'] ?? '',
      fcmToken: map['fcmToken'] ?? '',
      rating: (map['rating'] ?? 0.0).toDouble(),
      reviewCount: (map['reviewCount'] ?? 0).toInt(),
      isOnline: map['isOnline'] ?? false,
      locationMode: map['locationMode'] ?? 'off',
      fixedLat: (map['fixedLat'] ?? 0.0).toDouble(),
      fixedLng: (map['fixedLng'] ?? 0.0).toDouble(),
      fixedAddress: map['fixedAddress'] ?? '',
      locationExpiry: dateFrom(map['locationExpiry']),
      lastSeen: dateFrom(map['lastSeen']),
      createdAt: dateFrom(map['createdAt']),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'nom': nom,
      'email': email,
      'phone': phone,
      'bio': bio,
      'gpsLat': gpsLat,
      'gpsLng': gpsLng,
      'ville': ville, // ← AJOUTÉ
      'isPro': isPro,
      'categorie': categorie,
      'photoUrl': photoUrl,
      'fcmToken': fcmToken,
      'rating': rating,
      'reviewCount': reviewCount,
      'isOnline': isOnline,
      'locationMode': locationMode,
      'fixedLat': fixedLat,
      'fixedLng': fixedLng,
      'fixedAddress': fixedAddress,
      'locationExpiry': locationExpiry,
      'lastSeen': lastSeen,
      'createdAt': createdAt,
    };
  }
}
