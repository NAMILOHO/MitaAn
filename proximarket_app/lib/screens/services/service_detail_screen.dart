import 'package:flutter/material.dart';
import '../../models/service_model.dart';

class ServiceDetailScreen extends StatelessWidget {
  final ServiceModel service;
  final double? distanceKm;

  const ServiceDetailScreen({
    super.key,
    required this.service,
    this.distanceKm,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(service.titre),
        backgroundColor: const Color(0xFF1D9E75),
        foregroundColor: Colors.white,
      ),
      body: const Center(
        child: Text('Détail de l\'annonce — Tâche 9 🚀'),
      ),
    );
  }
}