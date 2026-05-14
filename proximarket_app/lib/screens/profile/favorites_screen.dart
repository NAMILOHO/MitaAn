import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';

import '../../models/service_model.dart';
import '../../services/user_service.dart';
import '../../services/service_firestore.dart';
import '../services/service_detail_screen.dart';
import '../../widgets/favorite_button.dart';

class FavoritesScreen extends StatefulWidget {
  const FavoritesScreen({super.key});

  @override
  State<FavoritesScreen> createState() => _FavoritesScreenState();
}

class _FavoritesScreenState extends State<FavoritesScreen> {
  final UserService _userService = UserService();
  final ServiceFirestore _serviceFirestore = ServiceFirestore();

  List<ServiceModel> _favoriteServices = [];
  List<String> _favoriteIds = [];
  bool _isLoading = true;

  static const Color primaryColor = Color(0xFF1D9E75);

  @override
  void initState() {
    super.initState();
    _loadFavorites();
  }

  Future<void> _loadFavorites() async {
    setState(() => _isLoading = true);

    try {
      final uid = FirebaseAuth.instance.currentUser?.uid;
      if (uid == null) return;

      final ids = await _userService.getFavorites(uid);
      _favoriteIds = ids;

      if (ids.isEmpty) {
        if (mounted) setState(() { _favoriteServices = []; _isLoading = false; });
        return;
      }

      // Charger chaque service par son ID
      final services = await Future.wait(
        ids.map((id) => _serviceFirestore.getServiceById(id)),
      );

      if (mounted) {
        setState(() {
          _favoriteServices =
              services.whereType<ServiceModel>().toList();
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F5F5),
      appBar: AppBar(
        backgroundColor: primaryColor,
        foregroundColor: Colors.white,
        title: const Text(
          'Mes favoris',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadFavorites,
          ),
        ],
      ),
      body: _isLoading
          ? const Center(
              child: CircularProgressIndicator(color: primaryColor))
          : _favoriteServices.isEmpty
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.favorite_border,
                          size: 80, color: Colors.grey.shade400),
                      const SizedBox(height: 16),
                      const Text(
                        'Aucun favori pour le moment',
                        style: TextStyle(
                            fontSize: 18, fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Ajoutez des annonces en favoris\npour les retrouver ici.',
                        textAlign: TextAlign.center,
                        style: TextStyle(color: Colors.grey.shade600),
                      ),
                    ],
                  ),
                )
              : RefreshIndicator(
                  color: primaryColor,
                  onRefresh: _loadFavorites,
                  child: ListView.builder(
                    padding: const EdgeInsets.all(16),
                    itemCount: _favoriteServices.length,
                    itemBuilder: (_, i) =>
                        _buildFavoriteTile(_favoriteServices[i]),
                  ),
                ),
    );
  }

  Widget _buildFavoriteTile(ServiceModel service) {
    return GestureDetector(
      onTap: () async {
        await Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => ServiceDetailScreen(service: service),
          ),
        );
        _loadFavorites(); // Rafraîchir après retour (l'utilisateur peut avoir retiré)
      },
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(14),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.06),
              blurRadius: 6,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Row(
          children: [
            // Photo
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
                      errorBuilder: (_, __, ___) => _placeholder(),
                    )
                  : _placeholder(),
            ),
            // Infos
            Expanded(
              child: Padding(
                padding: const EdgeInsets.symmetric(
                    horizontal: 12, vertical: 10),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      service.titre,
                      style: const TextStyle(
                          fontWeight: FontWeight.bold, fontSize: 14),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 4),
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 8, vertical: 2),
                      decoration: BoxDecoration(
                        color: primaryColor.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Text(
                        service.categorie,
                        style: const TextStyle(
                            color: primaryColor,
                            fontSize: 11,
                            fontWeight: FontWeight.bold),
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      service.prix > 0
                          ? '${service.prix.toStringAsFixed(0)} FCFA'
                          : 'Négociable',
                      style: const TextStyle(
                          color: primaryColor,
                          fontWeight: FontWeight.bold,
                          fontSize: 13),
                    ),
                  ],
                ),
              ),
            ),
            // Bouton cœur
            FavoriteButton(
              serviceId: service.id,
              favorites: _favoriteIds,
            ),
          ],
        ),
      ),
    );
  }

  Widget _placeholder() {
    return Container(
      width: 90,
      height: 90,
      color: const Color(0xFFE8F5F0),
      child: const Icon(Icons.image_outlined,
          color: primaryColor, size: 30),
    );
  }
}