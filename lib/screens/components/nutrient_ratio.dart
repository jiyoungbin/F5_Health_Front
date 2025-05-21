// nutrient_ratio.dart
import 'package:flutter/material.dart';

class NutrientRatio extends StatelessWidget {
  final String label;
  final int percent;
  final Color color;

  const NutrientRatio({
    super.key,
    required this.label,
    required this.percent,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          width: 8,
          height: 8,
          color: color,
          margin: const EdgeInsets.only(right: 8),
        ),
        Text(
          "$label  $percent%",
          style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w500),
        )
      ],
    );
  }
}
