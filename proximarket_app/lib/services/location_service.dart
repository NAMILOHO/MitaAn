import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import 'package:geocoding/geocoding.dart';
import 'package:geolocator/geolocator.dart';

class LocationService {
  // ─────────────────────────────────────────
  // DEMANDE DE PERMISSION
  // ─────────────────────────────────────────
  Future<bool> requestPermission() async {
    LocationPermission permission = await Geolocator.checkPermission();

    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
    }

    if (permission == LocationPermission.denied) {
      return false;
    }

    if (permission == LocationPermission.deniedForever) {
      return false;
    }

    return permission == LocationPermission.whileInUse ||
        permission == LocationPermission.always;
  }

  // ─────────────────────────────────────────
  // OBTENIR LA POSITION ACTUELLE (Version non-dépréciée)
  // ─────────────────────────────────────────
  Future<Position> getCurrentPosition() async {
    final granted = await requestPermission();
    if (!granted) {
      throw 'Permission GPS refusée.\n'
          'Activez-la dans Paramètres → Applications → ProxiMarket → Autorisations';
    }

    // Vérifier si le service de localisation est activé (sauf sur Web)
    if (!kIsWeb) {
      final serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        throw 'Le GPS est désactivé.\n'
            'Activez-le dans les paramètres de votre téléphone.';
      }
    }

    // Nouvelle API recommandée (non-dépréciée)
    if (kIsWeb) {
      return await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(
          accuracy: LocationAccuracy.low,
        ),
      );
    }

    return await Geolocator.getCurrentPosition(
      locationSettings: AndroidSettings(
        accuracy: LocationAccuracy.high,
        timeLimit: const Duration(seconds: 15),
      ),
    );
  }

  // ─────────────────────────────────────────
  // CONVERTIR COORDONNÉES → VILLE
  // ─────────────────────────────────────────
  Future<String> getCityFromCoordinates(double lat, double lng) async {
    try {
      if (kIsWeb) {
        return 'Lat: ${lat.toStringAsFixed(4)}, Lng: ${lng.toStringAsFixed(4)}';
      }

      final placemarks = await placemarkFromCoordinates(lat, lng);

      if (placemarks.isNotEmpty) {
        final place = placemarks.first;
        final city = place.locality ??
            place.subAdministrativeArea ??
            place.administrativeArea ??
            place.subLocality ??
            '';
        final country = place.country ?? '';

        return '$city, $country'.trim().isNotEmpty
            ? '$city, $country'
            : 'Localisation inconnue';
      }
      return 'Ville inconnue';
    } catch (e) {
      return 'Ville inconnue';
    }
  }

  // ─────────────────────────────────────────
  // SAUVEGARDER POSITION UTILISATEUR DANS FIRESTORE
  // ─────────────────────────────────────────
  Future<void> saveUserLocation(String uid) async {
    try {
      final position = await getCurrentPosition();
      final city = await getCityFromCoordinates(
        position.latitude,
        position.longitude,
      );

      await FirebaseFirestore.instance
          .collection('users')
          .doc(uid)
          .update({
        'gpsLat': position.latitude,
        'gpsLng': position.longitude,
        'ville': city,
        'updatedAt': FieldValue.serverTimestamp(),
      });
    } catch (e) {
      rethrow; // Laisse l'appelant gérer l'erreur (ex: afficher SnackBar)
    }
  }

  // ─────────────────────────────────────────
  // CALCUL DE DISTANCE EN KM
  // ─────────────────────────────────────────
  double calculateDistance(
    double lat1,
    double lng1,
    double lat2,
    double lng2,
  ) {
    return Geolocator.distanceBetween(lat1, lng1, lat2, lng2) / 1000;
  }
}