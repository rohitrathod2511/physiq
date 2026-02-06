import 'package:flutter/material.dart';
import 'package:physiq/theme/design_system.dart';

class JoinCard extends StatelessWidget {
  final VoidCallback onJoinTap;

  const JoinCard({super.key, required this.onJoinTap});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.card,
        borderRadius: BorderRadius.circular(AppRadii.card),
        boxShadow: [AppShadows.card],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Trophy Icon
              Container(
                width: 60,
                height: 60, // Approximate size from image
                alignment: Alignment.center,
                 // Using a standard icon for now as no assets were provided, 
                 // simply using a FontAwesome icon or Material icon that looks like a trophy.
                 // Icons.emoji_events is a trophy.
                child: Icon(
                  Icons.emoji_events,
                  size: 50,
                  color: AppColors.primaryText, // Black in light, White in dark (Image shows black silhouette)
                ),
              ),
              const SizedBox(width: 16),
              // Text Content
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '₹10,00,000',
                      style: AppTextStyles.heading1.copyWith(
                        fontSize: 26, // Slightly adjusted to fit
                        height: 1.1,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Global Physiq Championship',
                      style: AppTextStyles.heading3.copyWith(
                         fontWeight: FontWeight.w700,
                         fontSize: 17,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '6-Month Challenge',
                      style: AppTextStyles.body.copyWith(
                        color: AppColors.secondaryText,
                        fontSize: 15,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          
          // Dashed Divider
          CustomPaint(
            painter: _DashedLinePainter(
              color: AppColors.secondaryText.withOpacity(0.2),
            ),
            size: const Size(double.infinity, 1),
          ),
          
          const SizedBox(height: 16),

          // Footer
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              // Joined Count
              Row(
                children: [
                  Icon(Icons.groups, color: AppColors.secondaryText, size: 20),
                  const SizedBox(width: 8),
                  Text(
                    '18,725 joined',
                    style: AppTextStyles.bodyMedium.copyWith(
                      color: AppColors.secondaryText,
                    ),
                  ),
                ],
              ),
              
              // Join Button
              ElevatedButton(
                onPressed: onJoinTap,
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  foregroundColor: AppColors.card, // Text color inverse of card usually (White on Black button)
                  elevation: 0,
                  padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(30), // Rounded pill shape
                  ),
                ),
                child: Text(
                  'Join Now',
                  style: AppTextStyles.button.copyWith(
                     color: AppColors.background, // Ideally inverse of primary.
                     // AppColors.primary is Black in light -> Text should be White.
                     // AppColors.background is White in light.
                     // In dark mode: primary is DarkGrey -> Text needs to be White?
                     // Let's check AppColors.background again.
                     // Dark mode: Primary is 0xFF333333 (Dark Grey). Background is 0xFF121212 (Black).
                     // If button is 333333, text should be light.
                     // Existing 'Save' button in ProgressScreen uses 'Colors.white' for foreground.
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _DashedLinePainter extends CustomPainter {
  final Color color;
  _DashedLinePainter({required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..strokeWidth = 1.5
      ..style = PaintingStyle.stroke;

    const dashWidth = 4;
    const dashSpace = 4;
    double startX = 0;

    while (startX < size.width) {
      canvas.drawLine(
        Offset(startX, 0),
        Offset(startX + dashWidth, 0),
        paint,
      );
      startX += dashWidth + dashSpace;
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
