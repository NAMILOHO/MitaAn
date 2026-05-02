import 'dart:io';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:image_picker/image_picker.dart';
import '../models/user_model.dart';

class UserService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseStorage _storage = FirebaseStorage.instance;
  final ImagePicker _picker = ImagePicker();

  // ─────────────────────────────────────────
  // RÉCUPÉRER LE PROFIL UTILISATEUR
  // ─────────────────────────────────────────
  Future<UserModel?> getUserProfile(String uid) async {
    try {
      final doc = await _firestore.collection('users').doc(uid).get();
      if (doc.exists) {
        return UserModel.fromMap(doc.data()!, uid);
      }
      return null;
    } catch (e) {
      throw 'Erreur lors de la récupération du profil';
    }
  }

  // ─────────────────────────────────────────
  // CHOISIR UNE PHOTO (galerie ou caméra)
  // ─────────────────────────────────────────
  Future<File?> pickImage(ImageSource source) async {
    try {
      final XFile? picked = await _picker.pickImage(
        source: source,
        maxWidth: 500,
        maxHeight: 500,
        imageQuality: 70,
      );
      if (picked != null) {
        return File(picked.path);
      }
      return null;
    } catch (e) {
      throw 'Erreur lors de la sélection de la photo';
    }
  }

  // ─────────────────────────────────────────
  // UPLOADER LA PHOTO SUR FIREBASE STORAGE
  // ─────────────────────────────────────────
  Future<String> uploadProfilePhoto(String uid, File imageFile) async {
    try {
      // Chemin dans Storage : profiles/uid.jpg
      final ref = _storage.ref().child('profiles/$uid.jpg');

      // Upload du fichier
      await ref.putFile(
        imageFile,
        SettableMetadata(contentType: 'image/jpeg'),
      );

      // Récupérer l'URL publique
      final url = await ref.getDownloadURL();
      return url;
    } catch (e) {
      throw 'Erreur lors de l\'upload de la photo';
    }
  }

  // ─────────────────────────────────────────
  // METTRE À JOUR LE PROFIL DANS FIRESTORE
  // ─────────────────────────────────────────
  Future<void> updateProfile(String uid, Map<String, dynamic> data) async {
    try {
      await _firestore.collection('users').doc(uid).update(data);
    } catch (e) {
      throw 'Erreur lors de la mise à jour du profil';
    }
  }

  // ─────────────────────────────────────────
  // TOUT EN UN : choisir + uploader + mettre à jour
  // ─────────────────────────────────────────
  Future<String?> changeProfilePhoto(String uid, ImageSource source) async {
    final file = await pickImage(source);
    if (file == null) return null;

    final url = await uploadProfilePhoto(uid, file);
    await updateProfile(uid, {'photoUrl': url});
    return url;
  }
}