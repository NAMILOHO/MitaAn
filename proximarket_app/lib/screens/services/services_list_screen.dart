import 'dart:async';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:firebase_auth/firebase_auth.dart';

import '../../providers/service_provider.dart';
import '../../services/user_service.dart';
import '../../models/service_model.dart';
import '../../utils/geo_utils.dart';
import '../../services/user_service.dart';
import 'service_detail_screen.dart';

// ─────────────────────────────────────────────────
// THÈME
// ─────────────────────────────────────────────────
class _T {
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
class ServicesListScreen extends StatefulWidget {
  const ServicesListScreen({super.key});

  @override
  State<ServicesListScreen> createState() => _ServicesListScreenState();
}

class _ServicesListScreenState extends State<ServicesListScreen> {
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
  ];

  @override
  void initState() {
    super.initState();
    _loadData();
    _scrollController.addListener(_onScroll);
  }

  @override
  void dispose() {
    _searchController.dispose();
    _debounceTimer?.cancel();
    _scrollController.removeListener(_onScroll);
    _scrollController.dispose();
    super.dispose();
  }

  Future<void> _loadData() async {
    await context.read<ServiceProvider>().loadAllServices(reset: true);
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid != null) {
      final user = await _userService.getUserProfile(uid);
      if (user != null && GeoUtils.isValidCoordinate(user.gpsLat, user.gpsLng)) {
        if (mounted) setState(() { _myLat = user.gpsLat; _myLng = user.gpsLng; });
      }
    }
  }

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
        left: 20, right: 20, bottom: 0,
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
                ),
              ),
              const Spacer(),
              if (_myLat == null)
                const Text(
                  'Position non disponible',
                  style: TextStyle(color: Colors.orange, fontSize: 11),
                ),
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
              min: 1, max: 50, divisions: 49,
              label: '${_radiusKm.round()} km',
              onChanged: _myLat != null ? (v) => setState(() => _radiusKm = v) : null,
            ),
          ),
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
                    Text(
                      'Réinitialiser les filtres',
                      style: TextStyle(color: Color(0xFFA32D2D), fontSize: 13, fontWeight: FontWeight.w500),
                    ),
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
                  if (sel) _selectedCategories.remove(cat);
                  else _selectedCategories.add(cat);
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
          border: Border.all(
            color: selected ? _T.primary : _T.border,
          ),
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
            border: Border(
              bottom: BorderSide(color: _T.border, width: 0.5),
            ),
          ),
          child: Row(
            children: [
              Text(
                '$count annonce${count > 1 ? 's' : ''} trouvée${count > 1 ? 's' : ''}',
                style: const TextStyle(
                  fontSize: 12,
                  color: _T.textSecondary,
                ),
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
                      style: const TextStyle(
                        fontSize: 12,
                        color: _T.primary,
                        fontWeight: FontWeight.w600,
                      ),
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
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (_) => Padding(
        padding: const EdgeInsets.fromLTRB(20, 12, 20, 32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
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
                    border: Border.all(
                      color: selected ? const Color(0xFF9FE1CB) : _T.border,
                    ),
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
                      if (selected)
                        const Icon(Icons.check_rounded, color: _T.primary, size: 18),
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

        return RefreshIndicator(
          color: _T.primary,
          onRefresh: () => context.read<ServiceProvider>().loadAllServices(reset: true),
          child: ListView.builder(
            controller: _scrollController,
            padding: const EdgeInsets.fromLTRB(16, 14, 16, 16),
            itemCount: items.length + 1,
            itemBuilder: (context, index) {
              if (index == items.length) {
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
              textAlign: TextAlign.center,
              style: const TextStyle(fontSize: 13, color: _T.textSecondary),
            ),
            if (!noData && _hasActiveFilters) ...[
              const SizedBox(height: 20),
              GestureDetector(
                onTap: _resetFilters,
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 11),
                  decoration: BoxDecoration(
                    color: _T.primary,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Text(
                    'Réinitialiser les filtres',
                    style: TextStyle(color: Colors.white, fontWeight: FontWeight.w600, fontSize: 13),
                  ),
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
    final catBg    = _T.catBgColor(service.categorie);
    final hasPhoto = service.photos.isNotEmpty;

    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.only(bottom: 10),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: _T.border, width: 0.5),
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
                        errorBuilder: (_, __, ___) => _photoPlaceholder(catBg, catColor),
                      )
                    : _photoPlaceholder(catBg, catColor),
              ),
            ),

            // ── INFOS ──
            Expanded(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(12, 10, 12, 10),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Badge + Cœur
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
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
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 2),

                    // Description
                    Text(
                      service.description,
                      style: const TextStyle(
                        fontSize: 11,
                        color: _T.textSecondary,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 8),

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
                        ),
                        const Spacer(),
                        if (distance != null) ...[
                          const Icon(Icons.location_on_rounded, size: 11, color: _T.textTertiary),
                          const SizedBox(width: 2),
                          Text(
                            GeoUtils.formatDistance(distance!),
                            style: const TextStyle(fontSize: 10, color: _T.textTertiary),
                          ),
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
                          ),
                        ],
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

  Widget _proximityBadge(double km) {
    Color color;
    Color bg;
    String label;
    if (km <= 2) {
      color = const Color(0xFF085041);
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
}