import 'package:flutter/material.dart';
import 'package:share_plus/share_plus.dart';

// CORRECTED: Using a single, consistent import for the design system.
import '../../utils/design_system.dart';

class InviteCard extends StatelessWidget {
  const InviteCard({super.key});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () {
        // This uses the share_plus package to open the native share sheet.
        Share.share(
          'Check out Physiq AI! It helps me track my fitness and nutrition goals. Download it here: [Your App Link]',
          subject: 'Join me on Physiq AI!',
        );
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [
              AppColors.accent.withOpacity(0.8),
              AppColors.accent,
            ],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          // CORRECTED: Used the correct property 'AppRadii.bigCard' instead of 'AppRadii.card'
          borderRadius: BorderRadius.circular(AppRadii.bigCard),
          boxShadow: [
            BoxShadow(
              color: AppColors.accent.withOpacity(0.3),
              blurRadius: 15,
              offset: const Offset(0, 5),
            ),
          ],
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Invite a Friend',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
                SizedBox(height: 4),
                Text(
                  'Share the app and get rewards!',
                  style: TextStyle(
                    fontSize: 14,
                    color: Colors.white70,
                  ),
                ),
              ],
            ),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.2),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.share_outlined,
                color: Colors.white,
                size: 24,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
