import 'package:flutter/material.dart';

import '../../models/water_reading.dart';
import '../../theme/app_theme.dart';

class QualityCard extends StatelessWidget {
  const QualityCard({
    super.key,
    required this.title,
    required this.value,
    required this.unit,
    required this.quality,
    required this.idealRange,
    required this.icon,
  });

  final String title;
  final String value;
  final String unit;
  final WaterQuality quality;
  final String idealRange;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    final color = switch (quality) {
      WaterQuality.adequate => AppColors.success,
      WaterQuality.attention => AppColors.warning,
      WaterQuality.alert => AppColors.danger,
    };
    final label = switch (quality) {
      WaterQuality.adequate => 'Adequado',
      WaterQuality.attention => 'Atencao',
      WaterQuality.alert => 'Alerta',
    };

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(18),
        child: Row(
          children: [
            Container(
              width: 52,
              height: 52,
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.11),
                borderRadius: BorderRadius.circular(16),
              ),
              child: Icon(icon, color: color, size: 28),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title, style: Theme.of(context).textTheme.titleMedium),
                  const SizedBox(height: 2),
                  Text(
                    idealRange,
                    style: Theme.of(context)
                        .textTheme
                        .bodySmall
                        ?.copyWith(color: Colors.blueGrey),
                  ),
                ],
              ),
            ),
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text.rich(
                  TextSpan(
                    text: value,
                    style: const TextStyle(
                      fontSize: 26,
                      fontWeight: FontWeight.w800,
                      color: AppColors.navy,
                    ),
                    children: [
                      TextSpan(
                        text: unit.isEmpty ? '' : ' $unit',
                        style: const TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ),
                Text(
                  label,
                  style: TextStyle(
                    color: color,
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
