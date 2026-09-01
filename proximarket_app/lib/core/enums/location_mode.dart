enum LocationMode { off, fixed, service, meeting, delivery, mobileSeller }

extension LocationModeExt on LocationMode {
  String get label {
    switch (this) {
      case LocationMode.off:
        return 'Invisible';
      case LocationMode.fixed:
        return 'Position fixe';
      case LocationMode.service:
        return 'En service';
      case LocationMode.meeting:
        return 'Rencontre';
      case LocationMode.delivery:
        return 'Livraison';
      case LocationMode.mobileSeller:
        return 'Vendeur mobile';
    }
  }

  String get firestoreKey => name;

  static LocationMode fromString(String? value) {
    return LocationMode.values.firstWhere(
      (mode) => mode.name == value,
      orElse: () => LocationMode.off,
    );
  }
}
