import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

import '../../models/user_model.dart';
import '../../services/user_service.dart';
import '../../providers/auth_provider.dart' as app_auth;
import 'edit_profile_screen.dart';
import '../services/my_services_screen.dart';
import 'favorites_screen.dart';           // ← Import ajouté
import '../auth/login_screen.dart';

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

      // Création automatique si profil inexistant
      final firebaseUser = FirebaseAuth.instance.currentUser!;
      final newUser = UserModel(
        uid: uid,
        nom: firebaseUser.displayName ?? 'Utilisateur',
        email: firebaseUser.email ?? '',
        phone: '',
        photoUrl: firebaseUser.photoURL ?? '',
        createdAt: DateTime.now(),
      );

      await FirebaseFirestore.instance.collection('users').doc(uid).set({
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
            Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: Colors.grey[300],
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(height: 16),
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
            const SizedBox(height: 8),
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
            backgroundColor: primaryColor.withValues(alpha: 0.15),
            child: Icon(icon, color: primaryColor, size: 28),
          ),
          const SizedBox(height: 8),
          Text(
            label,
            style: const TextStyle(fontWeight: FontWeight.w500, fontSize: 13),
          ),
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
      if (url == null) {
        if (mounted) setState(() => _isUploadingPhoto = false);
        return;
      }

      await _loadProfile();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Photo de profil mise à jour ✅'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Erreur lors de l\'upload : $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isUploadingPhoto = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    if (_userModel == null) {
      return const Scaffold(body: Center(child: Text('Profil introuvable')));
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Mon Profil'),
        actions: [
          IconButton(
            icon: const Icon(Icons.logout, color: Colors.red),
            tooltip: 'Se déconnecter',
            onPressed: () async {
              await context.read<app_auth.AuthProvider>().signOut();
              if (!mounted) return;
              Navigator.pushAndRemoveUntil(
                context,
                MaterialPageRoute(builder: (_) => const LoginScreen()),
                (route) => false,
              );
            },
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          children: [
            // Photo de profil
            Stack(
              alignment: Alignment.bottomRight,
              children: [
                GestureDetector(
                  onTap: _isUploadingPhoto ? null : _showPhotoOptions,
                  child: Stack(
                    alignment: Alignment.center,
                    children: [
                      CircleAvatar(
                        radius: 55,
                        backgroundColor: primaryColor.withValues(alpha: 0.15),
                        backgroundImage: _userModel!.photoUrl.isNotEmpty
                            ? NetworkImage(_userModel!.photoUrl)
                            : null,
                        child: _userModel!.photoUrl.isEmpty
                            ? Text(
                                _userModel!.nom.isNotEmpty
                                    ? _userModel!.nom[0].toUpperCase()
                                    : '?',
                                style: const TextStyle(
                                  fontSize: 36,
                                  fontWeight: FontWeight.bold,
                                  color: primaryColor,
                                ),
                              )
                            : null,
                      ),
                      if (_isUploadingPhoto)
                        Container(
                          width: 110,
                          height: 110,
                          decoration: BoxDecoration(
                            color: Colors.black.withValues(alpha: 0.4),
                            shape: BoxShape.circle,
                          ),
                          child: const Center(
                            child: CircularProgressIndicator(color: Colors.white, strokeWidth: 3),
                          ),
                        ),
                    ],
                  ),
                ),
                if (!_isUploadingPhoto)
                  GestureDetector(
                    onTap: _showPhotoOptions,
                    child: Container(
                      padding: const EdgeInsets.all(6),
                      decoration: BoxDecoration(
                        color: primaryColor,
                        shape: BoxShape.circle,
                        border: Border.all(color: Colors.white, width: 2),
                      ),
                      child: const Icon(Icons.camera_alt, color: Colors.white, size: 16),
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 20),

            Text(
              _userModel!.nom,
              style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 4),
            Text(_userModel!.email, style: const TextStyle(color: Colors.grey)),

            if (_userModel!.ville.isNotEmpty) ...[
              const SizedBox(height: 4),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.location_on, size: 14, color: Colors.grey),
                  const SizedBox(width: 4),
                  Text(_userModel!.ville, style: const TextStyle(color: Colors.grey, fontSize: 13)),
                ],
              ),
            ],

            if (_userModel!.isPro) ...[
              const SizedBox(height: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                decoration: BoxDecoration(
                  color: primaryColor.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  _userModel!.categorie,
                  style: const TextStyle(color: primaryColor, fontWeight: FontWeight.bold, fontSize: 12),
                ),
              ),
            ],

            if (_userModel!.bio.isNotEmpty) ...[
              const SizedBox(height: 12),
              Text(
                _userModel!.bio,
                textAlign: TextAlign.center,
                style: const TextStyle(color: Colors.black87, fontSize: 14, height: 1.5),
              ),
            ],

            const SizedBox(height: 30),

            // Bouton Mes annonces
            SizedBox(
              width: double.infinity,
              height: 52,
              child: OutlinedButton.icon(
                onPressed: () => Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const MyServicesScreen()),
                ),
                icon: const Icon(Icons.list_alt, color: primaryColor),
                label: const Text('Mes annonces',
                    style: TextStyle(color: primaryColor, fontWeight: FontWeight.bold, fontSize: 16)),
                style: OutlinedButton.styleFrom(
                  side: const BorderSide(color: primaryColor),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
              ),
            ),

            const SizedBox(height: 12),

            // === Bouton Mes favoris (NOUVEAU) ===
            SizedBox(
              width: double.infinity,
              height: 52,
              child: OutlinedButton.icon(
                onPressed: () => Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const FavoritesScreen()),
                ),
                icon: const Icon(Icons.favorite_border, color: primaryColor),
                label: const Text('Mes favoris',
                    style: TextStyle(color: primaryColor, fontWeight: FontWeight.bold, fontSize: 16)),
                style: OutlinedButton.styleFrom(
                  side: const BorderSide(color: primaryColor),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
              ),
            ),

            const SizedBox(height: 12),

            // Bouton Modifier le profil
            SizedBox(
              width: double.infinity,
              height: 52,
              child: ElevatedButton.icon(
                onPressed: () async {
                  final updated = await Navigator.push<bool>(
                    context,
                    MaterialPageRoute(builder: (_) => EditProfileScreen(user: _userModel!)),
                  );
                  if (updated == true && mounted) {
                    await _loadProfile();
                  }
                },
                icon: const Icon(Icons.edit),
                label: const Text('Modifier le profil',
                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                style: ElevatedButton.styleFrom(
                  backgroundColor: primaryColor,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}