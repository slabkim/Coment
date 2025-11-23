import 'package:cloud_firestore/cloud_firestore.dart';

enum AnnouncementScope { global, room }

extension AnnouncementScopeParser on AnnouncementScope {
  String get label => this == AnnouncementScope.global ? 'Global' : 'Room';

  String get asValue => name;

  static AnnouncementScope fromString(String? raw) {
    if (raw == 'room') return AnnouncementScope.room;
    return AnnouncementScope.global;
  }
}

enum AnnouncementStatus { draft, scheduled, live, archived }

extension AnnouncementStatusParser on AnnouncementStatus {
  String get label {
    switch (this) {
      case AnnouncementStatus.draft:
        return 'Draft';
      case AnnouncementStatus.scheduled:
        return 'Scheduled';
      case AnnouncementStatus.live:
        return 'Live';
      case AnnouncementStatus.archived:
        return 'Archived';
    }
  }

  String get asValue => name;

  static AnnouncementStatus fromString(String? raw) {
    switch (raw) {
      case 'scheduled':
        return AnnouncementStatus.scheduled;
      case 'live':
        return AnnouncementStatus.live;
      case 'archived':
        return AnnouncementStatus.archived;
      default:
        return AnnouncementStatus.draft;
    }
  }
}

class Announcement {
  final String id;
  final String title;
  final String body;
  final AnnouncementScope scope;
  final List<String> roomIds;
  final AnnouncementStatus status;
  final DateTime createdAt;
  final DateTime? publishAt;
  final bool sendPush;

  const Announcement({
    required this.id,
    required this.title,
    required this.body,
    required this.scope,
    required this.status,
    required this.createdAt,
    this.roomIds = const [],
    this.publishAt,
    this.sendPush = false,
  });

  factory Announcement.fromDoc(DocumentSnapshot<Map<String, dynamic>> doc) {
    final data = doc.data() ?? {};
    final createdRaw = data['createdAt'];
    final publishRaw = data['publishAt'];

    DateTime parseTime(dynamic raw) {
      if (raw is Timestamp) return raw.toDate();
      if (raw is int) return DateTime.fromMillisecondsSinceEpoch(raw);
      return DateTime.now();
    }

    return Announcement(
      id: doc.id,
      title: data['title'] as String? ?? '',
      body: data['body'] as String? ?? '',
      scope: AnnouncementScopeParser.fromString(data['scope'] as String?),
      roomIds: (data['roomIds'] as List<dynamic>? ?? const []).cast<String>(),
      status: AnnouncementStatusParser.fromString(data['status'] as String?),
      createdAt: parseTime(createdRaw),
      publishAt: publishRaw == null ? null : parseTime(publishRaw),
      sendPush: data['sendPush'] as bool? ?? false,
    );
  }

  Map<String, dynamic> toMap() => {
        'title': title,
        'body': body,
        'scope': scope.asValue,
        'roomIds': roomIds,
        'status': status.asValue,
        'createdAt': Timestamp.fromDate(createdAt),
        if (publishAt != null) 'publishAt': Timestamp.fromDate(publishAt!),
        'sendPush': sendPush,
      };
}
