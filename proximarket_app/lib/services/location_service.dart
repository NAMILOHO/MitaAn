import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import 'package:geocoding/geocoding.dart';
import 'package:geolocator/geolocator.dart';

import '../models/user_model.dart';

class LocationService {
  // ─────────────────────────────────────────
  // DEMANDE DE PERMISSION
  // ─────────────────────────────────────────
  Future<bool> requestPermission() async {
    LocationPermission permission =
        await Geolocator.checkPermission();

    if (permission == LocationPermission.denied) {
      permission =
          await Geolocator.requestPermission();
    }

    if (permission ==
            LocationPermission.denied ||
        permission ==
            LocationPermission.deniedForever) {
      return false;
    }

    return permission ==
            LocationPermission.whileInUse ||
        permission ==
            LocationPermission.always;
  }

  // ─────────────────────────────────────────
  // OBTENIR POSITION ACTUELLE
  // ─────────────────────────────────────────
  Future<Position> getCurrentPosition() async {
    final granted = await requestPermission();

    if (!granted) {
      throw Exception(
        'Permission GPS refusée.\n'
        'Activez-la dans Paramètres → Applications → MitaAn → Autorisations',
      );
    }

    if (!kIsWeb) {
      final serviceEnabled =
          await Geolocator.isLocationServiceEnabled();

      if (!serviceEnabled) {
        throw Exception(
          'Le GPS est désactivé.\n'
          'Activez-le dans les paramètres du téléphone.',
        );
      }
    }

    try {
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
    } catch (e) {
      throw Exception(
        'Impossible d’obtenir la position GPS : $e',
      );
    }
  }

  // ─────────────────────────────────────────
  // COORDONNÉES → VILLE
  // ─────────────────────────────────────────
  Future<String> getCityFromCoordinates(
    double lat,
    double lng,
  ) async {
    try {
      if (kIsWeb) {
        return 'Lat: ${lat.toStringAsFixed(4)}, '
            'Lng: ${lng.toStringAsFixed(4)}';
      }

      final placemarks =
          await placemarkFromCoordinates(lat, lng);

      if (placemarks.isNotEmpty) {
        final place = placemarks.first;

        final city =
            place.locality ??
                place.subAdministrativeArea ??
                place.administrativeArea ??
                place.subLocality ??
                '';

        final country = place.country ?? '';

        if (city.isNotEmpty) {
          return '$city, $country';
        }
      }

      return 'Ville inconnue';
    } catch (_) {
      return 'Ville inconnue';
    }
  }

  // ─────────────────────────────────────────
  // SAUVEGARDER POSITION UTILISATEUR
  // ─────────────────────────────────────────
  Future<void> saveUserLocation(
    String uid,
  ) async {
    try {
      final position =
          await getCurrentPosition();

      final city =
          await getCityFromCoordinates(
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
        'updatedAt':
            FieldValue.serverTimestamp(),
      });
    } catch (e) {
      throw Exception(
        'Erreur sauvegarde position : $e',
      );
    }
  }

  // ─────────────────────────────────────────
  // CALCUL DISTANCE EN KM
  // ─────────────────────────────────────────
  double calculateDistance(
    double lat1,
    double lng1,
    double lat2,
    double lng2,
  ) {
    return Geolocator.distanceBetween(
          lat1,
          lng1,
          lat2,
          lng2,
        ) /
        1000;
  }

  // ─────────────────────────────────────────
  // CHARGER LES PRESTATAIRES À PROXIMITÉ
  // ─────────────────────────────────────────
  Future<List<UserModel>> getNearbyPros({
    required double myLat,
    required double myLng,
    double radiusKm = 20.0,
    String? categorieFilter,
  }) async {
    try {
      // IMPORTANT :
      // Une seule condition Firestore
      // pour éviter les erreurs d’index
      final snapshot =
          await FirebaseFirestore.instance
              .collection('users')
              .where(
                'isPro',
                isEqualTo: true,
              )
              .get();

      final List<UserModel> results = [];

      for (final doc in snapshot.docs) {
        try {
          final data =
              doc.data();

          final user =
              UserModel.fromMap(
            data,
            doc.id,
          );

          // Ignorer coordonnées invalides
          if (user.gpsLat == 0.0 ||
              user.gpsLng == 0.0) {
            continue;
          }

          // Filtre catégorie
          if (categorieFilter != null &&
              categorieFilter.isNotEmpty &&
              user.categorie !=
                  categorieFilter) {
            continue;
          }

          // Distance
          final distance =
              calculateDistance(
            myLat,
            myLng,
            user.gpsLat,
            user.gpsLng,
          );

          // Filtre rayon
          if (distance <= radiusKm) {
            results.add(user);
          }
        } catch (e) {
          debugPrint(
            'Erreur utilisateur ${doc.id}: $e',
          );
        }
      }

      // Trier par distance
      results.sort((a, b) {
        final distanceA =
            calculateDistance(
          myLat,
          myLng,
          a.gpsLat,
          a.gpsLng,
        );

        final distanceB =
            calculateDistance(
          myLat,
          myLng,
          b.gpsLat,
          b.gpsLng,
        );

        return distanceA.compareTo(
          distanceB,
        );
      });

      return results;
    } catch (e) {
      throw Exception(
        'Erreur chargement prestataires : $e',
      );
    }
  }
}