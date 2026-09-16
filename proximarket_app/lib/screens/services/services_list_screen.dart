import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../providers/service_provider.dart';
import '../../providers/category_provider.dart';
import '../../services/user_service.dart';
import '../../models/service_model.dart';
import '../../utils/geo_utils.dart';
import '../../widgets/favorite_button.dart';
import '../notifications/notifications_screen.dart';
import 'service_detail_screen.dart';

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

  static const catColors = <String, Color>{
    'Services': Color(0xFF085041),
    'Produits': Color(0xFF0C447C),
    'Immobilier': Color(0xFF633806),
    'Véhicules': Color(0xFF185FA5),
    'Agriculture': Color(0xFF27500A),
    'Emploi': Color(0xFFBA7517),
    'Événements': Color(0xFF72243E),
    'Autres': Color(0xFF444441),

    // Compatibilité avec d'anciennes annonces
    'Artisan': Color(0xFF085041),
    'Artiste': Color(0xFF27500A),
    'Éleveur': Color(0xFF633806),
    'Commerçant': Color(0xFF0C447C),
    'Commerce': Color(0xFF0C447C),
    'Plombier': Color(0xFF3C3489),
    'Électricien': Color(0xFF72243E),
    'Menuisier': Color(0xFF4A1B0C),
    'Électronique': Color(0xFF5538BE),
    'Autre': Color(0xFF444441),
  };

  static Color catColor(String cat) => catColors[cat] ?? primary;
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

enum _ViewMode { list, grid }

// ─────────────────────────────────────────────────
// PETIT STOCKAGE HISTORIQUE DE RECHERCHE
// ─────────────────────────────────────────────────
class _SearchHistoryStore {
  static const _key = 'search_history';
  static const _max = 8;

  static Future<List<String>> get() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getStringList(_key) ?? [];
  }

  static Future<void> add(String term) async {
    if (term.trim().isEmpty) return;

    final prefs = await SharedPreferences.getInstance();
    final list = prefs.getStringList(_key) ?? [];

    list.remove(term);
    list.insert(0, term);

    await prefs.setStringList(
      _key,
      list.take(_max).toList(),
    );
  }

  static Future<void> clear() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_key);
  }
}

// ─────────────────────────────────────────────────
// ÉCRAN
// ─────────────────────────────────────────────────
class ServicesListScreen extends StatefulWidget {
  final String? initialCategory;
  final SortOption? initialSort;

  const ServicesListScreen({
    super.key,
    this.initialCategory,
    this.initialSort,
  });

  @override
  State<ServicesListScreen> createState() =>
      _ServicesListScreenState();
}

class _ServicesListScreenState extends State<ServicesListScreen> {
  final UserService _userService = UserService();

  final TextEditingController _searchController =
      TextEditingController();

  final FocusNode _searchFocus = FocusNode();

  final ScrollController _scrollController =
      ScrollController();

  double? _myLat;
  double? _myLng;

  String _searchQuery = '';

  Timer? _debounceTimer;

  final Set<String> _selectedCategories = {};

  late SortOption _sortOption;

  double _radiusKm = 50.0;

  bool _forceResultsView = false;

  _ViewMode _viewMode = _ViewMode.list;

  List<String> _history = [];

  List<String> _favoriteIds = [];

  // ───────────────────────────────────────────────
  // CATÉGORIES MITAAN
  // ───────────────────────────────────────────────
  static const List<_CategoryItem> _categories = [
    _CategoryItem(
      Icons.apps_rounded,
      'Tout',
    ),
    _CategoryItem(
      Icons.build_rounded,
      'Services',
    ),
    _CategoryItem(
      Icons.shopping_bag_rounded,
      'Produits',
    ),
    _CategoryItem(
      Icons.home_work_rounded,
      'Immobilier',
    ),
    _CategoryItem(
      Icons.directions_car_filled_rounded,
      'Véhicules',
    ),
    _CategoryItem(
      Icons.agriculture_rounded,
      'Agriculture',
    ),
    _CategoryItem(
      Icons.work_outline_rounded,
      'Emploi',
    ),
    _CategoryItem(
      Icons.celebration_rounded,
      'Événements',
    ),
  ];

  // ───────────────────────────────────────────────
  // SUGGESTIONS
  // ───────────────────────────────────────────────
  static const List<String> _suggestions = [
    'Appartement à louer',
    'iPhone',
    'Voiture d\'occasion',
    'Coiffeuse à domicile',
    'Terrain à vendre',
    'Ménage',
  ];

  bool get _showResults =>
      _searchQuery.isNotEmpty ||
      _selectedCategories.isNotEmpty ||
      _forceResultsView;

  @override
  void initState() {
    super.initState();

    _sortOption =
        widget.initialSort ?? SortOption.distance;

    if (widget.initialCategory != null &&
        widget.initialCategory != 'Tout') {
      _selectedCategories.add(
        widget.initialCategory!,
      );
    }

    if (widget.initialSort != null) {
      _forceResultsView = true;
    }

    _loadData();
    _loadHistory();

    _scrollController.addListener(_onScroll);
  }

  @override
  void dispose() {
    _searchController.dispose();
    _searchFocus.dispose();

    _debounceTimer?.cancel();

    _scrollController.removeListener(_onScroll);
    _scrollController.dispose();

    super.dispose();
  }

  // ─────────────────────────────────────────────────
  // CHARGEMENT
  // ─────────────────────────────────────────────────
  Future<void> _loadData() async {
    await context
        .read<ServiceProvider>()
        .loadAllServices(reset: true);

    final uid =
        FirebaseAuth.instance.currentUser?.uid;

    if (uid != null) {
      final user =
          await _userService.getUserProfile(uid);

      final favs =
          await _userService.getFavorites(uid);

      if (user != null &&
          GeoUtils.isValidCoordinate(
            user.gpsLat,
            user.gpsLng,
          )) {
        if (mounted) {
          setState(() {
            _myLat = user.gpsLat;
            _myLng = user.gpsLng;
            _favoriteIds = favs;
          });
        }
      } else if (mounted) {
        setState(() {
          _favoriteIds = favs;
        });
      }
    }
  }

  Future<void> _loadHistory() async {
    final h = await _SearchHistoryStore.get();

    if (mounted) {
      setState(() {
        _history = h;
      });
    }
  }

  // ─────────────────────────────────────────────────
  // PAGINATION
  // ─────────────────────────────────────────────────
  void _onScroll() {
    final pos = _scrollController.position;

    if (pos.pixels >= pos.maxScrollExtent - 200) {
      final p = context.read<ServiceProvider>();

      if (p.hasMore && !p.isLoadingMore) {
        p.loadMoreServices();
      }
    }
  }

  // ─────────────────────────────────────────────────
  // RECHERCHE
  // ─────────────────────────────────────────────────
  void _onSearchChanged(String value) {
    _debounceTimer?.cancel();

    _debounceTimer = Timer(
      const Duration(milliseconds: 300),
      () {
        if (mounted) {
          setState(() {
            _searchQuery = value.trim();
          });
        }
      },
    );
  }

  void _runSearch(String term) {
    _searchController.text = term;

    _searchController.selection =
        TextSelection.collapsed(
      offset: term.length,
    );

    setState(() {
      _searchQuery = term.trim();
      _forceResultsView = true;
    });

    _searchFocus.unfocus();

    _SearchHistoryStore
        .add(term.trim())
        .then((_) => _loadHistory());
  }

  // ─────────────────────────────────────────────────
  // NOUVELLE RECHERCHE
  // ─────────────────────────────────────────────────
  void _newSearch() {
    setState(() {
      _searchController.clear();

      _searchQuery = '';

      _selectedCategories.clear();

      _sortOption = SortOption.distance;

      _radiusKm = 50.0;

      _forceResultsView = false;
    });
  }

  // ─────────────────────────────────────────────────
  // DISTANCE
  // ─────────────────────────────────────────────────
  double? _getDistance(ServiceModel s) {
    if (_myLat == null || _myLng == null) {
      return null;
    }

    if (!GeoUtils.isValidCoordinate(
      s.gpsLat,
      s.gpsLng,
    )) {
      return null;
    }

    return GeoUtils.distanceBetween(
      _myLat!,
      _myLng!,
      s.gpsLat,
      s.gpsLng,
    );
  }

  // ─────────────────────────────────────────────────
  // TEMPS
  // ─────────────────────────────────────────────────
  String _timeAgo(DateTime? dt) {
    if (dt == null) return '';

    final diff =
        DateTime.now().difference(dt);

    if (diff.inMinutes < 60) {
      return 'Il y a ${diff.inMinutes} min';
    }

    if (diff.inHours < 24) {
      return 'Il y a ${diff.inHours} h';
    }

    if (diff.inDays < 7) {
      return 'Il y a ${diff.inDays} j';
    }

    return 'Il y a ${(diff.inDays / 7).floor()} sem.';
  }

  // ─────────────────────────────────────────────────
  // FILTRAGE
  // ─────────────────────────────────────────────────
  List<ServiceModel> _filtered(
    List<ServiceModel> all,
  ) {
    var result =
        List<ServiceModel>.from(all);

    // Rayon géographique
    if (_myLat != null && _myLng != null) {
      result = result.where((s) {
        final d = _getDistance(s);

        return d == null ||
            d <= _radiusKm;
      }).toList();
    }

    // Catégories
    if (_selectedCategories.isNotEmpty) {
      result = result.where((s) {
        return _selectedCategories
            .contains(s.categorie);
      }).toList();
    }

    // Recherche textuelle
    if (_searchQuery.isNotEmpty) {
      final q =
          _searchQuery.toLowerCase();

      result = result.where((s) {
        return s.titre
                .toLowerCase()
                .contains(q) ||
            s.description
                .toLowerCase()
                .contains(q) ||
            s.categorie
                .toLowerCase()
                .contains(q) ||
            s.ville
                .toLowerCase()
                .contains(q);
      }).toList();

      result.sort((a, b) {
        final aStarts = a.titre
            .toLowerCase()
            .startsWith(q);

        final bStarts = b.titre
            .toLowerCase()
            .startsWith(q);

        if (aStarts && !bStarts) {
          return -1;
        }

        if (!aStarts && bStarts) {
          return 1;
        }

        return 0;
      });

      return result;
    }

    // Tri
    switch (_sortOption) {
      case SortOption.distance:
        result.sort(
          (a, b) =>
              (_getDistance(a) ??
                      double.infinity)
                  .compareTo(
            _getDistance(b) ??
                double.infinity,
          ),
        );
        break;

      case SortOption.prixCroissant:
        result.sort(
          (a, b) =>
              a.prix.compareTo(b.prix),
        );
        break;

      case SortOption.prixDecroissant:
        result.sort(
          (a, b) =>
              b.prix.compareTo(a.prix),
        );
        break;

      case SortOption.recent:
        result.sort(
          (a, b) =>
              (b.createdAt ??
                      DateTime(2000))
                  .compareTo(
            a.createdAt ??
                DateTime(2000),
          ),
        );
        break;
    }

    return result;
  }

  // ─────────────────────────────────────────────────
  // BUILD
  // ─────────────────────────────────────────────────
  @override
  Widget build(BuildContext context) {
    final cat =
        context.watch<CategoryProvider>().selectedCategory;

    if (cat != null) {
      WidgetsBinding.instance
          .addPostFrameCallback((_) {
        if (mounted) {
          setState(() {
            _selectedCategories.clear();

            if (cat != 'Tout') {
              _selectedCategories.add(cat);
            }

            _forceResultsView = true;
          });

          context
              .read<CategoryProvider>()
              .reset();
        }
      });
    }

    return Scaffold(
      backgroundColor: _T.bg,

      body: SafeArea(
        child: Column(
          children: [
            _buildHeader(),

            Expanded(
              child: _showResults
                  ? _buildResultsView()
                  : _buildDiscoveryView(),
            ),
          ],
        ),
      ),

      floatingActionButton: _showResults
          ? FloatingActionButton(
              backgroundColor: _T.primary,
              elevation: 2,
              onPressed: _showFiltersSheet,
              child: const Icon(
                Icons.tune_rounded,
                color: Colors.white,
              ),
            )
          : null,
    );
  }

  // ─────────────────────────────────────────────────
  // HEADER
  // ─────────────────────────────────────────────────
  Widget _buildHeader() {
    return Container(
      color: Colors.white,

      padding:
          const EdgeInsets.fromLTRB(
        12,
        8,
        20,
        12,
      ),

      child: Row(
        children: [
          IconButton(
            onPressed: () {
              if (Navigator.canPop(context)) {
                Navigator.pop(context);
              }
            },
            icon: const Icon(
              Icons.arrow_back_ios_new_rounded,
              size: 18,
              color: _T.textPrimary,
            ),
          ),

          Expanded(
            child: Container(
              height: 44,

              decoration: BoxDecoration(
                color: _T.bg,
                borderRadius:
                    BorderRadius.circular(12),
                border: Border.all(
                  color: _T.border,
                ),
              ),

              child: Row(
                children: [
                  const SizedBox(width: 12),

                  const Icon(
                    Icons.search_rounded,
                    color: _T.textTertiary,
                    size: 18,
                  ),

                  const SizedBox(width: 8),

                  Expanded(
                    child: TextField(
                      controller:
                          _searchController,
                      focusNode: _searchFocus,
                      onChanged:
                          _onSearchChanged,
                      onSubmitted:
                          _runSearch,
                      textInputAction:
                          TextInputAction.search,

                      style: const TextStyle(
                        fontSize: 13,
                        color:
                            _T.textPrimary,
                      ),

                      decoration:
                          const InputDecoration(
                        hintText:
                            'Que recherchez-vous ?',
                        hintStyle:
                            TextStyle(
                          fontSize: 13,
                          color:
                              _T.textTertiary,
                        ),
                        border:
                            InputBorder.none,
                        isDense: true,
                      ),
                    ),
                  ),

                  if (_searchController
                      .text
                      .isNotEmpty)
                    GestureDetector(
                      onTap: () {
                        _searchController
                            .clear();

                        setState(() {
                          _searchQuery = '';
                        });
                      },
                      child:
                          const Padding(
                        padding:
                            EdgeInsets.all(10),
                        child: Icon(
                          Icons
                              .close_rounded,
                          size: 16,
                          color:
                              _T.textTertiary,
                        ),
                      ),
                    ),
                ],
              ),
            ),
          ),

          const SizedBox(width: 8),

          GestureDetector(
            behavior:
                HitTestBehavior.opaque,

            onTap: () =>
                Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) =>
                    const NotificationsScreen(),
              ),
            ),

            child: Container(
              width: 40,
              height: 40,

              decoration:
                  BoxDecoration(
                color: _T.bg,
                borderRadius:
                    BorderRadius.circular(
                  12,
                ),
                border: Border.all(
                  color: _T.border,
                ),
              ),

              child: const Icon(
                Icons
                    .notifications_none_rounded,
                size: 19,
                color:
                    _T.textSecondary,
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ─────────────────────────────────────────────────
  // VUE DÉCOUVERTE
  // ─────────────────────────────────────────────────
  Widget _buildDiscoveryView() {
    return ListView(
      padding:
          const EdgeInsets.fromLTRB(
        20,
        8,
        20,
        24,
      ),

      children: [
        // HISTORIQUE
        if (_history.isNotEmpty) ...[
          Row(
            children: [
              const Text(
                'Recherches récentes',
                style: TextStyle(
                  fontSize: 14.5,
                  fontWeight:
                      FontWeight.w700,
                  color:
                      _T.textPrimary,
                ),
              ),

              const Spacer(),

              GestureDetector(
                onTap: () async {
                  await _SearchHistoryStore
                      .clear();

                  _loadHistory();
                },

                child: const Text(
                  'Effacer l\'historique',
                  style: TextStyle(
                    fontSize: 12,
                    color: _T.primary,
                    fontWeight:
                        FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),

          const SizedBox(height: 10),

          Wrap(
            spacing: 8,
            runSpacing: 8,

            children: _history
                .map(
                  (h) => _historyChip(h),
                )
                .toList(),
          ),

          const SizedBox(height: 24),
        ],

        // SUGGESTIONS
        const Text(
          'Suggestions',
          style: TextStyle(
            fontSize: 14.5,
            fontWeight:
                FontWeight.w700,
            color: _T.textPrimary,
          ),
        ),

        const SizedBox(height: 10),

        ..._suggestions.map(
          (s) => _suggestionTile(s),
        ),

        const SizedBox(height: 24),

        // CATÉGORIES
        const Text(
          'Catégories populaires',
          style: TextStyle(
            fontSize: 14.5,
            fontWeight:
                FontWeight.w700,
            color: _T.textPrimary,
          ),
        ),

        const SizedBox(height: 12),

        GridView.builder(
          shrinkWrap: true,

          physics:
              const NeverScrollableScrollPhysics(),

          gridDelegate:
              const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 4,
            mainAxisSpacing: 14,
            crossAxisSpacing: 10,
            childAspectRatio: 0.8,
          ),

          itemCount: _categories.length,

          itemBuilder:
              (context, i) {
            final cat =
                _categories[i];

            return GestureDetector(
              onTap: () {
                setState(() {
                  _selectedCategories
                      .clear();

                  if (cat.label !=
                      'Tout') {
                    _selectedCategories
                        .add(cat.label);
                  }

                  _forceResultsView =
                      true;
                });
              },

              child: Column(
                children: [
                  Container(
                    width: 52,
                    height: 52,

                    decoration:
                        BoxDecoration(
                      color: _T
                          .catColor(
                            cat.label,
                          )
                          .withValues(
                            alpha: 0.1,
                          ),
                      borderRadius:
                          BorderRadius
                              .circular(
                        15,
                      ),
                    ),

                    child: Icon(
                      cat.icon,
                      color:
                          _T.catColor(
                        cat.label,
                      ),
                      size: 24,
                    ),
                  ),

                  const SizedBox(
                    height: 6,
                  ),

                  Text(
                    cat.label,
                    textAlign:
                        TextAlign.center,
                    maxLines: 1,
                    overflow:
                        TextOverflow.ellipsis,

                    style:
                        const TextStyle(
                      fontSize: 10,
                      color:
                          _T.textSecondary,
                      fontWeight:
                          FontWeight.w500,
                    ),
                  ),
                ],
              ),
            );
          },
        ),
      ],
    );
  }

  // ─────────────────────────────────────────────────
  // HISTORIQUE
  // ─────────────────────────────────────────────────
  Widget _historyChip(
    String term,
  ) {
    return GestureDetector(
      onTap: () =>
          _runSearch(term),

      child: Container(
        padding:
            const EdgeInsets.symmetric(
          horizontal: 12,
          vertical: 8,
        ),

        decoration:
            BoxDecoration(
          color: Colors.white,
          borderRadius:
              BorderRadius.circular(20),
          border: Border.all(
            color: _T.border,
          ),
        ),

        child: Row(
          mainAxisSize:
              MainAxisSize.min,

          children: [
            const Icon(
              Icons.history_rounded,
              size: 14,
              color:
                  _T.textTertiary,
            ),

            const SizedBox(width: 6),

            Text(
              term,
              style:
                  const TextStyle(
                fontSize: 12.5,
                color:
                    _T.textSecondary,
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ─────────────────────────────────────────────────
  // SUGGESTION
  // ─────────────────────────────────────────────────
  Widget _suggestionTile(
    String s,
  ) {
    return GestureDetector(
      onTap: () =>
          _runSearch(s),

      child: Padding(
        padding:
            const EdgeInsets.symmetric(
          vertical: 9,
        ),

        child: Row(
          children: [
            const Icon(
              Icons.search_rounded,
              size: 16,
              color:
                  _T.textTertiary,
            ),

            const SizedBox(width: 10),

            Expanded(
              child: Text(
                s,
                style:
                    const TextStyle(
                  fontSize: 13.5,
                  color:
                      _T.textPrimary,
                ),
              ),
            ),

            const Icon(
              Icons.north_west_rounded,
              size: 14,
              color:
                  _T.textTertiary,
            ),
          ],
        ),
      ),
    );
  }

  // ─────────────────────────────────────────────────
  // VUE RÉSULTATS
  // ─────────────────────────────────────────────────
  Widget _buildResultsView() {
    return Selector<
        ServiceProvider,
        ({
          List<ServiceModel> services,
          bool isLoading,
          bool isLoadingMore,
          bool hasMore
        })>(
      selector: (_, provider) => (
        services: provider.services,
        isLoading: provider.isLoading,
        isLoadingMore:
            provider.isLoadingMore,
        hasMore: provider.hasMore,
      ),

      builder:
          (context, data, _) {
        if (data.isLoading &&
            data.services.isEmpty) {
          return const Center(
            child:
                CircularProgressIndicator(
              color: _T.primary,
              strokeWidth: 2,
            ),
          );
        }

        final items =
            _filtered(data.services);

        return Column(
          children: [
            _buildActiveFiltersRow(),

            _buildSortRow(
              items.length,
            ),

            Expanded(
              child: items.isEmpty
                  ? _buildEmptyResults()
                  : _viewMode ==
                          _ViewMode.list
                      ? _buildListView(
                          items,
                          data,
                        )
                      : _buildGridView(
                          items,
                          data,
                        ),
            ),
          ],
        );
      },
    );
  }

  // ─────────────────────────────────────────────────
  // FILTRES ACTIFS
  // ─────────────────────────────────────────────────
  Widget _buildActiveFiltersRow() {
    final chips = <Widget>[];

    if (_searchQuery.isNotEmpty) {
      chips.add(
        _filterChip(
          _searchQuery,
          () => setState(() {
            _searchController
                .clear();

            _searchQuery = '';
          }),
        ),
      );
    }

    for (final c
        in _selectedCategories) {
      chips.add(
        _filterChip(
          c,
          () => setState(
            () => _selectedCategories
                .remove(c),
          ),
        ),
      );
    }

    if (_radiusKm < 50.0) {
      chips.add(
        _filterChip(
          '${_radiusKm.round()} km',
          () => setState(
            () => _radiusKm = 50.0,
          ),
        ),
      );
    }

    if (chips.isEmpty) {
      return const SizedBox.shrink();
    }

    return Container(
      color: Colors.white,

      padding:
          const EdgeInsets.fromLTRB(
        20,
        10,
        20,
        12,
      ),

      child:
          SingleChildScrollView(
        scrollDirection:
            Axis.horizontal,

        child: Row(
          children: chips,
        ),
      ),
    );
  }

  // ─────────────────────────────────────────────────
  // CHIP FILTRE
  // ─────────────────────────────────────────────────
  Widget _filterChip(
    String label,
    VoidCallback onRemove,
  ) {
    return Container(
      margin:
          const EdgeInsets.only(
        right: 8,
      ),

      padding:
          const EdgeInsets.only(
        left: 12,
        right: 6,
        top: 6,
        bottom: 6,
      ),

      decoration:
          BoxDecoration(
        color: _T.primaryLight,
        borderRadius:
            BorderRadius.circular(20),
        border: Border.all(
          color:
              const Color(0xFF9FE1CB),
        ),
      ),

      child: Row(
        mainAxisSize:
            MainAxisSize.min,

        children: [
          Text(
            label,
            style:
                const TextStyle(
              fontSize: 12,
              fontWeight:
                  FontWeight.w600,
              color:
                  _T.primaryDark,
            ),
          ),

          const SizedBox(width: 4),

          GestureDetector(
            onTap: onRemove,

            child: const Icon(
              Icons.close_rounded,
              size: 15,
              color:
                  _T.primaryDark,
            ),
          ),
        ],
      ),
    );
  }

  // ─────────────────────────────────────────────────
  // TRI
  // ─────────────────────────────────────────────────
  Widget _buildSortRow(
    int count,
  ) {
    return Container(
      padding:
          const EdgeInsets.symmetric(
        horizontal: 20,
        vertical: 8,
      ),

      decoration:
          const BoxDecoration(
        color: Colors.white,
        border: Border(
          bottom: BorderSide(
            color: _T.border,
            width: 0.5,
          ),
        ),
      ),

      child: Row(
        children: [
          GestureDetector(
            onTap: _showSortSheet,

            child: Row(
              children: [
                const Icon(
                  Icons.swap_vert_rounded,
                  size: 16,
                  color:
                      _T.primary,
                ),

                const SizedBox(width: 4),

                Text(
                  'Trier : ${_sortOption.label}',
                  style:
                      const TextStyle(
                    fontSize: 12,
                    color:
                        _T.primary,
                    fontWeight:
                        FontWeight.w600,
                  ),
                ),

                const Icon(
                  Icons
                      .keyboard_arrow_down_rounded,
                  size: 16,
                  color:
                      _T.primary,
                ),
              ],
            ),
          ),

          const Spacer(),

          Text(
            '$count annonce${count > 1 ? 's' : ''}',
            style:
                const TextStyle(
              fontSize: 12,
              color:
                  _T.textSecondary,
            ),
          ),

          const SizedBox(width: 12),

          _viewToggleBtn(
            Icons.view_list_rounded,
            _ViewMode.list,
          ),

          const SizedBox(width: 4),

          _viewToggleBtn(
            Icons.grid_view_rounded,
            _ViewMode.grid,
          ),
        ],
      ),
    );
  }

  // ─────────────────────────────────────────────────
  // SWITCH LISTE / GRILLE
  // ─────────────────────────────────────────────────
  Widget _viewToggleBtn(
    IconData icon,
    _ViewMode mode,
  ) {
    final active =
        _viewMode == mode;

    return GestureDetector(
      onTap: () => setState(
        () => _viewMode = mode,
      ),

      child: Container(
        padding:
            const EdgeInsets.all(6),

        decoration:
            BoxDecoration(
          color: active
              ? _T.primaryLight
              : Colors.transparent,

          borderRadius:
              BorderRadius.circular(8),
        ),

        child: Icon(
          icon,
          size: 17,
          color: active
              ? _T.primary
              : _T.textTertiary,
        ),
      ),
    );
  }

  // ─────────────────────────────────────────────────
  // LISTE
  // ─────────────────────────────────────────────────
  Widget _buildListView(
    List<ServiceModel> items,
    dynamic data,
  ) {
    return RefreshIndicator(
      color: _T.primary,

      onRefresh: () => context
          .read<ServiceProvider>()
          .loadAllServices(
            reset: true,
          ),

      child: ListView.builder(
        controller:
            _scrollController,

        padding:
            const EdgeInsets.fromLTRB(
          16,
          12,
          16,
          90,
        ),

        itemCount:
            items.length + 2,

        itemBuilder:
            (context, index) {
          if (index ==
              items.length) {
            return _promoBanner();
          }

          if (index ==
              items.length + 1) {
            return _endOfResults(
              data,
            );
          }

          final s =
              items[index];

          return _ServiceListTile(
            service: s,

            distance:
                _getDistance(s),

            timeAgo:
                _timeAgo(
              s.createdAt,
            ),

            favorites:
                _favoriteIds,

            onTap: () =>
                Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) =>
                    ServiceDetailScreen(
                  service: s,
                  distanceKm:
                      _getDistance(s),
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  // ─────────────────────────────────────────────────
  // GRILLE
  // ─────────────────────────────────────────────────
  Widget _buildGridView(
    List<ServiceModel> items,
    dynamic data,
  ) {
    return RefreshIndicator(
      color: _T.primary,

      onRefresh: () => context
          .read<ServiceProvider>()
          .loadAllServices(
            reset: true,
          ),

      child:
          CustomScrollView(
        controller:
            _scrollController,

        slivers: [
          SliverPadding(
            padding:
                const EdgeInsets.fromLTRB(
              16,
              12,
              16,
              8,
            ),

            sliver:
                SliverGrid(
              gridDelegate:
                  const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 2,
                mainAxisSpacing: 12,
                crossAxisSpacing: 12,
                childAspectRatio: 0.72,
              ),

              delegate:
                  SliverChildBuilderDelegate(
                (context, index) {
                  final s =
                      items[index];

                  return _ServiceGridTile(
                    service: s,

                    distance:
                        _getDistance(s),

                    favorites:
                        _favoriteIds,

                    onTap: () =>
                        Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) =>
                            ServiceDetailScreen(
                          service: s,
                          distanceKm:
                              _getDistance(
                            s,
                          ),
                        ),
                      ),
                    ),
                  );
                },

                childCount:
                    items.length,
              ),
            ),
          ),

          SliverToBoxAdapter(
            child: Padding(
              padding:
                  const EdgeInsets.fromLTRB(
                16,
                8,
                16,
                90,
              ),

              child: Column(
                children: [
                  _promoBanner(),
                  _endOfResults(data),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ─────────────────────────────────────────────────
  // BANNIÈRE PREMIUM
  // ─────────────────────────────────────────────────
  Widget _promoBanner() {
    return Container(
      margin:
          const EdgeInsets.symmetric(
        vertical: 12,
      ),

      padding:
          const EdgeInsets.all(18),

      decoration:
          BoxDecoration(
        gradient:
            const LinearGradient(
          colors: [
            _T.primaryDark,
            _T.primary,
          ],

          begin:
              Alignment.topLeft,

          end:
              Alignment.bottomRight,
        ),

        borderRadius:
            BorderRadius.circular(18),
      ),

      child: Column(
        crossAxisAlignment:
            CrossAxisAlignment.start,

        children: [
          Container(
            padding:
                const EdgeInsets.symmetric(
              horizontal: 9,
              vertical: 4,
            ),

            decoration:
                BoxDecoration(
              color: Colors.white
                  .withValues(
                alpha: 0.2,
              ),

              borderRadius:
                  BorderRadius.circular(6),
            ),

            child: const Text(
              'PREMIUM',
              style: TextStyle(
                color: Colors.white,
                fontSize: 9.5,
                fontWeight:
                    FontWeight.w800,
                letterSpacing: 0.6,
              ),
            ),
          ),

          const SizedBox(
            height: 10,
          ),

          const Text(
            'Donnez plus de visibilité à votre annonce',
            style: TextStyle(
              color: Colors.white,
              fontSize: 15.5,
              fontWeight:
                  FontWeight.w800,
            ),
          ),

          const SizedBox(
            height: 4,
          ),

          Text(
            'Boostez votre annonce et touchez davantage de personnes près de vous.',
            style: TextStyle(
              color: Colors.white
                  .withValues(
                alpha: 0.85,
              ),
              fontSize: 12,
              height: 1.4,
            ),
          ),

          const SizedBox(
            height: 12,
          ),

          Container(
            padding:
                const EdgeInsets.symmetric(
              horizontal: 14,
              vertical: 9,
            ),

            decoration:
                BoxDecoration(
              color: Colors.white,
              borderRadius:
                  BorderRadius.circular(10),
            ),

            child: const Text(
              'Découvrir le Boost',
              style: TextStyle(
                color:
                    _T.primaryDark,
                fontSize: 12.5,
                fontWeight:
                    FontWeight.w700,
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ─────────────────────────────────────────────────
  // FIN DES RÉSULTATS
  // ─────────────────────────────────────────────────
  Widget _endOfResults(
    dynamic data,
  ) {
    if (data.isLoadingMore) {
      return const Padding(
        padding:
            EdgeInsets.symmetric(
          vertical: 16,
        ),

        child: Center(
          child:
              CircularProgressIndicator(
            color: _T.primary,
            strokeWidth: 2,
          ),
        ),
      );
    }

    if (data.hasMore) {
      return const SizedBox.shrink();
    }

    return Padding(
      padding:
          const EdgeInsets.symmetric(
        vertical: 20,
      ),

      child: Column(
        children: [
          const Text(
            'Vous avez atteint la fin des résultats',
            style: TextStyle(
              color:
                  _T.textTertiary,
              fontSize: 12.5,
            ),
          ),

          const SizedBox(
            height: 14,
          ),

          OutlinedButton(
            onPressed:
                _newSearch,

            style:
                OutlinedButton.styleFrom(
              side:
                  const BorderSide(
                color: _T.border,
              ),

              padding:
                  const EdgeInsets.symmetric(
                horizontal: 22,
                vertical: 11,
              ),

              shape:
                  RoundedRectangleBorder(
                borderRadius:
                    BorderRadius.circular(
                  12,
                ),
              ),
            ),

            child:
                const Text(
              'Nouvelle recherche',
              style: TextStyle(
                color:
                    _T.textPrimary,
                fontSize: 13,
                fontWeight:
                    FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ─────────────────────────────────────────────────
  // EMPTY STATE
  // ─────────────────────────────────────────────────
  Widget _buildEmptyResults() {
    return Center(
      child: Padding(
        padding:
            const EdgeInsets.all(32),

        child: Column(
          mainAxisAlignment:
              MainAxisAlignment.center,

          children: [
            Container(
              width: 72,
              height: 72,

              decoration:
                  BoxDecoration(
                color: Colors.white,
                borderRadius:
                    BorderRadius.circular(
                  20,
                ),

                border: Border.all(
                  color: _T.border,
                ),
              ),

              child: const Icon(
                Icons.search_off_rounded,
                size: 34,
                color:
                    _T.textTertiary,
              ),
            ),

            const SizedBox(
              height: 16,
            ),

            const Text(
              'Aucune annonce trouvée',
              style: TextStyle(
                fontSize: 16,
                fontWeight:
                    FontWeight.w700,
                color:
                    _T.textPrimary,
              ),
            ),

            const SizedBox(
              height: 6,
            ),

            const Text(
              'Essayez une autre recherche ou modifiez vos filtres.',
              textAlign:
                  TextAlign.center,

              style: TextStyle(
                fontSize: 13,
                color:
                    _T.textSecondary,
              ),
            ),

            const SizedBox(
              height: 20,
            ),

            GestureDetector(
              onTap:
                  _newSearch,

              child: Container(
                padding:
                    const EdgeInsets.symmetric(
                  horizontal: 20,
                  vertical: 11,
                ),

                decoration:
                    BoxDecoration(
                  color:
                      _T.primary,

                  borderRadius:
                      BorderRadius.circular(
                    12,
                  ),
                ),

                child: const Text(
                  'Nouvelle recherche',
                  style: TextStyle(
                    color:
                        Colors.white,
                    fontWeight:
                        FontWeight.w600,
                    fontSize: 13,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ─────────────────────────────────────────────────
  // BOTTOM SHEET TRI
  // ─────────────────────────────────────────────────
  void _showSortSheet() {
    showModalBottomSheet(
      context: context,
      backgroundColor:
          Colors.white,

      shape:
          const RoundedRectangleBorder(
        borderRadius:
            BorderRadius.vertical(
          top: Radius.circular(20),
        ),
      ),

      builder: (_) => Padding(
        padding:
            const EdgeInsets.fromLTRB(
          20,
          12,
          20,
          32,
        ),

        child: Column(
          mainAxisSize:
              MainAxisSize.min,

          crossAxisAlignment:
              CrossAxisAlignment.start,

          children: [
            Center(
              child: Container(
                width: 36,
                height: 4,

                decoration:
                    BoxDecoration(
                  color: _T.border,
                  borderRadius:
                      BorderRadius.circular(
                    2,
                  ),
                ),
              ),
            ),

            const SizedBox(
              height: 16,
            ),

            const Text(
              'Trier par',
              style: TextStyle(
                fontSize: 16,
                fontWeight:
                    FontWeight.w700,
                color:
                    _T.textPrimary,
              ),
            ),

            const SizedBox(
              height: 12,
            ),

            ...SortOption.values.map(
              (opt) {
                final selected =
                    _sortOption ==
                        opt;

                return GestureDetector(
                  onTap: () {
                    setState(() {
                      _sortOption =
                          opt;

                      _forceResultsView =
                          true;
                    });

                    Navigator.pop(
                      context,
                    );
                  },

                  child: Container(
                    width:
                        double.infinity,

                    padding:
                        const EdgeInsets.symmetric(
                      vertical: 13,
                      horizontal: 14,
                    ),

                    margin:
                        const EdgeInsets.only(
                      bottom: 8,
                    ),

                    decoration:
                        BoxDecoration(
                      color: selected
                          ? _T.primaryLight
                          : _T.bg,

                      borderRadius:
                          BorderRadius.circular(
                        12,
                      ),

                      border:
                          Border.all(
                        color: selected
                            ? const Color(
                                0xFF9FE1CB,
                              )
                            : _T.border,
                      ),
                    ),

                    child: Row(
                      children: [
                        Text(
                          opt.label,

                          style:
                              TextStyle(
                            fontSize: 14,
                            fontWeight:
                                selected
                                    ? FontWeight
                                        .w600
                                    : FontWeight
                                        .w400,

                            color: selected
                                ? _T
                                    .primaryDark
                                : _T
                                    .textPrimary,
                          ),
                        ),

                        const Spacer(),

                        if (selected)
                          const Icon(
                            Icons
                                .check_rounded,
                            color:
                                _T.primary,
                            size: 18,
                          ),
                      ],
                    ),
                  ),
                );
              },
            ),
          ],
        ),
      ),
    );
  }

  // ─────────────────────────────────────────────────
  // BOTTOM SHEET FILTRES
  // ─────────────────────────────────────────────────
  void _showFiltersSheet() {
    double tempRadius =
        _radiusKm;

    showModalBottomSheet(
      context: context,
      backgroundColor:
          Colors.white,

      shape:
          const RoundedRectangleBorder(
        borderRadius:
            BorderRadius.vertical(
          top: Radius.circular(20),
        ),
      ),

      builder: (_) =>
          StatefulBuilder(
        builder:
            (ctx, setSheet) =>
                Padding(
          padding:
              const EdgeInsets.fromLTRB(
            20,
            12,
            20,
            32,
          ),

          child: Column(
            mainAxisSize:
                MainAxisSize.min,

            crossAxisAlignment:
                CrossAxisAlignment.start,

            children: [
              Center(
                child: Container(
                  width: 36,
                  height: 4,

                  decoration:
                      BoxDecoration(
                    color: _T.border,
                    borderRadius:
                        BorderRadius.circular(
                      2,
                    ),
                  ),
                ),
              ),

              const SizedBox(
                height: 16,
              ),

              const Text(
                'Filtrer les annonces',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight:
                      FontWeight.w700,
                  color:
                      _T.textPrimary,
                ),
              ),

              const SizedBox(
                height: 20,
              ),

              Row(
                children: [
                  const Icon(
                    Icons.radar_rounded,
                    color:
                        _T.primary,
                    size: 16,
                  ),

                  const SizedBox(
                    width: 6,
                  ),

                  Text(
                    'Rayon : ${tempRadius.round()} km',
                    style:
                        const TextStyle(
                      fontSize: 13,
                      fontWeight:
                          FontWeight.w600,
                      color:
                          _T.textPrimary,
                    ),
                  ),

                  const Spacer(),

                  if (_myLat == null)
                    const Text(
                      'Position non disponible',
                      style:
                          TextStyle(
                        color:
                            Colors.orange,
                        fontSize: 11,
                      ),
                    ),
                ],
              ),

              SliderTheme(
                data:
                    SliderTheme.of(
                  context,
                ).copyWith(
                  activeTrackColor:
                      _T.primary,

                  inactiveTrackColor:
                      _T.primaryLight,

                  thumbColor:
                      _T.primary,

                  overlayColor:
                      _T.primary
                          .withValues(
                    alpha: 0.1,
                  ),

                  trackHeight: 3,

                  thumbShape:
                      const RoundSliderThumbShape(
                    enabledThumbRadius:
                        7,
                  ),
                ),

                child: Slider(
                  value:
                      tempRadius,

                  min: 1,
                  max: 50,
                  divisions: 49,

                  label:
                      '${tempRadius.round()} km',

                  onChanged:
                      _myLat != null
                          ? (v) =>
                              setSheet(
                                () =>
                                    tempRadius =
                                        v,
                              )
                          : null,
                ),
              ),

              const SizedBox(
                height: 16,
              ),

              const Text(
                'Catégories',
                style: TextStyle(
                  fontSize: 13,
                  fontWeight:
                      FontWeight.w600,
                  color:
                      _T.textPrimary,
                ),
              ),

              const SizedBox(
                height: 10,
              ),

              Wrap(
                spacing: 8,
                runSpacing: 8,

                children:
                    _categories
                        .where(
                          (c) =>
                              c.label !=
                              'Tout',
                        )
                        .map(
                          (c) {
                            final sel =
                                _selectedCategories
                                    .contains(
                              c.label,
                            );

                            return GestureDetector(
                              onTap: () =>
                                  setSheet(
                                () {
                                  if (sel) {
                                    _selectedCategories
                                        .remove(
                                      c.label,
                                    );
                                  } else {
                                    _selectedCategories
                                        .add(
                                      c.label,
                                    );
                                  }
                                },
                              ),

                              child:
                                  Container(
                                padding:
                                    const EdgeInsets
                                        .symmetric(
                                  horizontal:
                                      12,
                                  vertical: 8,
                                ),

                                decoration:
                                    BoxDecoration(
                                  color: sel
                                      ? _T
                                          .primary
                                      : Colors
                                          .white,

                                  borderRadius:
                                      BorderRadius
                                          .circular(
                                    20,
                                  ),

                                  border:
                                      Border.all(
                                    color: sel
                                        ? _T
                                            .primary
                                        : _T
                                            .border,
                                  ),
                                ),

                                child:
                                    Text(
                                  c.label,

                                  style:
                                      TextStyle(
                                    fontSize:
                                        12,

                                    color: sel
                                        ? Colors
                                            .white
                                        : _T
                                            .textSecondary,

                                    fontWeight:
                                        FontWeight
                                            .w500,
                                  ),
                                ),
                              ),
                            );
                          },
                        )
                        .toList(),
              ),

              const SizedBox(
                height: 22,
              ),

              SizedBox(
                width:
                    double.infinity,

                height: 50,

                child:
                    ElevatedButton(
                  style:
                      ElevatedButton
                          .styleFrom(
                    backgroundColor:
                        _T.primary,

                    foregroundColor:
                        Colors.white,

                    shape:
                        RoundedRectangleBorder(
                      borderRadius:
                          BorderRadius
                              .circular(
                        12,
                      ),
                    ),

                    elevation: 0,
                  ),

                  onPressed: () {
                    setState(() {
                      _radiusKm =
                          tempRadius;

                      _forceResultsView =
                          true;
                    });

                    Navigator.pop(
                      ctx,
                    );
                  },

                  child:
                      const Text(
                    'Appliquer',
                    style: TextStyle(
                      fontSize: 15,
                      fontWeight:
                          FontWeight.w600,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────
// CARTE — MODE LISTE
// ─────────────────────────────────────────────────
class _ServiceListTile
    extends StatelessWidget {
  final ServiceModel service;
  final double? distance;
  final String timeAgo;
  final List<String> favorites;
  final VoidCallback onTap;

  const _ServiceListTile({
    required this.service,
    required this.distance,
    required this.timeAgo,
    required this.favorites,
    required this.onTap,
  });

  @override
  Widget build(
    BuildContext context,
  ) {
    final catColor =
        _T.catColor(
      service.categorie,
    );

    final hasPhoto =
        service.photos.isNotEmpty;

    return GestureDetector(
      onTap: onTap,

      child: Container(
        margin:
            const EdgeInsets.only(
          bottom: 12,
        ),

        decoration:
            BoxDecoration(
          color: Colors.white,

          borderRadius:
              BorderRadius.circular(
            16,
          ),

          border: Border.all(
            color: _T.border,
            width: 0.5,
          ),

          boxShadow: [
            BoxShadow(
              color: Colors.black
                  .withValues(
                alpha: 0.03,
              ),

              blurRadius: 8,

              offset:
                  const Offset(0, 2),
            ),
          ],
        ),

        child: Row(
          children: [
            ClipRRect(
              borderRadius:
                  const BorderRadius
                      .only(
                topLeft:
                    Radius.circular(
                  16,
                ),

                bottomLeft:
                    Radius.circular(
                  16,
                ),
              ),

              child: SizedBox(
                width: 96,
                height: 96,

                child: hasPhoto
                    ? Image.network(
                        service.photos
                            .first,

                        fit:
                            BoxFit.cover,

                        errorBuilder:
                            (
                          _,
                          __,
                          ___,
                        ) =>
                            _placeholder(
                          catColor,
                        ),
                      )
                    : _placeholder(
                        catColor,
                      ),
              ),
            ),

            Expanded(
              child: Padding(
                padding:
                    const EdgeInsets
                        .fromLTRB(
                  12,
                  10,
                  8,
                  10,
                ),

                child: Column(
                  crossAxisAlignment:
                      CrossAxisAlignment
                          .start,

                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            service.titre,

                            style:
                                const TextStyle(
                              fontSize:
                                  14,
                              fontWeight:
                                  FontWeight
                                      .w600,
                              color:
                                  _T.textPrimary,
                            ),

                            maxLines: 1,

                            overflow:
                                TextOverflow
                                    .ellipsis,
                          ),
                        ),

                        FavoriteButton(
                          serviceId:
                              service.id,
                          favorites:
                              favorites,
                          size: 18,
                        ),
                      ],
                    ),

                    const SizedBox(
                      height: 4,
                    ),

                    Text(
                      service.prix > 0
                          ? '${service.prix.toStringAsFixed(0)} FCFA'
                          : 'Prix à négocier',

                      style:
                          const TextStyle(
                        fontSize:
                            14.5,
                        fontWeight:
                            FontWeight
                                .w800,
                        color:
                            _T.primary,
                      ),
                    ),

                    const SizedBox(
                      height: 6,
                    ),

                    Row(
                      children: [
                        const Icon(
                          Icons
                              .location_on_rounded,
                          size: 12,
                          color:
                              _T.textTertiary,
                        ),

                        const SizedBox(
                          width: 2,
                        ),

                        Flexible(
                          child: Text(
                            service.ville
                                    .isNotEmpty
                                ? service
                                    .ville
                                    .split(
                                      ',',
                                    )
                                    .first
                                : 'Localisation inconnue',

                            style:
                                const TextStyle(
                              fontSize:
                                  11,
                              color:
                                  _T.textTertiary,
                            ),

                            overflow:
                                TextOverflow
                                    .ellipsis,
                          ),
                        ),

                        Text(
                          distance !=
                                  null
                              ? '  •  ${GeoUtils.formatDistance(distance!)}'
                              : '',

                          style:
                              const TextStyle(
                            fontSize:
                                11,
                            color:
                                _T.textTertiary,
                          ),
                        ),
                      ],
                    ),

                    const SizedBox(
                      height: 2,
                    ),

                    Text(
                      timeAgo,

                      style:
                          const TextStyle(
                        fontSize:
                            10.5,
                        color:
                            _T.textTertiary,
                      ),
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

  Widget _placeholder(
    Color color,
  ) {
    return Container(
      color: color.withValues(
        alpha: 0.1,
      ),

      child: Icon(
        Icons.image_outlined,
        color: color,
        size: 26,
      ),
    );
  }
}

// ─────────────────────────────────────────────────
// CARTE — MODE GRILLE
// ─────────────────────────────────────────────────
class _ServiceGridTile
    extends StatelessWidget {
  final ServiceModel service;
  final double? distance;
  final List<String> favorites;
  final VoidCallback onTap;

  const _ServiceGridTile({
    required this.service,
    required this.distance,
    required this.favorites,
    required this.onTap,
  });

  @override
  Widget build(
    BuildContext context,
  ) {
    final catColor =
        _T.catColor(
      service.categorie,
    );

    final hasPhoto =
        service.photos.isNotEmpty;

    return GestureDetector(
      onTap: onTap,

      child: Container(
        decoration:
            BoxDecoration(
          color: Colors.white,

          borderRadius:
              BorderRadius.circular(
            16,
          ),

          border: Border.all(
            color: _T.border,
            width: 0.5,
          ),

          boxShadow: [
            BoxShadow(
              color: Colors.black
                  .withValues(
                alpha: 0.04,
              ),

              blurRadius: 10,

              offset:
                  const Offset(0, 3),
            ),
          ],
        ),

        child: Column(
          crossAxisAlignment:
              CrossAxisAlignment.start,

          children: [
            Stack(
              children: [
                ClipRRect(
                  borderRadius:
                      const BorderRadius
                          .vertical(
                    top:
                        Radius.circular(
                      16,
                    ),
                  ),

                  child: AspectRatio(
                    aspectRatio: 1.3,

                    child: hasPhoto
                        ? Image.network(
                            service
                                .photos
                                .first,

                            fit:
                                BoxFit.cover,

                            width:
                                double.infinity,

                            errorBuilder:
                                (
                              _,
                              __,
                              ___,
                            ) =>
                                _placeholder(
                              catColor,
                            ),
                          )
                        : _placeholder(
                            catColor,
                          ),
                  ),
                ),

                Positioned(
                  right: 6,
                  top: 6,

                  child: Container(
                    decoration:
                        BoxDecoration(
                      color: Colors
                          .white
                          .withValues(
                        alpha: 0.92,
                      ),

                      shape:
                          BoxShape.circle,
                    ),

                    child:
                        FavoriteButton(
                      serviceId:
                          service.id,
                      favorites:
                          favorites,
                      size: 15,
                    ),
                  ),
                ),
              ],
            ),

            Padding(
              padding:
                  const EdgeInsets
                      .fromLTRB(
                10,
                8,
                10,
                10,
              ),

              child: Column(
                crossAxisAlignment:
                    CrossAxisAlignment
                        .start,

                children: [
                  Text(
                    service.titre,

                    style:
                        const TextStyle(
                      fontSize: 12.5,
                      fontWeight:
                          FontWeight.w600,
                      color:
                          _T.textPrimary,
                    ),

                    maxLines: 1,

                    overflow:
                        TextOverflow
                            .ellipsis,
                  ),

                  const SizedBox(
                    height: 5,
                  ),

                  Text(
                    service.prix > 0
                        ? '${service.prix.toStringAsFixed(0)} FCFA'
                        : 'À négocier',

                    style:
                        const TextStyle(
                      fontSize: 13,
                      fontWeight:
                          FontWeight.w800,
                      color:
                          _T.primary,
                    ),
                  ),

                  const SizedBox(
                    height: 5,
                  ),

                  Row(
                    children: [
                      const Icon(
                        Icons
                            .location_on_rounded,
                        size: 10,
                        color:
                            _T.textTertiary,
                      ),

                      const SizedBox(
                        width: 2,
                      ),

                      Expanded(
                        child: Text(
                          service.ville
                                  .isNotEmpty
                              ? service
                                  .ville
                                  .split(
                                    ',',
                                  )
                                  .first
                              : '—',

                          style:
                              const TextStyle(
                            fontSize:
                                10,
                            color:
                                _T.textTertiary,
                          ),

                          maxLines: 1,

                          overflow:
                              TextOverflow
                                  .ellipsis,
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

  Widget _placeholder(
    Color color,
  ) {
    return Container(
      color: color.withValues(
        alpha: 0.1,
      ),

      child: Icon(
        Icons.image_outlined,
        color: color,
        size: 26,
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

  const _CategoryItem(
    this.icon,
    this.label,
  );
}