<<<<<<< HEAD
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../providers/service_provider.dart';
import '../../services/location_service.dart';
import '../../services/user_service.dart';
import '../../widgets/service_card.dart';
import '../../models/service_model.dart';
import 'service_detail_screen.dart';

=======
import 'dart:async';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/services.dart';

import '../../providers/service_provider.dart';
import '../../providers/category_provider.dart';
import '../../services/user_service.dart';
import '../../models/service_model.dart';
import '../../utils/geo_utils.dart';
import '../../services/user_service.dart';
import 'service_detail_screen.dart';

// ─────────────────────────────────────────────────
// THÈME
// ─────────────────────────────────────────────────
class _T {
<<<<<<< HEAD
  static const primary     = Color(0xFF1D9E75);
  static const primaryLight= Color(0xFFE1F5EE);
  static const primaryDark = Color(0xFF085041);
  static const bg          = Color(0xFFF8F9FA);
  static const card        = Colors.white;
  static const textPrimary = Color(0xFF0D1117);
  static const textSecondary = Color(0xFF6B7280);
  static const textTertiary  = Color(0xFFB0B7C3);
  static const border      = Color(0xFFEEEEF2);

  static const catColors = <String, Color>{
    'Artisan'     : Color(0xFF085041),
    'Artiste'     : Color(0xFF27500A),
    'Éleveur'     : Color(0xFF633806),
    'Commerçant'  : Color(0xFF0C447C),
    'Commerce'    : Color(0xFF0C447C),
    'Plombier'    : Color(0xFF3C3489),
    'Électricien' : Color(0xFF72243E),
    'Menuisier'   : Color(0xFF4A1B0C),
    'Autre'       : Color(0xFF444441),
  };

  static const catBg = <String, Color>{
    'Artisan'     : Color(0xFFE1F5EE),
    'Artiste'     : Color(0xFFEAF3DE),
    'Éleveur'     : Color(0xFFFAEEDA),
    'Commerçant'  : Color(0xFFE6F1FB),
    'Commerce'    : Color(0xFFE6F1FB),
    'Plombier'    : Color(0xFFEEEDFE),
    'Électricien' : Color(0xFFFBEAF0),
    'Menuisier'   : Color(0xFFFAEEDA),
    'Autre'       : Color(0xFFF1EFE8),
=======
  static const primary = Color(0xFF1D9E75);
  static const primaryLight = Color(0xFFE1F5EE);
  static const primaryDark = Color(0xFF085041);
  static const bg = Color(0xFFF8F9FA);
  static const card = Colors.white;
  static const textPrimary = Color(0xFF0D1117);
  static const textSecondary = Color(0xFF6B7280);
  static const textTertiary = Color(0xFFB0B7C3);
  static const border = Color(0xFFEEEEF2);

  static const catColors = <String, Color>{
    'Artisan': Color(0xFF085041),
    'Artiste': Color(0xFF27500A),
    'Éleveur': Color(0xFF633806),
    'Commerçant': Color(0xFF0C447C),
    'Commerce': Color(0xFF0C447C),
    'Plombier': Color(0xFF3C3489),
    'Électricien': Color(0xFF72243E),
    'Menuisier': Color(0xFF4A1B0C),
    'Autre': Color(0xFF444441),
  };

  static const catBg = <String, Color>{
    'Artisan': Color(0xFFE1F5EE),
    'Artiste': Color(0xFFEAF3DE),
    'Éleveur': Color(0xFFFAEEDA),
    'Commerçant': Color(0xFFE6F1FB),
    'Commerce': Color(0xFFE6F1FB),
    'Plombier': Color(0xFFEEEDFE),
    'Électricien': Color(0xFFFBEAF0),
    'Menuisier': Color(0xFFFAEEDA),
    'Autre': Color(0xFFF1EFE8),
>>>>>>> develop
  };

  static Color catColor(String cat) => catColors[cat] ?? primary;
  static Color catBgColor(String cat) => catBg[cat] ?? primaryLight;
}

// ─────────────────────────────────────────────────
// TRI
// ─────────────────────────────────────────────────
enum SortOption {
  distance('Plus proche'),
  prixCroissant('Prix croissant'),
  prixDecroissant('Prix décroissant'),
  recent('Plus récent');

  final String label;
  const SortOption(this.label);
}

// ─────────────────────────────────────────────────
// ÉCRAN
// ─────────────────────────────────────────────────
<<<<<<< HEAD
>>>>>>> develop
=======
>>>>>>> develop
class ServicesListScreen extends StatefulWidget {
  final String? initialCategory;

  const ServicesListScreen({
    super.key,
    this.initialCategory,
  });

  @override
  State<ServicesListScreen> createState() => _ServicesListScreenState();
}

class _ServicesListScreenState extends State<ServicesListScreen> {
<<<<<<< HEAD
  final LocationService _locationService = LocationService();
  final UserService _userService = UserService();
  final TextEditingController _searchController = TextEditingController();
<<<<<<< HEAD
=======
  final ScrollController _scrollController = ScrollController();
>>>>>>> develop

  double? _myLat;
  double? _myLng;
  String _searchQuery = '';
<<<<<<< HEAD
  String? _selectedCategory;

  static const Color primaryColor = Color(0xFF1D9E75);

  final List<String> _categories = [
    'Tous',
=======
  Timer? _debounceTimer;
  final Set<String> _selectedCategories = {};
  SortOption _sortOption = SortOption.distance;
  double _radiusKm = 50.0;
  bool _showFiltersPanel = false;

  static const List<String> _categories = [
>>>>>>> develop
    'Artisan',
    'Artiste',
    'Éleveur',
    'Commerçant',
    'Plombier',
    'Électricien',
    'Menuisier',
    'Autre',
=======
  final UserService _userService = UserService();
  final TextEditingController _searchController = TextEditingController();
  final ScrollController _scrollController = ScrollController();

  double? _myLat;
  double? _myLng;

  String _searchQuery = '';
  Timer? _debounceTimer;

  final Set<String> _selectedCategories = {};
  SortOption _sortOption = SortOption.distance;
  double _radiusKm = 50.0;
  bool _showFiltersPanel = false;

  static const List<String> _categories = [
    'Artisan', 'Artiste', 'Éleveur', 'Commerçant',
    'Plombier', 'Électricien', 'Menuisier', 'Autre',
>>>>>>> develop
  ];

  @override
  void initState() {
    super.initState();
    _loadData();
<<<<<<< HEAD
=======
    _scrollController.addListener(_onScroll);
>>>>>>> develop
  }

  @override
  void dispose() {
    _searchController.dispose();
<<<<<<< HEAD
=======
    _debounceTimer?.cancel();
    _scrollController.removeListener(_onScroll);
    _scrollController.dispose();
>>>>>>> develop
    super.dispose();
  }

  Future<void> _loadData() async {
<<<<<<< HEAD
<<<<<<< HEAD
    // Charger toutes les annonces
    await context.read<ServiceProvider>().loadAllServices();

    // Charger la position de l'utilisateur connecté
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid != null) {
      final user = await _userService.getUserProfile(uid);
      if (user != null && user.gpsLat != 0.0) {
        setState(() {
          _myLat = user.gpsLat;
          _myLng = user.gpsLng;
        });
=======
=======
>>>>>>> develop
    await context.read<ServiceProvider>().loadAllServices(reset: true);
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid != null) {
      final user = await _userService.getUserProfile(uid);
      if (user != null && GeoUtils.isValidCoordinate(user.gpsLat, user.gpsLng)) {
        if (mounted) setState(() { _myLat = user.gpsLat; _myLng = user.gpsLng; });
>>>>>>> develop
      }
    }
  }

<<<<<<< HEAD
<<<<<<< HEAD
  // Calculer la distance entre l'utilisateur et une annonce
  double? _getDistance(ServiceModel service) {
    if (_myLat == null || _myLng == null) return null;
    if (service.gpsLat == 0.0 && service.gpsLng == 0.0) return null;
    return _locationService.calculateDistance(
      _myLat!,
      _myLng!,
      service.gpsLat,
      service.gpsLng,
    );
  }

  // Filtrer les annonces selon recherche + catégorie
  List<ServiceModel> _getFilteredServices(List<ServiceModel> all) {
    List<ServiceModel> filtered = all;

    // Filtre par catégorie
    if (_selectedCategory != null && _selectedCategory != 'Tous') {
      filtered = filtered
          .where((s) => s.categorie == _selectedCategory)
          .toList();
    }

    // Filtre par recherche texte
    if (_searchQuery.isNotEmpty) {
      final query = _searchQuery.toLowerCase();
      filtered = filtered.where((s) {
        return s.titre.toLowerCase().contains(query) ||
            s.description.toLowerCase().contains(query) ||
            s.categorie.toLowerCase().contains(query) ||
            s.ville.toLowerCase().contains(query);
      }).toList();
    }
=======
  void _onScroll() {
    final pos = _scrollController.position;
    if (pos.pixels >= pos.maxScrollExtent - 200) {
      final p = context.read<ServiceProvider>();
      if (p.hasMore && !p.isLoadingMore) p.loadMoreServices();
    }
  }

  void _onSearchChanged(String value) {
    _debounceTimer?.cancel();
    _debounceTimer = Timer(const Duration(milliseconds: 300), () {
      if (mounted) setState(() => _searchQuery = value.toLowerCase().trim());
    });
  }

  double? _getDistance(ServiceModel s) {
    if (_myLat == null || _myLng == null) return null;
    if (!GeoUtils.isValidCoordinate(s.gpsLat, s.gpsLng)) return null;
    return GeoUtils.distanceBetween(_myLat!, _myLng!, s.gpsLat, s.gpsLng);
  }

  List<ServiceModel> _filtered(List<ServiceModel> all) {
    var result = List<ServiceModel>.from(all);

    // Filtre distance
    if (_myLat != null && _myLng != null) {
      result = result.where((s) {
        final d = _getDistance(s);
        return d == null || d <= _radiusKm;
      }).toList();
    }

    // Filtre catégories
    if (_selectedCategories.isNotEmpty) {
      result = result.where((s) => _selectedCategories.contains(s.categorie)).toList();
    }

    // Recherche
    if (_searchQuery.isNotEmpty) {
      result = result.where((s) =>
          s.titre.toLowerCase().contains(_searchQuery) ||
          s.description.toLowerCase().contains(_searchQuery) ||
          s.categorie.toLowerCase().contains(_searchQuery) ||
          s.ville.toLowerCase().contains(_searchQuery)).toList();
>>>>>>> develop

    // Trier par distance si position disponible
    if (_myLat != null && _myLng != null) {
      filtered.sort((a, b) {
        final distA = _getDistance(a) ?? double.infinity;
        final distB = _getDistance(b) ?? double.infinity;
        return distA.compareTo(distB);
      });
    }

<<<<<<< HEAD
    return filtered;
  }

=======
    // Tri
    switch (_sortOption) {
      case SortOption.distance:
        result.sort((a, b) => (_getDistance(a) ?? double.infinity).compareTo(_getDistance(b) ?? double.infinity));
        break;
      case SortOption.prixCroissant:
        result.sort((a, b) => a.prix.compareTo(b.prix));
        break;
      case SortOption.prixDecroissant:
        result.sort((a, b) => b.prix.compareTo(a.prix));
        break;
      case SortOption.recent:
        result.sort((a, b) => (b.createdAt ?? DateTime(2000)).compareTo(a.createdAt ?? DateTime(2000)));
        break;
    }

    return result;
  }

  void _resetFilters() => setState(() {
        _searchController.clear();
        _searchQuery = '';
        _selectedCategories.clear();
        _sortOption = SortOption.distance;
        _radiusKm = 50.0;
      });

  bool get _hasActiveFilters =>
      _searchQuery.isNotEmpty ||
      _selectedCategories.isNotEmpty ||
      _sortOption != SortOption.distance ||
      _radiusKm < 50.0;

>>>>>>> develop
  @override
  Widget build(BuildContext context) {
    // ✅ Écouter le CategoryProvider en temps réel
    final cat = context.watch<CategoryProvider>().selectedCategory;
    if (cat != null) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) {
          setState(() {
            _selectedCategories.clear();
            _selectedCategories.add(cat);
          });
          context.read<CategoryProvider>().reset();
        }
      });
    }

    return Scaffold(
<<<<<<< HEAD
      backgroundColor: const Color(0xFFF5F5F5),
      appBar: AppBar(
        backgroundColor: primaryColor,
        elevation: 0,
        title: const Text(
          'Annonces',
          style: TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.bold,
          ),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh, color: Colors.white),
            onPressed: _loadData,
          ),
        ],
      ),
      body: Column(
        children: [

          // ── Barre de recherche ──
          Container(
            color: primaryColor,
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
            child: TextField(
              controller: _searchController,
              onChanged: (v) => setState(() => _searchQuery = v),
              decoration: InputDecoration(
                hintText: 'Rechercher un service, une ville...',
                hintStyle: const TextStyle(color: Colors.grey),
                prefixIcon:
                    const Icon(Icons.search, color: Colors.grey),
                suffixIcon: _searchQuery.isNotEmpty
                    ? IconButton(
                        icon: const Icon(Icons.close, color: Colors.grey),
                        onPressed: () {
                          _searchController.clear();
                          setState(() => _searchQuery = '');
                        },
                      )
                    : null,
                filled: true,
                fillColor: Colors.white,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide.none,
                ),
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 12,
                ),
              ),
            ),
          ),

          // ── Filtres par catégorie ──
          SizedBox(
            height: 48,
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(
                  horizontal: 12, vertical: 8),
              itemCount: _categories.length,
              itemBuilder: (context, index) {
                final cat = _categories[index];
                final isSelected = _selectedCategory == cat ||
                    (_selectedCategory == null && cat == 'Tous');
                return GestureDetector(
                  onTap: () => setState(() {
                    _selectedCategory = cat == 'Tous' ? null : cat;
                  }),
                  child: Container(
                    margin: const EdgeInsets.only(right: 8),
                    padding: const EdgeInsets.symmetric(
                        horizontal: 14, vertical: 4),
                    decoration: BoxDecoration(
                      color:
                          isSelected ? primaryColor : Colors.white,
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(
                        color: isSelected
                            ? primaryColor
                            : Colors.grey.shade300,
                      ),
                    ),
                    child: Text(
                      cat,
                      style: TextStyle(
                        color:
                            isSelected ? Colors.white : Colors.black87,
                        fontWeight: isSelected
                            ? FontWeight.bold
                            : FontWeight.normal,
                        fontSize: 13,
                      ),
                    ),
                  ),
                );
              },
            ),
          ),

          // ── Liste des annonces ──
          Expanded(
            child: Consumer<ServiceProvider>(
              builder: (context, provider, _) {
                if (provider.isLoading) {
                  return const Center(
                    child: CircularProgressIndicator(
                        color: primaryColor),
                  );
                }

                final filtered =
                    _getFilteredServices(provider.services);

                if (filtered.isEmpty) {
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(Icons.search_off,
                            size: 64, color: Colors.grey),
                        const SizedBox(height: 16),
                        Text(
                          _searchQuery.isNotEmpty
                              ? 'Aucun résultat pour "$_searchQuery"'
                              : 'Aucune annonce disponible',
                          style: const TextStyle(
                            color: Colors.grey,
                            fontSize: 16,
                          ),
                        ),
                        if (_searchQuery.isNotEmpty) ...[
                          const SizedBox(height: 12),
                          TextButton(
                            onPressed: () {
                              _searchController.clear();
                              setState(() => _searchQuery = '');
                            },
                            child: const Text('Effacer la recherche'),
=======
  void _onScroll() {
    final pos = _scrollController.position;
    if (pos.pixels >= pos.maxScrollExtent - 200) {
      final p = context.read<ServiceProvider>();
      if (p.hasMore && !p.isLoadingMore) p.loadMoreServices();
    }
  }

  void _onSearchChanged(String value) {
    _debounceTimer?.cancel();
    _debounceTimer = Timer(const Duration(milliseconds: 300), () {
      if (mounted) setState(() => _searchQuery = value.toLowerCase().trim());
    });
  }

  double? _getDistance(ServiceModel s) {
    if (_myLat == null || _myLng == null) return null;
    if (!GeoUtils.isValidCoordinate(s.gpsLat, s.gpsLng)) return null;
    return GeoUtils.distanceBetween(_myLat!, _myLng!, s.gpsLat, s.gpsLng);
  }

  List<ServiceModel> _filtered(List<ServiceModel> all) {
    var result = all;
    if (_myLat != null && _myLng != null) {
      result = result.where((s) {
        final d = _getDistance(s);
        return d == null || d <= _radiusKm;
      }).toList();
    }
    if (_selectedCategories.isNotEmpty) {
      result = result.where((s) => _selectedCategories.contains(s.categorie)).toList();
    }
    if (_searchQuery.isNotEmpty) {
      result = result.where((s) =>
        s.titre.toLowerCase().contains(_searchQuery) ||
        s.description.toLowerCase().contains(_searchQuery) ||
        s.categorie.toLowerCase().contains(_searchQuery) ||
        s.ville.toLowerCase().contains(_searchQuery),
      ).toList();
      result.sort((a, b) {
        final as_ = a.titre.toLowerCase().startsWith(_searchQuery);
        final bs_ = b.titre.toLowerCase().startsWith(_searchQuery);
        if (as_ && !bs_) return -1;
        if (!as_ && bs_) return 1;
        return 0;
      });
      return result;
    }
    switch (_sortOption) {
      case SortOption.distance:
        result.sort((a, b) => (_getDistance(a) ?? double.infinity).compareTo(_getDistance(b) ?? double.infinity));
      case SortOption.prixCroissant:
        result.sort((a, b) => a.prix.compareTo(b.prix));
      case SortOption.prixDecroissant:
        result.sort((a, b) => b.prix.compareTo(a.prix));
      case SortOption.recent:
        result.sort((a, b) => (b.createdAt ?? DateTime(2000)).compareTo(a.createdAt ?? DateTime(2000)));
    }
    return result;
  }

  void _resetFilters() => setState(() {
    _searchController.clear();
    _searchQuery = '';
    _selectedCategories.clear();
    _sortOption = SortOption.distance;
    _radiusKm = 50.0;
  });

  bool get _hasActiveFilters =>
    _searchQuery.isNotEmpty ||
    _selectedCategories.isNotEmpty ||
    _sortOption != SortOption.distance ||
    _radiusKm < 50.0;

  // ─────────────────────────────────────────────────
  // BUILD
  // ─────────────────────────────────────────────────
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _T.bg,
      body: Column(
        children: [
=======
      backgroundColor: _T.bg,
      body: Column(
        children: [
>>>>>>> develop
          _buildAppBar(),
          if (_showFiltersPanel) _buildFiltersPanel(),
          _buildCategoryChips(),
          _buildSortBar(),
          Expanded(child: _buildList()),
        ],
      ),
    );
  }

  // ── APP BAR ──
  Widget _buildAppBar() {
    return Container(
      color: Colors.white,
      padding: EdgeInsets.only(
        top: MediaQuery.of(context).padding.top + 8,
<<<<<<< HEAD
        left: 20, right: 20, bottom: 0,
=======
        left: 20,
        right: 20,
        bottom: 0,
>>>>>>> develop
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Text(
                'Annonces',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.w700,
                  color: _T.textPrimary,
                  letterSpacing: -0.3,
<<<<<<< HEAD
                ),
              ),
              const Spacer(),
              _iconBtn(
                icon: Icons.tune_rounded,
                active: _hasActiveFilters,
                onTap: () => setState(() => _showFiltersPanel = !_showFiltersPanel),
              ),
              const SizedBox(width: 8),
              _iconBtn(
                icon: Icons.refresh_rounded,
                onTap: _loadData,
              ),
            ],
          ),
          const SizedBox(height: 12),
          // Search bar
          Container(
            height: 44,
            decoration: BoxDecoration(
              color: _T.bg,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: _T.border),
            ),
            child: Row(
              children: [
                const SizedBox(width: 12),
                const Icon(Icons.search_rounded, color: _T.textTertiary, size: 18),
                const SizedBox(width: 8),
                Expanded(
                  child: TextField(
                    controller: _searchController,
                    onChanged: _onSearchChanged,
                    style: const TextStyle(fontSize: 13, color: _T.textPrimary),
                    decoration: const InputDecoration(
                      hintText: 'Rechercher un service, une ville...',
                      hintStyle: TextStyle(fontSize: 13, color: _T.textTertiary),
                      border: InputBorder.none,
                      isDense: true,
                    ),
                  ),
                ),
                if (_searchController.text.isNotEmpty)
                  GestureDetector(
                    onTap: () {
                      _searchController.clear();
                      setState(() => _searchQuery = '');
                    },
                    child: const Padding(
                      padding: EdgeInsets.all(10),
                      child: Icon(Icons.close_rounded, size: 16, color: _T.textTertiary),
                    ),
                  ),
              ],
            ),
          ),
          const SizedBox(height: 12),
        ],
      ),
    );
  }

  Widget _iconBtn({required IconData icon, bool active = false, required VoidCallback onTap}) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 36,
        height: 36,
        decoration: BoxDecoration(
          color: active ? _T.primaryLight : _T.bg,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: active ? const Color(0xFF9FE1CB) : _T.border),
        ),
        child: Icon(icon, size: 18, color: active ? _T.primary : _T.textSecondary),
      ),
    );
  }

  // ── FILTRES PANEL ──
  Widget _buildFiltersPanel() {
    return Container(
      color: Colors.white,
      padding: const EdgeInsets.fromLTRB(20, 8, 20, 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Divider(height: 1, color: _T.border),
          const SizedBox(height: 12),
          Row(
            children: [
              const Icon(Icons.radar_rounded, color: _T.primary, size: 16),
              const SizedBox(width: 6),
              Text(
                'Rayon : ${_radiusKm.round()} km',
                style: const TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: _T.textPrimary,
=======
>>>>>>> develop
                ),
              ),
              const Spacer(),
              _iconBtn(
                icon: Icons.tune_rounded,
                active: _hasActiveFilters,
                onTap: () => setState(() => _showFiltersPanel = !_showFiltersPanel),
              ),
              const SizedBox(width: 8),
              _iconBtn(
                icon: Icons.refresh_rounded,
                onTap: _loadData,
              ),
            ],
          ),
<<<<<<< HEAD
          SliderTheme(
            data: SliderTheme.of(context).copyWith(
              activeTrackColor: _T.primary,
              inactiveTrackColor: _T.primaryLight,
              thumbColor: _T.primary,
              overlayColor: _T.primary.withValues(alpha: 0.1),
              trackHeight: 3,
              thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 7),
            ),
            child: Slider(
              value: _radiusKm,
              min: 1, max: 50, divisions: 49,
              label: '${_radiusKm.round()} km',
              onChanged: _myLat != null ? (v) => setState(() => _radiusKm = v) : null,
            ),
          ),
=======
          const SizedBox(height: 12),
          Container(
            height: 44,
            decoration: BoxDecoration(
              color: _T.bg,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: _T.border),
            ),
            child: Row(
              children: [
                const SizedBox(width: 12),
                const Icon(Icons.search_rounded, color: _T.textTertiary, size: 18),
                const SizedBox(width: 8),
                Expanded(
                  child: TextField(
                    controller: _searchController,
                    onChanged: _onSearchChanged,
                    style: const TextStyle(fontSize: 13, color: _T.textPrimary),
                    decoration: const InputDecoration(
                      hintText: 'Rechercher un service, une ville...',
                      hintStyle: TextStyle(fontSize: 13, color: _T.textTertiary),
                      border: InputBorder.none,
                      isDense: true,
                    ),
                  ),
                ),
                if (_searchController.text.isNotEmpty)
                  GestureDetector(
                    onTap: () {
                      _searchController.clear();
                      setState(() => _searchQuery = '');
                    },
                    child: const Padding(
                      padding: EdgeInsets.all(10),
                      child: Icon(Icons.close_rounded, size: 16, color: _T.textTertiary),
                    ),
                  ),
              ],
            ),
          ),
          const SizedBox(height: 12),
        ],
      ),
    );
  }

  Widget _iconBtn({required IconData icon, bool active = false, required VoidCallback onTap}) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 36,
        height: 36,
        decoration: BoxDecoration(
          color: active ? _T.primaryLight : _T.bg,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: active ? const Color(0xFF9FE1CB) : _T.border),
        ),
        child: Icon(icon, size: 18, color: active ? _T.primary : _T.textSecondary),
      ),
    );
  }

  // ── FILTRES PANEL ──
  Widget _buildFiltersPanel() {
    return Container(
      color: Colors.white,
      padding: const EdgeInsets.fromLTRB(20, 8, 20, 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Divider(height: 1, color: _T.border),
          const SizedBox(height: 12),
          Row(
            children: [
              const Icon(Icons.radar_rounded, color: _T.primary, size: 16),
              const SizedBox(width: 6),
              Text(
                'Rayon : ${_radiusKm.round()} km',
                style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: _T.textPrimary),
              ),
              const Spacer(),
              if (_myLat == null)
                const Text('Position non disponible', style: TextStyle(color: Colors.orange, fontSize: 11)),
            ],
          ),
          SliderTheme(
            data: SliderTheme.of(context).copyWith(
              activeTrackColor: _T.primary,
              inactiveTrackColor: _T.primaryLight,
              thumbColor: _T.primary,
              overlayColor: _T.primary.withValues(alpha: 0.1),
              trackHeight: 3,
              thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 7),
            ),
            child: Slider(
              value: _radiusKm,
              min: 1,
              max: 50,
              divisions: 49,
              label: '${_radiusKm.round()} km',
              onChanged: _myLat != null ? (v) => setState(() => _radiusKm = v) : null,
            ),
          ),
>>>>>>> develop
          if (_hasActiveFilters)
            GestureDetector(
              onTap: _resetFilters,
              child: Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(vertical: 8),
                decoration: BoxDecoration(
                  color: const Color(0xFFFCEBEB),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.clear_all_rounded, color: Color(0xFFA32D2D), size: 16),
                    SizedBox(width: 6),
<<<<<<< HEAD
                    Text(
                      'Réinitialiser les filtres',
                      style: TextStyle(color: Color(0xFFA32D2D), fontSize: 13, fontWeight: FontWeight.w500),
                    ),
=======
                    Text('Réinitialiser les filtres', style: TextStyle(color: Color(0xFFA32D2D), fontSize: 13, fontWeight: FontWeight.w500)),
>>>>>>> develop
                  ],
                ),
              ),
            ),
        ],
      ),
    );
  }

  // ── CHIPS CATÉGORIES ──
  Widget _buildCategoryChips() {
    return Container(
      color: Colors.white,
      padding: const EdgeInsets.only(bottom: 10),
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 20),
        child: Row(
          children: [
            _chip('Tous', _selectedCategories.isEmpty, () => setState(() => _selectedCategories.clear())),
            ..._categories.map((cat) {
              final sel = _selectedCategories.contains(cat);
              return _chip(cat, sel, () {
                setState(() {
<<<<<<< HEAD
                  if (sel) _selectedCategories.remove(cat);
                  else _selectedCategories.add(cat);
=======
                  if (sel) {
                    _selectedCategories.remove(cat);
                  } else {
                    _selectedCategories.add(cat);
                  }
>>>>>>> develop
                });
              });
            }),
          ],
        ),
      ),
    );
  }

  Widget _chip(String label, bool selected, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.only(right: 8),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
        decoration: BoxDecoration(
          color: selected ? _T.primary : Colors.white,
          borderRadius: BorderRadius.circular(20),
<<<<<<< HEAD
          border: Border.all(
            color: selected ? _T.primary : _T.border,
          ),
=======
          border: Border.all(color: selected ? _T.primary : _T.border),
>>>>>>> develop
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w500,
            color: selected ? Colors.white : _T.textSecondary,
          ),
        ),
      ),
    );
  }

  // ── SORT BAR ──
  Widget _buildSortBar() {
    return Consumer<ServiceProvider>(
      builder: (context, provider, _) {
        final count = _filtered(provider.services).length;
        return Container(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
          decoration: const BoxDecoration(
            color: Colors.white,
<<<<<<< HEAD
            border: Border(
              bottom: BorderSide(color: _T.border, width: 0.5),
            ),
=======
            border: Border(bottom: BorderSide(color: _T.border, width: 0.5)),
>>>>>>> develop
          ),
          child: Row(
            children: [
              Text(
                '$count annonce${count > 1 ? 's' : ''} trouvée${count > 1 ? 's' : ''}',
<<<<<<< HEAD
                style: const TextStyle(
                  fontSize: 12,
                  color: _T.textSecondary,
                ),
=======
                style: const TextStyle(fontSize: 12, color: _T.textSecondary),
>>>>>>> develop
              ),
              const Spacer(),
              GestureDetector(
                onTap: _showSortSheet,
                child: Row(
                  children: [
                    const Icon(Icons.swap_vert_rounded, size: 16, color: _T.primary),
                    const SizedBox(width: 4),
                    Text(
                      _sortOption.label,
<<<<<<< HEAD
                      style: const TextStyle(
                        fontSize: 12,
                        color: _T.primary,
                        fontWeight: FontWeight.w600,
                      ),
=======
                      style: const TextStyle(fontSize: 12, color: _T.primary, fontWeight: FontWeight.w600),
>>>>>>> develop
                    ),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  void _showSortSheet() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.white,
<<<<<<< HEAD
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
=======
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
>>>>>>> develop
      builder: (_) => Padding(
        padding: const EdgeInsets.fromLTRB(20, 12, 20, 32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
<<<<<<< HEAD
              child: Container(
                width: 36, height: 4,
                decoration: BoxDecoration(
                  color: _T.border,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            const SizedBox(height: 16),
            const Text(
              'Trier par',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700, color: _T.textPrimary),
            ),
=======
              child: Container(width: 36, height: 4, decoration: BoxDecoration(color: _T.border, borderRadius: BorderRadius.circular(2))),
            ),
            const SizedBox(height: 16),
            const Text('Trier par', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700, color: _T.textPrimary)),
>>>>>>> develop
            const SizedBox(height: 12),
            ...SortOption.values.map((opt) {
              final selected = _sortOption == opt;
              return GestureDetector(
                onTap: () {
                  setState(() => _sortOption = opt);
                  Navigator.pop(context);
                },
                child: Container(
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(vertical: 13, horizontal: 14),
                  margin: const EdgeInsets.only(bottom: 8),
                  decoration: BoxDecoration(
                    color: selected ? _T.primaryLight : _T.bg,
                    borderRadius: BorderRadius.circular(12),
<<<<<<< HEAD
                    border: Border.all(
                      color: selected ? const Color(0xFF9FE1CB) : _T.border,
                    ),
=======
                    border: Border.all(color: selected ? const Color(0xFF9FE1CB) : _T.border),
>>>>>>> develop
                  ),
                  child: Row(
                    children: [
                      Text(
                        opt.label,
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: selected ? FontWeight.w600 : FontWeight.w400,
                          color: selected ? _T.primaryDark : _T.textPrimary,
                        ),
                      ),
                      const Spacer(),
<<<<<<< HEAD
                      if (selected)
                        const Icon(Icons.check_rounded, color: _T.primary, size: 18),
=======
                      if (selected) const Icon(Icons.check_rounded, color: _T.primary, size: 18),
>>>>>>> develop
                    ],
                  ),
                ),
              );
            }),
          ],
        ),
      ),
    );
  }

  // ── LISTE ──
  Widget _buildList() {
<<<<<<< HEAD
    return Consumer<ServiceProvider>(
      builder: (context, provider, _) {
        if (provider.isLoading && provider.services.isEmpty) {
          return const Center(
            child: CircularProgressIndicator(color: _T.primary, strokeWidth: 2),
          );
        }

        final items = _filtered(provider.services);

        if (items.isEmpty) {
          return _buildEmptyState(provider.services.isEmpty);
        }

=======
    return Selector<
        ServiceProvider,
        ({
          List<ServiceModel> services,
          bool isLoading,
          bool isLoadingMore,
          bool hasMore,
        })>(
      selector: (_, provider) => (
        services: provider.services,
        isLoading: provider.isLoading,
        isLoadingMore: provider.isLoadingMore,
        hasMore: provider.hasMore,
      ),
      builder: (context, data, _) {
        if (data.isLoading && data.services.isEmpty) {
          return const Center(child: CircularProgressIndicator(color: _T.primary, strokeWidth: 2));
        }
        final items = _filtered(data.services);
        if (items.isEmpty) {
          return _buildEmptyState(data.services.isEmpty);
        }
>>>>>>> develop
        return RefreshIndicator(
          color: _T.primary,
          onRefresh: () => context.read<ServiceProvider>().loadAllServices(reset: true),
          child: ListView.builder(
            controller: _scrollController,
            padding: const EdgeInsets.fromLTRB(16, 14, 16, 16),
            itemCount: items.length + 1,
            itemBuilder: (context, index) {
              if (index == items.length) {
<<<<<<< HEAD
                return Consumer<ServiceProvider>(
                  builder: (_, p, __) {
                    if (p.isLoadingMore) {
                      return const Padding(
                        padding: EdgeInsets.symmetric(vertical: 16),
                        child: Center(child: CircularProgressIndicator(color: _T.primary, strokeWidth: 2)),
                      );
                    }
                    if (!p.hasMore) {
                      return const Padding(
                        padding: EdgeInsets.symmetric(vertical: 16),
                        child: Center(
                          child: Text(
                            'Toutes les annonces sont affichées',
                            style: TextStyle(color: _T.textTertiary, fontSize: 12),
                          ),
                        ),
                      );
                    }
                    return const SizedBox.shrink();
                  },
                );
=======
                if (data.isLoadingMore) {
                  return const Padding(
                    padding: EdgeInsets.symmetric(vertical: 16),
                    child: Center(child: CircularProgressIndicator(color: _T.primary, strokeWidth: 2)),
                  );
                }
                if (!data.hasMore) {
                  return const Padding(
                    padding: EdgeInsets.symmetric(vertical: 16),
                    child: Center(child: Text('Toutes les annonces sont affichées', style: TextStyle(color: _T.textTertiary, fontSize: 12))),
                  );
                }
                return const SizedBox.shrink();
>>>>>>> develop
              }
              return _ServiceTile(
                service: items[index],
                distance: _getDistance(items[index]),
                onTap: () => Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => ServiceDetailScreen(
                      service: items[index],
                      distanceKm: _getDistance(items[index]),
                    ),
                  ),
                ),
              );
            },
          ),
        );
      },
    );
  }

  // ── EMPTY STATE ──
  Widget _buildEmptyState(bool noData) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 72,
              height: 72,
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: _T.border),
              ),
              child: Icon(
                noData ? Icons.storefront_outlined : Icons.search_off_rounded,
                size: 36,
                color: _T.textTertiary,
              ),
            ),
            const SizedBox(height: 16),
            Text(
              noData ? 'Aucune annonce disponible' : 'Aucun résultat trouvé',
<<<<<<< HEAD
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: _T.textPrimary,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              noData
                  ? 'Soyez le premier à publier une annonce !'
                  : 'Essayez d\'augmenter le rayon ou de modifier les filtres.',
=======
              style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600, color: _T.textPrimary),
            ),
            const SizedBox(height: 6),
            Text(
              noData ? 'Soyez le premier à publier une annonce !' : 'Essayez d\'augmenter le rayon ou de modifier les filtres.',
>>>>>>> develop
              textAlign: TextAlign.center,
              style: const TextStyle(fontSize: 13, color: _T.textSecondary),
            ),
            if (!noData && _hasActiveFilters) ...[
              const SizedBox(height: 20),
              GestureDetector(
                onTap: _resetFilters,
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 11),
<<<<<<< HEAD
                  decoration: BoxDecoration(
                    color: _T.primary,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Text(
                    'Réinitialiser les filtres',
                    style: TextStyle(color: Colors.white, fontWeight: FontWeight.w600, fontSize: 13),
                  ),
=======
                  decoration: BoxDecoration(color: _T.primary, borderRadius: BorderRadius.circular(12)),
                  child: const Text('Réinitialiser les filtres', style: TextStyle(color: Colors.white, fontWeight: FontWeight.w600, fontSize: 13)),
>>>>>>> develop
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────
// TILE SERVICE
// ─────────────────────────────────────────────────
class _ServiceTile extends StatelessWidget {
  final ServiceModel service;
  final double? distance;
  final VoidCallback onTap;

  const _ServiceTile({
    required this.service,
    required this.distance,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final catColor = _T.catColor(service.categorie);
<<<<<<< HEAD
    final catBg    = _T.catBgColor(service.categorie);
=======
    final catBg = _T.catBgColor(service.categorie);
>>>>>>> develop
    final hasPhoto = service.photos.isNotEmpty;

    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.only(bottom: 10),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: _T.border, width: 0.5),
<<<<<<< HEAD
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.03),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Row(
          children: [
            // ── PHOTO ──
=======
          boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.03), blurRadius: 8, offset: const Offset(0, 2))],
        ),
        child: Row(
          children: [
>>>>>>> develop
            ClipRRect(
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(16),
                bottomLeft: Radius.circular(16),
              ),
              child: SizedBox(
                width: 92,
                height: 92,
                child: hasPhoto
                    ? Image.network(
                        service.photos.first,
                        fit: BoxFit.cover,
<<<<<<< HEAD
                        errorBuilder: (_, __, ___) => _photoPlaceholder(catBg, catColor),
=======
                        errorBuilder: (context, error, stackTrace) =>
                            _photoPlaceholder(catBg, catColor),
>>>>>>> develop
                      )
                    : _photoPlaceholder(catBg, catColor),
              ),
            ),
<<<<<<< HEAD

            // ── INFOS ──
=======
>>>>>>> develop
            Expanded(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(12, 10, 12, 10),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
<<<<<<< HEAD
                    // Badge + Cœur
=======
>>>>>>> develop
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
<<<<<<< HEAD
                          decoration: BoxDecoration(
                            color: catBg,
                            borderRadius: BorderRadius.circular(5),
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
                        const Icon(Icons.favorite_border_rounded, size: 16, color: _T.textTertiary),
                      ],
                    ),
                    const SizedBox(height: 5),

                    // Titre
                    Text(
                      service.titre,
                      style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: _T.textPrimary,
                        letterSpacing: -0.1,
                      ),
=======
                          decoration: BoxDecoration(color: catBg, borderRadius: BorderRadius.circular(5)),
                          child: Text(
                            service.categorie,
                            style: TextStyle(fontSize: 10, fontWeight: FontWeight.w600, color: catColor),
                          ),
                        ),
                        const Spacer(),
                        _FavoriteTileButton(serviceId: service.id),
                      ],
                    ),
                    const SizedBox(height: 5),
                    Text(
                      service.titre,
                      style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: _T.textPrimary, letterSpacing: -0.1),
>>>>>>> develop
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 2),
<<<<<<< HEAD

                    // Description
                    Text(
                      service.description,
                      style: const TextStyle(
                        fontSize: 11,
                        color: _T.textSecondary,
                      ),
=======
                    Text(
                      service.description,
                      style: const TextStyle(fontSize: 11, color: _T.textSecondary),
>>>>>>> develop
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 8),
<<<<<<< HEAD

                    // Prix + Distance
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
=======
                    Row(
                      children: [
                        Text(
                          service.prix > 0 ? '${service.prix.toStringAsFixed(0)} FCFA' : 'Négociable',
                          style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w700, color: _T.primary),
>>>>>>> develop
                        ),
                        const Spacer(),
                        if (distance != null) ...[
                          const Icon(Icons.location_on_rounded, size: 11, color: _T.textTertiary),
                          const SizedBox(width: 2),
<<<<<<< HEAD
                          Text(
                            GeoUtils.formatDistance(distance!),
                            style: const TextStyle(fontSize: 10, color: _T.textTertiary),
                          ),
=======
                          Text(GeoUtils.formatDistance(distance!), style: const TextStyle(fontSize: 10, color: _T.textTertiary)),
>>>>>>> develop
                          const SizedBox(width: 5),
                          _proximityBadge(distance!),
                        ] else if (service.ville.isNotEmpty) ...[
                          const Icon(Icons.location_on_rounded, size: 11, color: _T.textTertiary),
                          const SizedBox(width: 2),
                          Flexible(
                            child: Text(
                              service.ville.split(',').first,
                              style: const TextStyle(fontSize: 10, color: _T.textTertiary),
                              overflow: TextOverflow.ellipsis,
                            ),
<<<<<<< HEAD
>>>>>>> develop
=======
>>>>>>> develop
                          ),
                        ],
                      ],
                    ),
<<<<<<< HEAD
                  );
                }

                return RefreshIndicator(
                  color: primaryColor,
                  onRefresh: _loadData,
                  child: ListView.builder(
                    padding: const EdgeInsets.all(16),
                    itemCount: filtered.length,
                    itemBuilder: (context, index) {
                      final service = filtered[index];
                      return ServiceCard(
                        service: service,
                        distanceKm: _getDistance(service),
                        onTap: () => Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => ServiceDetailScreen(
                              service: service,
                              distanceKm: _getDistance(service),
                            ),
                          ),
                        ),
                      );
                    },
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
=======
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _proximityBadge(double km) {
    Color color;
    Color bg;
    String label;
    if (km <= 2) {
      color = const Color(0xFF085041);
<<<<<<< HEAD
      bg    = const Color(0xFFE1F5EE);
      label = 'Très proche';
    } else if (km <= 10) {
      color = const Color(0xFF633806);
      bg    = const Color(0xFFFAEEDA);
      label = 'Proche';
    } else {
      color = const Color(0xFF444441);
      bg    = const Color(0xFFF1EFE8);
      label = 'Éloigné';
    }
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(color: bg, borderRadius: BorderRadius.circular(4)),
      child: Text(label, style: TextStyle(fontSize: 9, fontWeight: FontWeight.w600, color: color)),
    );
  }

  Widget _photoPlaceholder(Color bg, Color color) {
    return Container(
      color: bg,
      child: Center(child: Icon(Icons.image_outlined, color: color, size: 26)),
    );
  }
>>>>>>> develop
}
=======
      bg = const Color(0xFFE1F5EE);
      label = 'Très proche';
    } else if (km <= 10) {
      color = const Color(0xFF633806);
      bg = const Color(0xFFFAEEDA);
      label = 'Proche';
    } else {
      color = const Color(0xFF444441);
      bg = const Color(0xFFF1EFE8);
      label = 'Éloigné';
    }
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(color: bg, borderRadius: BorderRadius.circular(4)),
      child: Text(label, style: TextStyle(fontSize: 9, fontWeight: FontWeight.w600, color: color)),
    );
  }

  Widget _photoPlaceholder(Color bg, Color color) {
    return Container(
      color: bg,
      child: Center(child: Icon(Icons.image_outlined, color: color, size: 26)),
    );
  }
}

// ─────────────────────────────────────────────────
// FAVORI BUTTON
// ─────────────────────────────────────────────────
class _FavoriteTileButton extends StatefulWidget {
  final String serviceId;
  const _FavoriteTileButton({required this.serviceId});

  @override
  State<_FavoriteTileButton> createState() => _FavoriteTileButtonState();
}

class _FavoriteTileButtonState extends State<_FavoriteTileButton> {
  final UserService _userService = UserService();
  bool _isFavorite = false;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadFavoriteState();
  }

  Future<void> _loadFavoriteState() async {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) {
      if (mounted) setState(() => _isLoading = false);
      return;
    }
    try {
      final favs = await _userService.getFavorites(uid);
      if (mounted) {
        setState(() {
          _isFavorite = favs.contains(widget.serviceId);
          _isLoading = false;
        });
      }
    } catch (_) {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _toggle() async {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) return;

    HapticFeedback.lightImpact();
    final previousState = _isFavorite;
    setState(() => _isFavorite = !_isFavorite);

    try {
      if (_isFavorite) {
        await _userService.addFavorite(uid, widget.serviceId);
      } else {
        await _userService.removeFavorite(uid, widget.serviceId);
      }
    } catch (_) {
      if (mounted) setState(() => _isFavorite = previousState);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const SizedBox(
        width: 28,
        height: 28,
        child: Center(
          child: SizedBox(
            width: 12,
            height: 12,
            child: CircularProgressIndicator(strokeWidth: 1.5, color: Color(0xFFB0B7C3)),
          ),
        ),
      );
    }

    return GestureDetector(
      onTap: _toggle,
      behavior: HitTestBehavior.opaque,
      child: Padding(
        padding: const EdgeInsets.all(4),
        child: AnimatedSwitcher(
          duration: const Duration(milliseconds: 200),
          child: Icon(
            _isFavorite ? Icons.favorite_rounded : Icons.favorite_border_rounded,
            key: ValueKey(_isFavorite),
            color: _isFavorite ? Colors.red : const Color(0xFFB0B7C3),
            size: 16,
          ),
        ),
      ),
    );
  }
}
>>>>>>> develop
