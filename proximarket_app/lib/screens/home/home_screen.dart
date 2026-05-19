import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:provider/provider.dart';

import '../services/services_list_screen.dart';
import '../services/create_service_screen.dart';
import '../profile/profile_screen.dart';
import '../chat/chat_list_screen.dart';
import '../services/service_detail_screen.dart';
import '../map/map_screen.dart';

import '../../services/location_service.dart';
import '../../services/user_service.dart';
import '../../models/user_model.dart';
import '../../providers/service_provider.dart';

// ─────────────────────────────────────────────────
// COULEURS & THÈME
// ─────────────────────────────────────────────────
class _T {
  static const primary = Color(0xFF1D9E75);
  static const primaryLight = Color(0xFFE1F5EE);
  static const primaryDark = Color(0xFF085041);
  static const bg = Color(0xFFF8F9FA);
  static const card = Colors.white;
  static const textPrimary = Color(0xFF0D1117);
  static const textSecondary = Color(0xFF6B7280);
  static const textTertiary = Color(0xFFB0B7C3);
  static const border = Color(0xFFEEEFF2);
}

// ─────────────────────────────────────────────────
// ÉCRAN PRINCIPAL
// ─────────────────────────────────────────────────
class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  HomeScreenState createState() => HomeScreenState();
}

class HomeScreenState extends State<HomeScreen> {
  int _currentIndex = 0;

  void changeTab(int index) => setState(() => _currentIndex = index);

  late final List<Widget> _screens;

  @override
  void initState() {
    super.initState();
    _screens = [
      const _HomeTab(),
      const MapScreen(),
      const ServicesListScreen(),
      const CreateServiceScreen(),
      const ChatListScreen(),
      const ProfileScreen(),
    ];
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _T.bg,
      body: IndexedStack(index: _currentIndex, children: _screens),
      bottomNavigationBar: _BottomNav(
        currentIndex: _currentIndex,
        onTap: (i) => setState(() => _currentIndex = i),
      ),
    );
  }
}

// ─────────────────────────────────────────────────
// BOTTOM NAV CUSTOM
// ─────────────────────────────────────────────────
class _BottomNav extends StatelessWidget {
  final int currentIndex;
  final ValueChanged<int> onTap;

  const _BottomNav({required this.currentIndex, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 72,
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border(top: BorderSide(color: _T.border, width: 0.5)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 20,
            offset: const Offset(0, -4),
          ),
        ],
      ),
      child: SafeArea(
        top: false,
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceAround,
          children: [
            _NavItem(icon: Icons.home_rounded, label: 'Accueil', index: 0, current: currentIndex, onTap: onTap),
            _NavItem(icon: Icons.map_rounded, label: 'Carte', index: 1, current: currentIndex, onTap: onTap),
            _NavItem(icon: Icons.search_rounded, label: 'Rechercher', index: 2, current: currentIndex, onTap: onTap),
            // Bouton Publier centré
            GestureDetector(
              onTap: () => onTap(3),
              child: Container(
                width: 52,
                height: 52,
                decoration: BoxDecoration(
                  color: _T.primary,
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(
                      color: _T.primary.withValues(alpha: 0.35),
                      blurRadius: 12,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: const Icon(Icons.add_rounded, color: Colors.white, size: 26),
              ),
            ),
            _NavItem(icon: Icons.chat_bubble_outline_rounded, label: 'Messages', index: 4, current: currentIndex, onTap: onTap),
            _NavItem(icon: Icons.person_outline_rounded, label: 'Profil', index: 5, current: currentIndex, onTap: onTap),
          ],
        ),
      ),
    );
  }
}

class _NavItem extends StatelessWidget {
  final IconData icon;
  final String label;
  final int index;
  final int current;
  final ValueChanged<int> onTap;

  const _NavItem({
    required this.icon,
    required this.label,
    required this.index,
    required this.current,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final active = index == current;
    return GestureDetector(
      onTap: () => onTap(index),
      behavior: HitTestBehavior.opaque,
      child: SizedBox(
        width: 52,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              icon,
              size: 22,
              color: active ? _T.primary : _T.textTertiary,
            ),
            const SizedBox(height: 3),
            if (active)
              Container(
                width: 4,
                height: 4,
                decoration: const BoxDecoration(
                  color: _T.primary,
                  shape: BoxShape.circle,
                ),
              )
            else
              Text(
                label,
                style: const TextStyle(
                  fontSize: 9,
                  color: _T.textTertiary,
                ),
              ),
          ],
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────
// ONGLET ACCUEIL
// ─────────────────────────────────────────────────
class _HomeTab extends StatefulWidget {
  const _HomeTab();

  @override
  State<_HomeTab> createState() => _HomeTabState();
}

class _HomeTabState extends State<_HomeTab> {
  final LocationService _locationService = LocationService();
  final UserService _userService = UserService();
  final TextEditingController _searchController = TextEditingController();

  UserModel? _userModel;
  bool _isLoadingLocation = false;
  String _ville = '';

  static const List<_CategoryItem> _categories = [
    _CategoryItem(Icons.handyman_rounded, 'Artisan', Color(0xFFE1F5EE), Color(0xFF1D9E75)),
    _CategoryItem(Icons.palette_rounded, 'Artiste', Color(0xFFEAF3DE), Color(0xFF639922)),
    _CategoryItem(Icons.agriculture_rounded, 'Éleveur', Color(0xFFFAEEDA), Color(0xFFBA7517)),
    _CategoryItem(Icons.storefront_rounded, 'Commerce', Color(0xFFE6F1FB), Color(0xFF185FA5)),
    _CategoryItem(Icons.electrical_services_rounded, 'Électricien', Color(0xFFFBEAF0), Color(0xFF993556)),
  ];

  @override
  void initState() {
    super.initState();
    _loadUser();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<ServiceProvider>().loadAllServices(reset: true);
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _loadUser() async {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) return;
    final user = await _userService.getUserProfile(uid);
    if (!mounted) return;
    setState(() {
      _userModel = user;
      _ville = user?.ville ?? '';
    });
  }

  Future<void> _updateLocation() async {
    setState(() => _isLoadingLocation = true);
    try {
      final uid = FirebaseAuth.instance.currentUser!.uid;
      await _locationService.saveUserLocation(uid);
      final updated = await _userService.getUserProfile(uid);
      if (!mounted) return;
      setState(() {
        _userModel = updated;
        _ville = updated?.ville ?? '';
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('Position mise à jour'),
          backgroundColor: _T.primary,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        ),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(e.toString()),
          backgroundColor: Colors.red,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        ),
      );
    } finally {
      if (mounted) setState(() => _isLoadingLocation = false);
    }
  }

  String get _firstName {
    final nom = _userModel?.nom ?? '';
    return nom.isNotEmpty ? nom.split(' ').first : 'là';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _T.bg,
      body: CustomScrollView(
        slivers: [
          _buildAppBar(),
          SliverToBoxAdapter(child: _buildSearchBar()),
          SliverToBoxAdapter(child: _buildGpsCard()),
          SliverToBoxAdapter(child: _buildCategories()),
          SliverToBoxAdapter(child: _buildNearbyHeader()),
          _buildServicesList(),
          const SliverToBoxAdapter(child: SizedBox(height: 24)),
        ],
      ),
    );
  }

  // ── APP BAR ──
  Widget _buildAppBar() {
    return SliverAppBar(
      backgroundColor: Colors.white,
      elevation: 0,
      pinned: true,
      expandedHeight: 100,
      automaticallyImplyLeading: false,
      surfaceTintColor: Colors.transparent,
      bottom: PreferredSize(
        preferredSize: const Size.fromHeight(0),
        child: Container(height: 0.5, color: _T.border),
      ),
      flexibleSpace: FlexibleSpaceBar(
        background: SafeArea(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(20, 12, 20, 0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    // Localisation
                    Expanded(
                      child: GestureDetector(
                        onTap: _updateLocation,
                        child: Row(
                          children: [
                            Container(
                              width: 28,
                              height: 28,
                              decoration: BoxDecoration(
                                color: _T.primaryLight,
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: const Icon(
                                Icons.location_on_rounded,
                                size: 16,
                                color: _T.primary,
                              ),
                            ),
                            const SizedBox(width: 8),
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Text(
                                  'Localisation',
                                  style: TextStyle(
                                    fontSize: 10,
                                    color: _T.textTertiary,
                                  ),
                                ),
                                Row(
                                  children: [
                                    Text(
                                      _ville.isNotEmpty
                                          ? (_ville.length > 20 ? '${_ville.substring(0, 20)}…' : _ville)
                                          : 'Définir ma position',
                                      style: const TextStyle(
                                        fontSize: 13,
                                        fontWeight: FontWeight.w600,
                                        color: _T.textPrimary,
                                      ),
                                    ),
                                    const SizedBox(width: 2),
                                    const Icon(
                                      Icons.keyboard_arrow_down_rounded,
                                      size: 16,
                                      color: _T.textSecondary,
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ),
                    // Cloche + Avatar
                    Row(
                      children: [
                        Container(
                          width: 38,
                          height: 38,
                          decoration: BoxDecoration(
                            color: _T.bg,
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(color: _T.border),
                          ),
                          child: const Icon(
                            Icons.notifications_none_rounded,
                            size: 20,
                            color: _T.textSecondary,
                          ),
                        ),
                        const SizedBox(width: 10),
                        _buildAvatar(),
                      ],
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Text(
                  'Bonjour, $_firstName 👋',
                  style: const TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.w700,
                    color: _T.textPrimary,
                    letterSpacing: -0.3,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildAvatar() {
    final initial = _userModel?.nom.isNotEmpty == true
        ? _userModel!.nom[0].toUpperCase()
        : 'U';
    final photoUrl = _userModel?.photoUrl ?? '';

    return Container(
      width: 38,
      height: 38,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: _T.primaryLight,
        border: Border.all(color: _T.border),
        image: photoUrl.isNotEmpty
            ? DecorationImage(image: NetworkImage(photoUrl), fit: BoxFit.cover)
            : null,
      ),
      child: photoUrl.isEmpty
          ? Center(
              child: Text(
                initial,
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: _T.primaryDark,
                ),
              ),
            )
          : null,
    );
  }

  // ── SEARCH BAR ──
  Widget _buildSearchBar() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
      child: GestureDetector(
        onTap: () {
          final homeState = context.findAncestorStateOfType<HomeScreenState>();
          homeState?.changeTab(2);
        },
        child: Container(
          height: 48,
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: _T.border),
          ),
          child: Row(
            children: [
              const SizedBox(width: 14),
              const Icon(Icons.search_rounded, color: _T.textTertiary, size: 20),
              const SizedBox(width: 10),
              const Expanded(
                child: Text(
                  'Rechercher un service, une ville...',
                  style: TextStyle(
                    fontSize: 13,
                    color: _T.textTertiary,
                  ),
                ),
              ),
              Container(
                margin: const EdgeInsets.all(6),
                width: 36,
                height: 36,
                decoration: BoxDecoration(
                  color: _T.primary,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Icon(Icons.tune_rounded, color: Colors.white, size: 18),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ── GPS CARD ──
  Widget _buildGpsCard() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 14, 20, 0),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        decoration: BoxDecoration(
          color: _T.primaryLight,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: const Color(0xFF9FE1CB), width: 0.5),
        ),
        child: Row(
          children: [
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: _T.primary,
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Icon(Icons.my_location_rounded, color: Colors.white, size: 20),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    _ville.isNotEmpty ? _ville : 'Position non définie',
                    style: const TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: _T.primaryDark,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const Text(
                    'Votre position actuelle',
                    style: TextStyle(fontSize: 11, color: Color(0xFF0F6E56)),
                  ),
                ],
              ),
            ),
            Row(
              children: [
                GestureDetector(
                  onTap: () {
                    final homeState = context.findAncestorStateOfType<HomeScreenState>();
                    homeState?.changeTab(1);
                  },
                  child: const Text(
                    'Carte',
                    style: TextStyle(
                      fontSize: 12,
                      color: _T.primary,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                GestureDetector(
                  onTap: _isLoadingLocation ? null : _updateLocation,
                  child: _isLoadingLocation
                      ? const SizedBox(
                          width: 16,
                          height: 16,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: _T.primary,
                          ),
                        )
                      : const Icon(Icons.refresh_rounded, color: _T.primary, size: 20),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  // ── CATÉGORIES ──
  Widget _buildCategories() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(20, 22, 20, 12),
          child: Row(
            children: [
              const Text(
                'Catégories',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                  color: _T.textPrimary,
                  letterSpacing: -0.2,
                ),
              ),
              const Spacer(),
              GestureDetector(
                onTap: () {
                  final homeState = context.findAncestorStateOfType<HomeScreenState>();
                  homeState?.changeTab(2);
                },
                child: const Text(
                  'Voir tout',
                  style: TextStyle(
                    fontSize: 12,
                    color: _T.primary,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
            ],
          ),
        ),
        SizedBox(
          height: 88,
          child: ListView.builder(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 20),
            itemCount: _categories.length,
            itemBuilder: (context, i) {
              final cat = _categories[i];
              return GestureDetector(
                onTap: () async {
                  await context.read<ServiceProvider>().loadServicesByCategory(cat.label);
                  if (!mounted) return;
                  final homeState = context.findAncestorStateOfType<HomeScreenState>();
                  homeState?.changeTab(2);
                },
                child: Container(
                  margin: const EdgeInsets.only(right: 12),
                  child: Column(
                    children: [
                      Container(
                        width: 56,
                        height: 56,
                        decoration: BoxDecoration(
                          color: cat.bg,
                          borderRadius: BorderRadius.circular(16),
                        ),
                        child: Icon(cat.icon, color: cat.color, size: 26),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        cat.label,
                        style: const TextStyle(
                          fontSize: 10,
                          color: _T.textSecondary,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
        ),
      ],
    );
  }

  // ── HEADER NEARBY ──
  Widget _buildNearbyHeader() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 22, 20, 12),
      child: Row(
        children: [
          const Text(
            'Près de vous',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w700,
              color: _T.textPrimary,
              letterSpacing: -0.2,
            ),
          ),
          const Spacer(),
          GestureDetector(
            onTap: () {
              final homeState = context.findAncestorStateOfType<HomeScreenState>();
              homeState?.changeTab(2);
            },
            child: const Text(
              'Voir tout',
              style: TextStyle(
                fontSize: 12,
                color: _T.primary,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ── LISTE SERVICES ──
  Widget _buildServicesList() {
    return Consumer<ServiceProvider>(
      builder: (context, provider, _) {
        if (provider.isLoading) {
          return const SliverToBoxAdapter(
            child: Center(
              child: Padding(
                padding: EdgeInsets.all(40),
                child: CircularProgressIndicator(color: _T.primary, strokeWidth: 2),
              ),
            ),
          );
        }

        if (provider.services.isEmpty) {
          return SliverToBoxAdapter(child: _buildEmptyState());
        }

        final items = provider.services.take(4).toList();

        return SliverPadding(
          padding: const EdgeInsets.symmetric(horizontal: 20),
          sliver: SliverList(
            delegate: SliverChildBuilderDelegate(
              (context, i) => _ServiceCard(
                service: items[i],
                onTap: () => Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => ServiceDetailScreen(service: items[i]),
                  ),
                ),
              ),
              childCount: items.length,
            ),
          ),
        );
      },
    );
  }

  Widget _buildEmptyState() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 20),
      padding: const EdgeInsets.all(32),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: _T.border),
      ),
      child: const Column(
        children: [
          Icon(Icons.search_off_rounded, size: 48, color: _T.textTertiary),
          SizedBox(height: 12),
          Text(
            'Aucune annonce disponible',
            style: TextStyle(
              color: _T.textSecondary,
              fontSize: 14,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────
// CARD SERVICE
// ─────────────────────────────────────────────────
class _ServiceCard extends StatelessWidget {
  final dynamic service;
  final VoidCallback onTap;

  const _ServiceCard({required this.service, required this.onTap});

  static const _catColors = <String, Color>{
    'Artisan': Color(0xFF1D9E75),
    'Artiste': Color(0xFF639922),
    'Éleveur': Color(0xFFBA7517),
    'Commerçant': Color(0xFF185FA5),
    'Commerce': Color(0xFF185FA5),
    'Plombier': Color(0xFF5538BE),
    'Électricien': Color(0xFF993556),
    'Menuisier': Color(0xFF7B4A1E),
  };

  static const _catBg = <String, Color>{
    'Artisan': Color(0xFFE1F5EE),
    'Artiste': Color(0xFFEAF3DE),
    'Éleveur': Color(0xFFFAEEDA),
    'Commerçant': Color(0xFFE6F1FB),
    'Commerce': Color(0xFFE6F1FB),
    'Plombier': Color(0xFFEEEDFE),
    'Électricien': Color(0xFFFBEAF0),
    'Menuisier': Color(0xFFFAEEDA),
  };

  @override
  Widget build(BuildContext context) {
    final catColor = _catColors[service.categorie] ?? _T.primary;
    final catBg = _catBg[service.categorie] ?? _T.primaryLight;
    final hasPhoto = service.photos != null && service.photos.isNotEmpty;

    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: _T.border, width: 0.5),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.04),
              blurRadius: 12,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Row(
          children: [
            // Photo
            ClipRRect(
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(16),
                bottomLeft: Radius.circular(16),
              ),
              child: SizedBox(
                width: 96,
                height: 96,
                child: hasPhoto
                    ? Image.network(
                        service.photos.first,
                        fit: BoxFit.cover,
                        errorBuilder: (_, __, ___) => _placeholder(catBg, catColor),
                      )
                    : _placeholder(catBg, catColor),
              ),
            ),
            // Infos
            Expanded(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(12, 12, 12, 12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
                          decoration: BoxDecoration(
                            color: catBg,
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: Text(
                            service.categorie,
                            style: TextStyle(
                              fontSize: 10,
                              fontWeight: FontWeight.w600,
                              color: catColor,
                            ),
                          ),
                        ),
                        const Spacer(),
                        if (service.ville != null && service.ville.isNotEmpty)
                          Row(
                            children: [
                              const Icon(Icons.location_on_rounded, size: 11, color: _T.textTertiary),
                              const SizedBox(width: 2),
                              Text(
                                service.ville.split(',').first,
                                style: const TextStyle(
                                  fontSize: 10,
                                  color: _T.textTertiary,
                                ),
                              ),
                            ],
                          ),
                      ],
                    ),
                    const SizedBox(height: 6),
                    Text(
                      service.titre,
                      style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: _T.textPrimary,
                        letterSpacing: -0.1,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 4),
                    Text(
                      service.description,
                      style: const TextStyle(
                        fontSize: 12,
                        color: _T.textSecondary,
                        height: 1.4,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        Text(
                          service.prix > 0
                              ? '${service.prix.toStringAsFixed(0)} FCFA'
                              : 'Négociable',
                          style: const TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w700,
                            color: _T.primary,
                          ),
                        ),
                        const Spacer(),
                        Container(
                          padding: const EdgeInsets.all(6),
                          decoration: BoxDecoration(
                            color: _T.bg,
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: const Icon(
                            Icons.arrow_forward_ios_rounded,
                            size: 12,
                            color: _T.textTertiary,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _placeholder(Color bg, Color color) {
    return Container(
      color: bg,
      child: Center(
        child: Icon(Icons.image_outlined, color: color, size: 28),
      ),
    );
  }
}

// ─────────────────────────────────────────────────
// DATA
// ─────────────────────────────────────────────────
class _CategoryItem {
  final IconData icon;
  final String label;
  final Color bg;
  final Color color;
  const _CategoryItem(this.icon, this.label, this.bg, this.color);
}