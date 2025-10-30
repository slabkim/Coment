/// User Class/Rank system based on XP
class UserClass {
  final String name;
  final int minXP;
  final int? maxXP; // null for highest tier
  final String color; // Hex color
  final String gradient1; // For gradient effect
  final String gradient2;
  final bool hasGlow;
  final String icon;

  const UserClass({
    required this.name,
    required this.minXP,
    this.maxXP,
    required this.color,
    required this.gradient1,
    required this.gradient2,
    this.hasGlow = false,
    required this.icon,
  });

  /// Get class tier from total XP
  static UserClass fromXP(int xp) {
    for (final classRank in allClasses.reversed) {
      if (xp >= classRank.minXP) {
        if (classRank.maxXP == null || xp <= classRank.maxXP!) {
          return classRank;
        }
      }
    }
    return allClasses.first; // Default to F class
  }

  /// Calculate XP needed for next class
  int? getXPToNextClass(int currentXP) {
    if (maxXP == null) return null; // Already at max class
    return maxXP! - currentXP + 1;
  }

  /// Calculate progress percentage to next class
  double getProgressPercentage(int currentXP) {
    if (maxXP == null) return 1.0; // Max class = 100%
    final range = maxXP! - minXP + 1;
    final progress = currentXP - minXP;
    return (progress / range).clamp(0.0, 1.0);
  }

  /// All class tiers from lowest to highest
  static const List<UserClass> allClasses = [
    // F Class - Beginner
    UserClass(
      name: 'F',
      minXP: 0,
      maxXP: 99,
      color: 'CCCCCC', // Light gray
      gradient1: 'CCCCCC',
      gradient2: 'AAAAAA',
      icon: '🌱',
    ),
    
    // D Class - Novice
    UserClass(
      name: 'D',
      minXP: 100,
      maxXP: 299,
      color: 'CD7F32', // Bronze
      gradient1: 'CD7F32',
      gradient2: 'A0522D',
      icon: '🥉',
    ),
    
    // C Class - Apprentice
    UserClass(
      name: 'C',
      minXP: 300,
      maxXP: 599,
      color: 'C0C0C0', // Silver
      gradient1: 'C0C0C0',
      gradient2: 'A9A9A9',
      icon: '🥈',
    ),
    
    // B Class - Skilled
    UserClass(
      name: 'B',
      minXP: 600,
      maxXP: 999,
      color: 'FFD700', // Gold
      gradient1: 'FFD700',
      gradient2: 'FFA500',
      icon: '🥇',
    ),
    
    // A Class - Expert
    UserClass(
      name: 'A',
      minXP: 1000,
      maxXP: 1999,
      color: '4169E1', // Royal Blue
      gradient1: '4169E1',
      gradient2: '1E90FF',
      hasGlow: true,
      icon: '💎',
    ),
    
    // S Class - Master
    UserClass(
      name: 'S',
      minXP: 2000,
      maxXP: 3999,
      color: '9370DB', // Purple
      gradient1: '9370DB',
      gradient2: '8A2BE2',
      hasGlow: true,
      icon: '👑',
    ),
    
    // SS Class - Grandmaster
    UserClass(
      name: 'SS',
      minXP: 4000,
      maxXP: 7999,
      color: 'FF1493', // Deep Pink
      gradient1: 'FF1493',
      gradient2: 'FF69B4',
      hasGlow: true,
      icon: '⭐',
    ),
    
    // SSS Class - Legend
    UserClass(
      name: 'SSS',
      minXP: 8000,
      maxXP: null, // No limit
      color: 'FFD700', // Golden
      gradient1: 'FFD700',
      gradient2: 'FFA500',
      hasGlow: true,
      icon: '🏆',
    ),
  ];

  @override
  String toString() => '$icon $name Class';
}

/// XP Rewards for different activities
class XPReward {
  static const int completeComic = 50;
  static const int addFavorite = 10;
  static const int removeFavorite = -10; // Penalty for removing
  static const int writeComment = 5;
  static const int replyComment = 3;
  static const int getFollower = 15;
  static const int loseFollower = -15; // Penalty for losing follower
  static const int updateReadingStatus = 2;
  static const int shareComic = 3;
  static const int dailyLogin = 5; // Daily bonus
}

