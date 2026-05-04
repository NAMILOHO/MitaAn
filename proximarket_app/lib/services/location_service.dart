import 'package:geolocator/geolocator.dart';
import 'package:geocoding/geocoding.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import 'package:permission_handler/permission_handler.dart';

class LocationService {

  // ─────────────────────────────────────────
  // DEMANDER LA PERMISSION GPS
  // ─────────────────────────────────────────
  Future<bool> requestPermission() async {
    if (kIsWeb) {
      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
      }
      return permission != LocationPermission.denied &&
             permission != LocationPermission.deniedForever;
    }

    // Sur Android/iOS → utiliser permission_handler
    final status = await Permission.location.request();

    if (status.isGranted) return true;

    if (status.isPermanentlyDenied) {
      // L'utilisateur a dit "Ne plus demander"
      // On ouvre les paramètres de l'app
      await openAppSettings();
      return false;
    }

    return false;
  }

  // ─────────────────────────────────────────
  // OBTENIR LA POSITION ACTUELLE
  // ─────────────────────────────────────────
  Future<Position> getCurrentPosition() async {
    // 1. Demander la permission
    final granted = await requestPermission();
    if (!granted) {
      throw 'Permission GPS refusée. '
            'Activez-la dans Paramètres → Applications → ProxiMarket → Autorisations';
    }

    // 2. Vérifier que le GPS est activé
    if (!kIsWeb) {
      final serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        throw 'Le GPS est désactivé. '
              'Activez-le dans les paramètres de votre téléphone.';
      }
    }

    // 3. Obtenir la position
    return await Geolocator.getCurrentPosition(
      desiredAccuracy: kIsWeb
          ? LocationAccuracy.low
          : LocationAccuracy.high,
      timeLimit: const Duration(seconds: 15),
    );
  }

  // ─────────────────────────────────────────
  // CONVERTIR COORDONNÉES → NOM DE VILLE
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
                     place.subAdministrativeArea ?? '';
        final country = place.country ?? '';
        return '$city, $country'.trim();
      }
      return 'Ville inconnue';
    } catch (e) {
      return 'Ville inconnue';
    }
  }

  // ─────────────────────────────────────────
  // SAUVEGARDER LA POSITION DANS FIRESTORE
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
  // CALCULER LA DISTANCE (en km)
  // ─────────────────────────────────────────
  double calculateDistance(
    double lat1, double lng1,
    double lat2, double lng2,
  ) {
    return Geolocator.distanceBetween(
            lat1, lng1, lat2, lng2) / 1000;
  }
}