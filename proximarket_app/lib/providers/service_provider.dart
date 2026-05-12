import 'dart:io';
import 'package:flutter/material.dart';

import '../models/service_model.dart';
import '../services/service_firestore.dart';

class ServiceProvider extends ChangeNotifier {
  final ServiceFirestore _serviceFirestore = ServiceFirestore();

  // ✅ Getter pour accès depuis les écrans
  ServiceFirestore get serviceFirestore => _serviceFirestore;

  List<ServiceModel> _services = [];
  List<ServiceModel> _myServices = [];

  bool _isLoading = false;
  String? _errorMessage;

  // ─────────────────────────────────────────
  // GETTERS
  // ─────────────────────────────────────────
  List<ServiceModel> get services => _services;
  List<ServiceModel> get myServices => _myServices;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;

  // ─────────────────────────────────────────
  // CRÉER UNE ANNONCE
  // ─────────────────────────────────────────
  Future<bool> createService({
    required String userId,
    required String titre,
    required String description,
    required String categorie,
    required double prix,
    required String unite, // ✅ AJOUT
    required List<File> imageFiles,
    required double gpsLat,
    required double gpsLng,
    required String ville,
  }) async {
    _setLoading(true);

    try {
      // ✅ Upload des photos
      List<String> photoUrls = [];

      if (imageFiles.isNotEmpty) {
        photoUrls = await _serviceFirestore.uploadServicePhotos(
          userId,
          imageFiles,
        );
      }

      // ✅ Création Firestore
      final service = await _serviceFirestore.createService(
        userId: userId,
        titre: titre,
        description: description,
        categorie: categorie,
        prix: prix,
        unite: unite, // ✅ AJOUT
        photos: photoUrls,
        gpsLat: gpsLat,
        gpsLng: gpsLng,
        ville: ville,
      );

      // ✅ Ajout local
      _services.insert(0, service);
      _myServices.insert(0, service);

      _errorMessage = null;
      notifyListeners();

      return true;
    } catch (e) {
      _errorMessage = e.toString();
      notifyListeners();

      return false;
    } finally {
      _setLoading(false);
    }
  }

  // ─────────────────────────────────────────
  // CHARGER TOUTES LES ANNONCES
  // ─────────────────────────────────────────
  Future<void> loadAllServices() async {
    _setLoading(true);

    try {
      _services = await _serviceFirestore.getAllServices();

      _errorMessage = null;
      notifyListeners();
    } catch (e) {
      _errorMessage = e.toString();
      notifyListeners();
    } finally {
      _setLoading(false);
    }
  }

  // ─────────────────────────────────────────
  // CHARGER PAR CATÉGORIE
  // ─────────────────────────────────────────
  Future<void> loadServicesByCategory(
    String categorie,
  ) async {
    _setLoading(true);

    try {
      _services = await _serviceFirestore
          .getServicesByCategory(categorie);

      _errorMessage = null;
      notifyListeners();
    } catch (e) {
      _errorMessage = e.toString();
      notifyListeners();
    } finally {
      _setLoading(false);
    }
  }

  // ─────────────────────────────────────────
  // CHARGER MES ANNONCES
  // ─────────────────────────────────────────
  Future<void> loadMyServices(String userId) async {
    _setLoading(true);

    try {
      _myServices = await _serviceFirestore
          .getUserServices(userId);

      _errorMessage = null;
      notifyListeners();
    } catch (e) {
      _errorMessage = e.toString();
      notifyListeners();
    } finally {
      _setLoading(false);
    }
  }

  // ─────────────────────────────────────────
  // SUPPRIMER UNE ANNONCE
  // ─────────────────────────────────────────
  Future<bool> deleteService(String serviceId) async {
    _setLoading(true);

    try {
      await _serviceFirestore.deleteService(serviceId);

      // ✅ Mise à jour locale
      _services.removeWhere((s) => s.id == serviceId);
      _myServices.removeWhere((s) => s.id == serviceId);

      _errorMessage = null;
      notifyListeners();

      return true;
    } catch (e) {
      _errorMessage = e.toString();
      notifyListeners();

      return false;
    } finally {
      _setLoading(false);
    }
  }

  // ─────────────────────────────────────────
  // ACTIVER / DÉSACTIVER UNE ANNONCE
  // ─────────────────────────────────────────
  Future<void> toggleServiceActive(
    String serviceId,
    bool isActive,
  ) async {
    try {
      await _serviceFirestore.toggleServiceActive(
        serviceId,
        isActive,
      );

      // ✅ Mise à jour locale
      final index =
          _services.indexWhere((s) => s.id == serviceId);

      if (index != -1) {
        _services[index] = _services[index].copyWith(
          isActive: isActive,
        );
      }

      notifyListeners();
    } catch (e) {
      _errorMessage = e.toString();
      notifyListeners();
    }
  }

  // ─────────────────────────────────────────
  // RESET DES ERREURS
  // ─────────────────────────────────────────
  void clearError() {
    _errorMessage = null;
    notifyListeners();
  }

  // ─────────────────────────────────────────
  // ÉTAT DE CHARGEMENT
  // ─────────────────────────────────────────
  void _setLoading(bool value) {
    _isLoading = value;
    notifyListeners();
  }
}