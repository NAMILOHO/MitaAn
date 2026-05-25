import 'package:flutter/material.dart';
<<<<<<< HEAD
import '../models/service_model.dart';
import '../utils/distance_helper.dart';

class ServiceCard extends StatelessWidget {
  final ServiceModel service;
  final double? distanceKm; // null si position inconnue
=======
import 'package:firebase_auth/firebase_auth.dart';

import '../models/service_model.dart';
import '../utils/distance_helper.dart';
import '../services/user_service.dart';
import 'favorite_button.dart';

class ServiceCard extends StatefulWidget {
  final ServiceModel service;
  final double? distanceKm;
>>>>>>> develop
  final VoidCallback? onTap;

  const ServiceCard({
    super.key,
    required this.service,
    this.distanceKm,
    this.onTap,
  });

<<<<<<< HEAD
  static const Color primaryColor = Color(0xFF1D9E75);

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
=======
  @override
  State<ServiceCard> createState() => _ServiceCardState();
}

class _ServiceCardState extends State<ServiceCard> {
  static const Color primaryColor = Color(0xFF1D9E75);
  List<String> _favorites = [];

  @override
  void initState() {
    super.initState();
    _loadFavorites();
  }

  Future<void> _loadFavorites() async {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) return;
    try {
      final ids = await UserService().getFavorites(uid);
      if (mounted) {
        setState(() => _favorites = ids);
      }
    } catch (_) {}
  }

  @override
  Widget build(BuildContext context) {
    // ✅ CORRECTION : print() debug supprimé

    return GestureDetector(
      onTap: widget.onTap,
>>>>>>> develop
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
<<<<<<< HEAD
              color: Colors.black.withOpacity(0.06),
=======
              // ✅ CORRECTION : withValues() au lieu de withOpacity() déprécié
              color: Colors.black.withValues(alpha: 0.06),
>>>>>>> develop
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
<<<<<<< HEAD

            // ── Photo principale ──
            ClipRRect(
              borderRadius: const BorderRadius.vertical(
                top: Radius.circular(16),
              ),
              child: service.photos.isNotEmpty
                  ? Image.network(
                      service.photos.first,
                      height: 160,
                      width: double.infinity,
                      fit: BoxFit.cover,
                      errorBuilder: (_, __, ___) => _placeholderImage(),
                    )
                  : _placeholderImage(),
            ),

            // ── Infos ──
=======
            // Photo principale avec bouton favori
            Stack(
              children: [
                ClipRRect(
                  borderRadius: const BorderRadius.vertical(
                    top: Radius.circular(16),
                  ),
                  child: widget.service.photos.isNotEmpty
                      ? Image.network(
                          widget.service.photos.first,
                          height: 160,
                          width: double.infinity,
                          fit: BoxFit.cover,
                          loadingBuilder: (context, child, loadingProgress) {
                            if (loadingProgress == null) return child;
                            return Container(
                              height: 160,
                              color: const Color(0xFFE8F5F0),
                              child: Center(
                                child: CircularProgressIndicator(
                                  color: primaryColor,
                                  value: loadingProgress.expectedTotalBytes != null
                                      ? loadingProgress.cumulativeBytesLoaded /
                                          loadingProgress.expectedTotalBytes!
                                      : null,
                                ),
                              ),
                            );
                          },
                          errorBuilder: (context, error, stackTrace) =>
                              _placeholderImage(),
                        )
                      : _placeholderImage(),
                ),
                Positioned(
                  top: 8,
                  right: 8,
                  child: Container(
                    decoration: BoxDecoration(
                      // ✅ CORRECTION : withValues()
                      color: Colors.white.withValues(alpha: 0.9),
                      shape: BoxShape.circle,
                    ),
                    child: FavoriteButton(
                      serviceId: widget.service.id,
                      favorites: _favorites,
                    ),
                  ),
                ),
                if (widget.service.quantity == 0 && widget.service.quantity != -1)
                  Positioned(
                    top: 8,
                    left: 8,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.red.shade700,
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: const Text(
                        'Épuisé',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 10,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),
              ],
            ),

            // Infos
>>>>>>> develop
            Padding(
              padding: const EdgeInsets.all(12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
<<<<<<< HEAD

                  // Titre + Badge catégorie
=======
>>>>>>> develop
                  Row(
                    children: [
                      Expanded(
                        child: Text(
<<<<<<< HEAD
                          service.titre,
=======
                          widget.service.titre,
>>>>>>> develop
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 15,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 3,
                        ),
                        decoration: BoxDecoration(
<<<<<<< HEAD
                          color: primaryColor.withOpacity(0.12),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Text(
                          service.categorie,
=======
                          // ✅ CORRECTION : withValues()
                          color: primaryColor.withValues(alpha: 0.12),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Text(
                          widget.service.categorie,
>>>>>>> develop
                          style: const TextStyle(
                            color: primaryColor,
                            fontSize: 11,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 6),

<<<<<<< HEAD
                  // Description
                  Text(
                    service.description,
=======
                  Text(
                    widget.service.description,
>>>>>>> develop
                    style: const TextStyle(
                      color: Colors.grey,
                      fontSize: 13,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 10),

<<<<<<< HEAD
                  // Prix + Distance + Ville
                  Row(
                    children: [
                      // Prix
                      Text(
                        service.prix > 0
                            ? '${service.prix.toStringAsFixed(0)} FCFA'
=======
                  Row(
                    children: [
                      Text(
                        widget.service.prix > 0
                            ? '${widget.service.prix.toStringAsFixed(0)} FCFA'
>>>>>>> develop
                            : 'Prix à négocier',
                        style: const TextStyle(
                          color: primaryColor,
                          fontWeight: FontWeight.bold,
                          fontSize: 14,
                        ),
                      ),
                      const Spacer(),
<<<<<<< HEAD

                      // Distance
                      if (distanceKm != null) ...[
                        const Icon(
                          Icons.location_on,
                          size: 14,
                          color: Colors.grey,
                        ),
                        const SizedBox(width: 2),
                        Text(
                          DistanceHelper.format(distanceKm!),
                          style: const TextStyle(
                            color: Colors.grey,
                            fontSize: 12,
                          ),
                        ),
                        const SizedBox(width: 6),
                        // Label proximité
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 6,
                            vertical: 2,
                          ),
                          decoration: BoxDecoration(
                            color: _proximityColor(distanceKm!)
                                .withOpacity(0.15),
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: Text(
                            DistanceHelper.getProximityLabel(distanceKm!),
                            style: TextStyle(
                              color: _proximityColor(distanceKm!),
=======
                      if (widget.distanceKm != null) ...[
                        const Icon(Icons.location_on, size: 14, color: Colors.grey),
                        const SizedBox(width: 2),
                        Text(
                          DistanceHelper.format(widget.distanceKm!),
                          style: const TextStyle(color: Colors.grey, fontSize: 12),
                        ),
                        const SizedBox(width: 6),
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 6, vertical: 2),
                          decoration: BoxDecoration(
                            color: _proximityColor(widget.distanceKm!)
                                // ✅ CORRECTION : withValues()
                                .withValues(alpha: 0.15),
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: Text(
                            DistanceHelper.getProximityLabel(widget.distanceKm!),
                            style: TextStyle(
                              color: _proximityColor(widget.distanceKm!),
>>>>>>> develop
                              fontSize: 10,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ] else ...[
<<<<<<< HEAD
                        const Icon(
                          Icons.location_on,
                          size: 14,
                          color: Colors.grey,
                        ),
                        const SizedBox(width: 2),
                        Text(
                          service.ville.isNotEmpty
                              ? service.ville
                              : 'Localisation inconnue',
                          style: const TextStyle(
                            color: Colors.grey,
                            fontSize: 12,
                          ),
=======
                        const Icon(Icons.location_on, size: 14, color: Colors.grey),
                        const SizedBox(width: 2),
                        Text(
                          widget.service.ville.isNotEmpty
                              ? widget.service.ville
                              : 'Localisation inconnue',
                          style: const TextStyle(color: Colors.grey, fontSize: 12),
>>>>>>> develop
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
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

<<<<<<< HEAD
  // Image placeholder quand pas de photo
=======
>>>>>>> develop
  Widget _placeholderImage() {
    return Container(
      height: 160,
      width: double.infinity,
      color: const Color(0xFFE8F5F0),
      child: const Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.image_outlined, size: 48, color: Color(0xFF1D9E75)),
          SizedBox(height: 8),
<<<<<<< HEAD
          Text(
            'Pas de photo',
            style: TextStyle(color: Colors.grey, fontSize: 12),
          ),
=======
          Text('Pas de photo',
              style: TextStyle(color: Colors.grey, fontSize: 12)),
>>>>>>> develop
        ],
      ),
    );
  }

<<<<<<< HEAD
  // Couleur selon la distance
=======
>>>>>>> develop
  Color _proximityColor(double km) {
    if (km <= 2) return Colors.green;
    if (km <= 10) return Colors.orange;
    return Colors.grey;
  }
}
