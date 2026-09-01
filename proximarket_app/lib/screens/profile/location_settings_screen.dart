import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

import '../../core/enums/location_mode.dart';
import '../../services/live_location_service.dart';
import '../../services/location_service.dart';
import '../../widgets/location_mode_selector.dart';

class LocationSettingsScreen extends StatefulWidget {
  final String currentMode;

  const LocationSettingsScreen({super.key, required this.currentMode});

  @override
  State<LocationSettingsScreen> createState() => _LocationSettingsScreenState();
}

class _LocationSettingsScreenState extends State<LocationSettingsScreen> {
  static const primary = Color(0xFF1D9E75);

  late String _selectedMode;
  bool _isSaving = false;
  final _liveService = LiveLocationService();
  final _locationService = LocationService();

  @override
  void initState() {
    super.initState();
    _selectedMode = widget.currentMode;
  }

  Future<void> _save() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    setState(() => _isSaving = true);

    DateTime? expiry;
    double? fixedLat;
    double? fixedLng;
    String? fixedAddress;

    if (_selectedMode == 'meeting' || _selectedMode == 'mobileSeller') {
      expiry = DateTime.now().add(const Duration(hours: 2));
    }

    if (_selectedMode == 'fixed') {
      try {
        final position = await _locationService.getCurrentPosition();
        final city = await _locationService.getCityFromCoordinates(
          position.latitude,
          position.longitude,
        );
        fixedLat = position.latitude;
        fixedLng = position.longitude;
        fixedAddress = city;
      } catch (_) {
        if (!mounted) return;
        setState(() => _isSaving = false);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Impossible d\'obtenir votre position GPS'),
            backgroundColor: Colors.red,
          ),
        );
        return;
      }
    }

    final mode = LocationModeExt.fromString(_selectedMode);
    if (_usesLiveTracking(mode)) {
      _liveService.startLiveTracking(user.uid);
    } else {
      _liveService.stopLiveTracking();
    }

    try {
      await _liveService.setLocationMode(
        user.uid,
        mode,
        expiry: expiry,
        fixedLat: fixedLat,
        fixedLng: fixedLng,
        fixedAddress: fixedAddress,
      );
    } catch (_) {
      if (!mounted) return;
      setState(() => _isSaving = false);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Impossible de mettre a jour le mode de localisation'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    if (!mounted) return;
    setState(() => _isSaving = false);
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Mode de localisation mis a jour'),
        backgroundColor: Colors.green,
      ),
    );
    Navigator.pop(context, true);
  }

  bool _usesLiveTracking(LocationMode mode) {
    return mode == LocationMode.service ||
        mode == LocationMode.meeting ||
        mode == LocationMode.delivery ||
        mode == LocationMode.mobileSeller;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FA),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded, size: 18),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          'Visibilite & Localisation',
          style: TextStyle(
            fontSize: 17,
            fontWeight: FontWeight.w700,
            color: Color(0xFF0D1117),
          ),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            Container(
              padding: const EdgeInsets.all(14),
              margin: const EdgeInsets.only(bottom: 20),
              decoration: BoxDecoration(
                color: const Color(0xFFFFF3E0),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: const Color(0xFFFFCC80)),
              ),
              child: const Row(
                children: [
                  Icon(
                    Icons.security_rounded,
                    color: Color(0xFFBA7517),
                    size: 20,
                  ),
                  SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      'Votre position n\'est jamais publique. Vous controlez entierement votre visibilite.',
                      style: TextStyle(fontSize: 12, color: Color(0xFF633806)),
                    ),
                  ),
                ],
              ),
            ),
            LocationModeSelector(
              currentMode: _selectedMode,
              onModeChanged: (mode) => setState(() => _selectedMode = mode),
            ),
            const SizedBox(height: 24),
            SizedBox(
              width: double.infinity,
              height: 52,
              child: ElevatedButton(
                onPressed: _isSaving ? null : _save,
                style: ElevatedButton.styleFrom(
                  backgroundColor: primary,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: _isSaving
                    ? const CircularProgressIndicator(
                        color: Colors.white,
                        strokeWidth: 2,
                      )
                    : const Text(
                        'Appliquer',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
