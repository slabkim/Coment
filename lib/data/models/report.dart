import 'package:cloud_firestore/cloud_firestore.dart';

enum ReportStatus { open, inReview, resolved, rejected }

extension ReportStatusParser on ReportStatus {
  String get label {
    switch (this) {
      case ReportStatus.open:
        return 'Open';
      case ReportStatus.inReview:
        return 'In Review';
      case ReportStatus.resolved:
        return 'Resolved';
      case ReportStatus.rejected:
        return 'Rejected';
    }
  }

  String get asValue => name;

  static ReportStatus fromString(String? raw) {
    switch (raw) {
      case 'inReview':
        return ReportStatus.inReview;
      case 'resolved':
        return ReportStatus.resolved;
      case 'rejected':
        return ReportStatus.rejected;
      default:
        return ReportStatus.open;
    }
  }
}

class ReportItem {
  final String id;
  final ReportStatus status;
  final String reporterId;
  final String? reporterName;
  final String? targetUserId;
  final String? targetMessageId;
  final String? roomId;
  final String? roomName;
  final String? reason;
  final String? snapshotText;
  final String? assignedAdminId;
  final String? assignedAdminName;
  final DateTime createdAt;
  final DateTime updatedAt;
  final Map<String, dynamic>? actions;

  const ReportItem({
    required this.id,
    required this.status,
    required this.reporterId,
    required this.createdAt,
    required this.updatedAt,
    this.reporterName,
    this.targetUserId,
    this.targetMessageId,
    this.roomId,
    this.roomName,
    this.reason,
    this.snapshotText,
    this.assignedAdminId,
    this.assignedAdminName,
    this.actions,
  });

  factory ReportItem.fromDoc(DocumentSnapshot<Map<String, dynamic>> doc) {
    final data = doc.data() ?? {};
    final createdRaw = data['createdAt'];
    final updatedRaw = data['updatedAt'];

    DateTime parseTime(dynamic raw) {
      if (raw is Timestamp) return raw.toDate();
      if (raw is int) return DateTime.fromMillisecondsSinceEpoch(raw);
      return DateTime.now();
    }

    return ReportItem(
      id: doc.id,
      status: ReportStatusParser.fromString(data['status'] as String?),
      reporterId: data['reporterId'] as String? ?? '',
      reporterName: data['reporterName'] as String?,
      targetUserId: data['targetUserId'] as String?,
      targetMessageId: data['targetMessageId'] as String?,
      roomId: data['roomId'] as String?,
      roomName: data['roomName'] as String?,
      reason: data['reason'] as String?,
      snapshotText: data['snapshotText'] as String?,
      assignedAdminId: data['assignedAdminId'] as String?,
      assignedAdminName: data['assignedAdminName'] as String?,
      createdAt: parseTime(createdRaw),
      updatedAt: parseTime(updatedRaw),
      actions: data['actions'] as Map<String, dynamic>?,
    );
  }

  Map<String, dynamic> toMap() => {
        'status': status.asValue,
        'reporterId': reporterId,
        if (reporterName != null) 'reporterName': reporterName,
        if (targetUserId != null) 'targetUserId': targetUserId,
        if (targetMessageId != null) 'targetMessageId': targetMessageId,
        if (roomId != null) 'roomId': roomId,
        if (roomName != null) 'roomName': roomName,
        if (reason != null) 'reason': reason,
        if (snapshotText != null) 'snapshotText': snapshotText,
        if (assignedAdminId != null) 'assignedAdminId': assignedAdminId,
        if (assignedAdminName != null) 'assignedAdminName': assignedAdminName,
        'createdAt': Timestamp.fromDate(createdAt),
        'updatedAt': Timestamp.fromDate(updatedAt),
        if (actions != null) 'actions': actions,
      };
}
