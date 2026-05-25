import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:firebase_crashlytics/firebase_crashlytics.dart';
import 'package:shared_preferences/shared_preferences.dart';

class DebugScreen extends StatefulWidget {
  const DebugScreen({super.key});

  @override
  State<DebugScreen> createState() => _DebugScreenState();
}

class _DebugScreenState extends State<DebugScreen> {
  static const primary = Color(0xFF1D9E75);
  String _fcmToken = '';
  String _uid = '';
  String _info = '';

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final user = FirebaseAuth.instance.currentUser;
    setState(() => _uid = user?.uid ?? 'non connecté');
  }

  Future<void> _loadFcmToken() async {
    final token = await FirebaseMessaging.instance.getToken();
    setState(() => _fcmToken = token ?? 'indisponible');
  }

  Future<void> _resetOnboarding() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('onboarding_done', false);
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Onboarding réinitialisé — relancez l\'app'),
          backgroundColor: Colors.orange,
        ),
      );
    }
  }

  Future<void> _clearHistory() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('viewed_services');
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Historique effacé ✅'),
          backgroundColor: Colors.green,
        ),
      );
    }
  }

  Future<void> _testCrash() async {
    FirebaseCrashlytics.instance.crash();
  }

  Future<void> _checkFirestore() async {
    try {
      final snap = await FirebaseFirestore.instance
          .collection('services')
          .limit(1)
          .get();
      setState(() => _info = '✅ Firestore OK — ${snap.docs.length} doc(s)');
    } catch (e) {
      setState(() => _info = '❌ Firestore erreur : $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    if (kReleaseMode) {
      return const Scaffold(
        body: Center(child: Text('Non disponible en production')),
      );
    }

    return Scaffold(
      backgroundColor: const Color(0xFFF5F5F5),
      appBar: AppBar(
        backgroundColor: primary,
        foregroundColor: Colors.white,
        title: const Text(
          '🛠 Debug MitaAn',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          _section('Utilisateur', [
            _infoTile('UID', _uid),
          ]),
          _section('FCM Token', [
            if (_fcmToken.isNotEmpty)
              SelectableText(
                _fcmToken,
                style: const TextStyle(fontSize: 11, color: Colors.grey),
              ),
            _actionBtn('Charger le token FCM', _loadFcmToken),
          ]),
          _section('Firestore', [
            if (_info.isNotEmpty)
              Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: Text(_info),
              ),
            _actionBtn('Tester la connexion Firestore', _checkFirestore),
          ]),
          _section('SharedPreferences', [
            _actionBtn(
              'Réinitialiser l\'onboarding',
              _resetOnboarding,
              color: Colors.orange,
            ),
            const SizedBox(height: 8),
            _actionBtn(
              'Effacer l\'historique',
              _clearHistory,
              color: Colors.orange,
            ),
          ]),
          _section('Crashlytics', [
            _actionBtn(
              'Déclencher un crash test',
              _testCrash,
              color: Colors.red,
            ),
          ]),
          const SizedBox(height: 8),
          const Center(
            child: Text(
              'v1.0.0-beta • debug build',
              style: TextStyle(color: Colors.grey, fontSize: 11),
            ),
          ),
        ],
      ),
    );
  }

  Widget _section(String title, List<Widget> children) {
    return Container(
      margin: const EdgeInsets.only(bottom: 14),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFEEEEF2)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: const TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 13,
              color: Colors.black87,
            ),
          ),
          const SizedBox(height: 10),
          ...children,
        ],
      ),
    );
  }

  Widget _infoTile(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 4),
      child: Row(
        children: [
          Text(
            '$label : ',
            style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 12),
          ),
          Expanded(
            child: SelectableText(
              value,
              style: const TextStyle(fontSize: 12, color: Colors.grey),
            ),
          ),
        ],
      ),
    );
  }

  Widget _actionBtn(
    String label,
    VoidCallback onTap, {
    Color color = const Color(0xFF1D9E75),
  }) {
    return SizedBox(
      width: double.infinity,
      child: ElevatedButton(
        onPressed: onTap,
        style: ElevatedButton.styleFrom(
          backgroundColor: color,
          foregroundColor: Colors.white,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10),
          ),
          padding: const EdgeInsets.symmetric(vertical: 12),
        ),
        child: Text(label, style: const TextStyle(fontSize: 13)),
      ),
    );
  }
}
