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
              children: [
                // Trophy Icon
                Container(
                  width: 50,
                  height: 50,
                  alignment: Alignment.center,
                  child: Icon(
                    Icons.emoji_events,
                    size: 44,
                    color: AppColors.primaryText,
                  ),
                ),
                const SizedBox(width: 16),
                
                // Rank Info
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Rank #7',
                      style: AppTextStyles.heading2.copyWith(fontSize: 22),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '2,840 pts',
                      style: AppTextStyles.heading3.copyWith(
                        fontWeight: FontWeight.normal,
                      ),
                    ),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 20),
            
            // Highlight Text
            Text(
              '#1 Amit Kumar is currently leading the leaderboard',
              textAlign: TextAlign.center,
              style: AppTextStyles.body.copyWith(
                color: AppColors.secondaryText,
                fontSize: 14,
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
                    color: AppColors.background, // Match Join Card button text color
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
