import 'dart:io';
import 'package:cloud_firestore/cloud_firestore.dart';
<<<<<<< HEAD
import 'package:firebase_storage/firebase_storage.dart';
import 'package:image_picker/image_picker.dart';
import '../models/service_model.dart';

class ServiceFirestore {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseStorage _storage = FirebaseStorage.instance;
=======
import 'package:flutter/foundation.dart';
import 'package:image_picker/image_picker.dart';

import '../models/service_model.dart';
import 'cloudinary_service.dart';

class ServiceFirestore {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
>>>>>>> develop
  final ImagePicker _picker = ImagePicker();

  // ─────────────────────────────────────────
  // CHOISIR PLUSIEURS PHOTOS
  // ─────────────────────────────────────────
  Future<List<File>> pickImages() async {
<<<<<<< HEAD
    final List<XFile> picked = await _picker.pickMultiImage(
      maxWidth: 800,
      maxHeight: 800,
      imageQuality: 75,
    );
    return picked.map((xfile) => File(xfile.path)).toList();
  }

  // ─────────────────────────────────────────
  // UPLOADER LES PHOTOS SUR FIREBASE STORAGE
=======
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
>>>>>>> develop
  // ─────────────────────────────────────────
  Future<List<String>> uploadServicePhotos(
    String userId,
    List<File> images,
  ) async {
<<<<<<< HEAD
    List<String> urls = [];

    for (int i = 0; i < images.length; i++) {
      final timestamp = DateTime.now().millisecondsSinceEpoch;
      // Chemin : services/userId_timestamp_index.jpg
      final ref = _storage
          .ref()
          .child('services/${userId}_${timestamp}_$i.jpg');

      await ref.putFile(
        images[i],
        SettableMetadata(contentType: 'image/jpeg'),
      );

      final url = await ref.getDownloadURL();
      urls.add(url);
    }

=======
    debugPrint('📸 Upload de ${images.length} images en parallèle...');
    final cloudinary = CloudinaryService();
    final folder = 'mitan/services/$userId';

    final List<String?> results = await Future.wait(
      images.map((file) => cloudinary.uploadImage(file, folder: folder)),
    );

    final urls = results.whereType<String>().toList();
    debugPrint('✅ ${urls.length}/${images.length} images uploadées');
>>>>>>> develop
    return urls;
  }

  // ─────────────────────────────────────────
<<<<<<< HEAD
  // CRÉER UNE ANNONCE DANS FIRESTORE
=======
  // CRÉER UNE ANNONCE
>>>>>>> develop
  // ─────────────────────────────────────────
  Future<ServiceModel> createService({
    required String userId,
    required String titre,
    required String description,
    required String categorie,
    required double prix,
<<<<<<< HEAD
=======
    required String unite,
>>>>>>> develop
    required List<String> photos,
    required double gpsLat,
    required double gpsLng,
    required String ville,
  }) async {
    final docRef = _firestore.collection('services').doc();
<<<<<<< HEAD

=======
>>>>>>> develop
    final service = ServiceModel(
      id: docRef.id,
      userId: userId,
      titre: titre,
      description: description,
      categorie: categorie,
      prix: prix,
<<<<<<< HEAD
=======
      unite: unite,
>>>>>>> develop
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
<<<<<<< HEAD

=======
>>>>>>> develop
    return service;
  }

  // ─────────────────────────────────────────
<<<<<<< HEAD
  // RÉCUPÉRER TOUTES LES ANNONCES ACTIVES
  // ─────────────────────────────────────────
  Future<List<ServiceModel>> getAllServices() async {
    final snapshot = await _firestore
        .collection('services')
        .where('isActive', isEqualTo: true)
        .orderBy('createdAt', descending: true)
        .get();

    return snapshot.docs
        .map((doc) => ServiceModel.fromMap(doc.data(), doc.id))
        .toList();
  }

  // ─────────────────────────────────────────
  // RÉCUPÉRER LES ANNONCES PAR CATÉGORIE
  // ─────────────────────────────────────────
  Future<List<ServiceModel>> getServicesByCategory(
      String categorie) async {
    final snapshot = await _firestore
        .collection('services')
        .where('isActive', isEqualTo: true)
        .where('categorie', isEqualTo: categorie)
        .orderBy('createdAt', descending: true)
        .get();

    return snapshot.docs
        .map((doc) => ServiceModel.fromMap(doc.data(), doc.id))
        .toList();
=======
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
>>>>>>> develop
  }

  // ─────────────────────────────────────────
  // RÉCUPÉRER LES ANNONCES D'UN UTILISATEUR
  // ─────────────────────────────────────────
  Future<List<ServiceModel>> getUserServices(String userId) async {
<<<<<<< HEAD
    final snapshot = await _firestore
        .collection('services')
        .where('userId', isEqualTo: userId)
        .orderBy('createdAt', descending: true)
        .get();

    return snapshot.docs
        .map((doc) => ServiceModel.fromMap(doc.data(), doc.id))
        .toList();
  }

  // ─────────────────────────────────────────
  // SUPPRIMER UNE ANNONCE
  // ─────────────────────────────────────────
  Future<void> deleteService(String serviceId) async {
    await _firestore.collection('services').doc(serviceId).update({
      'isActive': false,
    });
=======
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
>>>>>>> develop
  }
}