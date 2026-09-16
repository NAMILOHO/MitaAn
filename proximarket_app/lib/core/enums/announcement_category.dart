import 'package:flutter/material.dart';

enum AnnouncementCategory {
  immobilier,
  produit,
  service,
  vehicule,
  agriculture,
  emploi,
  evenement,
  autre,
}

extension AnnouncementCategoryExt on AnnouncementCategory {
  String get label {
    switch (this) {
      case AnnouncementCategory.immobilier:
        return 'Immobilier';
      case AnnouncementCategory.produit:
        return 'Produit';
      case AnnouncementCategory.service:
        return 'Service';
      case AnnouncementCategory.vehicule:
        return 'Véhicule';
      case AnnouncementCategory.agriculture:
        return 'Agriculture';
      case AnnouncementCategory.emploi:
        return 'Emploi';
      case AnnouncementCategory.evenement:
        return 'Événement';
      case AnnouncementCategory.autre:
        return 'Autre';
    }
  }

  IconData get icon {
    switch (this) {
      case AnnouncementCategory.immobilier:
        return Icons.home_rounded;
      case AnnouncementCategory.produit:
        return Icons.shopping_bag_rounded;
      case AnnouncementCategory.service:
        return Icons.build_rounded;
      case AnnouncementCategory.vehicule:
        return Icons.directions_car_rounded;
      case AnnouncementCategory.agriculture:
        return Icons.eco_rounded;
      case AnnouncementCategory.emploi:
        return Icons.work_rounded;
      case AnnouncementCategory.evenement:
        return Icons.celebration_rounded;
      case AnnouncementCategory.autre:
        return Icons.apps_rounded;
    }
  }

  Color get color {
    switch (this) {
      case AnnouncementCategory.immobilier:
        return const Color(0xFF085041);
      case AnnouncementCategory.produit:
        return const Color(0xFF0C447C);
      case AnnouncementCategory.service:
        return const Color(0xFF3C3489);
      case AnnouncementCategory.vehicule:
        return const Color(0xFF993556);
      case AnnouncementCategory.agriculture:
        return const Color(0xFF633806);
      case AnnouncementCategory.emploi:
        return const Color(0xFF27500A);
      case AnnouncementCategory.evenement:
        return const Color(0xFFBA7517);
      case AnnouncementCategory.autre:
        return const Color(0xFF444441);
    }
  }

  Color get bgColor {
    switch (this) {
      case AnnouncementCategory.immobilier:
        return const Color(0xFFE1F5EE);
      case AnnouncementCategory.produit:
        return const Color(0xFFE6F1FB);
      case AnnouncementCategory.service:
        return const Color(0xFFEEEDFE);
      case AnnouncementCategory.vehicule:
        return const Color(0xFFFBEAF0);
      case AnnouncementCategory.agriculture:
        return const Color(0xFFFAEEDA);
      case AnnouncementCategory.emploi:
        return const Color(0xFFEAF3DE);
      case AnnouncementCategory.evenement:
        return const Color(0xFFFFF3E0);
      case AnnouncementCategory.autre:
        return const Color(0xFFF1EFE8);
    }
  }

  /// Attributs suggérés dans le bottom sheet "+ Ajouter plus d'informations"
  List<String> get suggestedAttributes {
    switch (this) {
      case AnnouncementCategory.immobilier:
        return [
          'Chambres',
          'Salles de bain',
          'Surface',
          'Meublé',
          'Étage',
          'Parking',
          'Piscine',
          'Jardin',
        ];
      case AnnouncementCategory.produit:
        return ['État', 'Marque', 'Quantité disponible', 'Livraison'];
      case AnnouncementCategory.service:
        return ['Durée', 'Zone d\'intervention', 'Expérience', 'Disponibilité'];
      case AnnouncementCategory.vehicule:
        return [
          'Marque',
          'Modèle',
          'Année',
          'Kilométrage',
          'Transmission',
          'Carburant',
        ];
      case AnnouncementCategory.agriculture:
        return ['Quantité', 'Unité de vente', 'Saison', 'Livraison'];
      case AnnouncementCategory.emploi:
        return ['Type de contrat', 'Salaire', 'Horaires', 'Expérience requise'];
      case AnnouncementCategory.evenement:
        return ['Date', 'Lieu', 'Capacité', 'Horaires'];
      case AnnouncementCategory.autre:
        return [];
    }
  }

  static AnnouncementCategory fromString(String? value) {
    return AnnouncementCategory.values.firstWhere(
      (c) => c.name == value,
      orElse: () => AnnouncementCategory.autre,
    );
  }
}
