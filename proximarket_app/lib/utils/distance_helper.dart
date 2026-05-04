class DistanceHelper {
  // ─────────────────────────────────────────
  // FORMATER LA DISTANCE EN TEXTE LISIBLE
  // ─────────────────────────────────────────
  // Exemples :
  //   0.3  → "300 m"
  //   1.5  → "1.5 km"
  //   25.0 → "25 km"
  static String format(double distanceInKm) {
    if (distanceInKm < 1) {
      // Moins d'1 km → afficher en mètres
      final meters = (distanceInKm * 1000).round();
      return '$meters m';
    } else if (distanceInKm < 10) {
      // Entre 1 et 10 km → 1 décimale
      return '${distanceInKm.toStringAsFixed(1)} km';
    } else {
      // Plus de 10 km → nombre entier
      return '${distanceInKm.round()} km';
    }
  }

  // ─────────────────────────────────────────
  // COULEUR SELON LA DISTANCE
  // ─────────────────────────────────────────
  // Vert  → moins de 2 km (très proche)
  // Orange → entre 2 et 10 km (proche)
  // Gris  → plus de 10 km (loin)
  static String getProximityLabel(double distanceInKm) {
    if (distanceInKm <= 2) return 'Très proche';
    if (distanceInKm <= 10) return 'Proche';
    return 'Éloigné';
  }
}