/// Helper functions for chat screen.
class ChatHelpers {
  /// Formats initials from a user's name.
  static String initials(String name) {
    final parts = name.trim().split(' ');
    final first = parts.isNotEmpty && parts.first.isNotEmpty
        ? parts.first[0]
        : 'U';
    final second = parts.length > 1 && parts.last.isNotEmpty ? parts.last[0] : '';
    return (first + second).toUpperCase();
  }

  /// Format status online berdasarkan lastSeen
  static String getOnlineStatus(DateTime? lastSeen) {
    if (lastSeen == null) {
      return 'Status tidak tersedia';
    }
    
    final now = DateTime.now();
    final diff = now.difference(lastSeen);
    
    // If last seen within 3 minutes, consider online
    if (diff.inMinutes < 3) {
      return 'Online';
    }
    
    // If less than 1 hour
    if (diff.inMinutes < 60) {
      final mins = diff.inMinutes;
      return 'Terakhir online $mins menit yang lalu';
    }
    
    // If less than 24 hours
    if (diff.inHours < 24) {
      final hours = diff.inHours;
      return 'Terakhir online $hours jam yang lalu';
    }
    
    // If less than 7 days
    if (diff.inDays < 7) {
      final days = diff.inDays;
      return 'Terakhir online $days hari yang lalu';
    }
    
    // Otherwise show date
    final day = lastSeen.day.toString().padLeft(2, '0');
    final month = lastSeen.month.toString().padLeft(2, '0');
    final year = lastSeen.year;
    return 'Terakhir online $day/$month/$year';
  }
}

