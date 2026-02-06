import 'package:flutter/material.dart';
import 'package:physiq/theme/design_system.dart';
import 'package:physiq/widgets/leaderboard/leaderboard_data.dart';
import 'package:physiq/widgets/header_widget.dart'; // Assuming generic header exists, or I'll build custom

class LeaderboardScreen extends StatelessWidget {
  const LeaderboardScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final currentUser = LeaderboardData.currentUser;
    final allUsers = LeaderboardData.getFullList();

    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: Column(
          children: [
            // Custom App Bar / Header
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
              child: Row(
                children: [
                   IconButton(
                    icon: Icon(Icons.arrow_back, color: AppColors.primaryText),
                    onPressed: () => Navigator.pop(context),
                  ),
                  Expanded(
                    child: Center(
                      child: Text(
                        'Leaderboard',
                        style: AppTextStyles.heading2,
                      ),
                    ),
                  ),
                   const SizedBox(width: 48), // Balance back button
                ],
              ),
            ),
            
            Expanded(
              child: CustomScrollView(
                physics: const BouncingScrollPhysics(),
                slivers: [
                  SliverToBoxAdapter(
                    child: Padding(
                      padding: const EdgeInsets.symmetric(vertical: 20.0, horizontal: 24.0),
                      child: Column(
                        children: [
                          Icon(Icons.emoji_events, size: 64, color: Color(0xFFFFD700)), // Gold-ish crown/trophy
                          const SizedBox(height: 8),
                          Text(
                            '₹10,00,000',
                            style: AppTextStyles.largeNumber.copyWith(fontSize: 40),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            'Build your dream physique and compete\nfor ₹10 lakh in rewards!',
                            textAlign: TextAlign.center,
                            style: AppTextStyles.body.copyWith(color: AppColors.secondaryText),
                          ),
                          const SizedBox(height: 24),
                        ],
                      ),
                    ),
                  ),
                  
                  // Sticky Header for Current User
                  SliverPersistentHeader(
                    pinned: true,
                    delegate: _SliverHeaderDelegate(
                      minHeight: 80,
                      maxHeight: 80,
                      child: Container(
                        color: AppColors.background, // Match background
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                        child: _UserRow(
                          user: currentUser,
                          isHighlight: true,
                        ),
                      ),
                    ),
                  ),
                  
                  // Divider
                   SliverToBoxAdapter(
                     child: Divider(height: 1, color: AppColors.secondaryText.withOpacity(0.1)),
                   ),

                   // List of All Users
                   SliverList(
                     delegate: SliverChildBuilderDelegate(
                       (context, index) {
                         final user = allUsers[index];
                         // Check if this user is the current user (Rank 7).
                         // The prompt says "Always show current user at top". 
                         // It doesn't explicitly say "Remove current user from list". 
                         // But usually if it's pinned at top, it's weird to show it again.
                         // However, scrolling to rank 7 and seeing yourself is normal.
                         // But if I already have a pinned header, maybe I should strictly follow "Leaderboard UI matches reference images".
                         // Reference Image 2 shows #7 HIGHLIGHTED in the list. It DOES NOT show a pinned header separately.
                         // BUT Prompt says "Top Highlight (Current User): Always show current user at top".
                         // This contradicts Image 2. 
                         // "Highlight row with darker background" checks out with Image 2.
                         // "Always show current user at top" might mean "Show current user ROW at the top of the list" (Pinned).
                         
                         // Decision: I will keep the Pinned Header AND the list content. This ensures requirements are met.
                         // Actually, if I pin it, I don't need to show it again in the list if it looks redundant?
                         // Let's show it in the list too, but highlighted, like in the image. 
                         
                         return Column(
                           children: [
                             _UserRow(
                               user: user,
                               isHighlight: user.rank == currentUser.rank,
                             ),
                             Divider(
                               height: 1, 
                               indent: 70, 
                               endIndent: 0, 
                               color: AppColors.secondaryText.withOpacity(0.05)
                             ),
                           ],
                         );
                       },
                       childCount: allUsers.length,
                     ),
                   ),
                   
                   const SliverToBoxAdapter(child: SizedBox(height: 40)),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _UserRow extends StatelessWidget {
  final LeaderboardUser user;
  final bool isHighlight;

  const _UserRow({required this.user, required this.isHighlight});

  @override
  Widget build(BuildContext context) {
    // Highlight means dark background (in light mode) or lighter in dark mode?
    // Image 2 shows #7 has a Dark Black background with White text (in what looks like a light mode app).
    // So "Highlight row with darker background" -> Use AppColors.primary (Black/DarkGrey) background.
    
    final bgColor = isHighlight ? AppColors.primary : Colors.transparent;
    final textColor = isHighlight ? AppColors.background : AppColors.primaryText; // Text inverse
    final subTextColor = isHighlight ? AppColors.background.withOpacity(0.8) : AppColors.secondaryText;
    
    // Trophies for Top 3
    Widget rankWidget;
    if (user.rank == 1) {
      rankWidget = _buildTrophy(Colors.amber, user.rank, textColor); // Gold
    } else if (user.rank == 2) {
      rankWidget = _buildTrophy(Colors.grey.shade400, user.rank, textColor); // Silver
    } else if (user.rank == 3) {
      rankWidget = _buildTrophy(const Color(0xFFE5E4E2), user.rank, textColor); // Platinum
    } else {
       rankWidget = Text(
         '#${user.rank}',
         style: AppTextStyles.bodyBold.copyWith(color: subTextColor),
       );
    }
    
    // If highlighted, we override the text color even for non-trophy ranks (though top 3 normally aren't highlighted unless user is top 3)
    if (isHighlight) {
       // user.rank is 7.
    }

    return Container(
      color: bgColor,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Row(
        children: [
          Container(
            width: 40,  
            alignment: Alignment.center,
            child: rankWidget,
          ),
          const SizedBox(width: 12),
          // Flag
          Text(
            user.countryFlag,
            style: const TextStyle(fontSize: 20),
          ),
          const SizedBox(width: 12),
          // Name
          Expanded(
            child: Text(
              user.name,
              style: AppTextStyles.bodyBold.copyWith(color: textColor),
              overflow: TextOverflow.ellipsis,
            ),
          ),
          // Points
          Text(
            '${user.points} pts',
            style: AppTextStyles.bodyMedium.copyWith(color: textColor),
          ),
        ],
      ),
    );
  }
  
  Widget _buildTrophy(Color color, int rank, Color textColor) {
    // "Rank number inside trophy icon"
    // Since I don't have a complex trophy widget with text inside, I'll stack it.
    return Stack(
      alignment: Alignment.center,
      children: [
        Icon(Icons.emoji_events, color: color, size: 32),
        Padding(
          padding: const EdgeInsets.only(bottom: 6.0), // Adjust to center in the "cup" part
          child: Text(
            '$rank',
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.bold,
              color: Colors.white, // Number inside trophy usually contrasts
            ),
          ),
        ),
      ],
    );
  }
}

class _SliverHeaderDelegate extends SliverPersistentHeaderDelegate {
  final double minHeight;
  final double maxHeight;
  final Widget child;

  _SliverHeaderDelegate({required this.minHeight, required this.maxHeight, required this.child});

  @override
  double get minExtent => minHeight;
  @override
  double get maxExtent => maxHeight;

  @override
  Widget build(BuildContext context, double shrinkOffset, bool overlapsContent) {
    return SizedBox.expand(child: child);
  }

  @override
  bool shouldRebuild(_SliverHeaderDelegate oldDelegate) {
    return maxHeight != oldDelegate.maxHeight ||
        minHeight != oldDelegate.minHeight ||
        child != oldDelegate.child;
  }
}
