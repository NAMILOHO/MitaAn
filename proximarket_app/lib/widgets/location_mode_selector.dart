import 'package:flutter/material.dart';

class LocationModeSelector extends StatelessWidget {
  final String currentMode;
  final ValueChanged<String> onModeChanged;

  const LocationModeSelector({
    super.key,
    required this.currentMode,
    required this.onModeChanged,
  });

  static const _modes = [
    _LocationModeOption(
      mode: 'off',
      icon: Icons.visibility_off_rounded,
      color: Color(0xFF9E9E9E),
      label: 'Invisible',
      desc: 'Personne ne vous voit',
    ),
    _LocationModeOption(
      mode: 'fixed',
      icon: Icons.store_rounded,
      color: Color(0xFF1D9E75),
      label: 'Position fixe',
      desc: 'Boutique / Ferme / Atelier',
    ),
    _LocationModeOption(
      mode: 'service',
      icon: Icons.build_rounded,
      color: Color(0xFF185FA5),
      label: 'En service',
      desc: 'Visible pendant ma mission',
    ),
    _LocationModeOption(
      mode: 'meeting',
      icon: Icons.handshake_rounded,
      color: Color(0xFFBA7517),
      label: 'Rencontre',
      desc: 'Partage temporaire (2h)',
    ),
    _LocationModeOption(
      mode: 'delivery',
      icon: Icons.local_shipping_rounded,
      color: Color(0xFF6F4CC3),
      label: 'Livraison',
      desc: 'Suivi pendant une livraison',
    ),
    _LocationModeOption(
      mode: 'mobileSeller',
      icon: Icons.directions_walk_rounded,
      color: Color(0xFF993556),
      label: 'Vendeur mobile',
      desc: 'Visible en deplacement',
    ),
  ];

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Mode de localisation',
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w700,
            color: Color(0xFF0D1117),
          ),
        ),
        const SizedBox(height: 10),
        ..._modes.map((mode) {
          final selected = currentMode == mode.mode;

          return GestureDetector(
            onTap: () => onModeChanged(mode.mode),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              margin: const EdgeInsets.only(bottom: 8),
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
              decoration: BoxDecoration(
                color: selected
                    ? mode.color.withValues(alpha: 0.1)
                    : Colors.white,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: selected ? mode.color : const Color(0xFFEEEEF2),
                  width: selected ? 2 : 1,
                ),
              ),
              child: Row(
                children: [
                  Container(
                    width: 40,
                    height: 40,
                    decoration: BoxDecoration(
                      color: selected
                          ? mode.color.withValues(alpha: 0.15)
                          : const Color(0xFFF8F9FA),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Icon(
                      mode.icon,
                      color: selected ? mode.color : const Color(0xFFB0B7C3),
                      size: 20,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          mode.label,
                          style: TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                            color: selected
                                ? mode.color
                                : const Color(0xFF0D1117),
                          ),
                        ),
                        Text(
                          mode.desc,
                          style: const TextStyle(
                            fontSize: 11,
                            color: Color(0xFF6B7280),
                          ),
                        ),
                      ],
                    ),
                  ),
                  if (selected)
                    Icon(
                      Icons.check_circle_rounded,
                      color: mode.color,
                      size: 20,
                    ),
                ],
              ),
            ),
          );
        }),
      ],
    );
  }
}

class _LocationModeOption {
  final String mode;
  final IconData icon;
  final Color color;
  final String label;
  final String desc;

  const _LocationModeOption({
    required this.mode,
    required this.icon,
    required this.color,
    required this.label,
    required this.desc,
  });
}
