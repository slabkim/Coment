import 'package:cloud_firestore/cloud_firestore.dart';

enum RoomVisibility { public, private, protected }

extension RoomVisibilityParser on RoomVisibility {
  String get label {
    switch (this) {
      case RoomVisibility.public:
        return 'Public';
      case RoomVisibility.private:
        return 'Private';
      case RoomVisibility.protected:
        return 'Protected';
    }
  }

  String get asValue => name;

  static RoomVisibility fromString(String? raw) {
    switch (raw) {
      case 'private':
        return RoomVisibility.private;
      case 'protected':
        return RoomVisibility.protected;
      default:
        return RoomVisibility.public;
    }
  }
}

class Room {
  final String id;
  final String name;
  final String? description;
  final RoomVisibility visibility;
  final String? coverUrl;
  final bool requiresPasscode;
  final int memberCount;
  final int activeMemberCount;
  final Map<String, dynamic>? stats;
  final List<String> moderatorIds;
  final DateTime createdAt;
  final String createdBy;

  const Room({
    required this.id,
    required this.name,
    required this.visibility,
    required this.memberCount,
    required this.activeMemberCount,
    required this.createdAt,
    required this.createdBy,
    this.description,
    this.coverUrl,
    this.requiresPasscode = false,
    this.stats,
    this.moderatorIds = const [],
  });

  factory Room.fromDoc(DocumentSnapshot<Map<String, dynamic>> doc) {
    final data = doc.data() ?? {};
    final createdRaw = data['createdAt'];
    DateTime createdAt;
    if (createdRaw is Timestamp) {
      createdAt = createdRaw.toDate();
    } else if (createdRaw is int) {
      createdAt = DateTime.fromMillisecondsSinceEpoch(createdRaw);
    } else {
      createdAt = DateTime.now();
    }

    return Room(
      id: doc.id,
      name: data['name'] as String? ?? '',
      description: data['description'] as String?,
      visibility: RoomVisibilityParser.fromString(data['visibility'] as String?),
      coverUrl: data['coverUrl'] as String?,
      requiresPasscode: data['requiresPasscode'] as bool? ?? false,
      memberCount: (data['memberCount'] as num?)?.toInt() ?? 0,
      activeMemberCount: (data['activeMemberCount'] as num?)?.toInt() ?? 0,
      stats: data['stats'] as Map<String, dynamic>?,
      moderatorIds: (data['moderatorIds'] as List<dynamic>? ?? const []).cast<String>(),
      createdAt: createdAt,
      createdBy: data['createdBy'] as String? ?? '',
    );
  }

  Map<String, dynamic> toMap() => {
        'name': name,
        if (description != null) 'description': description,
        'visibility': visibility.asValue,
        if (coverUrl != null) 'coverUrl': coverUrl,
        'requiresPasscode': requiresPasscode,
        'memberCount': memberCount,
        'activeMemberCount': activeMemberCount,
        if (stats != null) 'stats': stats,
        'moderatorIds': moderatorIds,
        'createdAt': Timestamp.fromDate(createdAt),
        'createdBy': createdBy,
      };
}
