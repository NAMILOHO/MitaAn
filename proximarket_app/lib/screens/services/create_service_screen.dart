import 'dart:io';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:provider/provider.dart';

import '../../providers/service_provider.dart';
import '../../services/service_firestore.dart';
import '../../services/location_service.dart';

class CreateServiceScreen extends StatefulWidget {
  const CreateServiceScreen({super.key});

  @override
  State<CreateServiceScreen> createState() => _CreateServiceScreenState();
}

class _CreateServiceScreenState extends State<CreateServiceScreen> {
  final _formKey = GlobalKey<FormState>();
  final ServiceFirestore _serviceFirestore = ServiceFirestore();
  final LocationService _locationService = LocationService();

  final _titreController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _prixController = TextEditingController();

  String? _selectedCategory;
  List<File> _selectedImages = [];
  bool _isLoading = false;
  double _gpsLat = 0.0;
  double _gpsLng = 0.0;
  String _ville = '';
  bool _locationLoaded = false;

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
    _loadLocation();
  }

  @override
  void dispose() {
    _titreController.dispose();
    _descriptionController.dispose();
    _prixController.dispose();
    super.dispose();
  }

  // Charger la position GPS automatiquement
  Future<void> _loadLocation() async {
    try {
      final position = await _locationService.getCurrentPosition();
      final city = await _locationService.getCityFromCoordinates(
        position.latitude,
        position.longitude,
      );
      setState(() {
        _gpsLat = position.latitude;
        _gpsLng = position.longitude;
        _ville = city;
        _locationLoaded = true;
      });
    } catch (e) {
      setState(() => _locationLoaded = true);
    }
  }

  // Choisir des photos
  Future<void> _pickImages() async {
    try {
      final images = await _serviceFirestore.pickImages();
      if (images.isNotEmpty) {
        setState(() {
          _selectedImages = [..._selectedImages, ...images].take(4).toList();
        });
      }
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(e.toString())),
      );
    }
  }

  // Supprimer une photo
  void _removeImage(int index) {
    setState(() => _selectedImages.removeAt(index));
  }

  // ====================== CORRECTION : Méthode _publish ======================
  Future<void> _publish() async {
    if (!_formKey.currentState!.validate()) return;
    if (_selectedCategory == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Veuillez sélectionner une catégorie'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    setState(() => _isLoading = true);

    final uid = FirebaseAuth.instance.currentUser!.uid;
    final serviceProvider = context.read<ServiceProvider>();

    final success = await serviceProvider.createService(
      userId: uid,
      titre: _titreController.text.trim(),
      description: _descriptionController.text.trim(),
      categorie: _selectedCategory!,
      prix: double.tryParse(_prixController.text.trim()) ?? 0.0,
      imageFiles: _selectedImages,
      gpsLat: _gpsLat,
      gpsLng: _gpsLng,
      ville: _ville,
    );

    setState(() => _isLoading = false);

    if (success) {
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Annonce publiée avec succès ✅'),
          backgroundColor: Colors.green,
        ),
      );

      // Vider le formulaire pour permettre une nouvelle publication
      _formKey.currentState!.reset();
      _titreController.clear();
      _descriptionController.clear();
      _prixController.clear();

      setState(() {
        _selectedCategory = null;
        _selectedImages = [];
      });

      // Recharger la localisation
      _loadLocation();
    } else if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(serviceProvider.errorMessage ?? 'Erreur lors de la publication'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }
  // ============================================================================

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.black),
          onPressed: () {
            if (Navigator.canPop(context)) {
              Navigator.pop(context);
            }
          },
        ),
        title: const Text(
          'Publier une annonce',
          style: TextStyle(
            color: Colors.black,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // ── Photos ──
              const Text(
                'Photos (max 4)',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 15,
                ),
              ),
              const SizedBox(height: 10),
              SizedBox(
                height: 100,
                child: ListView(
                  scrollDirection: Axis.horizontal,
                  children: [
                    if (_selectedImages.length < 4)
                      GestureDetector(
                        onTap: _pickImages,
                        child: Container(
                          width: 100,
                          height: 100,
                          margin: const EdgeInsets.only(right: 10),
                          decoration: BoxDecoration(
                            border: Border.all(
                              color: primaryColor,
                              width: 2,
                              style: BorderStyle.solid,
                            ),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: const Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(Icons.add_photo_alternate,
                                  color: primaryColor, size: 30),
                              SizedBox(height: 4),
                              Text(
                                'Ajouter',
                                style: TextStyle(
                                  color: primaryColor,
                                  fontSize: 12,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ..._selectedImages.asMap().entries.map((entry) {
                      return Stack(
                        children: [
                          Container(
                            width: 100,
                            height: 100,
                            margin: const EdgeInsets.only(right: 10),
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(12),
                              image: DecorationImage(
                                image: FileImage(entry.value),
                                fit: BoxFit.cover,
                              ),
                            ),
                          ),
                          Positioned(
                            top: 4,
                            right: 14,
                            child: GestureDetector(
                              onTap: () => _removeImage(entry.key),
                              child: Container(
                                decoration: const BoxDecoration(
                                  color: Colors.red,
                                  shape: BoxShape.circle,
                                ),
                                child: const Icon(
                                  Icons.close,
                                  color: Colors.white,
                                  size: 18,
                                ),
                              ),
                            ),
                          ),
                        ],
                      );
                    }),
                  ],
                ),
              ),
              const SizedBox(height: 20),

              // Titre
              TextFormField(
                controller: _titreController,
                decoration: _inputDecoration('Titre de l\'annonce', Icons.title),
                validator: (v) => v == null || v.isEmpty ? 'Le titre est requis' : null,
              ),
              const SizedBox(height: 16),

              // Catégorie
              DropdownButtonFormField<String>(
                initialValue: _selectedCategory,
                decoration: _inputDecoration('Catégorie', Icons.category),
                hint: const Text('Choisir une catégorie'),
                items: _categories.map((cat) {
                  return DropdownMenuItem(value: cat, child: Text(cat));
                }).toList(),
                onChanged: (v) => setState(() => _selectedCategory = v),
              ),
              const SizedBox(height: 16),

              // Description
              TextFormField(
                controller: _descriptionController,
                maxLines: 4,
                decoration: _inputDecoration('Description du service', Icons.description),
                validator: (v) => v == null || v.length < 10 ? 'Minimum 10 caractères' : null,
              ),
              const SizedBox(height: 16),

              // Prix
              TextFormField(
                controller: _prixController,
                keyboardType: TextInputType.number,
                decoration: _inputDecoration('Prix (FCFA)', Icons.payments),
                validator: (v) {
                  if (v == null || v.isEmpty) return 'Le prix est requis';
                  if (double.tryParse(v) == null) return 'Entrez un nombre valide';
                  return null;
                },
              ),
              const SizedBox(height: 16),

              // Localisation
              Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: primaryColor.withValues(alpha: 0.08),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: primaryColor.withValues(alpha: 0.3)),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.location_on, color: primaryColor),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        _locationLoaded
                            ? (_ville.isNotEmpty ? _ville : 'Position non disponible')
                            : 'Récupération de la position...',
                        style: const TextStyle(fontSize: 14),
                      ),
                    ),
                    if (!_locationLoaded)
                      const SizedBox(
                        width: 16,
                        height: 16,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: primaryColor,
                        ),
                      ),
                  ],
                ),
              ),
              const SizedBox(height: 32),

              // Bouton Publier
              SizedBox(
                width: double.infinity,
                height: 54,
                child: ElevatedButton(
                  onPressed: _isLoading ? null : _publish,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: primaryColor,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: _isLoading
                      ? const CircularProgressIndicator(color: Colors.white)
                      : const Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.send),
                            SizedBox(width: 8),
                            Text(
                              'Publier l\'annonce',
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                ),
              ),
              const SizedBox(height: 20),
            ],
          ),
        ),
      ),
    );
  }

  InputDecoration _inputDecoration(String label, IconData icon) {
    return InputDecoration(
      labelText: label,
      prefixIcon: Icon(icon, color: primaryColor),
      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: primaryColor, width: 2),
      ),
    );
  }
}