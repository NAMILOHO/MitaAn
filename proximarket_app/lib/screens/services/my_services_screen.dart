// lib/screens/services/my_services_screen.dart
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:provider/provider.dart';

import '../../models/service_model.dart';
import '../../providers/service_provider.dart';

import 'service_detail_screen.dart';
import 'create_service_screen.dart';
<<<<<<< HEAD
import 'edit_service_screen.dart';
=======
import 'edit_service_screen.dart'; // ✅ AJOUT
import 'archived_services_screen.dart';
>>>>>>> develop

class MyServicesScreen extends StatefulWidget {
  const MyServicesScreen({super.key});

  @override
  State<MyServicesScreen> createState() => _MyServicesScreenState();
}

class _MyServicesScreenState extends State<MyServicesScreen> {
  static const Color primaryColor = Color(0xFF1D9E75);

  @override
  void initState() {
    super.initState();
    _loadMyServices();
  }

  Future<void> _loadMyServices() async {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid != null) {
      await context.read<ServiceProvider>().loadMyServices();
    }
  }

  // ─────────────────────────────────────────
<<<<<<< HEAD
  // ✅ TOGGLE ACTIF / INACTIF — VERSION AMÉLIORÉE
  // ─────────────────────────────────────────
  Future<void> _toggleActive(ServiceModel service) async {
    final newStatus = !service.isActive;

=======
  // ✅ TOGGLE ACTIF / INACTIF (UI Optimiste)
  // ─────────────────────────────────────────
  Future<void> _toggleActive(ServiceModel service) async {
    final newStatus = !service.isActive;
    
>>>>>>> develop
    // Feedback immédiat sans attendre Firestore
    final success = await context
        .read<ServiceProvider>()
        .toggleServiceActive(service.id, newStatus);
<<<<<<< HEAD

    if (!mounted) return;

=======
        
    if (!mounted) return;
    
>>>>>>> develop
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          success
              ? (newStatus ? 'Annonce activée ✅' : 'Annonce désactivée')
              : 'Erreur — réessayez',
        ),
        backgroundColor: success
            ? (newStatus ? Colors.green : Colors.orange)
            : Colors.red,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        duration: const Duration(seconds: 2),
      ),
    );
  }

  // ─────────────────────────────────────────
  // CONFIRMATION AVANT SUPPRESSION
  // ─────────────────────────────────────────
  Future<void> _confirmDelete(
      BuildContext context, ServiceModel service) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
        title: const Text(
          'Supprimer l\'annonce ?',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        content: Text(
          'Voulez-vous vraiment supprimer "${service.titre}" ?\n'
          'Cette action est irréversible.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text(
              'Annuler',
              style: TextStyle(color: Colors.grey),
            ),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
              ),
            ),
            child: const Text('Supprimer'),
          ),
        ],
      ),
    );

    if (confirm == true && context.mounted) {
      final success =
          await context.read<ServiceProvider>().deleteService(service.id);

      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              success
                  ? 'Annonce supprimée ✅'
                  : 'Erreur lors de la suppression',
            ),
            backgroundColor: success ? Colors.green : Colors.red,
          ),
        );
      }
    }
  }

  // ─────────────────────────────────────────
  // BUILD
  // ─────────────────────────────────────────
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F5F5),
      appBar: AppBar(
        backgroundColor: primaryColor,
        foregroundColor: Colors.white,
        title: const Text(
          'Mes annonces',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.archive_outlined),
            onPressed: () => Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) => const ArchivedServicesScreen(),
              ),
            ),
            tooltip: 'Archives',
          ),
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadMyServices,
          ),
        ],
      ),
      // Bouton publier une nouvelle annonce
      floatingActionButton: FloatingActionButton(
        backgroundColor: primaryColor,
        foregroundColor: Colors.white,
        onPressed: () async {
          final created = await Navigator.push<bool>(
            context,
            MaterialPageRoute(
              builder: (_) => const CreateServiceScreen(),
            ),
          );
          if (created == true) _loadMyServices();
        },
        child: const Icon(Icons.add),
      ),
      body: Consumer<ServiceProvider>(
        builder: (context, provider, _) {
          if (provider.isLoading) {
            return const Center(
              child: CircularProgressIndicator(color: primaryColor),
            );
          }

          if (provider.myServices.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.post_add, size: 80, color: Colors.grey),
                  const SizedBox(height: 16),
                  const Text(
                    'Vous n\'avez pas encore\nd\'annonces publiées',
                    textAlign: TextAlign.center,
                    style: TextStyle(color: Colors.grey, fontSize: 16),
                  ),
                  const SizedBox(height: 24),
                  ElevatedButton.icon(
                    onPressed: () async {
                      final created = await Navigator.push<bool>(
                        context,
                        MaterialPageRoute(
                          builder: (_) => const CreateServiceScreen(),
                        ),
                      );
                      if (created == true) _loadMyServices();
                    },
                    icon: const Icon(Icons.add),
                    label: const Text('Publier une annonce'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: primaryColor,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(
                          horizontal: 24, vertical: 12),
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12)),
                    ),
                  ),
                ],
              ),
            );
          }

          return RefreshIndicator(
            color: primaryColor,
            onRefresh: _loadMyServices,
            child: ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: provider.myServices.length,
              itemBuilder: (context, index) {
                final service = provider.myServices[index];
                return _buildMyServiceCard(context, service);
              },
            ),
          );
        },
      ),
    );
  }

  // ─────────────────────────────────────────
  // CARTE D'UNE ANNONCE
  // ─────────────────────────────────────────
  Widget _buildMyServiceCard(BuildContext context, ServiceModel service) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
<<<<<<< HEAD
=======
        // ✅ Bordure subtile orange si inactif
>>>>>>> develop
        border: service.isActive
            ? null
            : Border.all(color: Colors.orange.withValues(alpha: 0.4)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.06),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        children: [
          // ── Photo + infos ──
          ListTile(
            contentPadding: const EdgeInsets.all(12),
            leading: ClipRRect(
              borderRadius: BorderRadius.circular(10),
              child: service.photos.isNotEmpty
                  ? Image.network(
                      service.photos.first,
                      width: 64,
                      height: 64,
                      fit: BoxFit.cover,
                      errorBuilder: (context, error, stackTrace) =>
                          _placeholderImage(),
                    )
                  : _placeholderImage(),
            ),
            title: Text(
              service.titre,
              style: const TextStyle(
                  fontWeight: FontWeight.bold, fontSize: 15),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
            subtitle: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SizedBox(height: 4),
                // Badge catégorie
                Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 8, vertical: 2),
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
                const SizedBox(height: 4),
                // Prix + unité
                Text(
                  service.prix > 0
                      ? '${service.prix.toStringAsFixed(0)} FCFA  •  ${service.unite}'
                      : 'Prix à négocier',
                  style: const TextStyle(
                    color: primaryColor,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            // ✅ Toggle Actif / Inactif
            trailing: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Switch(
                  value: service.isActive,
                  activeColor: primaryColor,
                  onChanged: (_) => _toggleActive(service),
                ),
                Text(
                  service.isActive ? 'Active' : 'Inactive',
                  style: TextStyle(
                    color: service.isActive ? primaryColor : Colors.grey,
                    fontSize: 10,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            onTap: () => Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) => ServiceDetailScreen(service: service),
              ),
            ),
          ),

          // ── Boutons actions ──
          const Divider(height: 1),
          Padding(
            padding: const EdgeInsets.symmetric(
                horizontal: 12, vertical: 8),
            child: Row(
              children: [
                // Modifier
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: () async {
                      final updated = await Navigator.push<bool>(
                        context,
                        MaterialPageRoute(
                          builder: (_) =>
                              EditServiceScreen(service: service),
                        ),
                      );
                      if (updated == true) _loadMyServices();
                    },
                    icon: const Icon(
                      Icons.edit_outlined,
                      size: 16,
                      color: primaryColor,
                    ),
                    label: const Text(
                      'Modifier',
                      style: TextStyle(color: primaryColor),
                    ),
                    style: OutlinedButton.styleFrom(
                      side: const BorderSide(color: primaryColor),
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8)),
                    ),
                  ),
                ),
                const SizedBox(width: 8),

                // Voir
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: () => Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) =>
                            ServiceDetailScreen(service: service),
                      ),
                    ),
                    icon: const Icon(
                      Icons.visibility_outlined,
                      size: 16,
                      color: Colors.grey,
                    ),
                    label: const Text(
                      'Voir',
                      style: TextStyle(color: Colors.grey),
                    ),
                    style: OutlinedButton.styleFrom(
                      side: BorderSide(color: Colors.grey.shade400),
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8)),
                    ),
                  ),
                ),
                const SizedBox(width: 8),

<<<<<<< HEAD
                // Supprimer
=======
                IconButton(
                  onPressed: () async {
                    await context.read<ServiceProvider>().archiveService(service.id);
                    _loadMyServices();
                    if (context.mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('Annonce archivée'),
                          backgroundColor: Colors.orange,
                        ),
                      );
                    }
                  },
                  icon: const Icon(Icons.archive_outlined, color: Colors.orange),
                  tooltip: 'Archiver',
                ),

                // Bouton Supprimer
>>>>>>> develop
                IconButton(
                  onPressed: () => _confirmDelete(context, service),
                  icon: const Icon(Icons.delete_outline, color: Colors.red),
                  tooltip: 'Supprimer',
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _placeholderImage() {
    return Container(
      width: 64,
      height: 64,
      decoration: BoxDecoration(
        color: const Color(0xFFE8F5F0),
        borderRadius: BorderRadius.circular(10),
      ),
      child: const Icon(Icons.image_outlined, color: primaryColor, size: 28),
    );
  }
}
