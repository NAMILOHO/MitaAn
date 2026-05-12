import 'package:cloud_firestore/cloud_firestore.dart';

class ServiceModel {
  final String id;
  final String userId;
  final String titre;
  final String description;
  final String categorie;
  final double prix;
  final String unite;        // ✅ AJOUT : par heure / par jour / forfait
  final List<String> photos;
  final double gpsLat;
  final double gpsLng;
  final String ville;
  final bool isActive;
  final DateTime? createdAt;

  ServiceModel({
    required this.id,
    required this.userId,
    required this.titre,
    required this.description,
    required this.categorie,
    required this.prix,
    this.unite = 'forfait',   // ✅ valeur par défaut
    this.photos = const [],
    this.gpsLat = 0.0,
    this.gpsLng = 0.0,
    this.ville = '',
    this.isActive = true,
    this.createdAt,
  });

  // Firestore → ServiceModel
  factory ServiceModel.fromMap(Map<String, dynamic> map, String id) {
    return ServiceModel(
      id: id,
      userId: map['userId'] ?? '',
      titre: map['titre'] ?? '',
      description: map['description'] ?? '',
      categorie: map['categorie'] ?? '',
      prix: (map['prix'] ?? 0.0).toDouble(),
      unite: map['unite'] ?? 'forfait', // ✅ rétrocompatible si absent
      photos: List<String>.from(map['photos'] ?? []),
      gpsLat: (map['gpsLat'] ?? 0.0).toDouble(),
      gpsLng: (map['gpsLng'] ?? 0.0).toDouble(),
      ville: map['ville'] ?? '',
      isActive: map['isActive'] ?? true,
      createdAt: map['createdAt'] is Timestamp
          ? (map['createdAt'] as Timestamp).toDate()
          : map['createdAt']?.toDate(),
    );
  }

  // ServiceModel → Firestore
  Map<String, dynamic> toMap() {
    return {
      'userId': userId,
      'titre': titre,
      'description': description,
      'categorie': categorie,
      'prix': prix,
      'unite': unite,         // ✅ inclus dans la sérialisation
      'photos': photos,
      'gpsLat': gpsLat,
      'gpsLng': gpsLng,
      'ville': ville,
      'isActive': isActive,
      if (createdAt != null) 'createdAt': createdAt,
    };
  }

  // ✅ copyWith pour la mise à jour partielle (utilisé dans EditServiceScreen)
  ServiceModel copyWith({
    String? titre,
    String? description,
    String? categorie,
    double? prix,
    String? unite,
    List<String>? photos,
    double? gpsLat,
    double? gpsLng,
    String? ville,
    bool? isActive,
  }) {
    return ServiceModel(
      id: id,
      userId: userId,
      titre: titre ?? this.titre,
      description: description ?? this.description,
      categorie: categorie ?? this.categorie,
      prix: prix ?? this.prix,
      unite: unite ?? this.unite,
      photos: photos ?? this.photos,
      gpsLat: gpsLat ?? this.gpsLat,
      gpsLng: gpsLng ?? this.gpsLng,
      ville: ville ?? this.ville,
      isActive: isActive ?? this.isActive,
      createdAt: createdAt,
    );
  }
}