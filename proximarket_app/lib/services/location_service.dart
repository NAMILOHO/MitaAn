import 'package:geolocator/geolocator.dart';
import 'package:geocoding/geocoding.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';

class LocationService {

  // ─────────────────────────────────────────
  // OBTENIR LA POSITION AVEC GESTION COMPLÈTE
  // ─────────────────────────────────────────
  Future<Position> getCurrentPosition() async {
    // 1. Vérifier si le GPS est activé
    bool serviceEnabled = await Geolocator.isLocationServiceEnabled();

    if (!serviceEnabled) {
      throw 'Le GPS est désactivé. Activez-le dans les paramètres.';
    }

    // 2. Vérifier permission
    LocationPermission permission = await Geolocator.checkPermission();

    if (permission == LocationPermission.denied) {
      // Demander permission
      permission = await Geolocator.requestPermission();
    }

    if (permission == LocationPermission.denied) {
      throw 'Permission GPS refusée';
    }

    if (permission == LocationPermission.deniedForever) {
      throw 'Permission refusée définitivement. '
            'Activez-la dans Paramètres > Applications > ProxiMarket';
    }

    // 3. Obtenir position
    return await Geolocator.getCurrentPosition(
      desiredAccuracy: kIsWeb
          ? LocationAccuracy.low
          : LocationAccuracy.high,
      timeLimit: const Duration(seconds: 15),
    );
  }

  // ─────────────────────────────────────────
  // CONVERTIR COORDONNÉES → VILLE
  // ─────────────────────────────────────────
  Future<String> getCityFromCoordinates(double lat, double lng) async {
    try {
      if (kIsWeb) {
        return 'Lat: ${lat.toStringAsFixed(4)}, '
               'Lng: ${lng.toStringAsFixed(4)}';
      }

      final placemarks = await placemarkFromCoordinates(lat, lng);

      if (placemarks.isNotEmpty) {
        final place = placemarks.first;

        final city = place.locality ??
                     place.subAdministrativeArea ??
                     place.administrativeArea ??
                     '';

        final country = place.country ?? '';

        return '$city, $country'.trim();
      }

      return 'Ville inconnue';
    } catch (e) {
      return 'Ville inconnue';
    }
  }

  // ─────────────────────────────────────────
  // SAUVEGARDER POSITION UTILISATEUR
  // ─────────────────────────────────────────
  Future<void> saveUserLocation(String uid) async {
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
    });
  }

  // ─────────────────────────────────────────
  // CALCUL DISTANCE (KM)
  // ─────────────────────────────────────────
  double calculateDistance(
    double lat1, double lng1,
    double lat2, double lng2,
  ) {
    return Geolocator.distanceBetween(
      lat1,
      lng1,
      lat2,
      lng2,
    ) / 1000;
  }
}