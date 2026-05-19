import 'dart:io';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../models/service_model.dart';
import '../../providers/service_provider.dart';
import '../../services/location_service.dart';
import '../../services/service_firestore.dart';
import '../../services/cloudinary_service.dart';

class EditServiceScreen extends StatefulWidget {
  final ServiceModel service;

  const EditServiceScreen({super.key, required this.service});

  @override
  State<EditServiceScreen> createState() => _EditServiceScreenState();
}

class _EditServiceScreenState extends State<EditServiceScreen> {
  final _formKey = GlobalKey<FormState>();

  late TextEditingController _titreController;
  late TextEditingController _descriptionController;
  late TextEditingController _prixController;

  late String _selectedCategory;
  late String _selectedUnite;

  // Photos existantes (URLs Cloudinary)
  late List<String> _existingPhotos;

  // Nouvelles photos choisies localement
  final List<File> _newImages = [];

  bool _isLoading = false;
  bool _isLoadingLocation = false;

  late double _gpsLat;
  late double _gpsLng;
  late String _ville;

  static const Color primaryColor = Color(0xFF1D9E75);
  static const int _maxPhotos = 4;

  final LocationService _locationService = LocationService();
  final ServiceFirestore _serviceFirestore = ServiceFirestore();

  final List<String> _categories = [
    'Artisan', 'Artiste', 'Éleveur', 'Commerçant',
    'Plombier', 'Électricien', 'Menuisier', 'Autre',
  ];

  final List<String> _unites = ['forfait', 'par heure', 'par jour'];

  @override
  void initState() {
    super.initState();
    // ✅ Pré-remplir tous les champs avec les valeurs existantes
    _titreController =
        TextEditingController(text: widget.service.titre);
    _descriptionController =
        TextEditingController(text: widget.service.description);
    _prixController =
        TextEditingController(text: widget.service.prix.toStringAsFixed(0));

    _selectedCategory = widget.service.categorie.isNotEmpty
        ? widget.service.categorie
        : _categories.first;

    _selectedUnite = _unites.contains(widget.service.unite)
        ? widget.service.unite
        : 'forfait';

    _existingPhotos = List<String>.from(widget.service.photos);
    _gpsLat = widget.service.gpsLat;
    _gpsLng = widget.service.gpsLng;
    _ville  = widget.service.ville;
  }

  @override
  void dispose() {
    _titreController.dispose();
    _descriptionController.dispose();
    _prixController.dispose();
    super.dispose();
  }

  // ─────────────────────────────────────────
  // AJOUTER DE NOUVELLES PHOTOS
  // ─────────────────────────────────────────
  Future<void> _pickNewImages() async {
    final remaining = _maxPhotos - _existingPhotos.length - _newImages.length;
    if (remaining <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Maximum 4 photos atteint'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    try {
      final images = await _serviceFirestore.pickImages();
      if (images.isNotEmpty) {
        setState(() {
          final toAdd = images.take(remaining).toList();
          _newImages.addAll(toAdd);
        });
      }
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(e.toString()), backgroundColor: Colors.red),
      );
    }
  }

  // ─────────────────────────────────────────
  // SUPPRIMER UNE PHOTO EXISTANTE
  // ─────────────────────────────────────────
  void _removeExistingPhoto(int index) {
    setState(() => _existingPhotos.removeAt(index));
  }

  // ─────────────────────────────────────────
  // SUPPRIMER UNE NOUVELLE PHOTO
  // ─────────────────────────────────────────
  void _removeNewImage(int index) {
    setState(() => _newImages.removeAt(index));
  }

  // ─────────────────────────────────────────
  // METTRE À JOUR LA POSITION GPS
  // ─────────────────────────────────────────
  Future<void> _refreshLocation() async {
    setState(() => _isLoadingLocation = true);
    try {
      final position = await _locationService.getCurrentPosition();
      final city = await _locationService.getCityFromCoordinates(
        position.latitude,
        position.longitude,
      );
      if (mounted) {
        setState(() {
          _gpsLat = position.latitude;
          _gpsLng = position.longitude;
          _ville  = city;
        });
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Erreur GPS : $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoadingLocation = false);
    }
  }

  // ─────────────────────────────────────────
  // ENREGISTRER LES MODIFICATIONS
  // ─────────────────────────────────────────
  Future<void> _saveChanges() async {
    if (!(_formKey.currentState?.validate() ?? false)) return;

    final totalPhotos =
        _existingPhotos.length + _newImages.length;
    if (totalPhotos == 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Au moins une photo est requise'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    setState(() => _isLoading = true);

    try {
      // 1. Uploader les nouvelles photos en parallèle
      List<String> newUrls = [];
      if (_newImages.isNotEmpty) {
        newUrls = await _serviceFirestore.uploadServicePhotos(
          widget.service.userId,
          _newImages,
        );
      }

      // 2. Fusionner anciennes + nouvelles URLs
      final allPhotos = [..._existingPhotos, ...newUrls];

      // 3. Construire le map de mise à jour
      final data = {
        'titre':       _titreController.text.trim(),
        'description': _descriptionController.text.trim(),
        'categorie':   _selectedCategory,
        'prix':        double.tryParse(_prixController.text.trim()) ?? 0.0,
        'unite':       _selectedUnite,
        'photos':      allPhotos,
        'gpsLat':      _gpsLat,
        'gpsLng':      _gpsLng,
        'ville':       _ville,
      };

      // 4. Mettre à jour Firestore
      await _serviceFirestore.updateService(widget.service.id, data);

      // 5. Rafraîchir la liste locale dans le provider
      await context
          .read<ServiceProvider>()
          .loadMyServices(widget.service.userId);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Annonce mise à jour ✅'),
            backgroundColor: Colors.green,
          ),
        );
        Navigator.pop(context, true); // ✅ retourner true = rafraîchir
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Erreur : $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  // ─────────────────────────────────────────
  // BUILD
  // ─────────────────────────────────────────
  @override
  Widget build(BuildContext context) {
    final totalPhotos = _existingPhotos.length + _newImages.length;

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.black),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          'Modifier l\'annonce',
          style: TextStyle(
              color: Colors.black, fontWeight: FontWeight.bold),
        ),
      ),
      body: _isLoading
          ? const Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  CircularProgressIndicator(color: primaryColor),
                  SizedBox(height: 16),
                  Text('Enregistrement en cours...'),
                ],
              ),
            )
          : SingleChildScrollView(
              padding: const EdgeInsets.all(20),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [

                    // ── SECTION 1 : Informations ──────────────────
                    _sectionTitle('Informations'),
                    const SizedBox(height: 12),

                    // Titre
                    TextFormField(
                      controller: _titreController,
                      decoration:
                          _inputDecoration('Titre', Icons.title),
                      validator: (v) {
                        if (v == null || v.trim().isEmpty) {
                          return 'Titre requis';
                        }
                        if (v.trim().length < 5) {
                          return 'Minimum 5 caractères';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 14),

                    // Catégorie
                    DropdownButtonFormField<String>(
                      value: _selectedCategory,
                      decoration: _inputDecoration(
                          'Catégorie', Icons.category_outlined),
                      items: _categories
                          .map((c) => DropdownMenuItem(
                              value: c, child: Text(c)))
                          .toList(),
                      onChanged: (v) =>
                          setState(() => _selectedCategory = v!),
                    ),
                    const SizedBox(height: 14),

                    // Description
                    TextFormField(
                      controller: _descriptionController,
                      maxLines: 4,
                      decoration: _inputDecoration(
                          'Description', Icons.description),
                      validator: (v) {
                        if (v == null || v.trim().isEmpty) {
                          return 'Description requise';
                        }
                        if (v.trim().length < 20) {
                          return 'Minimum 20 caractères';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 14),

                    // Prix + Unité
                    Row(
                      children: [
                        Expanded(
                          flex: 3,
                          child: TextFormField(
                            controller: _prixController,
                            keyboardType: TextInputType.number,
                            decoration: _inputDecoration(
                                'Prix (FCFA)', Icons.payments),
                            validator: (v) {
                              if (v == null || v.trim().isEmpty) {
                                return 'Prix requis';
                              }
                              final val = double.tryParse(v.trim());
                              if (val == null || val < 0) {
                                return 'Valeur invalide';
                              }
                              return null;
                            },
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          flex: 2,
                          child: DropdownButtonFormField<String>(
                            value: _selectedUnite,
                            decoration: _inputDecoration(
                                'Unité', Icons.access_time),
                            items: _unites
                                .map((u) => DropdownMenuItem(
                                    value: u, child: Text(u)))
                                .toList(),
                            onChanged: (v) =>
                                setState(() => _selectedUnite = v!),
                          ),
                        ),
                      ],
                    ),

                    const SizedBox(height: 24),

                    // ── SECTION 2 : Photos ────────────────────────
                    Row(
                      children: [
                        _sectionTitle('Photos'),
                        const Spacer(),
                        Text(
                          '$totalPhotos / $_maxPhotos',
                          style: TextStyle(
                            color: totalPhotos == 0
                                ? Colors.red
                                : Colors.grey,
                            fontSize: 13,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),

                    Wrap(
                      spacing: 10,
                      runSpacing: 10,
                      children: [
                        // Bouton ajouter photo
                        if (totalPhotos < _maxPhotos)
                          GestureDetector(
                            onTap: _pickNewImages,
                            child: Container(
                              width: 85,
                              height: 85,
                              decoration: BoxDecoration(
                                border: Border.all(
                                    color: primaryColor, width: 2),
                                borderRadius:
                                    BorderRadius.circular(10),
                              ),
                              child: const Column(
                                mainAxisAlignment:
                                    MainAxisAlignment.center,
                                children: [
                                  Icon(Icons.add_photo_alternate,
                                      color: primaryColor, size: 26),
                                  SizedBox(height: 4),
                                  Text(
                                    'Ajouter',
                                    style: TextStyle(
                                        color: primaryColor,
                                        fontSize: 11),
                                  ),
                                ],
                              ),
                            ),
                          ),

                        // Photos existantes (URLs)
                        ..._existingPhotos.asMap().entries.map((e) =>
                            _photoTile(
                              child: Image.network(
                                e.value,
                                fit: BoxFit.cover,
                                width: 85,
                                height: 85,
                                errorBuilder: (_, __, ___) =>
                                    _photoError(),
                              ),
                              onRemove: () =>
                                  _removeExistingPhoto(e.key),
                            )),

                        // Nouvelles photos (fichiers locaux)
                        ..._newImages.asMap().entries.map((e) =>
                            _photoTile(
                              child: Image.file(
                                e.value,
                                fit: BoxFit.cover,
                                width: 85,
                                height: 85,
                              ),
                              onRemove: () => _removeNewImage(e.key),
                              isNew: true,
                            )),
                      ],
                    ),

                    if (totalPhotos == 0) ...[
                      const SizedBox(height: 8),
                      const Text(
                        '⚠️  Au moins une photo est requise',
                        style: TextStyle(
                            color: Colors.orange, fontSize: 12),
                      ),
                    ],

                    const SizedBox(height: 24),

                    // ── SECTION 3 : Localisation ──────────────────
                    _sectionTitle('Localisation'),
                    const SizedBox(height: 12),

                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(14),
                      decoration: BoxDecoration(
                        color: primaryColor.withValues(alpha: 0.08),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                            color: primaryColor.withValues(alpha: 0.3)),
                      ),
                      child: Row(
                        children: [
                          const Icon(Icons.location_on,
                              color: primaryColor, size: 20),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Text(
                              _ville.isNotEmpty
                                  ? _ville
                                  : 'Position non disponible',
                              style: const TextStyle(
                                  fontWeight: FontWeight.w500),
                            ),
                          ),
                          if (_isLoadingLocation)
                            const SizedBox(
                              width: 18,
                              height: 18,
                              child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  color: primaryColor),
                            ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 8),

                    TextButton.icon(
                      onPressed:
                          _isLoadingLocation ? null : _refreshLocation,
                      icon: const Icon(Icons.refresh,
                          color: primaryColor, size: 16),
                      label: const Text(
                        'Mettre à jour ma position',
                        style: TextStyle(color: primaryColor),
                      ),
                    ),

                    const SizedBox(height: 32),

                    // ── BOUTON ENREGISTRER ──
                    SizedBox(
                      width: double.infinity,
                      height: 52,
                      child: ElevatedButton(
                        onPressed: _isLoading ? null : _saveChanges,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: primaryColor,
                          foregroundColor: Colors.white,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        child: const Text(
                          'Enregistrer les modifications',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
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

  // ─────────────────────────────────────────
  // WIDGETS HELPERS
  // ─────────────────────────────────────────
  Widget _sectionTitle(String title) {
    return Text(
      title,
      style: const TextStyle(
        fontSize: 16,
        fontWeight: FontWeight.bold,
        color: Colors.black87,
      ),
    );
  }

  Widget _photoTile({
    required Widget child,
    required VoidCallback onRemove,
    bool isNew = false,
  }) {
    return Stack(
      children: [
        ClipRRect(
          borderRadius: BorderRadius.circular(10),
          child: SizedBox(width: 85, height: 85, child: child),
        ),
        // Badge "Nouveau"
        if (isNew)
          Positioned(
            bottom: 4,
            left: 4,
            child: Container(
              padding:
                  const EdgeInsets.symmetric(horizontal: 5, vertical: 2),
              decoration: BoxDecoration(
                color: Colors.blue.withValues(alpha: 0.85),
                borderRadius: BorderRadius.circular(4),
              ),
              child: const Text(
                'Nouveau',
                style: TextStyle(color: Colors.white, fontSize: 9),
              ),
            ),
          ),
        // Bouton supprimer
        Positioned(
          top: 4,
          right: 4,
          child: GestureDetector(
            onTap: onRemove,
            child: Container(
              decoration: const BoxDecoration(
                color: Colors.red,
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.close, color: Colors.white, size: 16),
            ),
          ),
        ),
      ],
    );
  }

  Widget _photoError() {
    return Container(
      width: 85,
      height: 85,
      color: const Color(0xFFE8F5F0),
      child: const Icon(Icons.broken_image_outlined,
          color: primaryColor, size: 28),
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