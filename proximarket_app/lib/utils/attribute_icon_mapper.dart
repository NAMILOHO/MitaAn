import 'package:flutter/material.dart';

class AttributeIconMapper {
  AttributeIconMapper._();

  static const Map<String, IconData> _map = {
    'chambre': Icons.bed_rounded,
    'chambres': Icons.bed_rounded,
    'salle de bain': Icons.bathtub_rounded,
    'salles de bain': Icons.bathtub_rounded,
    'surface': Icons.square_foot_rounded,
    'meublé': Icons.chair_rounded,
    'type de bien': Icons.home_work_rounded,
    'étage': Icons.stairs_rounded,
    'état': Icons.verified_rounded,
    'marque': Icons.local_offer_rounded,
    'année': Icons.calendar_today_rounded,
    'kilométrage': Icons.speed_rounded,
    'durée': Icons.timer_rounded,
    'zone d\'intervention': Icons.map_rounded,
    'expérience': Icons.workspace_premium_rounded,
    'date': Icons.event_rounded,
    'lieu': Icons.place_rounded,
    'capacité': Icons.groups_rounded,
  };

  static IconData iconFor(String key) {
    return _map[key.trim().toLowerCase()] ?? Icons.label_rounded;
  }
}
