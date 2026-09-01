import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import 'package:geolocator/geolocator.dart';

import '../core/enums/location_mode.dart';

class LiveLocationService {
  static final LiveLocationService _instance = LiveLocationService._internal();

  factory LiveLocationService() => _instance;

  LiveLocationService._internal();

  final _firestore = FirebaseFirestore.instance;
  StreamSubscription<Position>? _positionSub;

  void startLiveTracking(String uid) {
    _positionSub?.cancel();
    _positionSub =
        Geolocator.getPositionStream(
          locationSettings: const LocationSettings(
            accuracy: LocationAccuracy.high,
            distanceFilter: 20,
          ),
        ).listen((position) async {
          try {
            await _firestore.collection('users').doc(uid).update({
              'gpsLat': position.latitude,
              'gpsLng': position.longitude,
              'lastLocationUpdate': FieldValue.serverTimestamp(),
              'updatedAt': FieldValue.serverTimestamp(),
            });
            debugPrint(
              'Position live mise a jour: ${position.latitude}, ${position.longitude}',
            );
          } catch (e) {
            debugPrint('Erreur live tracking: $e');
          }
        });
  }

  void stopLiveTracking() {
    _positionSub?.cancel();
    _positionSub = null;
    debugPrint('Live tracking arrete');
  }

  Future<void> setLocationMode(
    String uid,
    LocationMode mode, {
    DateTime? expiry,
    double? fixedLat,
    double? fixedLng,
    String? fixedAddress,
  }) async {
    final data = <String, dynamic>{
      'locationMode': mode.firestoreKey,
      'updatedAt': FieldValue.serverTimestamp(),
    };

    if (expiry != null) {
      data['locationExpiry'] = Timestamp.fromDate(expiry);
    }
    if (fixedLat != null) data['fixedLat'] = fixedLat;
    if (fixedLng != null) data['fixedLng'] = fixedLng;
    if (fixedAddress != null) data['fixedAddress'] = fixedAddress;

    await _firestore.collection('users').doc(uid).update(data);
  }

  Stream<List<Map<String, dynamic>>> getVisiblePros({
    required double myLat,
    required double myLng,
    double radiusKm = 20,
  }) {
    return _firestore
        .collection('users')
        .where('isPro', isEqualTo: true)
        .where('locationMode', whereNotIn: [LocationMode.off.firestoreKey])
        .snapshots()
        .map((snapshot) {
          final now = DateTime.now();

          return snapshot.docs
              .map((doc) => {'id': doc.id, ...doc.data()})
              .where((user) {
                final expiry = _dateFrom(user['locationExpiry']);
                if (expiry != null && expiry.isBefore(now)) return false;

                final mode = user['locationMode'] as String? ?? '';
                final lat = mode == LocationMode.fixed.firestoreKey
                    ? _doubleFrom(user['fixedLat'])
                    : _doubleFrom(user['gpsLat']);
                final lng = mode == LocationMode.fixed.firestoreKey
                    ? _doubleFrom(user['fixedLng'])
                    : _doubleFrom(user['gpsLng']);
                if (lat == 0.0 && lng == 0.0) return false;

                final distanceKm =
                    Geolocator.distanceBetween(myLat, myLng, lat, lng) / 1000;
                return distanceKm <= radiusKm;
              })
              .toList();
        });
  }

  DateTime? _dateFrom(dynamic value) {
    if (value is Timestamp) return value.toDate();
    if (value is DateTime) return value;
    return null;
  }

  double _doubleFrom(dynamic value) {
    if (value is num) return value.toDouble();
    return 0.0;
  }

  void dispose() {
    stopLiveTracking();
  }
}
