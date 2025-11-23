import 'package:cloud_firestore/cloud_firestore.dart';

/// Log entry that captures admin/moderation actions for auditing.
class AuditLogEntry {
  final String id;
  final String actorId;
  final String actorName;
  final String action;
  final String objectType;
  final String objectId;
  final Map<String, dynamic>? details;
  final DateTime createdAt;

  const AuditLogEntry({
    required this.id,
    required this.actorId,
    required this.actorName,
    required this.action,
    required this.objectType,
    required this.objectId,
    required this.createdAt,
    this.details,
  });

  factory AuditLogEntry.fromDoc(DocumentSnapshot<Map<String, dynamic>> doc) {
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

    return AuditLogEntry(
      id: doc.id,
      actorId: data['actorId'] as String? ?? '',
      actorName: data['actorName'] as String? ?? 'Unknown',
      action: data['action'] as String? ?? 'unknown',
      objectType: data['objectType'] as String? ?? 'unknown',
      objectId: data['objectId'] as String? ?? '',
      details: data['details'] as Map<String, dynamic>?,
      createdAt: createdAt,
    );
  }

  Map<String, dynamic> toMap() => {
        'actorId': actorId,
        'actorName': actorName,
        'action': action,
        'objectType': objectType,
        'objectId': objectId,
        if (details != null) 'details': details,
        'createdAt': Timestamp.fromDate(createdAt),
      };
}
