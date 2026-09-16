import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:provider/provider.dart';

import '../services/services_list_screen.dart';
import '../services/create_service_screen.dart';
import '../profile/profile_screen.dart';
import '../profile/favorites_screen.dart';
import '../notifications/notifications_screen.dart';
import '../services/service_detail_screen.dart';
import '../../services/location_service.dart';
import '../../services/user_service.dart';
import '../../models/service_model.dart';
import '../../models/user_model.dart';
import '../../providers/service_provider.dart';
import '../../providers/category_provider.dart';
import '../../widgets/favorite_button.dart';

// ─────────────────────────────────────────────────
// THÈME
// ─────────────────────────────────────────────────
class _T {
  static const primary = Color(0xFF1D9E75);
  static const primaryDark = Color(0xFF085041);
  static const primaryLight = Color(0xFFE7F5EF);
  static const bg = Color(0xFFF8FAF9);
  static const card = Colors.white;
  static const textPrimary = Color(0xFF111827);
  static const textSecondary = Color(0xFF6B7280);
  static const textTertiary = Color(0xFF9CA3AF);
  static const border = Color(0xFFEDF0EF);
}

// ─────────────────────────────────────────────────
// ÉCRAN PRINCIPAL (conteneur IndexedStack + bottom nav)
// ─────────────────────────────────────────────────
class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  HomeScreenState createState() => HomeScreenState();
}

class HomeScreenState extends State<HomeScreen> {
  int _currentIndex = 0;

  // index 0 Accueil · 1 Rechercher · 2 Favoris · 3 Profil
  // (Publier est un bouton central qui pousse un écran, pas un tab)
  late final List<Widget> _screens;
  ServicesListScreen _searchScreen = const ServicesListScreen();

  void changeTab(int index) => setState(() => _currentIndex = index);

  void changeTabWithCategory(String category) {
    setState(() {
      _searchScreen = ServicesListScreen(initialCategory: category);
      _screens[1] = _searchScreen;
      _currentIndex = 1;
    });
  }

  void changeTabRecent() {
    setState(() {
      _searchScreen = const ServicesListScreen(initialSort: SortOption.recent);
      _screens[1] = _searchScreen;
      _currentIndex = 1;
    });
  }

  void openNotifications() {
    Navigator.of(context).push(
      MaterialPageRoute(builder: (_) => const NotificationsScreen()),
    );
  }

  @override
  void initState() {
    super.initState();
    _screens = [
      const _HomeTab(),
      _searchScreen,
      const FavoritesScreen(),
      const ProfileScreen(),
    ];
  }

  void _openPublish() {
    Navigator.push(
      context,
      MaterialPageRoute(
        fullscreenDialog: true,
        builder: (_) => const CreateServiceScreen(),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _T.bg,
      body: IndexedStack(index: _currentIndex, children: _screens),
      bottomNavigationBar: _BottomNav(
        currentIndex: _currentIndex,
        onTap: (i) => setState(() => _currentIndex = i),
        onPublish: _openPublish,
      ),
    );
  }
}

// ─────────────────────────────────────────────────
// BOTTOM NAV — 5 items : Accueil / Rechercher / Publier / Favoris / Profil
// ─────────────────────────────────────────────────
class _BottomNav extends StatelessWidget {
  final int currentIndex;
  final ValueChanged<int> onTap;
  final VoidCallback onPublish;

  const _BottomNav({
    required this.currentIndex,
    required this.onTap,
    required this.onPublish,
  });

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
            _NavItem(icon: Icons.search_rounded, label: 'Rechercher', index: 1, current: currentIndex, onTap: onTap),
            GestureDetector(
              onTap: onPublish,
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
            _NavItem(icon: Icons.favorite_border_rounded, label: 'Favoris', index: 2, current: currentIndex, onTap: onTap),
            _NavItem(icon: Icons.person_outline_rounded, label: 'Profil', index: 3, current: currentIndex, onTap: onTap),
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
        width: 58,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: 22, color: active ? _T.primary : _T.textTertiary),
            const SizedBox(height: 3),
            if (active)
              Container(
                width: 4,
                height: 4,
                decoration: const BoxDecoration(color: _T.primary, shape: BoxShape.circle),
              )
            else
              Text(label, style: const TextStyle(fontSize: 9, color: _T.textTertiary)),
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

  UserModel? _userModel;
  bool _isLoadingLocation = false;
  String _ville = '';
  List<String> _favoriteIds = [];

  static const List<_CategoryItem> _categories = [
    _CategoryItem(Icons.directions_car_filled_rounded, 'Véhicules', Color(0xFFE6F1FB), Color(0xFF185FA5)),
    _CategoryItem(Icons.home_work_rounded, 'Immobilier', Color(0xFFE1F5EE), Color(0xFF1D9E75)),
    _CategoryItem(Icons.phone_iphone_rounded, 'Électronique', Color(0xFFEEEDFE), Color(0xFF5538BE)),
    _CategoryItem(Icons.work_outline_rounded, 'Emploi', Color(0xFFFAEEDA), Color(0xFFBA7517)),
    _CategoryItem(Icons.build_rounded, 'Services', Color(0xFFFBEAF0), Color(0xFF993556)),
    _CategoryItem(Icons.agriculture_rounded, 'Agriculture', Color(0xFFEAF3DE), Color(0xFF639922)),
    _CategoryItem(Icons.celebration_rounded, 'Événements', Color(0xFFFFE9E5), Color(0xFFCC4B33)),
    _CategoryItem(Icons.apps_rounded, 'Autres', Color(0xFFF1EFE8), Color(0xFF444441)),
  ];

  static const List<String> _villes = [
    'Abidjan', 'Bouaké', 'Daloa', 'Yamoussoukro', 'Korhogo', 'San-Pédro',
  ];

  @override
  void initState() {
    super.initState();
    _loadUser();
    _loadFavorites();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<ServiceProvider>().loadAllServices(reset: true);
    });
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

  Future<void> _loadFavorites() async {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) return;
    final ids = await _userService.getFavorites(uid);
    if (mounted) setState(() => _favoriteIds = ids);
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

  String _timeAgo(DateTime? dt) {
    if (dt == null) return '';
    final diff = DateTime.now().difference(dt);
    if (diff.inMinutes < 60) return 'Il y a ${diff.inMinutes} min';
    if (diff.inHours < 24) return 'Il y a ${diff.inHours} h';
    if (diff.inDays < 7) return 'Il y a ${diff.inDays} j';
    return 'Il y a ${(diff.inDays / 7).floor()} sem.';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _T.bg,
      body: SafeArea(
        child: CustomScrollView(
          slivers: [
            SliverToBoxAdapter(child: _buildHeader()),
            SliverToBoxAdapter(child: _buildSearchBar()),
            SliverToBoxAdapter(child: _buildPromoBanner()),
            SliverToBoxAdapter(child: _buildCategories()),
            SliverToBoxAdapter(child: _buildLocationSection()),
            SliverToBoxAdapter(child: _buildNewAnnouncementsBanner()),
            SliverToBoxAdapter(child: _buildFeaturedHeader()),
            SliverToBoxAdapter(child: _buildFeaturedList()),
            SliverToBoxAdapter(child: _buildRecommendedHeader()),
            _buildRecommendedGrid(),
            SliverToBoxAdapter(child: _buildCityBrowse()),
            const SliverToBoxAdapter(child: SizedBox(height: 24)),
          ],
        ),
      ),
    );
  }

  // ── EN-TÊTE ──
  Widget _buildHeader() {
    final photoUrl = _userModel?.photoUrl ?? '';
    final initial = _userModel?.nom.isNotEmpty == true ? _userModel!.nom[0].toUpperCase() : 'U';

    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 12, 20, 0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Bonjour, $_firstName 👋',
                  style: const TextStyle(
                    fontSize: 19,
                    fontWeight: FontWeight.w800,
                    color: _T.textPrimary,
                    letterSpacing: -0.3,
                  ),
                ),
                const SizedBox(height: 2),
                const Text(
                  'Que recherchez-vous aujourd\'hui ?',
                  style: TextStyle(fontSize: 13, color: _T.textSecondary),
                ),
              ],
            ),
          ),
          GestureDetector(
            behavior: HitTestBehavior.opaque,
            onTap: () {
              final homeState = context.findAncestorStateOfType<HomeScreenState>();
              homeState?.openNotifications();
            },
            child: Container(
              width: 40,
              height: 40,
              margin: const EdgeInsets.only(right: 10),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: _T.border),
              ),
              child: const Icon(Icons.notifications_none_rounded, size: 20, color: _T.textSecondary),
            ),
          ),
          Container(
            width: 42,
            height: 42,
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
                      style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w700, color: _T.primaryDark),
                    ),
                  )
                : null,
          ),
        ],
      ),
    );
  }

  // ── BARRE DE RECHERCHE ──
  Widget _buildSearchBar() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
      child: GestureDetector(
        onTap: () => context.findAncestorStateOfType<HomeScreenState>()?.changeTab(1),
        child: Container(
          height: 52,
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: _T.border),
            boxShadow: [
              BoxShadow(color: Colors.black.withValues(alpha: 0.03), blurRadius: 10, offset: const Offset(0, 3)),
            ],
          ),
          child: Row(
            children: [
              const SizedBox(width: 16),
              const Icon(Icons.search_rounded, color: _T.textTertiary, size: 20),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  'Que recherchez-vous à ${_ville.isNotEmpty ? _ville.split(',').first : 'Abidjan'} ?',
                  style: const TextStyle(fontSize: 13.5, color: _T.textTertiary),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              Container(
                margin: const EdgeInsets.all(6),
                width: 40,
                height: 40,
                decoration: BoxDecoration(color: _T.primary, borderRadius: BorderRadius.circular(11)),
                child: const Icon(Icons.tune_rounded, color: Colors.white, size: 19),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ── BANNIÈRE PROMO ──
  Widget _buildPromoBanner() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(20),
        child: Container(
          height: 150,
          width: double.infinity,
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              colors: [Color(0xFF2B2B2B), Color(0xFF4A4A4A)],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
          ),
          child: Stack(
            children: [
              Positioned(
                right: -30,
                bottom: -30,
                child: Container(
                  width: 140,
                  height: 140,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: _T.primary.withValues(alpha: 0.25),
                  ),
                ),
              ),
              Padding(
                padding: const EdgeInsets.all(18),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                      decoration: BoxDecoration(
                        color: _T.primary,
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: const Text(
                        'Promo locale',
                        style: TextStyle(color: Colors.white, fontSize: 10.5, fontWeight: FontWeight.w700),
                      ),
                    ),
                    const Spacer(),
                    const Text(
                      'Le marché d\'Abidjan\nest ici',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 19,
                        fontWeight: FontWeight.w800,
                        height: 1.2,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Trouvez tout ce qu\'il vous faut au meilleur prix.',
                      style: TextStyle(color: Colors.white.withValues(alpha: 0.75), fontSize: 12),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ── CATÉGORIES ──
  Widget _buildCategories() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 20, 0, 0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Padding(
            padding: EdgeInsets.only(right: 20),
            child: Text(
              'Catégories',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700, color: _T.textPrimary),
            ),
          ),
          const SizedBox(height: 12),
          SizedBox(
            height: 84,
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.only(right: 20),
              itemCount: _categories.length,
              itemBuilder: (context, i) {
                final cat = _categories[i];
                return GestureDetector(
                  onTap: () => context
                      .findAncestorStateOfType<HomeScreenState>()
                      ?.changeTabWithCategory(cat.label),
                  child: Container(
                    width: 72,
                    margin: const EdgeInsets.only(right: 10),
                    child: Column(
                      children: [
                        Container(
                          width: 52,
                          height: 52,
                          decoration: BoxDecoration(color: cat.bg, borderRadius: BorderRadius.circular(15)),
                          child: Icon(cat.icon, color: cat.color, size: 24),
                        ),
                        const SizedBox(height: 6),
                        Text(
                          cat.label,
                          textAlign: TextAlign.center,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(fontSize: 10.5, color: _T.textSecondary, fontWeight: FontWeight.w500),
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  // ── LOCALISATION ──
  Widget _buildLocationSection() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 18, 20, 0),
      child: Row(
        children: [
          Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(color: _T.primaryLight, borderRadius: BorderRadius.circular(10)),
            child: const Icon(Icons.location_on_rounded, color: _T.primary, size: 18),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Annonces près de vous',
                  style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: _T.textPrimary),
                ),
                Text(
                  _ville.isNotEmpty ? _ville : 'Abidjan, Côte d\'Ivoire',
                  style: const TextStyle(fontSize: 11.5, color: _T.textSecondary),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
          GestureDetector(
            onTap: _isLoadingLocation ? null : _updateLocation,
            child: _isLoadingLocation
                ? const Padding(
                    padding: EdgeInsets.all(8),
                    child: SizedBox(
                      width: 16,
                      height: 16,
                      child: CircularProgressIndicator(strokeWidth: 2, color: _T.primary),
                    ),
                  )
                : const Padding(
                    padding: EdgeInsets.all(6),
                    child: Text(
                      'Modifier',
                      style: TextStyle(fontSize: 12, color: _T.primary, fontWeight: FontWeight.w700),
                    ),
                  ),
          ),
        ],
      ),
    );
  }

  // ── BANNIÈRE NOUVELLES ANNONCES ──
  Widget _buildNewAnnouncementsBanner() {
    return Consumer<ServiceProvider>(
      builder: (context, provider, _) {
        final count = provider.services.length;
        return Padding(
          padding: const EdgeInsets.fromLTRB(20, 18, 20, 0),
          child: GestureDetector(
            onTap: () => context.findAncestorStateOfType<HomeScreenState>()?.changeTabRecent(),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
              decoration: BoxDecoration(
                gradient: const LinearGradient(colors: [_T.primary, Color(0xFF17B486)]),
                borderRadius: BorderRadius.circular(16),
              ),
              child: Row(
                children: [
                  Container(
                    width: 34,
                    height: 34,
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.2),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: const Icon(Icons.bolt_rounded, color: Colors.white, size: 18),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      count > 0 ? '+$count Nouvelles annonces' : 'Découvrez les dernières annonces',
                      style: const TextStyle(color: Colors.white, fontSize: 13.5, fontWeight: FontWeight.w700),
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.18),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: const Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text('Voir', style: TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.w700)),
                        Icon(Icons.chevron_right_rounded, color: Colors.white, size: 16),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  // ── EN-TÊTE ANNONCES EN VEDETTE ──
  Widget _buildFeaturedHeader() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 22, 20, 12),
      child: Row(
        children: [
          const Text(
            'Annonces en vedette',
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700, color: _T.textPrimary),
          ),
          const Spacer(),
          GestureDetector(
            onTap: () => context.findAncestorStateOfType<HomeScreenState>()?.changeTab(1),
            child: const Text(
              'Voir tout',
              style: TextStyle(fontSize: 12, color: _T.primary, fontWeight: FontWeight.w600),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFeaturedList() {
    return Consumer<ServiceProvider>(
      builder: (context, provider, _) {
        if (provider.isLoading && provider.services.isEmpty) {
          return const SizedBox(
            height: 190,
            child: Center(child: CircularProgressIndicator(color: _T.primary, strokeWidth: 2)),
          );
        }
        final items = provider.services.take(6).toList();
        if (items.isEmpty) return const SizedBox.shrink();

        return SizedBox(
          height: 200,
          child: ListView.builder(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 20),
            itemCount: items.length,
            itemBuilder: (context, i) => _FeaturedCard(
              service: items[i],
              isFavorite: _favoriteIds.contains(items[i].id),
              favorites: _favoriteIds,
              timeAgo: _timeAgo(items[i].createdAt),
              onTap: () => Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => ServiceDetailScreen(service: items[i])),
              ),
            ),
          ),
        );
      },
    );
  }

  // ── EN-TÊTE ANNONCES RECOMMANDÉES ──
  Widget _buildRecommendedHeader() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 22, 20, 12),
      child: Row(
        children: [
          const Text(
            'Annonces recommandées',
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700, color: _T.textPrimary),
          ),
          const Spacer(),
          GestureDetector(
            onTap: () => context.findAncestorStateOfType<HomeScreenState>()?.changeTab(1),
            child: const Text(
              'Voir tout',
              style: TextStyle(fontSize: 12, color: _T.primary, fontWeight: FontWeight.w600),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRecommendedGrid() {
    return Consumer<ServiceProvider>(
      builder: (context, provider, _) {
        if (provider.isLoading && provider.services.isEmpty) {
          return const SliverToBoxAdapter(child: SizedBox.shrink());
        }
        final items = provider.services.skip(6).take(8).toList();
        if (items.isEmpty) {
          return const SliverToBoxAdapter(child: SizedBox.shrink());
        }

        return SliverPadding(
          padding: const EdgeInsets.symmetric(horizontal: 20),
          sliver: SliverGrid(
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 2,
              mainAxisSpacing: 12,
              crossAxisSpacing: 12,
              childAspectRatio: 0.72,
            ),
            delegate: SliverChildBuilderDelegate(
              (context, i) => _RecommendedCard(
                service: items[i],
                isFavorite: _favoriteIds.contains(items[i].id),
                favorites: _favoriteIds,
                timeAgo: _timeAgo(items[i].createdAt),
                onTap: () => Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => ServiceDetailScreen(service: items[i])),
                ),
              ),
              childCount: items.length,
            ),
          ),
        );
      },
    );
  }

  // ── PARCOURIR PAR VILLE ──
  Widget _buildCityBrowse() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 22, 20, 0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Text(
                'Parcourir par ville',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700, color: _T.textPrimary),
              ),
              const Spacer(),
              GestureDetector(
                onTap: () => context.findAncestorStateOfType<HomeScreenState>()?.changeTab(1),
                child: const Text(
                  'Tout',
                  style: TextStyle(fontSize: 12, color: _T.primary, fontWeight: FontWeight.w600),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: _villes.map((v) {
              return GestureDetector(
                onTap: () => context.findAncestorStateOfType<HomeScreenState>()?.changeTab(1),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 9),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: _T.border),
                  ),
                  child: Text(
                    v,
                    style: const TextStyle(fontSize: 12.5, color: _T.textSecondary, fontWeight: FontWeight.w500),
                  ),
                ),
              );
            }).toList(),
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────
// CARTE — ANNONCE EN VEDETTE (scroll horizontal)
// ─────────────────────────────────────────────────
class _FeaturedCard extends StatelessWidget {
  final ServiceModel service;
  final bool isFavorite;
  final List<String> favorites;
  final String timeAgo;
  final VoidCallback onTap;

  const _FeaturedCard({
    required this.service,
    required this.isFavorite,
    required this.favorites,
    required this.timeAgo,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final hasPhoto = service.photos.isNotEmpty;

    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 150,
        margin: const EdgeInsets.only(right: 12),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: _T.border, width: 0.5),
          boxShadow: [
            BoxShadow(color: Colors.black.withValues(alpha: 0.04), blurRadius: 10, offset: const Offset(0, 3)),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Stack(
              children: [
                ClipRRect(
                  borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
                  child: SizedBox(
                    height: 100,
                    width: double.infinity,
                    child: hasPhoto
                        ? Image.network(
                            service.photos.first,
                            fit: BoxFit.cover,
                            errorBuilder: (_, __, ___) => _placeholder(),
                          )
                        : _placeholder(),
                  ),
                ),
                Positioned(
                  top: 6,
                  right: 6,
                  child: Container(
                    decoration: BoxDecoration(color: Colors.white.withValues(alpha: 0.92), shape: BoxShape.circle),
                    child: FavoriteButton(serviceId: service.id, favorites: favorites, size: 15),
                  ),
                ),
              ],
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(10, 8, 10, 10),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    service.titre,
                    style: const TextStyle(fontSize: 12.5, fontWeight: FontWeight.w600, color: _T.textPrimary),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 4),
                  Text(
                    service.prix > 0 ? '${service.prix.toStringAsFixed(0)} FCFA' : 'Négociable',
                    style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w800, color: _T.primary),
                  ),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      const Icon(Icons.location_on_rounded, size: 10, color: _T.textTertiary),
                      const SizedBox(width: 2),
                      Expanded(
                        child: Text(
                          service.ville.isNotEmpty ? service.ville.split(',').first : timeAgo,
                          style: const TextStyle(fontSize: 10, color: _T.textTertiary),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _placeholder() {
    return Container(
      color: _T.primaryLight,
      child: const Icon(Icons.image_outlined, color: _T.primary, size: 26),
    );
  }
}

// ─────────────────────────────────────────────────
// CARTE — ANNONCE RECOMMANDÉE (grille 2 colonnes)
// ─────────────────────────────────────────────────
class _RecommendedCard extends StatelessWidget {
  final ServiceModel service;
  final bool isFavorite;
  final List<String> favorites;
  final String timeAgo;
  final VoidCallback onTap;

  const _RecommendedCard({
    required this.service,
    required this.isFavorite,
    required this.favorites,
    required this.timeAgo,
    required this.onTap,
  });

  static const Map<String, Color> _catColors = {
    'Artisan': Color(0xFF1D9E75), 'Immobilier': Color(0xFF1D9E75),
    'Véhicules': Color(0xFF185FA5), 'Commerçant': Color(0xFF185FA5),
    'Électronique': Color(0xFF5538BE), 'Emploi': Color(0xFFBA7517),
  };

  @override
  Widget build(BuildContext context) {
    final hasPhoto = service.photos.isNotEmpty;
    final catColor = _catColors[service.categorie] ?? _T.primary;

    return GestureDetector(
      onTap: onTap,
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: _T.border, width: 0.5),
          boxShadow: [
            BoxShadow(color: Colors.black.withValues(alpha: 0.04), blurRadius: 10, offset: const Offset(0, 3)),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Stack(
              children: [
                ClipRRect(
                  borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
                  child: AspectRatio(
                    aspectRatio: 1.35,
                    child: hasPhoto
                        ? Image.network(
                            service.photos.first,
                            fit: BoxFit.cover,
                            width: double.infinity,
                            errorBuilder: (_, __, ___) => _placeholder(),
                          )
                        : _placeholder(),
                  ),
                ),
                if (service.categorie.isNotEmpty)
                  Positioned(
                    left: 8,
                    top: 8,
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                      decoration: BoxDecoration(color: catColor, borderRadius: BorderRadius.circular(6)),
                      child: Text(
                        service.categorie,
                        style: const TextStyle(color: Colors.white, fontSize: 9.5, fontWeight: FontWeight.w700),
                      ),
                    ),
                  ),
                Positioned(
                  right: 6,
                  top: 6,
                  child: Container(
                    decoration: BoxDecoration(color: Colors.white.withValues(alpha: 0.92), shape: BoxShape.circle),
                    child: FavoriteButton(serviceId: service.id, favorites: favorites, size: 15),
                  ),
                ),
              ],
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(10, 8, 10, 10),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    service.titre,
                    style: const TextStyle(fontSize: 12.5, fontWeight: FontWeight.w600, color: _T.textPrimary),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 5),
                  Text(
                    service.prix > 0 ? '${service.prix.toStringAsFixed(0)} FCFA' : 'Négociable',
                    style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w800, color: _T.primary),
                  ),
                  const SizedBox(height: 5),
                  Row(
                    children: [
                      const Icon(Icons.location_on_rounded, size: 10, color: _T.textTertiary),
                      const SizedBox(width: 2),
                      Expanded(
                        child: Text(
                          service.ville.isNotEmpty ? service.ville.split(',').first : '—',
                          style: const TextStyle(fontSize: 10, color: _T.textTertiary),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 2),
                  Text(
                    timeAgo,
                    style: const TextStyle(fontSize: 9.5, color: _T.textTertiary),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _placeholder() {
    return Container(
      color: _T.primaryLight,
      child: const Icon(Icons.image_outlined, color: _T.primary, size: 26),
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