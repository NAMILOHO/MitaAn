enum TypeAnnonce { service, location, vente, evenement, autre }

extension TypeAnnonceExt on TypeAnnonce {
  String get label {
    switch (this) {
      case TypeAnnonce.service:
        return 'Service';
      case TypeAnnonce.location:
        return 'Location';
      case TypeAnnonce.vente:
        return 'Vente';
      case TypeAnnonce.evenement:
        return 'Événement';
      case TypeAnnonce.autre:
        return 'Autre';
    }
  }

  String get firestoreKey => name;

  static TypeAnnonce fromString(String? value) {
    return TypeAnnonce.values.firstWhere(
      (t) => t.name == value,
      orElse: () => TypeAnnonce.autre,
    );
  }

  static const Map<TypeAnnonce, List<String>> suggestedFields = {
    TypeAnnonce.location: [
      'Chambres',
      'Salles de bain',
      'Surface',
      'Meublé',
      'Type de bien',
      'Étage',
    ],
    TypeAnnonce.vente: ['État', 'Marque', 'Année', 'Kilométrage'],
    TypeAnnonce.service: ['Durée', 'Zone d\'intervention', 'Expérience'],
    TypeAnnonce.evenement: ['Date', 'Lieu', 'Capacité'],
    TypeAnnonce.autre: [],
  };
}
