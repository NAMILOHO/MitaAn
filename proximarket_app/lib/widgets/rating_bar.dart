import 'package:flutter/material.dart';

class RatingBar extends StatelessWidget {
  final double rating;
  final int count;
  final double size;
  final bool showCount;

  const RatingBar({
    super.key,
    required this.rating,
    this.count = 0,
    this.size = 16,
    this.showCount = true,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        ...List.generate(5, (i) {
          if (i < rating.floor()) {
            return Icon(
              Icons.star_rounded,
              size: size,
              color: const Color(0xFFFFA726),
            );
          } else if (i < rating) {
            return Icon(
              Icons.star_half_rounded,
              size: size,
              color: const Color(0xFFFFA726),
            );
          }
          return Icon(
            Icons.star_outline_rounded,
            size: size,
            color: Colors.grey.shade300,
          );
        }),
        if (showCount && count > 0) ...[
          const SizedBox(width: 4),
          Text(
            '($count)',
            style: TextStyle(fontSize: size * 0.75, color: Colors.grey),
          ),
        ],
      ],
    );
  }
}
