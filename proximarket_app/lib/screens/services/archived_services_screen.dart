import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';

import '../../models/service_model.dart';
import '../../services/service_firestore.dart';

class ArchivedServicesScreen extends StatefulWidget {
  const ArchivedServicesScreen({super.key});

  @override
  State<ArchivedServicesScreen> createState() => _ArchivedServicesScreenState();
}

class _ArchivedServicesScreenState extends State<ArchivedServicesScreen> {
  final ServiceFirestore _serviceFirestore = ServiceFirestore();
  List<ServiceModel> _archived = [];
  bool _isLoading = true;

  static const primary = Color(0xFF1D9E75);

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) {
      if (mounted) setState(() => _isLoading = false);
      return;
    }

    setState(() => _isLoading = true);
    final list = await _serviceFirestore.getArchivedServices(uid);
    if (mounted) {
      setState(() {
        _archived = list;
        _isLoading = false;
      });
    }
  }

  Future<void> _restore(ServiceModel service) async {
    await _serviceFirestore.restoreService(service.id);
    await _load();
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Annonce restaurée ✅'),
          backgroundColor: Colors.green,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: primary,
        foregroundColor: Colors.white,
        title: const Text(
          'Annonces archivées',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _load,
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator(color: primary))
          : _archived.isEmpty
              ? const Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.archive_outlined, size: 64, color: Colors.grey),
                      SizedBox(height: 12),
                      Text(
                        'Aucune annonce archivée',
                        style: TextStyle(color: Colors.grey),
                      ),
                    ],
                  ),
                )
              : ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: _archived.length,
                  itemBuilder: (context, i) {
                    final service = _archived[i];
                    return Card(
                      margin: const EdgeInsets.only(bottom: 10),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: ListTile(
                        leading: ClipRRect(
                          borderRadius: BorderRadius.circular(8),
                          child: service.photos.isNotEmpty
                              ? Image.network(
                                  service.photos.first,
                                  width: 56,
                                  height: 56,
                                  fit: BoxFit.cover,
                                )
                              : Container(
                                  width: 56,
                                  height: 56,
                                  color: const Color(0xFFE8F5F0),
                                  child: const Icon(
                                    Icons.image_outlined,
                                    color: primary,
                                  ),
                                ),
                        ),
                        title: Text(
                          service.titre,
                          style: const TextStyle(fontWeight: FontWeight.bold),
                        ),
                        subtitle: Text(
                          '${service.prix.toStringAsFixed(0)} FCFA • ${service.categorie}',
                        ),
                        trailing: TextButton(
                          onPressed: () => _restore(service),
                          child: const Text(
                            'Restaurer',
                            style: TextStyle(
                              color: primary,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ),
                    );
                  },
                ),
    );
  }
}
