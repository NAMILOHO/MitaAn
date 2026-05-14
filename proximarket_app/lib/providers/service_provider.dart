import 'dart:io';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';   // ← Import ajouté

import '../models/service_model.dart';
import '../services/service_firestore.dart';

class ServiceProvider extends ChangeNotifier {
  final ServiceFirestore _serviceFirestore = ServiceFirestore();

  // ✅ Exposé publiquement pour que CreateServiceScreen accède à pickImages()
  ServiceFirestore get serviceFirestore => _serviceFirestore;

  List<ServiceModel> _services = [];
  List<ServiceModel> _myServices = [];
  bool _isLoading = false;
  String? _errorMessage;

  // === NOUVELLES VARIABLES POUR LA PAGINATION ===
  DocumentSnapshot? _lastDocument;
  bool _hasMore = true;
  bool _isLoadingMore = false;

  List<ServiceModel> get services => _services;
  List<ServiceModel> get myServices => _myServices;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;

  // Getters pagination
  bool get hasMore => _hasMore;
  bool get isLoadingMore => _isLoadingMore;

  // ─────────────────────────────────────────
  // CRÉER UNE ANNONCE
  // ─────────────────────────────────────────
  Future<bool> createService({
    required String userId,
    required String titre,
    required String description,
    required String categorie,
    required double prix,
    required String unite,
    required List<File> imageFiles,
    required double gpsLat,
    required double gpsLng,
    required String ville,
  }) async {
    _setLoading(true);
    try {
      List<String> photoUrls = [];
      if (imageFiles.isNotEmpty) {
        photoUrls = await _serviceFirestore.uploadServicePhotos(
          userId,
          imageFiles,
        );
      }

      final service = await _serviceFirestore.createService(
        userId: userId,
        titre: titre,
        description: description,
        categorie: categorie,
        prix: prix,
        unite: unite,
        photos: photoUrls,
        gpsLat: gpsLat,
        gpsLng: gpsLng,
        ville: ville,
      );

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
  // CHARGER TOUTES LES ANNONCES (Paginée)
  // ─────────────────────────────────────────
  Future<void> loadAllServices({bool reset = false}) async {
    if (reset) {
      _services = [];
      _lastDocument = null;
      _hasMore = true;
    }

    if (!_hasMore) return;
    if (_isLoadingMore) return;

    if (_services.isEmpty) {
      _setLoading(true);
    } else {
      _isLoadingMore = true;
      notifyListeners();
    }

    try {
      final result = await _serviceFirestore.getAllServicesPaginated(
        limit: 10,
        startAfter: _lastDocument,
      );

      _services.addAll(result.services);
      _lastDocument = result.lastDoc;
      _hasMore = result.services.length == 10;
      _errorMessage = null;
      notifyListeners();
    } catch (e) {
      _errorMessage = e.toString();
      notifyListeners();
    } finally {
      _setLoading(false);
      _isLoadingMore = false;
      notifyListeners();
    }
  }

  // Méthode pour charger la page suivante
  Future<void> loadMoreServices() async {
    await loadAllServices();
  }

  // ─────────────────────────────────────────
  // CHARGER PAR CATÉGORIE
  // ─────────────────────────────────────────
  Future<void> loadServicesByCategory(String categorie) async {
    _setLoading(true);
    try {
      _services = await _serviceFirestore.getServicesByCategory(categorie);
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
      _myServices = await _serviceFirestore.getUserServices(userId);
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
  // AUTRES MÉTHODES (update, toggle, delete...)
  // ─────────────────────────────────────────
  Future<bool> updateService({
    required String serviceId,
    required String titre,
    required String description,
    required String categorie,
    required double prix,
    required String unite,
    required List<String> existingPhotos,
    required List<File> newImageFiles,
    required String userId,
  }) async {
    _setLoading(true);
    try {
      List<String> newUrls = [];
      if (newImageFiles.isNotEmpty) {
        newUrls = await _serviceFirestore.uploadServicePhotos(
          userId,
          newImageFiles,
        );
      }

      final allPhotos = [...existingPhotos, ...newUrls];

      await _serviceFirestore.updateService(serviceId, {
        'titre': titre,
        'description': description,
        'categorie': categorie,
        'prix': prix,
        'unite': unite,
        'photos': allPhotos,
      });

      _updateLocalService(serviceId, {
        'titre': titre,
        'description': description,
        'categorie': categorie,
        'prix': prix,
        'unite': unite,
        'photos': allPhotos,
      });

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

  Future<bool> toggleServiceActive(String serviceId, bool isActive) async {
    try {
      await _serviceFirestore.toggleServiceActive(serviceId, isActive);
      _updateLocalServiceBool(serviceId, 'isActive', isActive);
      notifyListeners();
      return true;
    } catch (e) {
      _errorMessage = e.toString();
      notifyListeners();
      return false;
    }
  }

  Future<bool> deleteService(String serviceId) async {
    _setLoading(true);
    try {
      await _serviceFirestore.deleteService(serviceId);
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
  // HELPERS PRIVÉS
  // ─────────────────────────────────────────
  void _updateLocalService(String serviceId, Map<String, dynamic> data) {
    for (final list in [_services, _myServices]) {
      final idx = list.indexWhere((s) => s.id == serviceId);
      if (idx != -1) {
        final s = list[idx];
        list[idx] = s.copyWith(
          titre: data['titre'],
          description: data['description'],
          categorie: data['categorie'],
          prix: (data['prix'] as num?)?.toDouble(),
          unite: data['unite'],
          photos: data['photos'] != null ? List<String>.from(data['photos']) : null,
        );
      }
    }
  }

  void _updateLocalServiceBool(String serviceId, String field, bool value) {
    for (final list in [_services, _myServices]) {
      final idx = list.indexWhere((s) => s.id == serviceId);
      if (idx != -1 && field == 'isActive') {
        list[idx] = list[idx].copyWith(isActive: value);
      }
    }
  }

  void _setLoading(bool value) {
    _isLoading = value;
    notifyListeners();
  }
}