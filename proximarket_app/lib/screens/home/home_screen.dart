import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../services/services_list_screen.dart';

// Services
import 'package:proximarket_app/services/location_service.dart';
import 'package:proximarket_app/services/user_service.dart';

// Models
import 'package:proximarket_app/models/user_model.dart';

// Screens
import 'package:proximarket_app/screens/profile/profile_screen.dart';
import 'package:proximarket_app/screens/services/create_service_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final LocationService _locationService = LocationService();
  final UserService _userService = UserService();

  UserModel? _userModel;
  bool _isLoadingLocation = false;
  String _locationStatus = 'Position non définie';
  int _currentIndex = 0;

  static const Color primaryColor = Color(0xFF1D9E75);

  @override
  void initState() {
    super.initState();
    _loadUser();
  }

  Future<void> _loadUser() async {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid != null) {
      final user = await _userService.getUserProfile(uid);
      setState(() {
        _userModel = user;
        if (user != null &&
            user.gpsLat != 0.0 &&
            user.gpsLng != 0.0) {
          _locationStatus = 'Position enregistrée ✅';
        }
      });
    }
  }

  Future<void> _updateLocation() async {
    setState(() {
      _isLoadingLocation = true;
      _locationStatus = 'Récupération en cours...';
    });

    try {
      final uid = FirebaseAuth.instance.currentUser!.uid;
      await _locationService.saveUserLocation(uid);

      final updated = await _userService.getUserProfile(uid);

      setState(() {
        _userModel = updated;
        _locationStatus =
            'Position mise à jour ✅\n${updated?.ville ?? ''}';
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Position mise à jour ✅'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      setState(() => _locationStatus = 'Erreur : $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(e.toString()),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      setState(() => _isLoadingLocation = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F5F5),

      appBar: AppBar(
        backgroundColor: primaryColor,
        elevation: 0,
        title: Row(
          children: [
            const Icon(Icons.location_on, color: Colors.white, size: 20),
            const SizedBox(width: 6),
            Expanded(
              child: Text(
                _userModel?.ville?.isNotEmpty == true
                    ? _userModel!.ville!
                    : 'ProxiMarket',
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
        actions: [
          IconButton(
            icon: CircleAvatar(
              radius: 16,
              backgroundColor: Colors.white,
              backgroundImage: _userModel?.photoUrl.isNotEmpty == true
                  ? NetworkImage(_userModel!.photoUrl)
                  : null,
              child: _userModel?.photoUrl.isEmpty != false
                  ? Text(
                      _userModel?.nom.isNotEmpty == true
                          ? _userModel!.nom[0].toUpperCase()
                          : '?',
                      style: const TextStyle(
                        color: primaryColor,
                        fontWeight: FontWeight.bold,
                        fontSize: 14,
                      ),
                    )
                  : null,
            ),
            onPressed: () => Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const ProfileScreen()),
            ),
          ),
        ],
      ),

      // ✅ CORRECTION ICI
      body: _currentIndex == 0
          ? _buildBody() // Accueil
          : _currentIndex == 1
              ? const ServicesListScreen() // Recherche
              : _currentIndex == 2
                  ? const CreateServiceScreen() // Publier
                  : const ProfileScreen(), // Profil

      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _currentIndex,
        selectedItemColor: primaryColor,
        unselectedItemColor: Colors.grey,
        onTap: (index) => setState(() => _currentIndex = index),
        items: const [
          BottomNavigationBarItem(
            icon: Icon(Icons.home_outlined),
            activeIcon: Icon(Icons.home),
            label: 'Accueil',
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
            icon: Icon(Icons.person_outline),
            activeIcon: Icon(Icons.person),
            label: 'Profil',
          ),
        ],
      ),
    );
  }

  Widget _buildBody() {
    return const Center(
      child: Text("Page Accueil"),
    );
  }
}