import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../providers/service_provider.dart';
import '../../services/location_service.dart';
import '../../services/user_service.dart';
import '../../widgets/service_card.dart';
import '../../models/service_model.dart';
import 'service_detail_screen.dart';

class ServicesListScreen extends StatefulWidget {
  const ServicesListScreen({super.key});

  @override
  State<ServicesListScreen> createState() => _ServicesListScreenState();
}

class _ServicesListScreenState extends State<ServicesListScreen> {
  final LocationService _locationService = LocationService();
  final UserService _userService = UserService();
  final TextEditingController _searchController = TextEditingController();

  double? _myLat;
  double? _myLng;
  String _searchQuery = '';
  String? _selectedCategory;

  static const Color primaryColor = Color(0xFF1D9E75);

  final List<String> _categories = [
    'Tous',
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
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _loadData() async {
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
      }
    }
  }

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

    // Trier par distance si position disponible
    if (_myLat != null && _myLng != null) {
      filtered.sort((a, b) {
        final distA = _getDistance(a) ?? double.infinity;
        final distB = _getDistance(b) ?? double.infinity;
        return distA.compareTo(distB);
      });
    }

    return filtered;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
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
                          ),
                        ],
                      ],
                    ),
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
}