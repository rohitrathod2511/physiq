import 'package:flutter/material.dart';
import 'package:physiq/theme/design_system.dart';
import 'package:physiq/widgets/leaderboard/leaderboard_data.dart';

class LeaderboardScreen extends StatelessWidget {
  const LeaderboardScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final allUsers = LeaderboardData.getFullList();
    final topThree = allUsers.take(3).toList();
    final remainingUsers = allUsers.skip(3).toList();
    final currentUser = LeaderboardData.currentUser;

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.arrow_back, color: AppColors.primaryText),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          'Leaderboard',
          style: AppTextStyles.h2.copyWith(fontWeight: FontWeight.bold),
        ),
        centerTitle: true,
      ),
      body: Stack(
        children: [
          Column(
            children: [
              const SizedBox(height: 20),
              // Top 3 Hero Section
              _buildTopThreeSection(topThree),
              const SizedBox(height: 32),

              // Rank List Section
              Expanded(
                child: Container(
                  decoration: BoxDecoration(
                    color: AppColors.card,
                    borderRadius: const BorderRadius.only(
                      topLeft: Radius.circular(32),
                      topRight: Radius.circular(32),
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.05),
                        blurRadius: 20,
                        offset: const Offset(0, -5),
                      ),
                    ],
                  ),
                  child: ClipRRect(
                    borderRadius: const BorderRadius.only(
                      topLeft: Radius.circular(32),
                      topRight: Radius.circular(32),
                    ),
                    child: ListView.separated(
                      physics: const BouncingScrollPhysics(),
                      padding: const EdgeInsets.fromLTRB(16, 24, 16, 100),
                      itemCount: remainingUsers.length,
                      separatorBuilder: (context, index) => Divider(
                        height: 1,
                        color: AppColors.secondaryText.withOpacity(0.05),
                        indent: 50,
                      ),
                      itemBuilder: (context, index) {
                        final user = remainingUsers[index];
                        final isCurrentUser = user.rank == currentUser.rank;
                        return _buildRankRow(user, isCurrentUser);
                      },
                    ),
                  ),
                ),
              ),
            ],
          ),
          // Floating Current User Rank Card
          Positioned(
            bottom: 0,
            left: 0,
            right: 0,
            child: Container(
              padding: const EdgeInsets.only(
                bottom: 10,
              ), // Space for bottom nav bar
              color: AppColors.background, // To hide content underneath
              child: _buildRankRow(currentUser, true),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTopThreeSection(List<LeaderboardUser> topThree) {
    if (topThree.length < 3) return const SizedBox();

    // Order: 2nd, 1st, 3rd
    final first = topThree[0];
    final second = topThree[1];
    final third = topThree[2];

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          // 2nd Place
          Expanded(child: _buildTopUserBlock(second, 2, false)),
          // 1st Place (Elevated)
          Expanded(child: _buildTopUserBlock(first, 1, true)),
          // 3rd Place
          Expanded(child: _buildTopUserBlock(third, 3, false)),
        ],
      ),
    );
  }

  Widget _buildTopUserBlock(LeaderboardUser user, int rank, bool isFirst) {
    Color crownColor;
    double size = isFirst ? 100 : 80;
    double fontSize = isFirst ? 40 : 32;

    if (rank == 1) {
      crownColor = const Color(0xFFFFD700); // Gold
    } else if (rank == 2) {
      crownColor = const Color(0xFFC0C0C0); // Silver
    } else {
      crownColor = const Color(0xFFCD7F32); // Bronze
    }

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        // Crown
        Icon(
          Icons.workspace_premium,
          color: crownColor,
          size: isFirst ? 32 : 24,
        ),
        const SizedBox(height: 4),
        // Rank Number Container
        Container(
          width: size,
          height: size,
          decoration: BoxDecoration(
            color: AppColors.card,
            shape: BoxShape.circle,
            border: Border.all(
              color: crownColor.withOpacity(0.5),
              width: isFirst ? 4 : 2,
            ),
            boxShadow: [
              BoxShadow(
                color: crownColor.withOpacity(0.2),
                blurRadius: 15,
                spreadRadius: 2,
              ),
            ],
          ),
          alignment: Alignment.center,
          child: Text(
            '$rank',
            style: AppTextStyles.largeNumber.copyWith(
              fontSize: fontSize,
              color: AppColors.primaryText,
            ),
          ),
        ),
        const SizedBox(height: 12),
        // Username
        Text(
          user.name,
          style: AppTextStyles.bodyBold.copyWith(fontSize: isFirst ? 16 : 14),
          textAlign: TextAlign.center,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
        const SizedBox(height: 4),
        // Points
        Text(
          '${user.points} Pts',
          style: AppTextStyles.label.copyWith(
            color: crownColor,
            fontWeight: FontWeight.bold,
            fontSize: isFirst ? 14 : 12,
          ),
        ),
        if (isFirst) const SizedBox(height: 20), // Lift first place up
      ],
    );
  }

  Widget _buildRankRow(LeaderboardUser user, bool isCurrentUser) {
    return Container(
      margin: const EdgeInsets.symmetric(vertical: 4),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: isCurrentUser
            ? AppColors.primary.withOpacity(0.05)
            : Colors.transparent,
        borderRadius: BorderRadius.circular(16),
        border: isCurrentUser
            ? Border.all(color: AppColors.primary.withOpacity(0.1))
            : null,
      ),
      child: Row(
        children: [
          // Rank Number
          SizedBox(
            width: 40,
            child: Text(
              '${user.rank}',
              style: AppTextStyles.bodyBold.copyWith(
                color: AppColors.secondaryText.withOpacity(0.6),
                fontSize: 15,
              ),
            ),
          ),
          const SizedBox(width: 8),
          // Flag (Optional, but kept from logic if needed, or remove if strictly following "No profile images")
          // Reference shows only Username. I'll remove flag for cleaner look.

          // Username
          Expanded(
            child: Text(
              user.name,
              style: AppTextStyles.bodyMedium.copyWith(
                fontWeight: isCurrentUser ? FontWeight.w700 : FontWeight.w500,
              ),
            ),
          ),
          // Points
          Text(
            '${user.points} Pts',
            style: AppTextStyles.bodyBold.copyWith(
              fontSize: 15,
              color: isCurrentUser
                  ? AppColors.primaryText
                  : AppColors.secondaryText,
            ),
          ),
        ],
      ),
    );
  }
}
