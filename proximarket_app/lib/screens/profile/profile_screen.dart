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
import 'favorites_screen.dart';
import '../auth/login_screen.dart';

// ─────────────────────────────────────────────────
// THÈME
// ─────────────────────────────────────────────────
class _T {
  static const primary      = Color(0xFF1D9E75);
  static const primaryLight = Color(0xFFE1F5EE);
  static const primaryDark  = Color(0xFF085041);
  static const bg           = Color(0xFFF8F9FA);
  static const textPrimary  = Color(0xFF0D1117);
  static const textSecondary= Color(0xFF6B7280);
  static const textTertiary = Color(0xFFB0B7C3);
  static const border       = Color(0xFFEEEEF2);
}

// ─────────────────────────────────────────────────
// ÉCRAN
// ─────────────────────────────────────────────────
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
  int _servicesCount = 0;
  int _favoritesCount = 0;

  @override
  void initState() {
    super.initState();
    _loadProfile();
  }

  Future<void> _loadProfile() async {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) { if (mounted) setState(() => _isLoading = false); return; }

    try {
      final user = await _userService.getUserProfile(uid);

      if (user != null) {
        // Compter les annonces actives
        final servicesSnap = await FirebaseFirestore.instance
            .collection('services')
            .where('userId', isEqualTo: uid)
            .where('isActive', isEqualTo: true)
            .get();

        final favs = await _userService.getFavorites(uid);

        if (mounted) {
          setState(() {
            _userModel = user;
            _servicesCount = servicesSnap.docs.length;
            _favoritesCount = favs.length;
            _isLoading = false;
          });
        }
        return;
      }

      // Créer le profil si inexistant
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
      if (mounted) setState(() { _userModel = newUser; _isLoading = false; });
    } catch (e) {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  void _showPhotoOptions() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (_) => Padding(
        padding: const EdgeInsets.fromLTRB(20, 12, 20, 32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 36, height: 4,
              decoration: BoxDecoration(color: _T.border, borderRadius: BorderRadius.circular(2)),
            ),
            const SizedBox(height: 16),
            const Text(
              'Changer la photo',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700, color: _T.textPrimary),
            ),
            const SizedBox(height: 20),
            Row(
              children: [
                Expanded(child: _photoOption(Icons.camera_alt_rounded, 'Caméra', ImageSource.camera)),
                const SizedBox(width: 12),
                Expanded(child: _photoOption(Icons.photo_library_rounded, 'Galerie', ImageSource.gallery)),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _photoOption(IconData icon, String label, ImageSource source) {
    return GestureDetector(
      onTap: () { Navigator.pop(context); _changePhoto(source); },
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 16),
        decoration: BoxDecoration(
          color: _T.bg,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: _T.border),
        ),
        child: Column(
          children: [
            Icon(icon, color: _T.primary, size: 26),
            const SizedBox(height: 8),
            Text(label, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w500, color: _T.textPrimary)),
          ],
        ),
      ),
    );
  }

  Future<void> _changePhoto(ImageSource source) async {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) return;
    setState(() => _isUploadingPhoto = true);
    try {
      final url = await _userService.changeProfilePhoto(uid, source);
      if (url == null) { if (mounted) setState(() => _isUploadingPhoto = false); return; }
      await _loadProfile();
      _snack('Photo de profil mise à jour', _T.primary);
    } catch (e) {
      _snack('Erreur : $e', Colors.red);
    } finally {
      if (mounted) setState(() => _isUploadingPhoto = false);
    }
  }

  void _snack(String msg, Color color) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(msg),
        backgroundColor: color,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
    );
  }

  // ─────────────────────────────────────────────────
  // BUILD
  // ─────────────────────────────────────────────────
  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Scaffold(
        backgroundColor: _T.bg,
        body: Center(child: CircularProgressIndicator(color: _T.primary, strokeWidth: 2)),
      );
    }
    if (_userModel == null) {
      return const Scaffold(
        backgroundColor: _T.bg,
        body: Center(child: Text('Profil introuvable')),
      );
    }

    return Scaffold(
      backgroundColor: _T.bg,
      body: RefreshIndicator(
        color: _T.primary,
        onRefresh: _loadProfile,
        child: CustomScrollView(
          slivers: [
            _buildHeader(),
            SliverToBoxAdapter(child: _buildBody()),
          ],
        ),
      ),
    );
  }

  // ── HEADER VERT ──
  Widget _buildHeader() {
    final nom      = _userModel!.nom;
    final email    = _userModel!.email;
    final photoUrl = _userModel!.photoUrl;
    final initial  = nom.isNotEmpty ? nom[0].toUpperCase() : 'U';

    return SliverAppBar(
      expandedHeight: 240,
      pinned: true,
      backgroundColor: _T.primary,
      surfaceTintColor: Colors.transparent,
      automaticallyImplyLeading: false,
      actions: [
        Padding(
          padding: const EdgeInsets.only(right: 12),
          child: GestureDetector(
            onTap: () async {
              await context.read<app_auth.AuthProvider>().signOut();
              if (!mounted) return;
              Navigator.pushAndRemoveUntil(
                context,
                MaterialPageRoute(builder: (_) => const LoginScreen()),
                (route) => false,
              );
            },
            child: Container(
              width: 36, height: 36,
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(10),
              ),
              child: const Icon(Icons.logout_rounded, color: Colors.white, size: 18),
            ),
          ),
        ),
      ],
      flexibleSpace: FlexibleSpaceBar(
        background: Container(
          color: _T.primary,
          child: SafeArea(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const SizedBox(height: 20),
                // Avatar
                GestureDetector(
                  onTap: _isUploadingPhoto ? null : _showPhotoOptions,
                  child: Stack(
                    children: [
                      Container(
                        width: 80,
                        height: 80,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: Colors.white,
                          border: Border.all(color: Colors.white.withValues(alpha: 0.4), width: 2.5),
                          image: photoUrl.isNotEmpty
                              ? DecorationImage(image: NetworkImage(photoUrl), fit: BoxFit.cover)
                              : null,
                        ),
                        child: photoUrl.isEmpty
                            ? Center(
                                child: Text(
                                  initial,
                                  style: const TextStyle(
                                    fontSize: 28,
                                    fontWeight: FontWeight.w700,
                                    color: _T.primary,
                                  ),
                                ),
                              )
                            : null,
                      ),
                      if (_isUploadingPhoto)
                        Positioned.fill(
                          child: Container(
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              color: Colors.black.withValues(alpha: 0.4),
                            ),
                            child: const Center(
                              child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
                            ),
                          ),
                        )
                      else
                        Positioned(
                          bottom: 0, right: 0,
                          child: Container(
                            width: 24, height: 24,
                            decoration: BoxDecoration(
                              color: Colors.white,
                              shape: BoxShape.circle,
                              border: Border.all(color: _T.primary, width: 1.5),
                            ),
                            child: const Icon(Icons.camera_alt_rounded, size: 13, color: _T.primary),
                          ),
                        ),
                    ],
                  ),
                ),
                const SizedBox(height: 12),
                Text(
                  nom,
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w700,
                    color: Colors.white,
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  email,
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.white.withValues(alpha: 0.75),
                  ),
                ),
                if (_userModel!.isPro && _userModel!.categorie.isNotEmpty) ...[
                  const SizedBox(height: 8),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 4),
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.18),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(
                      _userModel!.categorie,
                      style: const TextStyle(fontSize: 12, color: Colors.white),
                    ),
                  ),
                ],
                if (_userModel!.ville.isNotEmpty) ...[
                  const SizedBox(height: 6),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(Icons.location_on_rounded, size: 13, color: Colors.white70),
                      const SizedBox(width: 3),
                      Text(
                        _userModel!.ville.split(',').first,
                        style: const TextStyle(fontSize: 12, color: Colors.white70),
                      ),
                    ],
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }

  // ── BODY ──
  Widget _buildBody() {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          // Stats
          _buildStats(),
          const SizedBox(height: 14),

          // Bio
          if (_userModel!.bio.isNotEmpty) ...[
            _buildBioCard(),
            const SizedBox(height: 14),
          ],

          // Menu
          _buildMenu(),
          const SizedBox(height: 14),

          // Logout
          _buildLogoutBtn(),
          const SizedBox(height: 24),
        ],
      ),
    );
  }

  Widget _buildStats() {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: _T.border, width: 0.5),
      ),
      child: Row(
        children: [
          _statItem('$_servicesCount', 'Annonces'),
          _statDivider(),
          _statItem('$_favoritesCount', 'Favoris'),
          _statDivider(),
          _statItem('0', 'Messages'),
        ],
      ),
    );
  }

  Widget _statItem(String value, String label) {
    return Expanded(
      child: Column(
        children: [
          Text(
            value,
            style: const TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.w700,
              color: _T.primary,
            ),
          ),
          const SizedBox(height: 3),
          Text(
            label,
            style: const TextStyle(fontSize: 11, color: _T.textSecondary),
          ),
        ],
      ),
    );
  }

  Widget _statDivider() => Container(
    width: 0.5,
    height: 36,
    color: _T.border,
  );

  Widget _buildBioCard() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: _T.border, width: 0.5),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Bio',
            style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: _T.textPrimary),
          ),
          const SizedBox(height: 6),
          Text(
            _userModel!.bio,
            style: const TextStyle(fontSize: 13, color: _T.textSecondary, height: 1.5),
          ),
        ],
      ),
    );
  }

  Widget _buildMenu() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: _T.border, width: 0.5),
      ),
      child: Column(
        children: [
          _menuItem(
            icon: Icons.list_alt_rounded,
            iconBg: _T.primaryLight,
            iconColor: _T.primary,
            label: 'Mes annonces',
            onTap: () => Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const MyServicesScreen()),
            ),
          ),
          _menuDivider(),
          _menuItem(
            icon: Icons.favorite_border_rounded,
            iconBg: const Color(0xFFFBEAF0),
            iconColor: const Color(0xFF993556),
            label: 'Mes favoris',
            onTap: () => Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const FavoritesScreen()),
            ),
          ),
          _menuDivider(),
          _menuItem(
            icon: Icons.edit_outlined,
            iconBg: const Color(0xFFE6F1FB),
            iconColor: const Color(0xFF185FA5),
            label: 'Modifier le profil',
            last: true,
            onTap: () async {
              final updated = await Navigator.push<bool>(
                context,
                MaterialPageRoute(builder: (_) => EditProfileScreen(user: _userModel!)),
              );
              if (updated == true && mounted) await _loadProfile();
            },
          ),
        ],
      ),
    );
  }

  Widget _menuItem({
    required IconData icon,
    required Color iconBg,
    required Color iconColor,
    required String label,
    required VoidCallback onTap,
    bool last = false,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 13),
        child: Row(
          children: [
            Container(
              width: 36,
              height: 36,
              decoration: BoxDecoration(color: iconBg, borderRadius: BorderRadius.circular(10)),
              child: Icon(icon, color: iconColor, size: 18),
            ),
            const SizedBox(width: 12),
            Text(
              label,
              style: const TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w500,
                color: _T.textPrimary,
              ),
            ),
            const Spacer(),
            const Icon(Icons.chevron_right_rounded, size: 20, color: _T.textTertiary),
          ],
        ),
      ),
    );
  }

  Widget _menuDivider() => const Padding(
    padding: EdgeInsets.only(left: 62),
    child: Divider(height: 0.5, color: _T.border),
  );

  Widget _buildLogoutBtn() {
    return GestureDetector(
      onTap: () async {
        await context.read<app_auth.AuthProvider>().signOut();
        if (!mounted) return;
        Navigator.pushAndRemoveUntil(
          context,
          MaterialPageRoute(builder: (_) => const LoginScreen()),
          (route) => false,
        );
      },
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(vertical: 14),
        decoration: BoxDecoration(
          color: const Color(0xFFFCEBEB),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: const Color(0xFFF7C1C1), width: 0.5),
        ),
        child: const Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.logout_rounded, color: Color(0xFFA32D2D), size: 18),
            SizedBox(width: 8),
            Text(
              'Se déconnecter',
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: Color(0xFFA32D2D),
              ),
            ),
          ],
        ),
      ),
    );
  }
}