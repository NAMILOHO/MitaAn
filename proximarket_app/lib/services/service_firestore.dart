import 'dart:io';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:image_picker/image_picker.dart';
import '../models/service_model.dart';

class ServiceFirestore {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseStorage _storage = FirebaseStorage.instance;
  final ImagePicker _picker = ImagePicker();

  // ─────────────────────────────────────────
  // CHOISIR PLUSIEURS PHOTOS
  // ─────────────────────────────────────────
  Future<List<File>> pickImages() async {
    final List<XFile> picked = await _picker.pickMultiImage(
      maxWidth: 800,
      maxHeight: 800,
      imageQuality: 75,
    );
    return picked.map((xfile) => File(xfile.path)).toList();
  }

  // ─────────────────────────────────────────
  // UPLOADER LES PHOTOS SUR FIREBASE STORAGE
  // ─────────────────────────────────────────
  Future<List<String>> uploadServicePhotos(
    String userId,
    List<File> images,
  ) async {
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

    return urls;
  }

  // ─────────────────────────────────────────
  // CRÉER UNE ANNONCE DANS FIRESTORE
  // ─────────────────────────────────────────
  Future<ServiceModel> createService({
    required String userId,
    required String titre,
    required String description,
    required String categorie,
    required double prix,
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
  }

  // ─────────────────────────────────────────
  // RÉCUPÉRER LES ANNONCES D'UN UTILISATEUR
  // ─────────────────────────────────────────
  Future<List<ServiceModel>> getUserServices(String userId) async {
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
  }
}