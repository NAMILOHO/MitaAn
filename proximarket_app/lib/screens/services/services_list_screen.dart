import 'dart:async';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:firebase_auth/firebase_auth.dart';

import '../../providers/service_provider.dart';
import '../../services/user_service.dart';
import '../../models/service_model.dart';
import '../../utils/geo_utils.dart';
import 'service_detail_screen.dart';

// ─────────────────────────────────────────
// OPTIONS DE TRI
// ─────────────────────────────────────────
enum SortOption {
  distance('Plus proche'),
  prixCroissant('Prix croissant'),
  prixDecroissant('Prix décroissant'),
  recent('Plus récent');

  final String label;
  const SortOption(this.label);
}

class ServicesListScreen extends StatefulWidget {
  const ServicesListScreen({super.key});

  @override
  State<ServicesListScreen> createState() => _ServicesListScreenState();
}

class _ServicesListScreenState extends State<ServicesListScreen> {
  final UserService _userService = UserService();
  final TextEditingController _searchController = TextEditingController();

  // ScrollController pour la pagination infinie
  final ScrollController _scrollController = ScrollController();

  // Position de l'utilisateur
  double? _myLat;
  double? _myLng;

  // Recherche
  String _searchQuery = '';
  Timer? _debounceTimer;

  // Filtres
  final Set<String> _selectedCategories = {};
  SortOption _sortOption = SortOption.distance;
  double _radiusKm = 50.0;
  bool _showFiltersPanel = false;

  static const Color primaryColor = Color(0xFF1D9E75);

  final List<String> _categories = [
    'Artisan',
    'Artiste',
    'Éleveur',
    'Commerçant',
    'Plombier',
    'Électricien',
    'Menuisier',
    'Autre',
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

  // =============================================
  // CHARGEMENT INITIAL
  // =============================================
  Future<void> _loadData() async {
    await context.read<ServiceProvider>().loadAllServices(reset: true);

    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid != null) {
      final user = await _userService.getUserProfile(uid);
      if (user != null && GeoUtils.isValidCoordinate(user.gpsLat, user.gpsLng)) {
        if (mounted) {
          setState(() {
            _myLat = user.gpsLat;
            _myLng = user.gpsLng;
          });
        }
      }
    }
  }

  // =============================================
  // SCROLL INFINI
  // =============================================
  void _onScroll() {
    final position = _scrollController.position;
    if (position.pixels >= position.maxScrollExtent - 200) {
      final provider = context.read<ServiceProvider>();
      if (provider.hasMore && !provider.isLoadingMore) {
        provider.loadMoreServices();
      }
    }
  }

  // =============================================
  // DEBOUNCE RECHERCHE
  // =============================================
  void _onSearchChanged(String value) {
    _debounceTimer?.cancel();
    _debounceTimer = Timer(const Duration(milliseconds: 300), () {
      if (mounted) setState(() => _searchQuery = value.toLowerCase().trim());
    });
  }

  // =============================================
  // DISTANCE
  // =============================================
  double? _getDistance(ServiceModel service) {
    if (_myLat == null || _myLng == null) return null;
    if (!GeoUtils.isValidCoordinate(service.gpsLat, service.gpsLng)) return null;
    return GeoUtils.distanceBetween(
      _myLat!,
      _myLng!,
      service.gpsLat,
      service.gpsLng,
    );
  }

  // =============================================
  // FILTRAGE + TRI
  // =============================================
  List<ServiceModel> _getFilteredAndSorted(List<ServiceModel> all) {
    List<ServiceModel> result = all;

    // Filtre rayon
    if (_myLat != null && _myLng != null) {
      result = result.where((s) {
        final dist = _getDistance(s);
        if (dist == null) return true;
        return dist <= _radiusKm;
      }).toList();
    }

    // Filtre catégories
    if (_selectedCategories.isNotEmpty) {
      result = result.where((s) => _selectedCategories.contains(s.categorie)).toList();
    }

    // Recherche texte
    if (_searchQuery.isNotEmpty) {
      result = result.where((s) {
        return s.titre.toLowerCase().contains(_searchQuery) ||
            s.description.toLowerCase().contains(_searchQuery) ||
            s.categorie.toLowerCase().contains(_searchQuery) ||
            s.ville.toLowerCase().contains(_searchQuery);
      }).toList();

      result.sort((a, b) {
        final aStarts = a.titre.toLowerCase().startsWith(_searchQuery);
        final bStarts = b.titre.toLowerCase().startsWith(_searchQuery);
        if (aStarts && !bStarts) return -1;
        if (!aStarts && bStarts) return 1;
        return 0;
      });
      return result;
    }

    // Tri
    switch (_sortOption) {
      case SortOption.distance:
        result.sort((a, b) {
          final da = _getDistance(a) ?? double.infinity;
          final db = _getDistance(b) ?? double.infinity;
          return da.compareTo(db);
        });
      case SortOption.prixCroissant:
        result.sort((a, b) => a.prix.compareTo(b.prix));
      case SortOption.prixDecroissant:
        result.sort((a, b) => b.prix.compareTo(a.prix));
      case SortOption.recent:
        result.sort((a, b) {
          final da = a.createdAt ?? DateTime(2000);
          final db = b.createdAt ?? DateTime(2000);
          return db.compareTo(da);
        });
    }
    return result;
  }

  void _resetFilters() {
    setState(() {
      _searchController.clear();
      _searchQuery = '';
      _selectedCategories.clear();
      _sortOption = SortOption.distance;
      _radiusKm = 50.0;
    });
  }

  bool get _hasActiveFilters =>
      _searchQuery.isNotEmpty ||
      _selectedCategories.isNotEmpty ||
      _sortOption != SortOption.distance ||
      _radiusKm < 50.0;

  // =============================================
  // BUILD
  // =============================================
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F5F5),
      appBar: AppBar(
        backgroundColor: primaryColor,
        automaticallyImplyLeading: false,
        elevation: 0,
        title: const Text('Annonces', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
        actions: [
          IconButton(
            icon: Stack(
              children: [
                Icon(Icons.tune, color: _hasActiveFilters ? Colors.amber : Colors.white),
                if (_hasActiveFilters)
                  Positioned(right: 0, top: 0, child: Container(width: 8, height: 8, decoration: const BoxDecoration(color: Colors.amber, shape: BoxShape.circle))),
              ],
            ),
            onPressed: () => setState(() => _showFiltersPanel = !_showFiltersPanel),
          ),
          IconButton(icon: const Icon(Icons.refresh, color: Colors.white), onPressed: _loadData),
        ],
      ),
      body: Column(
        children: [
          // Barre de recherche
          Container(
            color: primaryColor,
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
            child: TextField(
              controller: _searchController,
              onChanged: _onSearchChanged,
              decoration: InputDecoration(
                hintText: 'Rechercher un service, une ville...',
                hintStyle: const TextStyle(color: Colors.grey),
                prefixIcon: const Icon(Icons.search, color: Colors.grey),
                suffixIcon: _searchController.text.isNotEmpty
                    ? IconButton(icon: const Icon(Icons.close, color: Colors.grey), onPressed: () {
                        _searchController.clear();
                        setState(() => _searchQuery = '');
                      })
                    : null,
                filled: true,
                fillColor: Colors.white,
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
              ),
            ),
          ),

          if (_showFiltersPanel) _buildFiltersPanel(),
          _buildCategoryChips(),
          _buildSortBar(),

          // Liste des annonces avec pagination infinie
          Expanded(
            child: Consumer<ServiceProvider>(
              builder: (context, provider, _) {
                if (provider.isLoading && provider.services.isEmpty) {
                  return const Center(child: CircularProgressIndicator(color: primaryColor));
                }

                final filtered = _getFilteredAndSorted(provider.services);

                if (filtered.isEmpty) {
                  return _buildEmptyState(provider.services.isEmpty);
                }

                return RefreshIndicator(
                  color: primaryColor,
                  onRefresh: () => context.read<ServiceProvider>().loadAllServices(reset: true),
                  child: ListView.builder(
                    controller: _scrollController,
                    padding: const EdgeInsets.all(16),
                    itemCount: filtered.length + 1,
                    itemBuilder: (context, index) {
                      if (index == filtered.length) {
                        return Consumer<ServiceProvider>(
                          builder: (_, provider, __) {
                            if (provider.isLoadingMore) {
                              return const Padding(
                                padding: EdgeInsets.symmetric(vertical: 16),
                                child: Center(child: CircularProgressIndicator(color: primaryColor)),
                              );
                            }
                            if (!provider.hasMore) {
                              return const Padding(
                                padding: EdgeInsets.symmetric(vertical: 16),
                                child: Center(
                                  child: Text('Toutes les annonces sont affichées', style: TextStyle(color: Colors.grey, fontSize: 13)),
                                ),
                              );
                            }
                            return const SizedBox.shrink();
                          },
                        );
                      }

                      final service = filtered[index];
                      return _buildServiceTile(service);
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

  // ─────────────────────────────────────────
  // PANNEAU FILTRES AVANCÉS
  // ─────────────────────────────────────────
  Widget _buildFiltersPanel() {
    return Container(
      color: Colors.white,
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Rayon
          Row(
            children: [
              const Icon(Icons.radar, color: primaryColor, size: 18),
              const SizedBox(width: 8),
              Text(
                'Rayon : ${_radiusKm.round()} km',
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 14,
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
          Slider(
            value: _radiusKm,
            min: 1,
            max: 50,
            divisions: 49,
            activeColor: primaryColor,
            inactiveColor: primaryColor.withValues(alpha: 0.2),
            label: '${_radiusKm.round()} km',
            onChanged: _myLat != null
                ? (v) => setState(() => _radiusKm = v)
                : null,
          ),
          const Padding(
            padding: EdgeInsets.symmetric(horizontal: 12),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text('1 km', style: TextStyle(color: Colors.grey, fontSize: 11)),
                Text('50 km', style: TextStyle(color: Colors.grey, fontSize: 11)),
              ],
            ),
          ),
          const SizedBox(height: 4),

          // Bouton réinitialiser
          if (_hasActiveFilters)
            SizedBox(
              width: double.infinity,
              child: TextButton.icon(
                onPressed: _resetFilters,
                icon: const Icon(Icons.clear_all, color: Colors.red),
                label: const Text(
                  'Réinitialiser tous les filtres',
                  style: TextStyle(color: Colors.red),
                ),
              ),
            ),
        ],
      ),
    );
  }

  // ─────────────────────────────────────────
  // CHIPS CATÉGORIES (multi-sélection)
  // ─────────────────────────────────────────
  Widget _buildCategoryChips() {
    return Container(
      color: Colors.white,
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 12),
        child: Row(
          children: [
            // Chip "Tous" — désélectionne tout
            Padding(
              padding: const EdgeInsets.only(right: 8),
              child: FilterChip(
                label: const Text('Tous'),
                selected: _selectedCategories.isEmpty,
                selectedColor: primaryColor,
                checkmarkColor: Colors.white,
                labelStyle: TextStyle(
                  color: _selectedCategories.isEmpty
                      ? Colors.white
                      : Colors.black87,
                  fontWeight: _selectedCategories.isEmpty
                      ? FontWeight.bold
                      : FontWeight.normal,
                ),
                backgroundColor: Colors.grey.shade200,
                onSelected: (_) =>
                    setState(() => _selectedCategories.clear()),
              ),
            ),
            // ✅ Chips individuels — multi-sélection
            ..._categories.map((cat) {
              final isSelected = _selectedCategories.contains(cat);
              return Padding(
                padding: const EdgeInsets.only(right: 8),
                child: FilterChip(
                  label: Text(cat),
                  selected: isSelected,
                  selectedColor: primaryColor,
                  checkmarkColor: Colors.white,
                  labelStyle: TextStyle(
                    color: isSelected ? Colors.white : Colors.black87,
                    fontWeight:
                        isSelected ? FontWeight.bold : FontWeight.normal,
                    fontSize: 13,
                  ),
                  backgroundColor: Colors.grey.shade200,
                  onSelected: (selected) {
                    setState(() {
                      if (selected) {
                        _selectedCategories.add(cat);
                      } else {
                        _selectedCategories.remove(cat);
                      }
                    });
                  },
                ),
              );
            }),
          ],
        ),
      ),
    );
  }

  // ─────────────────────────────────────────
  // BARRE DE TRI
  // ─────────────────────────────────────────
  Widget _buildSortBar() {
    return Container(
      color: Colors.white,
      padding: const EdgeInsets.fromLTRB(16, 4, 16, 8),
      child: Row(
        children: [
          const Icon(Icons.sort, color: Colors.grey, size: 16),
          const SizedBox(width: 6),
          const Text(
            'Trier par :',
            style: TextStyle(color: Colors.grey, fontSize: 13),
          ),
          const SizedBox(width: 8),
          DropdownButton<SortOption>(
            value: _sortOption,
            underline: const SizedBox(),
            isDense: true,
            style: const TextStyle(
              color: primaryColor,
              fontWeight: FontWeight.bold,
              fontSize: 13,
            ),
            items: SortOption.values
                .map((opt) => DropdownMenuItem(
                      value: opt,
                      child: Text(opt.label),
                    ))
                .toList(),
            onChanged: (opt) {
              if (opt != null) setState(() => _sortOption = opt);
            },
          ),
        ],
      ),
    );
  }

  // ─────────────────────────────────────────
  // TILE D'UN SERVICE (ListTile personnalisé)
  // ─────────────────────────────────────────
  Widget _buildServiceTile(ServiceModel service) {
    final distance = _getDistance(service);

    return GestureDetector(
      onTap: () => Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => ServiceDetailScreen(
            service: service,
            distanceKm: distance,
          ),
        ),
      ),
      child: Container(
        margin: const EdgeInsets.only(bottom: 10),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(14),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.06),
              blurRadius: 6,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Row(
          children: [
            // ── Photo miniature ──
            ClipRRect(
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(14),
                bottomLeft: Radius.circular(14),
              ),
              child: service.photos.isNotEmpty
                  ? Image.network(
                      service.photos.first,
                      width: 90,
                      height: 90,
                      fit: BoxFit.cover,
                      errorBuilder: (_, __, ___) => _photoPlaceholder(),
                    )
                  : _photoPlaceholder(),
            ),

            // ── Infos ──
            Expanded(
              child: Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 10,
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Titre + badge catégorie
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            service.titre,
                            style: const TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 14,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        const SizedBox(width: 6),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 6,
                            vertical: 2,
                          ),
                          decoration: BoxDecoration(
                            color: primaryColor.withValues(alpha: 0.12),
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: Text(
                            service.categorie,
                            style: const TextStyle(
                              color: primaryColor,
                              fontSize: 10,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),

                    // Description courte
                    Text(
                      service.description,
                      style: const TextStyle(
                        color: Colors.grey,
                        fontSize: 12,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 8),

                    // Prix + distance
                    Row(
                      children: [
                        // Prix
                        Text(
                          service.prix > 0
                              ? '${service.prix.toStringAsFixed(0)} FCFA'
                              : 'Négociable',
                          style: const TextStyle(
                            color: primaryColor,
                            fontWeight: FontWeight.bold,
                            fontSize: 13,
                          ),
                        ),
                        const Spacer(),
                        // Distance ou ville
                        if (distance != null) ...[
                          const Icon(
                            Icons.location_on,
                            size: 12,
                            color: Colors.grey,
                          ),
                          const SizedBox(width: 2),
                          Text(
                            GeoUtils.formatDistance(distance),
                            style: const TextStyle(
                              color: Colors.grey,
                              fontSize: 11,
                            ),
                          ),
                          const SizedBox(width: 4),
                          _proximityBadge(distance),
                        ] else if (service.ville.isNotEmpty) ...[
                          const Icon(
                            Icons.location_on,
                            size: 12,
                            color: Colors.grey,
                          ),
                          const SizedBox(width: 2),
                          Text(
                            service.ville,
                            style: const TextStyle(
                              color: Colors.grey,
                              fontSize: 11,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
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

  // ─────────────────────────────────────────
  // BADGE DE PROXIMITÉ
  // ─────────────────────────────────────────
  Widget _proximityBadge(double distanceKm) {
    Color color;
    if (distanceKm <= 2) {
      color = Colors.green;
    } else if (distanceKm <= 10) {
      color = Colors.orange;
    } else {
      color = Colors.grey;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(6),
      ),
      child: Text(
        GeoUtils.proximityLabel(distanceKm),
        style: TextStyle(
          color: color,
          fontSize: 9,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }

  // ─────────────────────────────────────────
  // PLACEHOLDER PHOTO
  // ─────────────────────────────────────────
  Widget _photoPlaceholder() {
    return Container(
      width: 90,
      height: 90,
      color: const Color(0xFFE8F5F0),
      child: const Icon(
        Icons.image_outlined,
        color: primaryColor,
        size: 30,
      ),
    );
  }

  // ─────────────────────────────────────────
  // ÉTAT VIDE
  // ─────────────────────────────────────────
  Widget _buildEmptyState(bool noDataAtAll) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              noDataAtAll ? Icons.storefront_outlined : Icons.search_off,
              size: 80,
              color: Colors.grey.shade400,
            ),
            const SizedBox(height: 16),
            Text(
              noDataAtAll
                  ? 'Aucune annonce disponible'
                  : 'Aucun résultat trouvé',
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Colors.black87,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              noDataAtAll
                  ? 'Soyez le premier à publier une annonce !'
                  : 'Essayez d\'augmenter le rayon ou de\nchanger les filtres de recherche.',
              textAlign: TextAlign.center,
              style: TextStyle(color: Colors.grey.shade600, fontSize: 14),
            ),
            if (!noDataAtAll && _hasActiveFilters) ...[
              const SizedBox(height: 20),
              ElevatedButton.icon(
                onPressed: _resetFilters,
                icon: const Icon(Icons.clear_all),
                label: const Text('Réinitialiser les filtres'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: primaryColor,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
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