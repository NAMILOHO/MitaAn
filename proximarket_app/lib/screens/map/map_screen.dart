import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:firebase_auth/firebase_auth.dart';

import '../../services/location_service.dart';
import '../../models/user_model.dart';

class MapScreen extends StatefulWidget {
  const MapScreen({super.key});

  @override
  State<MapScreen> createState() => _MapScreenState();
}

class _MapScreenState extends State<MapScreen> {
  static const Color primaryColor = Color(0xFF1D9E75);

  // Position par défaut : Abidjan
  static const LatLng _defaultPosition =
      LatLng(5.3600, -4.0083);

  final LocationService _locationService =
      LocationService();

  LatLng? _userPosition;
  List<UserModel> _pros = [];

  bool _isLoading = true;
  String? _errorMessage;

  // Rayon de recherche
  double _radiusKm = 20.0;

  static const List<double> _rayonOptions = [
    5,
    10,
    20,
    50,
  ];

  // Filtre catégorie
  String? _selectedCategorie;

  static const List<String> _categories = [
    'Tous',
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
    _initMap();
  }

  // ─────────────────────────────────────────
  // INITIALISATION
  // ─────────────────────────────────────────
  Future<void> _initMap() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final position =
          await _locationService.getCurrentPosition();

      _userPosition = LatLng(
        position.latitude,
        position.longitude,
      );

      await _loadPros();

      if (!mounted) return;
    } catch (e) {
      if (mounted) {
        setState(() {
          _errorMessage = e.toString();
        });
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  // ─────────────────────────────────────────
  // CHARGER LES PRESTATAIRES
  // ─────────────────────────────────────────
  Future<void> _loadPros() async {
    if (_userPosition == null) return;

    try {
      final pros =
          await _locationService.getNearbyPros(
        myLat: _userPosition!.latitude,
        myLng: _userPosition!.longitude,
        radiusKm: _radiusKm,
        categorieFilter:
            _selectedCategorie == 'Tous'
                ? null
                : _selectedCategorie,
      );

      final myUid =
          FirebaseAuth.instance.currentUser?.uid;

      final filtered =
          pros.where((u) => u.uid != myUid).toList();

      if (mounted) {
        setState(() {
          _pros = filtered;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _errorMessage = e.toString();
        });
      }
    }
  }

  // ─────────────────────────────────────────
  // APPLIQUER LES FILTRES
  // ─────────────────────────────────────────
  Future<void> _applyFilters() async {
    setState(() {
      _isLoading = true;
    });

    await _loadPros();

    if (mounted) {
      setState(() {
        _isLoading = false;
      });
    }
  }

  // ─────────────────────────────────────────
  // MARKERS
  // ─────────────────────────────────────────
  List<Marker> _buildMarkers() {
    final markers = <Marker>[];

    // POSITION UTILISATEUR
    if (_userPosition != null) {
      markers.add(
        Marker(
          point: _userPosition!,
          width: 50,
          height: 50,
          child: const Tooltip(
            message: 'Ma position',
            child: Icon(
              Icons.my_location,
              color: Colors.blue,
              size: 36,
            ),
          ),
        ),
      );
    }

    // PRESTATAIRES
    for (final pro in _pros) {
      final distance = _userPosition != null
          ? _locationService.calculateDistance(
              _userPosition!.latitude,
              _userPosition!.longitude,
              pro.gpsLat,
              pro.gpsLng,
            )
          : null;

      markers.add(
        Marker(
          point: LatLng(
            pro.gpsLat,
            pro.gpsLng,
          ),
          width: 160,
          height: 60,
          child: GestureDetector(
            onTap: () =>
                _showProBottomSheet(
              pro,
              distance,
            ),
            child: Column(
              mainAxisSize:
                  MainAxisSize.min,
              children: [
                Container(
                  padding:
                      const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: primaryColor,
                    borderRadius:
                        BorderRadius.circular(
                      8,
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black
                            .withOpacity(0.25),
                        blurRadius: 4,
                        offset:
                            const Offset(
                          0,
                          2,
                        ),
                      ),
                    ],
                  ),
                  child: Text(
                    pro.nom
                        .split(' ')
                        .first,
                    style:
                        const TextStyle(
                      color:
                          Colors.white,
                      fontSize: 11,
                      fontWeight:
                          FontWeight.bold,
                    ),
                    overflow:
                        TextOverflow
                            .ellipsis,
                  ),
                ),
                const Icon(
                  Icons.location_on,
                  color:
                      primaryColor,
                  size: 24,
                ),
              ],
            ),
          ),
        ),
      );
    }

    return markers;
  }

  // ─────────────────────────────────────────
  // BOTTOM SHEET
  // ─────────────────────────────────────────
  void _showProBottomSheet(
    UserModel pro,
    double? distance,
  ) {
    showModalBottomSheet(
      context: context,
      shape:
          const RoundedRectangleBorder(
        borderRadius:
            BorderRadius.vertical(
          top: Radius.circular(20),
        ),
      ),
      builder:
          (_) => Padding(
        padding:
            const EdgeInsets.fromLTRB(
          20,
          12,
          20,
          24,
        ),
        child: Column(
          mainAxisSize:
              MainAxisSize.min,
          crossAxisAlignment:
              CrossAxisAlignment.start,
          children: [
            Center(
              child: Container(
                width: 40,
                height: 4,
                decoration:
                    BoxDecoration(
                  color:
                      Colors.grey[300],
                  borderRadius:
                      BorderRadius.circular(
                    2,
                  ),
                ),
              ),
            ),

            const SizedBox(
              height: 16,
            ),

            Row(
              children: [
                CircleAvatar(
                  radius: 28,
                  backgroundColor:
                      primaryColor
                          .withOpacity(
                    0.15,
                  ),
                  backgroundImage:
                      pro.photoUrl
                              .isNotEmpty
                          ? NetworkImage(
                              pro.photoUrl,
                            )
                          : null,
                  child:
                      pro.photoUrl
                              .isEmpty
                          ? Text(
                              pro.nom
                                      .isNotEmpty
                                  ? pro
                                      .nom[0]
                                      .toUpperCase()
                                  : '?',
                              style:
                                  const TextStyle(
                                color:
                                    primaryColor,
                                fontWeight:
                                    FontWeight.bold,
                                fontSize:
                                    20,
                              ),
                            )
                          : null,
                ),

                const SizedBox(
                  width: 12,
                ),

                Expanded(
                  child: Column(
                    crossAxisAlignment:
                        CrossAxisAlignment
                            .start,
                    children: [
                      Text(
                        pro.nom,
                        style:
                            const TextStyle(
                          fontWeight:
                              FontWeight
                                  .bold,
                          fontSize:
                              16,
                        ),
                      ),

                      if (pro
                          .categorie
                          .isNotEmpty)
                        Container(
                          margin:
                              const EdgeInsets.only(
                            top: 4,
                          ),
                          padding:
                              const EdgeInsets.symmetric(
                            horizontal:
                                8,
                            vertical:
                                2,
                          ),
                          decoration:
                              BoxDecoration(
                            color:
                                primaryColor
                                    .withOpacity(
                              0.1,
                            ),
                            borderRadius:
                                BorderRadius.circular(
                              6,
                            ),
                          ),
                          child: Text(
                            pro.categorie,
                            style:
                                const TextStyle(
                              color:
                                  primaryColor,
                              fontSize:
                                  12,
                            ),
                          ),
                        ),
                    ],
                  ),
                ),

                if (distance != null)
                  Column(
                    children: [
                      const Icon(
                        Icons.near_me,
                        color:
                            Colors.grey,
                        size: 16,
                      ),
                      Text(
                        '${distance.toStringAsFixed(1)} km',
                        style:
                            const TextStyle(
                          color:
                              Colors.grey,
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
              ],
            ),

            if (pro.bio.isNotEmpty)
              ...[
                const SizedBox(
                  height: 12,
                ),
                Text(
                  pro.bio,
                  style:
                      const TextStyle(
                    color:
                        Colors.grey,
                    fontSize: 13,
                  ),
                  maxLines: 2,
                  overflow:
                      TextOverflow
                          .ellipsis,
                ),
              ],

            if (pro.ville.isNotEmpty)
              ...[
                const SizedBox(
                  height: 8,
                ),
                Row(
                  children: [
                    const Icon(
                      Icons.location_on,
                      color:
                          Colors.grey,
                      size: 14,
                    ),
                    const SizedBox(
                      width: 4,
                    ),
                    Text(
                      pro.ville,
                      style:
                          const TextStyle(
                        color:
                            Colors.grey,
                        fontSize: 13,
                      ),
                    ),
                  ],
                ),
              ],
          ],
        ),
      ),
    );
  }

  // ─────────────────────────────────────────
  // FILTRES
  // ─────────────────────────────────────────
  void _showFiltersSheet() {
    double tempRadius = _radiusKm;

    String? tempCategorie =
        _selectedCategorie;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape:
          const RoundedRectangleBorder(
        borderRadius:
            BorderRadius.vertical(
          top: Radius.circular(20),
        ),
      ),
      builder:
          (ctx) => StatefulBuilder(
        builder:
            (ctx, setSheetState) =>
                Padding(
          padding:
              const EdgeInsets.fromLTRB(
            20,
            12,
            20,
            32,
          ),
          child: Column(
            mainAxisSize:
                MainAxisSize.min,
            crossAxisAlignment:
                CrossAxisAlignment
                    .start,
            children: [
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  decoration:
                      BoxDecoration(
                    color:
                        Colors.grey[300],
                    borderRadius:
                        BorderRadius.circular(
                      2,
                    ),
                  ),
                ),
              ),

              const SizedBox(
                height: 16,
              ),

              const Text(
                'Filtres',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight:
                      FontWeight.bold,
                ),
              ),

              const SizedBox(
                height: 20,
              ),

              Wrap(
                spacing: 8,
                children:
                    _rayonOptions.map((r) {
                  final isSelected =
                      tempRadius == r;

                  return ChoiceChip(
                    label: Text(
                      '${r.toInt()} km',
                    ),
                    selected:
                        isSelected,
                    selectedColor:
                        primaryColor,
                    labelStyle:
                        TextStyle(
                      color: isSelected
                          ? Colors.white
                          : Colors.black87,
                    ),
                    onSelected:
                        (_) =>
                            setSheetState(
                      () =>
                          tempRadius =
                              r,
                    ),
                  );
                }).toList(),
              ),

              const SizedBox(
                height: 20,
              ),

              Wrap(
                spacing: 8,
                runSpacing: 4,
                children:
                    _categories.map((cat) {
                  final isSelected =
                      (tempCategorie ==
                                  null &&
                              cat ==
                                  'Tous') ||
                          tempCategorie ==
                              cat;

                  return ChoiceChip(
                    label: Text(cat),
                    selected:
                        isSelected,
                    selectedColor:
                        primaryColor,
                    labelStyle:
                        TextStyle(
                      color: isSelected
                          ? Colors.white
                          : Colors.black87,
                    ),
                    onSelected:
                        (_) =>
                            setSheetState(
                      () {
                        tempCategorie =
                            cat ==
                                    'Tous'
                                ? null
                                : cat;
                      },
                    ),
                  );
                }).toList(),
              ),

              const SizedBox(
                height: 24,
              ),

              SizedBox(
                width:
                    double.infinity,
                height: 50,
                child:
                    ElevatedButton(
                  style:
                      ElevatedButton.styleFrom(
                    backgroundColor:
                        primaryColor,
                    foregroundColor:
                        Colors.white,
                  ),
                  onPressed: () {
                    Navigator.pop(
                        ctx);

                    setState(() {
                      _radiusKm =
                          tempRadius;
                      _selectedCategorie =
                          tempCategorie;
                    });

                    _applyFilters();
                  },
                  child: const Text(
                    'Appliquer les filtres',
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ─────────────────────────────────────────
  // UI
  // ─────────────────────────────────────────
  @override
  Widget build(
    BuildContext context,
  ) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor:
            primaryColor,
        automaticallyImplyLeading:
            false,
        title: const Text(
          'Carte des prestataires',
          style: TextStyle(
            color: Colors.white,
            fontWeight:
                FontWeight.bold,
          ),
        ),
        actions: [
          IconButton(
            icon: Stack(
              clipBehavior:
                  Clip.none,
              children: [
                const Icon(
                  Icons.tune,
                  color:
                      Colors.white,
                ),
                if (_selectedCategorie !=
                    null)
                  Positioned(
                    right: -2,
                    top: -2,
                    child: Container(
                      width: 8,
                      height: 8,
                      decoration:
                          const BoxDecoration(
                        color:
                            Colors.orange,
                        shape:
                            BoxShape.circle,
                      ),
                    ),
                  ),
              ],
            ),
            onPressed:
                _isLoading
                    ? null
                    : _showFiltersSheet,
          ),

          IconButton(
            icon: const Icon(
              Icons.refresh,
              color: Colors.white,
            ),
            onPressed:
                _isLoading
                    ? null
                    : _initMap,
          ),
        ],
      ),

      body: _isLoading
          ? const Center(
              child: Column(
                mainAxisAlignment:
                    MainAxisAlignment
                        .center,
                children: [
                  CircularProgressIndicator(
                    color:
                        primaryColor,
                  ),
                  SizedBox(
                    height: 16,
                  ),
                  Text(
                    'Chargement de la carte...',
                  ),
                ],
              ),
            )
          : _errorMessage != null
              ? Center(
                  child: Padding(
                    padding:
                        const EdgeInsets.all(
                      24,
                    ),
                    child: Column(
                      mainAxisAlignment:
                          MainAxisAlignment
                              .center,
                      children: [
                        const Icon(
                          Icons
                              .location_off,
                          size: 64,
                          color:
                              Colors.grey,
                        ),

                        const SizedBox(
                          height: 16,
                        ),

                        Text(
                          _errorMessage!,
                          textAlign:
                              TextAlign
                                  .center,
                        ),

                        const SizedBox(
                          height: 20,
                        ),

                        ElevatedButton.icon(
                          onPressed:
                              _initMap,
                          icon:
                              const Icon(
                            Icons
                                .refresh,
                          ),
                          label:
                              const Text(
                            'Réessayer',
                          ),
                        ),
                      ],
                    ),
                  ),
                )
              : Stack(
                  children: [
                    FlutterMap(
                      options:
                          MapOptions(
                        initialCenter:
                            _userPosition ??
                                _defaultPosition,

                        initialZoom:
                            _radiusKm <= 5
                                ? 14
                                : _radiusKm <=
                                        10
                                    ? 13
                                    : _radiusKm <=
                                            20
                                        ? 12
                                        : 10,

                        minZoom: 5,
                        maxZoom: 18,
                      ),

                      children: [
                        TileLayer(
                          urlTemplate:
                              'https://tile.openstreetmap.org/{z}/{x}/{y}.png',

                          userAgentPackageName:
                              'com.mitan.app',
                        ),

                        MarkerLayer(
                          markers:
                              _buildMarkers(),
                        ),
                      ],
                    ),

                    Positioned(
                      bottom: 16,
                      left: 16,
                      child:
                          Container(
                        padding:
                            const EdgeInsets.symmetric(
                          horizontal:
                              12,
                          vertical:
                              8,
                        ),
                        decoration:
                            BoxDecoration(
                          color:
                              Colors
                                  .white,
                          borderRadius:
                              BorderRadius.circular(
                            10,
                          ),
                          boxShadow: [
                            BoxShadow(
                              color: Colors
                                  .black
                                  .withOpacity(
                                0.1,
                              ),
                              blurRadius:
                                  6,
                            ),
                          ],
                        ),
                        child: Row(
                          mainAxisSize:
                              MainAxisSize
                                  .min,
                          children: [
                            const Icon(
                              Icons
                                  .my_location,
                              color:
                                  Colors
                                      .blue,
                              size: 16,
                            ),

                            const SizedBox(
                              width: 6,
                            ),

                            const Text(
                              'Moi',
                              style:
                                  TextStyle(
                                fontSize:
                                    12,
                              ),
                            ),

                            const SizedBox(
                              width: 12,
                            ),

                            const Icon(
                              Icons
                                  .location_on,
                              color:
                                  primaryColor,
                              size: 16,
                            ),

                            const SizedBox(
                              width: 6,
                            ),

                            Text(
                              '${_pros.length} prestataire${_pros.length > 1 ? 's' : ''}'
                              ' (${_radiusKm.toInt()} km)',
                              style:
                                  const TextStyle(
                                fontSize:
                                    12,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
    );
  }
}