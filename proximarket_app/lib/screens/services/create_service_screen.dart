import 'dart:io';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:provider/provider.dart';

import '../../core/enums/type_annonce.dart';
import '../../providers/service_provider.dart';
import '../../services/location_service.dart';
import '../../widgets/attributes_input_field.dart';

class CreateServiceScreen extends StatefulWidget {
  const CreateServiceScreen({super.key});

  @override
  State<CreateServiceScreen> createState() => _CreateServiceScreenState();
}

class _CreateServiceScreenState extends State<CreateServiceScreen> {
  // Stepper
  int _currentStep = 0;

  // Clés de formulaire
  final _step1Key = GlobalKey<FormState>();

  // Contrôleurs
  final _titreController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _prixController = TextEditingController();
  final _quantityController = TextEditingController();

  // Données
  String? _selectedCategory;
  String _selectedUnite = 'forfait';
  List<File> _selectedImages = [];
  TypeAnnonce _typeAnnonce = TypeAnnonce.autre;
  Map<String, String> _attributs = {};

  // GPS
  double _gpsLat = 0.0;
  double _gpsLng = 0.0;
  String _ville = '';
  bool _locationLoaded = false;
  bool _isLoading = false;

  static const Color primaryColor = Color(0xFF1D9E75);

  final LocationService _locationService = LocationService();

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

  final List<String> _unites = [
    'forfait',
    'par heure',
    'par jour',
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
    _quantityController.dispose();
    super.dispose();
  }

  // =============================================
  // GPS
  // =============================================
  Future<void> _loadLocation() async {
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
          _ville = city;
          _locationLoaded = true;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() => _locationLoaded = true);
      }
    }
  }

  // =============================================
  // PHOTOS
  // =============================================
  Future<void> _pickImages() async {
    try {
      final images = await context
          .read<ServiceProvider>()
          .serviceFirestore
          .pickImages();

      if (images.isNotEmpty && mounted) {
        setState(() {
          _selectedImages = [
            ..._selectedImages,
            ...images,
          ].take(4).cast<File>().toList();
        });
      }
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Erreur: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  void _removeImage(int index) {
    setState(() => _selectedImages.removeAt(index));
  }

  // =============================================
  // NAVIGATION STEPPER
  // =============================================
  void _onStepContinue() {
    if (_currentStep == 0) {
      if (!(_step1Key.currentState?.validate() ?? false)) return;

      if ((_selectedCategory ?? '').trim().isEmpty) {
        _showError('Veuillez renseigner une catégorie.');
        return;
      }

      final prix = double.tryParse(_prixController.text.trim());
      if (_prixController.text.trim().isNotEmpty &&
          (prix == null || prix < 0)) {
        _showError('Le prix doit être un nombre positif.');
        return;
      }

      setState(() => _currentStep = 1);
      return;
    }

    if (_currentStep == 1) {
      setState(() => _currentStep = 2);
      return;
    }

    if (_currentStep == 2) {
      if (_selectedImages.isEmpty) {
        _showError('Ajoutez au moins une photo');
        return;
      }
      setState(() => _currentStep = 3);
      return;
    }

    if (_currentStep == 3) {
      _publish();
    }
  }

  void _onStepCancel() {
    if (_currentStep > 0) {
      setState(() => _currentStep--);
    }
  }

  // =============================================
  // PUBLICATION SÉCURISÉE
  // =============================================
  Future<void> _publish() async {
    // Validation finale avant envoi
    final titre = _titreController.text.trim();
    final description = _descriptionController.text.trim();
    final prixStr = _prixController.text.trim();
    final prix = double.tryParse(prixStr) ?? -1;

    if (titre.length < 5 || titre.length > 100) {
      _showError('Le titre doit contenir entre 5 et 100 caractères.');
      return;
    }
    if (description.length < 20) {
      _showError('La description doit contenir au moins 20 caractères.');
      return;
    }
    if (prix <= 0 && prixStr.isNotEmpty) {
      _showError('Le prix doit être supérieur à 0 (ou laisser vide pour "à négocier").');
      return;
    }
    if (_selectedImages.isEmpty) {
      _showError('Ajoutez au moins une photo.');
      return;
    }
    if ((_selectedCategory ?? '').trim().isEmpty) {
      _showError('Veuillez renseigner une catégorie.');
      return;
    }

    setState(() => _isLoading = true);

    final uid = FirebaseAuth.instance.currentUser!.uid;

    final success = await context.read<ServiceProvider>().createService(
      userId: uid,
      titre: titre,
      description: description,
      categorie: _selectedCategory!.trim(),
      prix: prix < 0 ? 0.0 : prix,
      unite: _selectedUnite,
      quantity: int.tryParse(_quantityController.text.trim()) ?? 0,
      imageFiles: _selectedImages,
      gpsLat: _gpsLat,
      gpsLng: _gpsLng,
      ville: _ville,
      typeAnnonce: _typeAnnonce.firestoreKey,
      attributs: _attributs,
    );

    setState(() => _isLoading = false);

    if (!mounted) return;

    if (success) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Annonce publiée avec succès ✅'),
          backgroundColor: Colors.green,
        ),
      );
      _resetForm();
      if (mounted && Navigator.canPop(context)) {
        Navigator.pop(context);
      }
    } else {
      final err = context.read<ServiceProvider>().errorMessage;
      _showError(err ?? 'Erreur lors de la publication');
    }
  }

  // Helper pour afficher les erreurs
  void _showError(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.red,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  void _resetForm() {
    _titreController.clear();
    _descriptionController.clear();
    _prixController.clear();
    _quantityController.clear();
    setState(() {
      _currentStep = 0;
      _selectedCategory = null;
      _selectedUnite = 'forfait';
      _selectedImages = [];
      _typeAnnonce = TypeAnnonce.autre;
      _attributs = {};
    });
    _loadLocation();
  }

  // =============================================
  // BUILD
  // =============================================
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.close, color: Colors.black),
          onPressed: () {
            if (Navigator.canPop(context)) {
              Navigator.pop(context);
            }
          },
        ),
        title: const Text(
          'Publier une annonce',
          style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold),
        ),
      ),
      body: _isLoading
          ? const Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  CircularProgressIndicator(color: primaryColor),
                  SizedBox(height: 16),
                  Text('Publication en cours...'),
                ],
              ),
            )
          : Stepper(
              currentStep: _currentStep,
              onStepContinue: _onStepContinue,
              onStepCancel: _onStepCancel,
              onStepTapped: (step) {
                if (step <= _currentStep) {
                  setState(() => _currentStep = step);
                }
              },
              controlsBuilder: (context, details) {
                return Padding(
                  padding: const EdgeInsets.only(top: 16),
                  child: Row(
                    children: [
                      Expanded(
                        child: ElevatedButton(
                          onPressed: details.onStepContinue,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: primaryColor,
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(vertical: 14),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                          child: Text(
                            _currentStep == 3 ? 'Publier l\'annonce' : 'Suivant',
                            style: const TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 16,
                            ),
                          ),
                        ),
                      ),
                      if (_currentStep > 0) ...[
                        const SizedBox(width: 12),
                        TextButton(
                          onPressed: details.onStepCancel,
                          child: const Text(
                            'Retour',
                            style: TextStyle(color: Colors.grey, fontSize: 16),
                          ),
                        ),
                      ],
                    ],
                  ),
                );
              },
              steps: [
                _buildStep1(),
                _buildStepAttributs(),
                _buildStep2(),
                _buildStep3(),
              ],
            ),
    );
  }

  // =============================================
  // ÉTAPES
  // =============================================
  Step _buildStep1() {
    return Step(
      title: const Text('Informations'),
      subtitle: const Text('Titre, catégorie, description, prix'),
      isActive: _currentStep >= 0,
      state: _currentStep > 0 ? StepState.complete : StepState.indexed,
      content: Form(
        key: _step1Key,
        child: Column(
          children: [
            TextFormField(
              controller: _titreController,
              decoration: _inputDecoration('Titre de l\'annonce', Icons.title),
              validator: (v) {
                if (v == null || v.trim().isEmpty) return 'Titre requis';
                if (v.trim().length < 5) return 'Minimum 5 caractères';
                if (v.trim().length > 100) return 'Maximum 100 caractères';
                return null;
              },
            ),
            const SizedBox(height: 16),

            Autocomplete<String>(
              optionsBuilder: (value) {
                final input = value.text.trim().toLowerCase();
                if (input.isEmpty) return _categories;
                return _categories.where(
                  (c) => c.toLowerCase().contains(input),
                );
              },
              onSelected: (value) => setState(() => _selectedCategory = value),
              fieldViewBuilder: (context, controller, focusNode, onSubmit) {
                if ((_selectedCategory ?? '').isNotEmpty &&
                    controller.text != _selectedCategory) {
                  controller.text = _selectedCategory!;
                  controller.selection = TextSelection.collapsed(
                    offset: controller.text.length,
                  );
                }
                return TextFormField(
                  controller: controller,
                  focusNode: focusNode,
                  decoration: _inputDecoration(
                    'Catégorie (libre)',
                    Icons.category_outlined,
                  ),
                  onChanged: (value) => _selectedCategory = value,
                  validator: (value) {
                    if (value == null || value.trim().isEmpty) {
                      return 'Catégorie requise';
                    }
                    return null;
                  },
                );
              },
            ),
            const SizedBox(height: 16),

            TextFormField(
              controller: _descriptionController,
              maxLines: 4,
              decoration: _inputDecoration('Description du service', Icons.description),
              validator: (v) {
                if (v == null || v.trim().isEmpty) return 'Description requise';
                if (v.trim().length < 20) return 'Minimum 20 caractères';
                return null;
              },
            ),
            const SizedBox(height: 16),

            Row(
              children: [
                Expanded(
                  flex: 3,
                  child: TextFormField(
                    controller: _prixController,
                    keyboardType: TextInputType.number,
                    decoration: _inputDecoration('Prix (FCFA)', Icons.payments),
                    validator: (v) {
                      if (v == null || v.trim().isEmpty) return 'Prix requis';
                      final val = double.tryParse(v.trim());
                      if (val == null) return 'Nombre invalide';
                      if (val < 0) return 'Prix invalide';
                      return null;
                    },
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  flex: 2,
                  child: DropdownButtonFormField<String>(
                    value: _selectedUnite,
                    decoration: _inputDecoration('Unité', Icons.access_time),
                    items: _unites
                        .map((u) => DropdownMenuItem(value: u, child: Text(u)))
                        .toList(),
                    onChanged: (v) => setState(() => _selectedUnite = v ?? 'forfait'),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _quantityController,
              keyboardType: TextInputType.number,
              decoration: _inputDecoration(
                'Stock disponible (optionnel)',
                Icons.inventory_2_outlined,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Step _buildStepAttributs() {
    return Step(
      title: const Text('Détails'),
      subtitle: const Text('Type et caractéristiques'),
      isActive: _currentStep >= 1,
      state: _currentStep > 1 ? StepState.complete : StepState.indexed,
      content: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: TypeAnnonce.values.map((type) {
              final selected = _typeAnnonce == type;
              return ChoiceChip(
                label: Text(type.label),
                selected: selected,
                selectedColor: primaryColor.withValues(alpha: 0.2),
                checkmarkColor: primaryColor,
                onSelected: (_) => setState(() => _typeAnnonce = type),
              );
            }).toList(),
          ),
          const SizedBox(height: 16),
          AttributesInputField(
            typeAnnonce: _typeAnnonce,
            attributs: _attributs,
            onChanged: (value) => setState(() => _attributs = value),
          ),
        ],
      ),
    );
  }

  Step _buildStep2() {
    return Step(
      title: const Text('Photos'),
      subtitle: Text('${_selectedImages.length}/4 photos'),
      isActive: _currentStep >= 2,
      state: _currentStep > 2 ? StepState.complete : StepState.indexed,
      content: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Ajoutez jusqu\'à 4 photos de votre service',
            style: TextStyle(color: Colors.grey, fontSize: 13),
          ),
          const SizedBox(height: 12),

          Wrap(
            spacing: 10,
            runSpacing: 10,
            children: [
              if (_selectedImages.length < 4)
                GestureDetector(
                  onTap: _pickImages,
                  child: Container(
                    width: 90,
                    height: 90,
                    decoration: BoxDecoration(
                      border: Border.all(color: primaryColor, width: 2),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.add_photo_alternate, color: primaryColor, size: 28),
                        SizedBox(height: 4),
                        Text('Ajouter', style: TextStyle(color: primaryColor, fontSize: 11)),
                      ],
                    ),
                  ),
                ),

              ..._selectedImages.asMap().entries.map((entry) {
                return Stack(
                  children: [
                    Container(
                      width: 90,
                      height: 90,
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
                      right: 4,
                      child: GestureDetector(
                        onTap: () => _removeImage(entry.key),
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
              }),
            ],
          ),
        ],
      ),
    );
  }

  Step _buildStep3() {
    return Step(
      title: const Text('Localisation'),
      subtitle: const Text('Confirmer votre position'),
      isActive: _currentStep >= 3,
      state: StepState.indexed,
      content: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Votre annonce sera visible pour les utilisateurs proches de cette position.',
            style: TextStyle(color: Colors.grey, fontSize: 13),
          ),
          const SizedBox(height: 16),

          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: primaryColor.withValues(alpha: 0.08),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: primaryColor.withValues(alpha: 0.3)),
            ),
            child: Row(
              children: [
                const Icon(Icons.location_on, color: primaryColor),
                const SizedBox(width: 12),
                Expanded(
                  child: _locationLoaded
                      ? Text(
                          _ville.isNotEmpty ? _ville : 'Position non disponible',
                          style: const TextStyle(fontWeight: FontWeight.w500),
                        )
                      : const Row(
                          children: [
                            SizedBox(
                              width: 16,
                              height: 16,
                              child: CircularProgressIndicator(strokeWidth: 2, color: primaryColor),
                            ),
                            SizedBox(width: 8),
                            Text('Récupération de la position...'),
                          ],
                        ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),

          TextButton.icon(
            onPressed: _loadLocation,
            icon: const Icon(Icons.refresh, color: primaryColor, size: 18),
            label: const Text(
              'Mettre à jour ma position',
              style: TextStyle(color: primaryColor),
            ),
          ),

          const SizedBox(height: 24),
          const Text(
            'Récapitulatif',
            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
          ),
          const SizedBox(height: 12),
          _buildRecapRow('Titre', _titreController.text.trim()),
          _buildRecapRow('Catégorie', _selectedCategory ?? '-'),
          _buildRecapRow('Type', _typeAnnonce.label),
          _buildRecapRow(
            'Prix',
            _prixController.text.isNotEmpty ? '${_prixController.text} FCFA / $_selectedUnite' : '-',
          ),
          if (_attributs.values.any((value) => value.trim().isNotEmpty))
            _buildRecapRow(
              'Détails',
              _attributs.entries
                  .where((entry) => entry.value.trim().isNotEmpty)
                  .map((entry) => '${entry.key}: ${entry.value}')
                  .join(' • '),
            ),
          _buildRecapRow('Photos', '${_selectedImages.length} photo(s)'),
        ],
      ),
    );
  }

  Widget _buildRecapRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 90,
            child: Text('$label :', style: const TextStyle(color: Colors.grey, fontSize: 14)),
          ),
          Expanded(
            child: Text(
              value.isEmpty ? '-' : value,
              style: const TextStyle(fontWeight: FontWeight.w500, fontSize: 14),
            ),
          ),
        ],
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
      contentPadding: const EdgeInsets.symmetric(vertical: 16, horizontal: 12),
    );
  }
}
