import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

import '../../models/user_model.dart';
import '../../services/user_service.dart';
import '../../providers/auth_provider.dart' as app_auth;

import 'edit_profile_screen.dart';
import '../services/my_services_screen.dart';   // ← Import ajouté

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  final UserService _userService = UserService();

  UserModel? _userModel;
  bool _isLoading = true;
  bool _isUploadingPhoto = false;

  static const Color primaryColor = Color(0xFF1D9E75);

  @override
  void initState() {
    super.initState();
    _loadProfile();
  }

  Future<void> _loadProfile() async {
    final uid = FirebaseAuth.instance.currentUser?.uid;

    if (uid == null) {
      if (mounted) setState(() => _isLoading = false);
      return;
    }

    try {
      // 🔹 Tentative 1 : Firestore
      final user = await _userService.getUserProfile(uid);

      if (user != null) {
        if (mounted) {
          setState(() {
            _userModel = user;
            _isLoading = false;
          });
        }
        return;
      }

      // 🔹 Tentative 2 : création automatique si inexistant
      final firebaseUser = FirebaseAuth.instance.currentUser!;

      final newUser = UserModel(
        uid: uid,
        nom: firebaseUser.displayName ?? 'Utilisateur',
        email: firebaseUser.email ?? '',
        phone: '',
        photoUrl: firebaseUser.photoURL ?? '',
        createdAt: DateTime.now(),
      );

      await FirebaseFirestore.instance
          .collection('users')
          .doc(uid)
          .set({
        ...newUser.toMap(),
        'createdAt': FieldValue.serverTimestamp(),
      });

      if (mounted) {
        setState(() {
          _userModel = newUser;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Erreur chargement profil : $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  void _showPhotoOptions() {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text(
              'Changer la photo de profil',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 20),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                _photoOption(Icons.camera_alt, "Caméra", ImageSource.camera),
                _photoOption(Icons.photo_library, "Galerie", ImageSource.gallery),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _photoOption(IconData icon, String label, ImageSource source) {
    return GestureDetector(
      onTap: () {
        Navigator.pop(context);
        _changePhoto(source);
      },
      child: Column(
        children: [
          CircleAvatar(
            radius: 30,
            backgroundColor: primaryColor.withOpacity(0.2),
            child: Icon(icon, color: primaryColor),
          ),
          const SizedBox(height: 8),
          Text(label),
        ],
      ),
    );
  }

  Future<void> _changePhoto(ImageSource source) async {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) return;

    setState(() => _isUploadingPhoto = true);

    try {
      final url = await _userService.changeProfilePhoto(uid, source);

      if (url != null) {
        await _loadProfile();

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text("Photo mise à jour ✅"),
              backgroundColor: Colors.green,
            ),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(e.toString()),
            backgroundColor: Colors.red,
          ),
        );
      }
    }

    setState(() => _isUploadingPhoto = false);
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    if (_userModel == null) {
      return const Scaffold(
        body: Center(child: Text("Profil introuvable")),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text("Mon Profil"),
        actions: [
          IconButton(
            icon: const Icon(Icons.logout, color: Colors.red),
            onPressed: () async {
              await context.read<app_auth.AuthProvider>().signOut();
            },
          )
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          children: [
            Stack(
              alignment: Alignment.bottomRight,
              children: [
                GestureDetector(
                  onTap: _showPhotoOptions,
                  child: CircleAvatar(
                    radius: 55,
                    backgroundImage: _userModel!.photoUrl.isNotEmpty
                        ? NetworkImage(_userModel!.photoUrl)
                        : null,
                    child: _userModel!.photoUrl.isEmpty
                        ? Text(
                            _userModel!.nom.isNotEmpty
                                ? _userModel!.nom[0].toUpperCase()
                                : "?",
                            style: const TextStyle(
                              fontSize: 30,
                              color: primaryColor,
                            ),
                          )
                        : null,
                  ),
                ),
                if (_isUploadingPhoto)
                  const Positioned(
                    child: CircularProgressIndicator(),
                  )
              ],
            ),

            const SizedBox(height: 20),

            Text(
              _userModel!.nom,
              style: const TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.bold,
              ),
            ),

            const SizedBox(height: 8),

            Text(_userModel!.email),

            const SizedBox(height: 30),

            // ── Bouton Mes Annonces ──
            SizedBox(
              width: double.infinity,
              height: 52,
              child: OutlinedButton.icon(
                onPressed: () => Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => const MyServicesScreen(),
                  ),
                ),
                icon: const Icon(Icons.list_alt, color: primaryColor),
                label: const Text(
                  'Mes annonces',
                  style: TextStyle(
                    color: primaryColor,
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                  ),
                ),
                style: OutlinedButton.styleFrom(
                  side: const BorderSide(color: primaryColor),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 12),

            // Bouton Modifier le profil
            ElevatedButton.icon(
              onPressed: () async {
                final updated = await Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => EditProfileScreen(user: _userModel!),
                  ),
                );

                if (updated == true) {
                  _loadProfile();
                }
              },
              icon: const Icon(Icons.edit),
              label: const Text("Modifier le profil"),
            ),
          ],
        ),
      ),
    );
  }
}