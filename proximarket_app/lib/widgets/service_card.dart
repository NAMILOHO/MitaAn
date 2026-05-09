import 'package:flutter/material.dart';
import '../models/service_model.dart';
import '../utils/distance_helper.dart';

class ServiceCard extends StatelessWidget {
  final ServiceModel service;
  final double? distanceKm;
  final VoidCallback? onTap;

  const ServiceCard({
    super.key,
    required this.service,
    this.distanceKm,
    this.onTap,
  });

  static const Color primaryColor = Color(0xFF1D9E75);

  @override
  Widget build(BuildContext context) {
    // ====================== DEBUG : Photos ======================
    // ignore: avoid_print
    print('Photos de "${service.titre}": ${service.photos}');
    // ============================================================

    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.06),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ── Photo principale (avec loading + error) ──
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
                      // Placeholder pendant le chargement
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

            // ── Infos ──
            Padding(
              padding: const EdgeInsets.all(12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Titre + Badge catégorie
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          service.titre,
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
                          color: primaryColor.withValues(alpha: 0.12),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Text(
                          service.categorie,
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

                  // Description
                  Text(
                    service.description,
                    style: const TextStyle(
                      color: Colors.grey,
                      fontSize: 13,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 10),

                  // Prix + Distance + Ville
                  Row(
                    children: [
                      // Prix
                      Text(
                        service.prix > 0
                            ? '${service.prix.toStringAsFixed(0)} FCFA'
                            : 'Prix à négocier',
                        style: const TextStyle(
                          color: primaryColor,
                          fontWeight: FontWeight.bold,
                          fontSize: 14,
                        ),
                      ),
                      const Spacer(),

                      // Distance ou Ville
                      if (distanceKm != null) ...[
                        const Icon(Icons.location_on, size: 14, color: Colors.grey),
                        const SizedBox(width: 2),
                        Text(
                          DistanceHelper.format(distanceKm!),
                          style: const TextStyle(
                            color: Colors.grey,
                            fontSize: 12,
                          ),
                        ),
                        const SizedBox(width: 6),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 6,
                            vertical: 2,
                          ),
                          decoration: BoxDecoration(
                            color: _proximityColor(distanceKm!)
                                .withValues(alpha: 0.15),
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: Text(
                            DistanceHelper.getProximityLabel(distanceKm!),
                            style: TextStyle(
                              color: _proximityColor(distanceKm!),
                              fontSize: 10,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ] else ...[
                        const Icon(Icons.location_on, size: 14, color: Colors.grey),
                        const SizedBox(width: 2),
                        Text(
                          service.ville.isNotEmpty
                              ? service.ville
                              : 'Localisation inconnue',
                          style: const TextStyle(
                            color: Colors.grey,
                            fontSize: 12,
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
          ],
        ),
      ),
    );
  }

  // Image placeholder quand pas de photo ou erreur
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
          Text(
            'Pas de photo',
            style: TextStyle(color: Colors.grey, fontSize: 12),
          ),
        ],
      ),
    );
  }

  // Couleur selon la distance
  Color _proximityColor(double km) {
    if (km <= 2) return Colors.green;
    if (km <= 10) return Colors.orange;
    return Colors.grey;
  }
}