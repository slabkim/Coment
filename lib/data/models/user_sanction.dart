import 'package:cloud_firestore/cloud_firestore.dart';

/// Type of moderation action issued against a user.
enum SanctionType {
  mute,
  ban,
  warning,
  shadowBan,
  custom,
}

extension SanctionTypeParser on SanctionType {
  String get label {
    switch (this) {
      case SanctionType.mute:
        return 'Mute';
      case SanctionType.ban:
        return 'Ban';
      case SanctionType.warning:
        return 'Warning';
      case SanctionType.shadowBan:
        return 'Shadow Ban';
      case SanctionType.custom:
        return 'Custom';
    }
  }

  String get asValue => name;

  static SanctionType fromString(String? raw) {
    switch (raw) {
      case 'ban':
        return SanctionType.ban;
      case 'warning':
        return SanctionType.warning;
      case 'shadowBan':
        return SanctionType.shadowBan;
      case 'custom':
        return SanctionType.custom;
      default:
        return SanctionType.mute;
    }
  }
}

/// Record describing a moderation action applied to a user.
class UserSanction {
  final String id;
  final String userId;
  final SanctionType type;
  final String? reason;
  final Map<String, dynamic>? metadata;
  final DateTime createdAt;
  final String createdBy;
  final String createdByName;
  final DateTime? expiresAt;
  final bool active;

  const UserSanction({
    required this.id,
    required this.userId,
    required this.type,
    required this.createdAt,
    required this.createdBy,
    required this.createdByName,
    this.reason,
    this.metadata,
    this.expiresAt,
    this.active = true,
  });

  factory UserSanction.fromDoc(DocumentSnapshot<Map<String, dynamic>> doc) {
    final data = doc.data() ?? {};
    final expiresRaw = data['expiresAt'];
    DateTime? expiresAt;
    if (expiresRaw is Timestamp) {
      expiresAt = expiresRaw.toDate();
    } else if (expiresRaw is int) {
      expiresAt = DateTime.fromMillisecondsSinceEpoch(expiresRaw);
    }

    final createdRaw = data['createdAt'];
    DateTime createdAt;
    if (createdRaw is Timestamp) {
      createdAt = createdRaw.toDate();
    } else if (createdRaw is int) {
      createdAt = DateTime.fromMillisecondsSinceEpoch(createdRaw);
    } else {
      createdAt = DateTime.now();
    }

    return UserSanction(
      id: doc.id,
      userId: data['userId'] as String? ?? '',
      type: SanctionTypeParser.fromString(data['type'] as String?),
      reason: data['reason'] as String?,
      metadata: data['metadata'] as Map<String, dynamic>?,
      createdAt: createdAt,
      createdBy: data['createdBy'] as String? ?? '',
      createdByName: data['createdByName'] as String? ?? 'System',
      expiresAt: expiresAt,
      active: data['active'] as bool? ?? true,
    );
  }

  Map<String, dynamic> toMap() => {
        'userId': userId,
        'type': type.asValue,
        if (reason != null) 'reason': reason,
        if (metadata != null) 'metadata': metadata,
        'createdAt': Timestamp.fromDate(createdAt),
        'createdBy': createdBy,
        'createdByName': createdByName,
        if (expiresAt != null) 'expiresAt': Timestamp.fromDate(expiresAt!),
        'active': active,
      };
}
