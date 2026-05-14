import 'dart:io';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import 'package:image_picker/image_picker.dart';

import '../models/service_model.dart';
import 'cloudinary_service.dart';

class ServiceFirestore {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final ImagePicker _picker = ImagePicker();

  // ─────────────────────────────────────────
  // CHOISIR PLUSIEURS PHOTOS
  // ─────────────────────────────────────────
  Future<List<File>> pickImages() async {
    try {
      final List<XFile> picked = await _picker.pickMultiImage(
        maxWidth: 600,
        maxHeight: 600,
        imageQuality: 65,
      );
      return picked.map((xfile) => File(xfile.path)).toList();
    } catch (e) {
      throw 'Erreur lors de la sélection des photos';
    }
  }

  // ─────────────────────────────────────────
  // UPLOAD EN PARALLÈLE des photos
  // ─────────────────────────────────────────
  Future<List<String>> uploadServicePhotos(
    String userId,
    List<File> images,
  ) async {
    debugPrint('📸 Upload de ${images.length} images en parallèle...');
    final cloudinary = CloudinaryService();
    final folder = 'mitan/services/$userId';

    final List<String?> results = await Future.wait(
      images.map((file) => cloudinary.uploadImage(file, folder: folder)),
    );

    final urls = results.whereType<String>().toList();
    debugPrint('✅ ${urls.length}/${images.length} images uploadées');
    return urls;
  }

  // ─────────────────────────────────────────
  // CRÉER UNE ANNONCE
  // ─────────────────────────────────────────
  Future<ServiceModel> createService({
    required String userId,
    required String titre,
    required String description,
    required String categorie,
    required double prix,
    required String unite,
    required List<String> photos,
    required double gpsLat,
    required double gpsLng,
    required String ville,
  }) async {
    final docRef = _firestore.collection('services').doc();
    final service = ServiceModel(
      id: docRef.id,
      userId: userId,
      titre: titre,
      description: description,
      categorie: categorie,
      prix: prix,
      unite: unite,
      photos: photos,
      gpsLat: gpsLat,
      gpsLng: gpsLng,
      ville: ville,
      isActive: true,
      createdAt: DateTime.now(),
    );

    await docRef.set({
      ...service.toMap(),
      'createdAt': FieldValue.serverTimestamp(),
    });
    return service;
  }

  // ─────────────────────────────────────────
  // METTRE À JOUR UNE ANNONCE
  // ─────────────────────────────────────────
  Future<void> updateService(
    String serviceId,
    Map<String, dynamic> data,
  ) async {
    await _firestore.collection('services').doc(serviceId).update({
      ...data,
      'updatedAt': FieldValue.serverTimestamp(),
    });
  }

  // ─────────────────────────────────────────
  // TOGGLE ACTIF / INACTIF
  // ─────────────────────────────────────────
  Future<void> toggleServiceActive(String serviceId, bool isActive) async {
    await _firestore.collection('services').doc(serviceId).update({
      'isActive': isActive,
      'updatedAt': FieldValue.serverTimestamp(),
    });
  }

  // ─────────────────────────────────────────
  // SUPPRIMER (désactivation)
  // ─────────────────────────────────────────
  Future<void> deleteService(String serviceId) async {
    await _firestore.collection('services').doc(serviceId).update({
      'isActive': false,
      'updatedAt': FieldValue.serverTimestamp(),
    });
  }

  // ─────────────────────────────────────────
  // RÉCUPÉRER TOUTES LES ANNONCES ACTIVES
  // ─────────────────────────────────────────
  Future<List<ServiceModel>> getAllServices({int limit = 20}) async {
    try {
      final snapshot = await _firestore
          .collection('services')
          .where('isActive', isEqualTo: true)
          .orderBy('createdAt', descending: true)
          .limit(limit)
          .get();
      return snapshot.docs
          .map((doc) => ServiceModel.fromMap(doc.data(), doc.id))
          .toList();
    } catch (e) {
      throw 'Erreur chargement annonces : $e';
    }
  }

  // ─────────────────────────────────────────
  // RÉCUPÉRER PAR CATÉGORIE
  // ─────────────────────────────────────────
  Future<List<ServiceModel>> getServicesByCategory(String categorie) async {
    try {
      final snapshot = await _firestore
          .collection('services')
          .where('isActive', isEqualTo: true)
          .where('categorie', isEqualTo: categorie)
          .orderBy('createdAt', descending: true)
          .limit(30)
          .get();
      return snapshot.docs
          .map((doc) => ServiceModel.fromMap(doc.data(), doc.id))
          .toList();
    } catch (e) {
      throw 'Erreur chargement annonces par catégorie : $e';
    }
  }

  // ─────────────────────────────────────────
  // RÉCUPÉRER LES ANNONCES D'UN UTILISATEUR
  // ─────────────────────────────────────────
  Future<List<ServiceModel>> getUserServices(String userId) async {
    try {
      final snapshot = await _firestore
          .collection('services')
          .where('userId', isEqualTo: userId)
          .orderBy('createdAt', descending: true)
          .limit(50)
          .get();
      return snapshot.docs
          .map((doc) => ServiceModel.fromMap(doc.data(), doc.id))
          .toList();
    } catch (e) {
      throw 'Erreur chargement mes annonces : $e';
    }
  }

  // =============================================
  // NOUVELLE MÉTHODE AJOUTÉE
  // =============================================
  Future<ServiceModel?> getServiceById(String serviceId) async {
    try {
      final doc = await _firestore.collection('services').doc(serviceId).get();
      if (!doc.exists) return null;
      return ServiceModel.fromMap(doc.data()!, doc.id);
    } catch (_) {
      return null;
    }
  }
}