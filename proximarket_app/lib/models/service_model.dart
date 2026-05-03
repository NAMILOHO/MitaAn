class ServiceModel {
  final String id;
  final String userId;
  final String titre;
  final String description;
  final String categorie;
  final double prix;
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
      photos: List<String>.from(map['photos'] ?? []),
      gpsLat: (map['gpsLat'] ?? 0.0).toDouble(),
      gpsLng: (map['gpsLng'] ?? 0.0).toDouble(),
      ville: map['ville'] ?? '',
      isActive: map['isActive'] ?? true,
      createdAt: map['createdAt']?.toDate(),
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
      'photos': photos,
      'gpsLat': gpsLat,
      'gpsLng': gpsLng,
      'ville': ville,
      'isActive': isActive,
      'createdAt': createdAt,
    };
  }
}