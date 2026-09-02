import 'dart:io';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';

import '../models/service_model.dart';
import '../utils/image_compressor.dart';
import 'cloudinary_service.dart';

class ServiceFirestore {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // ─────────────────────────────────────────
  // CHOISIR PLUSIEURS PHOTOS
  // ─────────────────────────────────────────
  Future<List<File>> pickImages() async {
    try {
      final files = await ImageCompressor.pickMultipleCompressed(
        maxWidth: 800,
        maxHeight: 800,
        quality: 70,
      );
      final errors = ImageCompressor.validateAll(files);
      if (errors.isNotEmpty) {
        throw errors.first;
      }
      return files;
    } catch (e) {
      throw 'Erreur lors de la sélection des photos : $e';
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
    required int quantity,
    required List<String> photos,
    required double gpsLat,
    required double gpsLng,
    required String ville,
    String typeAnnonce = 'autre',
    Map<String, String> attributs = const {},
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
      quantity: quantity,
      photos: photos,
      gpsLat: gpsLat,
      gpsLng: gpsLng,
      ville: ville,
      isActive: true,
      createdAt: DateTime.now(),
      typeAnnonce: typeAnnonce,
      attributs: attributs,
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

  Future<void> archiveService(String serviceId) async {
    await _firestore.collection('services').doc(serviceId).update({
      'isArchived': true,
      'isActive': false,
      'updatedAt': FieldValue.serverTimestamp(),
    });
  }

  Future<void> restoreService(String serviceId) async {
    await _firestore.collection('services').doc(serviceId).update({
      'isArchived': false,
      'isActive': true,
      'updatedAt': FieldValue.serverTimestamp(),
    });
  }

  Future<List<ServiceModel>> getArchivedServices(String userId) async {
    final snap = await _firestore
        .collection('services')
        .where('userId', isEqualTo: userId)
        .where('isArchived', isEqualTo: true)
        .orderBy('updatedAt', descending: true)
        .get();

    return snap.docs
        .map((doc) => ServiceModel.fromMap(doc.data(), doc.id))
        .toList();
  }

  Future<void> decrementStock(String serviceId) async {
    await _firestore.collection('services').doc(serviceId).update({
      'quantity': FieldValue.increment(-1),
    });

    final doc = await _firestore.collection('services').doc(serviceId).get();
    final qty = (doc.data()?['quantity'] ?? 1) as int;
    if (qty <= 0) {
      await _firestore.collection('services').doc(serviceId).update({
        'isActive': false,
        'updatedAt': FieldValue.serverTimestamp(),
      });
    }
  }

  // =============================================
  // VERSION PAGINÉE - getAllServices
  // =============================================
  Future<List<ServiceModel>> getAllServices({
    int limit = 10,
    DocumentSnapshot? startAfter,
  }) async {
    try {
      Query query = _firestore
          .collection('services')
          .where('isActive', isEqualTo: true)
          .orderBy('createdAt', descending: true)
          .limit(limit);

      if (startAfter != null) {
        query = query.startAfterDocument(startAfter);
      }

      final snapshot = await query.get();
      return snapshot.docs
          .map((doc) => ServiceModel.fromMap(
                doc.data() as Map<String, dynamic>,
                doc.id,
              ))
          .toList();
    } catch (e) {
      throw 'Erreur chargement annonces : $e';
    }
  }

  // =============================================
  // PAGINATION AVANCÉE (recommandée)
  // =============================================
  Future<({List<ServiceModel> services, DocumentSnapshot? lastDoc})>
      getAllServicesPaginated({
    int limit = 10,
    DocumentSnapshot? startAfter,
  }) async {
    try {
      Query query = _firestore
          .collection('services')
          .where('isActive', isEqualTo: true)
          .orderBy('createdAt', descending: true)
          .limit(limit);

      if (startAfter != null) {
        query = query.startAfterDocument(startAfter);
      }

      final snapshot = await query.get();

      final services = snapshot.docs
          .map((doc) => ServiceModel.fromMap(
                doc.data() as Map<String, dynamic>,
                doc.id,
              ))
          .toList();

      final lastDoc = snapshot.docs.isNotEmpty ? snapshot.docs.last : null;

      return (services: services, lastDoc: lastDoc);
    } catch (e) {
      throw 'Erreur pagination annonces : $e';
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
  // RÉCUPÉRER UNE ANNONCE PAR ID
  // =============================================
  Future<ServiceModel?> getServiceById(String serviceId) async {
    try {
      final doc = await _firestore
          .collection('services')
          .doc(serviceId)
          .get();
      if (!doc.exists) return null;
      return ServiceModel.fromMap(doc.data()!, doc.id);
    } catch (_) {
      return null;
    }
  }
}
