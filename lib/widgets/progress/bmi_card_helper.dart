import 'package:flutter/widgets.dart';
import 'package:physiq/theme/design_system.dart';

Widget _buildBmiRow(String label, String range, Color color) {
  return Padding(
    padding: const EdgeInsets.symmetric(vertical: 4.0),
    child: Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Row(
          children: [
            Container(
              width: 12,
              height: 12,
              decoration: BoxDecoration(color: color, shape: BoxShape.circle),
            ),
            const SizedBox(width: 8),
            Text(label, style: AppTextStyles.bodyMedium),
          ],
        ),
        Text(range, style: AppTextStyles.body.copyWith(fontFamily: 'Inter')),
      ],
    ),
  );
}
