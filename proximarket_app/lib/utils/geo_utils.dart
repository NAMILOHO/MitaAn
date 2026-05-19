import 'package:geolocator/geolocator.dart';

class GeoUtils {
  GeoUtils._(); // classe utilitaire non instanciable

  // ─────────────────────────────────────────
  // DISTANCE ENTRE DEUX COORDONNÉES GPS (en km)
  // Utilise la formule de Haversine via Geolocator
  // ─────────────────────────────────────────
  static double distanceBetween(
    double lat1,
    double lng1,
    double lat2,
    double lng2,
  ) {
    // Geolocator.distanceBetween retourne des mètres → on divise par 1000
    return Geolocator.distanceBetween(lat1, lng1, lat2, lng2) / 1000;
  }

  // ─────────────────────────────────────────
  // VÉRIFIER SI UNE COORDONNÉE EST VALIDE
  // (non nulle, non zéro)
  // ─────────────────────────────────────────
  static bool isValidCoordinate(double lat, double lng) {
    return lat != 0.0 && lng != 0.0;
  }

  // ─────────────────────────────────────────
  // FORMATER LA DISTANCE EN TEXTE LISIBLE
  // Exemples : 0.3 → "300 m" | 1.5 → "1.5 km" | 25 → "25 km"
  // ─────────────────────────────────────────
  static String formatDistance(double distanceInKm) {
    if (distanceInKm < 1) {
      return '${(distanceInKm * 1000).round()} m';
    } else if (distanceInKm < 10) {
      return '${distanceInKm.toStringAsFixed(1)} km';
    } else {
      return '${distanceInKm.round()} km';
    }
  }

  // ─────────────────────────────────────────
  // LABEL DE PROXIMITÉ
  // ─────────────────────────────────────────
  static String proximityLabel(double distanceInKm) {
    if (distanceInKm <= 2) return 'Très proche';
    if (distanceInKm <= 10) return 'Proche';
    return 'Éloigné';
  }

  // ─────────────────────────────────────────
  // COULEUR SELON LA DISTANCE
  // ─────────────────────────────────────────
  static ({int r, int g, int b}) proximityColor(double distanceInKm) {
    if (distanceInKm <= 2) return (r: 76, g: 175, b: 80);   // vert
    if (distanceInKm <= 10) return (r: 255, g: 152, b: 0);  // orange
    return (r: 158, g: 158, b: 158);                         // gris
  }
}