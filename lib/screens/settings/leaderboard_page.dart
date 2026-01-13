import 'package:flutter/material.dart';
import 'package:physiq/theme/design_system.dart';
import 'package:physiq/services/leaderboard_service.dart';
import 'package:firebase_auth/firebase_auth.dart';

class LeaderboardPage extends StatefulWidget {
  const LeaderboardPage({super.key});

  @override
  State<LeaderboardPage> createState() => _LeaderboardPageState();
}

class _LeaderboardPageState extends State<LeaderboardPage> {
  final _leaderboardService = LeaderboardService();
  final _auth = FirebaseAuth.instance;
  List<LeaderItem> _top10 = [];
  int _myRank = 0;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    final uid = _auth.currentUser?.uid;
    final top10 = await _leaderboardService.fetchTop10();
    int myRank = 0;
    
    if (uid != null) {
      // Check if in top 10
      final meInTop10 = top10.indexWhere((item) => item.uid == uid);
      if (meInTop10 != -1) {
        myRank = top10[meInTop10].rank;
      } else {
        // Fetch rank
        myRank = await _leaderboardService.fetchUserRank(uid);
      }
    }

    if (mounted) {
      setState(() {
        _top10 = top10;
        _myRank = myRank;
        _isLoading = false;
      });
    }
  }

  int _selectedTab = 0; // 0: Gain Weight, 1: Lose Weight

  @override
  Widget build(BuildContext context) {
    final uid = _auth.currentUser?.uid;

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: Text('Leaderboard', style: AppTextStyles.heading2),
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: const BackButton(color: AppColors.primaryText),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : Column(
              children: [
                // Motivational Banner
                Container(
                  width: double.infinity,
                  margin: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      colors: [Color(0xFF1E1E1E), Color(0xFF3A3A3A)], // Premium dark
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    borderRadius: BorderRadius.circular(AppRadii.bigCard),
                    boxShadow: [AppShadows.card],
                  ),
                  child: Column(
                    children: [
                
                      const SizedBox(height: 8),
                      Text(
                        'Win ₹1,00,000 by staying consistent and healthy',
                        style: AppTextStyles.h2.copyWith(color: Colors.white),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Top performers get exclusive rewards',
                        style: AppTextStyles.smallLabel.copyWith(color: Colors.white70),
                      ),
                    ],
                  ),
                ),
                
                // Tabs (Gain / Lose)
                Container(
                  margin: const EdgeInsets.symmetric(horizontal: 24),
                  padding: const EdgeInsets.all(4),
                  decoration: BoxDecoration(
                    color: AppColors.card,
                    borderRadius: BorderRadius.circular(30),
                  ),
                  child: Row(
                    children: [
                      Expanded(
                        child: GestureDetector(
                          onTap: () => setState(() => _selectedTab = 0),
                          child: Container(
                            padding: const EdgeInsets.symmetric(vertical: 12),
                            decoration: BoxDecoration(
                              color: _selectedTab == 0 ? AppColors.primary : Colors.transparent,
                              borderRadius: BorderRadius.circular(24),
                            ),
                            child: Center(
                              child: Text(
                                'Gain Weight',
                                style: AppTextStyles.bodyBold.copyWith(
                                  color: _selectedTab == 0 ? Colors.white : AppColors.secondaryText,
                                ),
                              ),
                            ),
                          ),
                        ),
                      ),
                      Expanded(
                        child: GestureDetector(
                          onTap: () => setState(() => _selectedTab = 1),
                          child: Container(
                            padding: const EdgeInsets.symmetric(vertical: 12),
                            decoration: BoxDecoration(
                              color: _selectedTab == 1 ? AppColors.primary : Colors.transparent,
                              borderRadius: BorderRadius.circular(24),
                            ),
                            child: Center(
                              child: Text(
                                'Lose Weight',
                                style: AppTextStyles.bodyBold.copyWith(
                                  color: _selectedTab == 1 ? Colors.white : AppColors.secondaryText,
                                ),
                              ),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),

                // My Rank if not in top 10 (Optional UI enhancement)
                if (uid != null && !_top10.any((i) => i.uid == uid) && _myRank > 0)
                   Padding(
                     padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
                     child: Text('Your Rank: #$_myRank', style: AppTextStyles.bodyBold),
                   ),

                // List
                Expanded(
                  child: ListView.builder(
                    padding: const EdgeInsets.symmetric(horizontal: 24),
                    itemCount: _top10.length,
                    itemBuilder: (context, index) {
                      final user = _top10[index];
                      final isMe = user.uid == uid;
                      
                      return Container(
                        margin: const EdgeInsets.only(bottom: 12),
                        padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 20),
                        decoration: BoxDecoration(
                          color: isMe ? AppColors.primary.withOpacity(0.05) : AppColors.card,
                          borderRadius: BorderRadius.circular(AppRadii.card),
                          border: isMe ? Border.all(color: AppColors.primary, width: 1.5) : null,
                          boxShadow: [AppShadows.card],
                        ),
                        child: Row(
                          children: [
                            Text(
                              '#${user.rank}',
                              style: AppTextStyles.heading2.copyWith(
                                color: isMe ? AppColors.primary : AppColors.secondaryText,
                              ),
                            ),
                            const SizedBox(width: 20),
                            CircleAvatar(
                              radius: 18,
                              backgroundColor: Colors.grey.shade200,
                              child: Text(user.displayName.isNotEmpty ? user.displayName[0].toUpperCase() : '?', style: const TextStyle(fontWeight: FontWeight.bold)),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Text(
                                user.displayName,
                                style: AppTextStyles.bodyMedium.copyWith(
                                  fontWeight: isMe ? FontWeight.bold : FontWeight.w500,
                                ),
                              ),
                            ),
                            Text(
                              '${user.score.toInt()} pts',
                              style: AppTextStyles.bodyBold.copyWith(color: AppColors.primary),
                            ),
                          ],
                        ),
                      );
                    },
                  ),
                ),
              ],
            ),
    );
  }
}
