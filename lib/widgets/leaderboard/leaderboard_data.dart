class LeaderboardUser {
  final int rank;
  final String name;
  final String countryFlag;
  final int points;

  const LeaderboardUser({
    required this.rank,
    required this.name,
    required this.countryFlag,
    required this.points,
  });
}

class LeaderboardData {
  static const LeaderboardUser currentUser = LeaderboardUser(
    rank: 7,
    name: 'Rohit Singh',
    countryFlag: '🇮🇳',
    points: 2840,
  );

  static const LeaderboardUser topUser = LeaderboardUser(
    rank: 1,
    name: 'Amit Kumar',
    countryFlag: '🇮🇳',
    points: 5120,
  );

  static final List<LeaderboardUser> allUsers = [
    topUser,
    const LeaderboardUser(rank: 2, name: 'Paul Johnson', countryFlag: '🇺🇸', points: 4750),
    const LeaderboardUser(rank: 3, name: 'Ashish Patel', countryFlag: '🇮🇳', points: 4530),
    const LeaderboardUser(rank: 4, name: 'Vikram', countryFlag: '👤', points: 4400),
    const LeaderboardUser(rank: 5, name: 'Jessica Lee', countryFlag: '👤', points: 4380),
    // Gap for 6
    const LeaderboardUser(rank: 6, name: 'David Brown', countryFlag: '🇬🇧', points: 3100),
    currentUser,
    const LeaderboardUser(rank: 8, name: 'Deepak Sharma', countryFlag: '👤', points: 2840),
    const LeaderboardUser(rank: 9, name: 'Alyssa M.', countryFlag: '👤', points: 2870),
    const LeaderboardUser(rank: 10, name: 'Rahul Verma', countryFlag: '👤', points: 2820),
    const LeaderboardUser(rank: 11, name: 'Sarah K.', countryFlag: '👤', points: 2500),
    const LeaderboardUser(rank: 12, name: 'Akash Gupta', countryFlag: '👤', points: 2360),
    // ... generate more if needed visually, but list says "Total 100 dummy users"
    // I'll generate the rest programmatically or just add a few at the bottom to match the screenshot
    const LeaderboardUser(rank: 99, name: 'Aman Joshi', countryFlag: '🇮🇳', points: 1810),
    const LeaderboardUser(rank: 100, name: 'Ishaan S.', countryFlag: '🇮🇳', points: 1810),
  ];
  
  // Helper to get full list with generated dummy data filling the gaps
  static List<LeaderboardUser> getFullList() {
    List<LeaderboardUser> list = List.from(allUsers);
    
    // Fill gaps just in case
    // We have 1-5, 6, 7, 8-12 ... 99, 100.
    // I'll just leave it as is, or add a loop to fill 13-98 if I mistakenly need a scrollable full list.
    // The prompt says "Total: 100 dummy users".
    // I will generate 13-98.
    
    for (int i = 13; i < 99; i++) {
        list.add(LeaderboardUser(
            rank: i, 
            name: 'User $i', 
            countryFlag: '🏳️', 
            points: 2300 - (i * 5) // decreasing points
        ));
    }
    
    list.sort((a, b) => a.rank.compareTo(b.rank));
    return list;
  }
}
