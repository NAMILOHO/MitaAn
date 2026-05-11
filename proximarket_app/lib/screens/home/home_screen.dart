import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:provider/provider.dart';
 
import '../services/services_list_screen.dart';
import '../services/create_service_screen.dart';
import '../profile/profile_screen.dart';
import '../chat/chat_list_screen.dart';
import '../services/service_detail_screen.dart';
import '../map/map_screen.dart'; // ← AJOUT
 
import '../../services/location_service.dart';
import '../../services/user_service.dart';
import '../../models/user_model.dart';
import '../../providers/service_provider.dart';
import '../../widgets/service_card.dart';
 
// ─────────────────────────────────────────────────
// ÉCRAN PRINCIPAL AVEC NAVIGATION
// ─────────────────────────────────────────────────
class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});
 
  @override
  HomeScreenState createState() => HomeScreenState();
}
 
// ─────────────────────────────────────────────────
// ÉTAT PUBLIC
// ─────────────────────────────────────────────────
class HomeScreenState extends State<HomeScreen> {
  int _currentIndex = 0;
 
  static const Color primaryColor = Color(0xFF1D9E75);
 
  // Méthode publique pour changer d'onglet
  void changeTab(int index) {
    setState(() {
      _currentIndex = index;
    });
  }
 
  late final List<Widget> _screens;
 
  @override
  void initState() {
    super.initState();
 
    _screens = [
      const _HomeTab(),        // index 0 — Accueil
      const MapScreen(),       // index 1 — Carte ← AJOUT
      const ServicesListScreen(), // index 2 — Rechercher
      const CreateServiceScreen(), // index 3 — Publier
      const ChatListScreen(),  // index 4 — Messages
      const ProfileScreen(),   // index 5 — Profil
    ];
  }
 
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: IndexedStack(
        index: _currentIndex,
        children: _screens,
      ),
 
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _currentIndex,
        selectedItemColor: primaryColor,
        unselectedItemColor: Colors.grey,
        type: BottomNavigationBarType.fixed,
 
        onTap: (index) {
          setState(() {
            _currentIndex = index;
          });
        },
 
        items: const [
          BottomNavigationBarItem(
            icon: Icon(Icons.home_outlined),
            activeIcon: Icon(Icons.home),
            label: 'Accueil',
          ),
 
          // ← AJOUT onglet Carte
          BottomNavigationBarItem(
            icon: Icon(Icons.map_outlined),
            activeIcon: Icon(Icons.map),
            label: 'Carte',
          ),
 
          BottomNavigationBarItem(
            icon: Icon(Icons.search_outlined),
            activeIcon: Icon(Icons.search),
            label: 'Rechercher',
          ),
 
          BottomNavigationBarItem(
            icon: Icon(Icons.add_circle_outline),
            activeIcon: Icon(Icons.add_circle),
            label: 'Publier',
          ),
 
          BottomNavigationBarItem(
            icon: Icon(Icons.chat_bubble_outline),
            activeIcon: Icon(Icons.chat_bubble),
            label: 'Messages',
          ),
 
          BottomNavigationBarItem(
            icon: Icon(Icons.person_outline),
            activeIcon: Icon(Icons.person),
            label: 'Profil',
          ),
        ],
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
 
  String _locationStatus = 'Position non définie';
 
  static const Color primaryColor = Color(0xFF1D9E75);
 
  @override
  void initState() {
    super.initState();
 
    _loadUser();
 
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<ServiceProvider>().loadAllServices();
    });
  }
 
  // ─────────────────────────────────────────────────
  // CHARGEMENT UTILISATEUR
  // ─────────────────────────────────────────────────
  Future<void> _loadUser() async {
    final uid = FirebaseAuth.instance.currentUser?.uid;
 
    if (uid != null) {
      final user = await _userService.getUserProfile(uid);
 
      if (!mounted) return;
 
      setState(() {
        _userModel = user;
 
        if (user != null && user.gpsLat != 0.0) {
          _locationStatus = 'Position enregistrée ✅';
        }
      });
    }
  }
 
  // ─────────────────────────────────────────────────
  // MISE À JOUR GPS
  // ─────────────────────────────────────────────────
  Future<void> _updateLocation() async {
    setState(() {
      _isLoadingLocation = true;
      _locationStatus = 'Récupération en cours...';
    });
 
    try {
      final uid = FirebaseAuth.instance.currentUser!.uid;
 
      await _locationService.saveUserLocation(uid);
 
      final updated = await _userService.getUserProfile(uid);
 
      if (!mounted) return;
 
      setState(() {
        _userModel = updated;
        _locationStatus =
            'Position mise à jour ✅\n${updated?.ville ?? ''}';
      });
 
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Position mise à jour ✅'),
          backgroundColor: Colors.green,
        ),
      );
    } catch (e) {
      if (!mounted) return;
 
      setState(() {
        _locationStatus = 'Erreur : $e';
      });
 
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(e.toString()),
          backgroundColor: Colors.red,
        ),
      );
    } finally {
      if (mounted) {
        setState(() {
          _isLoadingLocation = false;
        });
      }
    }
  }
 
  // ─────────────────────────────────────────────────
  // UI
  // ─────────────────────────────────────────────────
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F5F5),
 
      appBar: AppBar(
        backgroundColor: primaryColor,
        elevation: 0,
        automaticallyImplyLeading: false,
 
        title: Row(
          children: [
            const Icon(
              Icons.location_on,
              color: Colors.white,
              size: 20,
            ),
 
            const SizedBox(width: 6),
 
            Expanded(
              child: Text(
                _userModel?.ville != null &&
                        _userModel!.ville.isNotEmpty
                    ? _userModel!.ville
                    : 'MitaAn',
 
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
 
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
      ),
 
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
 
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ─────────────────────────────────────────
            // BONJOUR
            // ─────────────────────────────────────────
            Text(
              'Bonjour, ${_userModel?.nom.split(' ').first ?? 'là'} 👋',
 
              style: const TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.bold,
              ),
            ),
 
            const SizedBox(height: 4),
 
            const Text(
              'Que cherchez-vous aujourd\'hui ?',
 
              style: TextStyle(
                color: Colors.grey,
                fontSize: 14,
              ),
            ),
 
            const SizedBox(height: 20),
 
            // ─────────────────────────────────────────
            // BLOC GPS + CARTE
            // ─────────────────────────────────────────
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(20),
 
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [
                    Color(0xFF1D9E75),
                    Color(0xFF157A5A),
                  ],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(16),
              ),
 
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Row(
                    children: [
                      Icon(
                        Icons.my_location,
                        color: Colors.white,
                        size: 20,
                      ),
                      SizedBox(width: 8),
                      Text(
                        'Ma localisation',
                        style: TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                        ),
                      ),
                    ],
                  ),
 
                  const SizedBox(height: 8),
 
                  Text(
                    _locationStatus,
                    style: const TextStyle(
                      color: Colors.white70,
                      fontSize: 13,
                    ),
                  ),
 
                  const SizedBox(height: 12),
 
                  // ── BOUTON VOIR LA CARTE ← AJOUT ──
                  SizedBox(
                    width: double.infinity,
                    child: OutlinedButton.icon(
                      onPressed: () {
                        final homeState = context
                            .findAncestorStateOfType<HomeScreenState>();
                        homeState?.changeTab(1); // index 1 = Carte
                      },
                      icon: const Icon(
                        Icons.map,
                        color: Colors.white,
                      ),
                      label: const Text(
                        'Voir la carte des prestataires',
                        style: TextStyle(color: Colors.white),
                      ),
                      style: OutlinedButton.styleFrom(
                        side: const BorderSide(color: Colors.white54),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                      ),
                    ),
                  ),
 
                  const SizedBox(height: 8),
 
                  // ── BOUTON MISE À JOUR GPS ──
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton.icon(
                      onPressed:
                          _isLoadingLocation ? null : _updateLocation,
 
                      icon: _isLoadingLocation
                          ? const SizedBox(
                              width: 16,
                              height: 16,
                              child: CircularProgressIndicator(
                                color: primaryColor,
                                strokeWidth: 2,
                              ),
                            )
                          : const Icon(
                              Icons.gps_fixed,
                              color: primaryColor,
                            ),
 
                      label: Text(
                        _isLoadingLocation
                            ? 'Récupération...'
                            : 'Mettre à jour ma position',
 
                        style: const TextStyle(
                          color: primaryColor,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
 
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.white,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
 
            const SizedBox(height: 24),
 
            // ─────────────────────────────────────────
            // CATÉGORIES
            // ─────────────────────────────────────────
            const Text(
              'Catégories',
 
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
 
            const SizedBox(height: 12),
 
            GridView.count(
              crossAxisCount: 4,
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              crossAxisSpacing: 10,
              mainAxisSpacing: 10,
 
              children: [
                _buildCategory(Icons.handyman, 'Artisan'),
                _buildCategory(Icons.palette, 'Artiste'),
                _buildCategory(Icons.agriculture, 'Éleveur'),
                _buildCategory(Icons.store, 'Commerce'),
                _buildCategory(Icons.plumbing, 'Plombier'),
                _buildCategory(Icons.electrical_services, 'Électricien'),
                _buildCategory(Icons.carpenter, 'Menuisier'),
                _buildCategory(Icons.more_horiz, 'Autre'),
              ],
            ),
 
            const SizedBox(height: 24),
 
            // ─────────────────────────────────────────
            // SERVICES PRÈS DE VOUS
            // ─────────────────────────────────────────
            const Text(
              'Services près de vous',
 
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
 
            const SizedBox(height: 12),
 
            Consumer<ServiceProvider>(
              builder: (context, provider, _) {
                // Chargement
                if (provider.isLoading) {
                  return const Center(
                    child: CircularProgressIndicator(
                      color: primaryColor,
                    ),
                  );
                }
 
                // Aucun service
                if (provider.services.isEmpty) {
                  return Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(32),
 
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(12),
                    ),
 
                    child: const Column(
                      children: [
                        Icon(
                          Icons.search_off,
                          size: 48,
                          color: Colors.grey,
                        ),
                        SizedBox(height: 12),
                        Text(
                          'Aucune annonce disponible',
                          style: TextStyle(color: Colors.grey),
                          textAlign: TextAlign.center,
                        ),
                      ],
                    ),
                  );
                }
 
                final preview = provider.services.take(3).toList();
 
                return Column(
                  children: [
                    // Cartes services
                    ...preview.map(
                      (service) => ServiceCard(
                        service: service,
 
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => ServiceDetailScreen(
                                service: service,
                              ),
                            ),
                          );
                        },
                      ),
                    ),
 
                    const SizedBox(height: 8),
 
                    // ── BOUTON VOIR TOUTES LES ANNONCES ──
                    SizedBox(
                      width: double.infinity,
 
                      child: OutlinedButton(
                        onPressed: () {
                          final homeState = context
                              .findAncestorStateOfType<HomeScreenState>();
 
                          if (homeState != null) {
                            homeState.changeTab(2); // index 2 = Rechercher
                          }
                        },
 
                        style: OutlinedButton.styleFrom(
                          side: const BorderSide(color: primaryColor),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10),
                          ),
                        ),
 
                        child: const Text(
                          'Voir toutes les annonces',
                          style: TextStyle(color: primaryColor),
                        ),
                      ),
                    ),
                  ],
                );
              },
            ),
          ],
        ),
      ),
    );
  }
 
  // ─────────────────────────────────────────────────
  // WIDGET CATÉGORIE
  // ─────────────────────────────────────────────────
  Widget _buildCategory(IconData icon, String label) {
    return GestureDetector(
      onTap: () async {
        // 1. Charger les annonces filtrées par catégorie
        await context
            .read<ServiceProvider>()
            .loadServicesByCategory(label);
 
        // 2. Aller à l'onglet Rechercher (index 2)
        if (!mounted) return;
        final homeState =
            context.findAncestorStateOfType<HomeScreenState>();
        if (homeState != null) {
          homeState.changeTab(2); // index 2 = Rechercher
        }
      },
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            width: 52,
            height: 52,
            decoration: BoxDecoration(
              color: primaryColor.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(14),
            ),
            child: Icon(icon, color: primaryColor, size: 26),
          ),
          const SizedBox(height: 4),
          Text(
            label,
            style: const TextStyle(fontSize: 10),
            textAlign: TextAlign.center,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }
}