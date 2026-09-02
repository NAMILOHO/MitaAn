import 'package:flutter/material.dart';

import '../utils/attribute_icon_mapper.dart';

class AttributesGrid extends StatelessWidget {
  final Map<String, String> attributs;

  const AttributesGrid({super.key, required this.attributs});

  static const Color primary = Color(0xFF1D9E75);
  static const Color bg = Color(0xFFF8F9FA);
  static const Color border = Color(0xFFEEEEF2);

  @override
  Widget build(BuildContext context) {
    final entries =
        attributs.entries.where((e) => e.value.trim().isNotEmpty).toList();
    if (entries.isEmpty) return const SizedBox.shrink();

    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      padding: EdgeInsets.zero,
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        mainAxisSpacing: 8,
        crossAxisSpacing: 8,
        childAspectRatio: 3.2,
      ),
      itemCount: entries.length,
      itemBuilder: (context, i) {
        final e = entries[i];
        return Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
          decoration: BoxDecoration(
            color: bg,
            borderRadius: BorderRadius.circular(10),
            border: Border.all(color: border),
          ),
          child: Row(
            children: [
              Icon(AttributeIconMapper.iconFor(e.key), size: 16, color: primary),
              const SizedBox(width: 8),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      e.key,
                      style: const TextStyle(fontSize: 10, color: Colors.grey),
                      overflow: TextOverflow.ellipsis,
                    ),
                    Text(
                      e.value,
                      style: const TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}
