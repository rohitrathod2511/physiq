import 'package:flutter/material.dart';
import 'package:physiq/theme/design_system.dart';

class RankCard extends StatelessWidget {
  final VoidCallback onViewLeaderboardTap;

  const RankCard({super.key, required this.onViewLeaderboardTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onViewLeaderboardTap,
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: AppColors.card,
          borderRadius: BorderRadius.circular(AppRadii.card),
          boxShadow: [AppShadows.card],
        ),
        child: Column(
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                // Trophy Icon
                Container(
                  width: 64,
                  height: 64,
                  alignment: Alignment.center,
                  child: Icon(
                    Icons.emoji_events,
                    size: 60,
                    color: AppColors.primaryText,
                  ),
                ),
                const SizedBox(width: 16),

                // Rank Number
                Text(
                  '#7',
                  style: AppTextStyles.heading1.copyWith(
                    fontSize: 48,
                    height: 1.0,
                    fontWeight: FontWeight.w900,
                  ),
                ),

                const Spacer(),

                // Pts Info (Far Right)
                Text.rich(
                  TextSpan(
                    children: [
                      const TextSpan(text: '2,840 '),
                      TextSpan(
                        text: 'Pts',
                        style: TextStyle(
                          fontStyle: FontStyle.italic,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ],
                  ),
                  style: AppTextStyles.heading2.copyWith(
                    fontSize: 24,
                    color: AppColors.secondaryText,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),

            // Highlight Text
            Text.rich(
              TextSpan(
                children: [
                  const TextSpan(text: 'Build your Dream Physique and Earn '),
                  TextSpan(
                    text: '₹1,00,000',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontStyle: FontStyle.italic,
                      color: AppColors.primaryText,
                    ),
                  ),
                ],
              ),
              textAlign: TextAlign.center,
              style: AppTextStyles.body.copyWith(
                color: AppColors.secondaryText,
                fontSize: 14,
                fontWeight: FontWeight.w500,
              ),
            ),

            const SizedBox(height: 16),

            // View Leaderboard Button
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: onViewLeaderboardTap,
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  foregroundColor: AppColors.card, // Inverse
                  elevation: 0,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(30),
                  ),
                ),
                child: Text(
                  'View Leaderboard',
                  style: AppTextStyles.button.copyWith(
                    color: AppColors
                        .background, // Match Join Card button text color
                    fontSize: 16,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
