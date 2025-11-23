import 'package:cloud_firestore/cloud_firestore.dart';

class RoomMember {
  final String id;
  final String roomId;
  final String userId;
  final String role;
  final bool muted;
  final DateTime joinedAt;
  final DateTime? mutedUntil;
  final bool kicked;
  final DateTime? lastSeen;

  const RoomMember({
    required this.id,
    required this.roomId,
    required this.userId,
    required this.role,
    required this.joinedAt,
    this.muted = false,
    this.mutedUntil,
    this.kicked = false,
    this.lastSeen,
  });

  factory RoomMember.fromDoc(DocumentSnapshot<Map<String, dynamic>> doc) {
    final data = doc.data() ?? {};
    DateTime parseTime(dynamic value) {
      if (value is Timestamp) return value.toDate();
      if (value is int) return DateTime.fromMillisecondsSinceEpoch(value);
      return DateTime.now();
    }

    return RoomMember(
      id: doc.id,
      roomId: data['roomId'] as String? ?? '',
      userId: data['userId'] as String? ?? '',
      role: data['role'] as String? ?? 'member',
      joinedAt: parseTime(data['joinedAt']),
      muted: data['muted'] as bool? ?? false,
      mutedUntil: data['mutedUntil'] == null ? null : parseTime(data['mutedUntil']),
      kicked: data['kicked'] as bool? ?? false,
      lastSeen: data['lastSeen'] == null ? null : parseTime(data['lastSeen']),
    );
  }

  Map<String, dynamic> toMap() => {
        'roomId': roomId,
        'userId': userId,
        'role': role,
        'joinedAt': Timestamp.fromDate(joinedAt),
        'muted': muted,
        if (mutedUntil != null) 'mutedUntil': Timestamp.fromDate(mutedUntil!),
        'kicked': kicked,
        if (lastSeen != null) 'lastSeen': Timestamp.fromDate(lastSeen!),
      };
}
