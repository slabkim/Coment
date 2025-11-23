import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

import '../../data/models/announcement.dart';
import '../../data/models/audit_log.dart';
import '../../data/models/report.dart';
import '../../data/models/room.dart';
import '../../data/models/user_profile.dart';
import '../../data/models/user_role.dart';
import '../../data/models/user_sanction.dart';
import '../../data/services/admin_service.dart';
import 'user_public_profile_screen.dart';

class AdminDashboardScreen extends StatefulWidget {
  const AdminDashboardScreen({super.key});

  @override
  State<AdminDashboardScreen> createState() => _AdminDashboardScreenState();
}

class _AdminDashboardScreenState extends State<AdminDashboardScreen> {
  final _adminService = AdminService();
  final _userSearchController = TextEditingController();
  final _announcementTitleController = TextEditingController();
  final _announcementBodyController = TextEditingController();
  Timer? _ticker;
  UserRole? _roleFilter;
  UserStatus? _statusFilter;
  ReportStatus? _reportStatusFilter;
  RoomVisibility? _roomVisibilityFilter;
  DateTime _now = DateTime.now();

  @override
  void dispose() {
    _userSearchController.dispose();
    _announcementTitleController.dispose();
    _announcementBodyController.dispose();
    _ticker?.cancel();
    super.dispose();
  }

  @override
  void initState() {
    super.initState();
    _ticker = Timer.periodic(
      const Duration(seconds: 30),
      (_) => setState(() => _now = DateTime.now()),
    );
    _checkAdminAccess();
  }

  Future<void> _checkAdminAccess() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      _showAccessDenied();
      return;
    }
    try {
      final profile = await FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid)
          .get();
      if (!profile.exists) {
        _showAccessDenied();
        return;
      }
      final data = profile.data()!;
      final role = UserRoleParser.fromString(data['role'] as String?);
      if (role != UserRole.admin) {
        _showAccessDenied();
      }
    } catch (e) {
      _showAccessDenied();
    }
  }

  void _showAccessDenied() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        title: const Text('Access Denied'),
        content: const Text(
          'You do not have admin privileges to access this dashboard.',
        ),
        actions: [
          TextButton(
            onPressed: () =>
                Navigator.of(context).popUntil((route) => route.isFirst),
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }

  String _formatDateTime(DateTime value) {
    final local = value.toLocal();
    String two(int v) => v.toString().padLeft(2, '0');
    return '${local.year}-${two(local.month)}-${two(local.day)} '
        '${two(local.hour)}:${two(local.minute)}';
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final tabBar = TabBar(
      indicator: BoxDecoration(
        color: scheme.primary,
        borderRadius: BorderRadius.circular(16),
      ),
      labelColor: scheme.onPrimary,
      unselectedLabelColor: scheme.onSurfaceVariant,
      labelStyle: theme.textTheme.labelLarge?.copyWith(
        fontWeight: FontWeight.w700,
        letterSpacing: 0.2,
      ),
      unselectedLabelStyle: theme.textTheme.labelLarge,
      indicatorSize: TabBarIndicatorSize.tab,
      labelPadding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      tabs: const [
        Tab(text: 'Users'),
        Tab(text: 'Rooms'),
        Tab(text: 'Reports'),
        Tab(text: 'Announcements'),
        Tab(text: 'Audit'),
      ],
    );
    return DefaultTabController(
      length: 5,
      child: Scaffold(
        backgroundColor: scheme.surface,
        appBar: AppBar(
          elevation: 6,
          shadowColor: scheme.primary.withValues(alpha: 0.25),
          backgroundColor: scheme.surfaceContainerHighest.withValues(alpha: 0.9),
          titleSpacing: 0,
          title: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Coment Admin',
                style: theme.textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.w800,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                'Moderation & insights cockpit',
                style: theme.textTheme.bodySmall?.copyWith(
                  color: scheme.onSurfaceVariant,
                ),
              ),
            ],
          ),
          bottom: PreferredSize(
            preferredSize: tabBar.preferredSize,
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
              child: DecoratedBox(
                decoration: BoxDecoration(
                  color: scheme.surface,
                  borderRadius: BorderRadius.circular(28),
                  border: Border.all(
                    color: scheme.outlineVariant.withValues(alpha: 0.5),
                  ),
                ),
                child: tabBar,
              ),
            ),
          ),
        ),
        body: Container(
          decoration: _dashboardBackground(scheme),
          child: TabBarView(
            children: [
              _buildUsersTab(),
              _buildRoomsTab(),
              _buildReportsTab(),
              _buildAnnouncementsTab(),
              _buildAuditTab(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildUsersTab() {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
          child: _sectionCard(
            padding: const EdgeInsets.all(18),
            child: Row(
              children: [
                Icon(
                  Icons.shield_moon_outlined,
                  color: scheme.primary,
                  size: 32,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'User Safety Console',
                        style: theme.textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Search, filter, and act quickly. Countdown badges show remaining mute time.',
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: scheme.onSurfaceVariant,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
          child: _sectionCard(
            child: TextField(
              controller: _userSearchController,
              decoration: InputDecoration(
                hintText: 'Search users by name, handle, or email',
                prefixIcon: const Icon(Icons.search),
                suffixIcon: _userSearchController.text.isEmpty
                    ? null
                    : IconButton(
                        icon: const Icon(Icons.close),
                        onPressed: () {
                          _userSearchController.clear();
                          setState(() {});
                        },
                      ),
                filled: true,
                fillColor: scheme.surface,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(16),
                  borderSide: BorderSide.none,
                ),
              ),
              onChanged: (_) => setState(() {}),
            ),
          ),
        ),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: _sectionCard(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Roles',
                  style: theme.textTheme.labelLarge?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 8),
                SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Row(
                    children: [
                      _buildFilterPill(
                        label: 'All roles',
                        selected: _roleFilter == null,
                        onSelected: () => setState(() => _roleFilter = null),
                      ),
                      ...UserRole.values.map(
                        (role) => _buildFilterPill(
                          label: role.label,
                          selected: _roleFilter == role,
                          onSelected: () => setState(() => _roleFilter = role),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 12),
                Text(
                  'Status',
                  style: theme.textTheme.labelLarge?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 8),
                SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Row(
                    children: [
                      _buildFilterPill(
                        label: 'All status',
                        selected: _statusFilter == null,
                        onSelected: () => setState(() => _statusFilter = null),
                      ),
                      ...UserStatus.values.map(
                        (status) => _buildFilterPill(
                          label: status.label,
                          selected: _statusFilter == status,
                          onSelected: () =>
                              setState(() => _statusFilter = status),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
        Expanded(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
            child: _sectionCard(
              padding: EdgeInsets.zero,
              child: StreamBuilder<List<UserProfile>>(
                stream: _adminService.watchUsers(
                  role: _roleFilter,
                  status: _statusFilter,
                  search: _userSearchController.text,
                  limit: 200,
                ),
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return const Center(child: CircularProgressIndicator());
                  }
                  final users = snapshot.data ?? const [];
                  if (users.isEmpty) {
                    return _buildEmptyPlaceholder(
                      'No users found for the current filters',
                      icon: Icons.person_off_outlined,
                    );
                  }
                  return ListView.separated(
                    padding: const EdgeInsets.all(16),
                    itemCount: users.length,
                    separatorBuilder: (_, __) => Divider(
                      color: scheme.outlineVariant.withValues(alpha: 0.3),
                    ),
                    itemBuilder: (context, index) {
                      final user = users[index];
                      final subtitle = user.handle ?? user.email ?? '';
                      final mutedLabel = _muteCountdown(user.mutedUntil);
                      return Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 10,
                        ),
                        decoration: BoxDecoration(
                          color: scheme.surface,
                          borderRadius: BorderRadius.circular(18),
                          border: Border.all(
                            color: scheme.outlineVariant.withValues(alpha: 0.35),
                          ),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withValues(alpha: 0.04),
                              blurRadius: 12,
                              offset: const Offset(0, 6),
                            ),
                          ],
                        ),
                        child: ListTile(
                          contentPadding: const EdgeInsets.symmetric(vertical: 4),
                          leading: CircleAvatar(
                            backgroundColor: scheme.primaryContainer.withValues(
                              alpha: 0.8,
                            ),
                            foregroundColor: scheme.onPrimaryContainer,
                            child: Text(
                              user.username?.substring(0, 1).toUpperCase() ?? '?',
                            ),
                          ),
                          title: Row(
                            children: [
                              Expanded(
                                child: Text(
                                  user.username ?? user.email ?? user.id,
                                  style: theme.textTheme.titleMedium?.copyWith(
                                    fontWeight: FontWeight.w700,
                                  ),
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                              const SizedBox(width: 8),
                              _statusChip(user.status, scheme),
                            ],
                          ),
                          subtitle: Padding(
                            padding: const EdgeInsets.only(top: 6),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                if (subtitle.isNotEmpty)
                                  Text(
                                    subtitle,
                                    style: theme.textTheme.bodySmall?.copyWith(
                                      color: scheme.onSurfaceVariant,
                                    ),
                                  ),
                                const SizedBox(height: 6),
                                Wrap(
                                  spacing: 6,
                                  runSpacing: 4,
                                  children: [
                                    _metaPill(
                                      label: user.role.label,
                                      icon: Icons.workspace_premium_outlined,
                                      color: scheme.secondaryContainer,
                                      textColor: scheme.onSecondaryContainer,
                                    ),
                                    if (user.isMuted && mutedLabel != null)
                                      _metaPill(
                                        label: 'Mute • $mutedLabel',
                                        icon: Icons.timelapse,
                                        color: scheme.errorContainer,
                                        textColor: scheme.onErrorContainer,
                                      ),
                                    if (user.lastSanctionReason != null &&
                                        user.lastSanctionReason!.isNotEmpty)
                                      _metaPill(
                                        label: user.lastSanctionReason!,
                                        icon: Icons.info_outline,
                                        color: scheme.surfaceVariant,
                                        textColor: scheme.onSurfaceVariant,
                                      ),
                                  ],
                                ),
                              ],
                            ),
                          ),
                          onTap: () {
                            Navigator.of(context).push(
                              MaterialPageRoute(
                                builder: (_) =>
                                    UserPublicProfileScreen(userId: user.id),
                              ),
                            );
                          },
                          trailing: PopupMenuButton<String>(
                            icon: const Icon(Icons.more_horiz),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                            onSelected: (value) {
                              switch (value) {
                                case 'role':
                                  _showRolePicker(user);
                                  break;
                                case 'mute':
                                  _showMuteSheet(user);
                                  break;
                                case 'unmute':
                                  _handleUnmute(user);
                                  break;
                                case 'ban':
                                  _confirmBan(user);
                                  break;
                                case 'history':
                                  _showSanctionHistory(user);
                                  break;
                              }
                            },
                            itemBuilder: (_) {
                              final entries = <PopupMenuEntry<String>>[
                                const PopupMenuItem(
                                  value: 'role',
                                  child: Text('Set role'),
                                ),
                                PopupMenuItem(
                                  value: 'mute',
                                  child: Text(
                                    user.isMuted ? 'Adjust mute' : 'Mute user',
                                  ),
                                ),
                              ];
                              if (user.isMuted) {
                                entries.add(
                                  const PopupMenuItem(
                                    value: 'unmute',
                                    child: Text('Unmute now'),
                                  ),
                                );
                              }
                              entries.add(
                                PopupMenuItem(
                                  value: 'ban',
                                  child: Text(
                                    user.status == UserStatus.banned
                                        ? 'Unban user'
                                        : 'Ban user',
                                  ),
                                ),
                              );
                              entries.add(
                                const PopupMenuItem(
                                  value: 'history',
                                  child: Text('View history'),
                                ),
                              );
                              return entries;
                            },
                          ),
                        ),
                      );
                    },
                  );
                },
              ),
            ),
          ),
        ),
      ],
    );
  }

  Future<void> _showRolePicker(UserProfile user) async {
    final selected = await showModalBottomSheet<UserRole>(
      context: context,
      isScrollControlled: true,
      builder: (context) => SafeArea(
        top: false,
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: UserRole.values
                .map(
                  (role) => ListTile(
                    leading: Icon(
                      role == user.role
                          ? Icons.check_circle
                          : Icons.circle_outlined,
                    ),
                    title: Text(role.label),
                    onTap: () => Navigator.of(context).pop(role),
                  ),
                )
                .toList(),
          ),
        ),
      ),
    );
    if (!mounted || selected == null || selected == user.role) return;
    try {
      await _adminService.setUserRole(userId: user.id, role: selected);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Role updated to ${selected.label}')),
        );
      }
    } catch (error) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to update role: $error')),
        );
      }
    }
  }

  Future<void> _showMuteSheet(UserProfile user) async {
    final durations = <Duration>[
      const Duration(minutes: 15),
      const Duration(hours: 1),
      const Duration(hours: 12),
      const Duration(days: 1),
    ];
    final selected = await showModalBottomSheet<Duration?>(
      context: context,
      isScrollControlled: true,
      builder: (context) => SafeArea(
        top: false,
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: durations
                .map(
                  (duration) => ListTile(
                    title: Text(_formatDuration(duration)),
                    onTap: () => Navigator.of(context).pop(duration),
                  ),
                )
                .toList()
              ..insert(
                0,
                ListTile(
                  leading: const Icon(Icons.volume_up_outlined),
                  title: const Text('Unmute now'),
                  subtitle: const Text('Lift the current mute immediately'),
                  onTap: () => Navigator.of(context).pop(null),
                ),
              ),
          ),
        ),
      ),
    );
    if (!mounted) return;
    try {
      if (selected == null) {
        await _adminService.unmuteUser(user.id);
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('User unmuted')),
          );
        }
        return;
      }
      await _adminService.muteUser(userId: user.id, duration: selected);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('User muted for ${_formatDuration(selected)}'),
          ),
        );
      }
    } catch (error) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Failed to mute user: $error')));
      }
    }
  }

  Future<void> _handleUnmute(UserProfile user) async {
    try {
      await _adminService.unmuteUser(user.id);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('User unmuted')),
        );
      }
    } catch (error) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to unmute user: $error')),
        );
      }
    }
  }

  Future<void> _confirmBan(UserProfile user) async {
    final isBanned = user.status == UserStatus.banned;
    if (isBanned) {
      try {
        await _adminService.unbanUser(user.id);
        if (mounted) {
          ScaffoldMessenger.of(
            context,
          ).showSnackBar(const SnackBar(content: Text('User unbanned')));
        }
      } catch (error) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Failed to unban user: $error')),
          );
        }
      }
      return;
    }

    final controller = TextEditingController();
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Ban user'),
        content: TextField(
          controller: controller,
          decoration: const InputDecoration(labelText: 'Reason (optional)'),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('Ban'),
          ),
        ],
      ),
    );
    if (confirmed != true || !mounted) return;
    try {
      await _adminService.banUser(
        userId: user.id,
        reason: controller.text.trim(),
      );
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text('User banned')));
      }
    } catch (error) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Failed to ban user: $error')));
      }
    }
  }

  Future<void> _showSanctionHistory(UserProfile user) async {
    await showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (context) => SafeArea(
        top: false,
        child: SizedBox(
          height: MediaQuery.of(context).size.height * 0.6,
          child: StreamBuilder<List<UserSanction>>(
            stream: _adminService.watchUserSanctions(user.id),
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const Center(child: CircularProgressIndicator());
              }
              if (snapshot.hasError) {
                return Padding(
                  padding: const EdgeInsets.all(24),
                  child: Text('Failed to load sanctions: ${snapshot.error}'),
                );
              }
              final sanctions = snapshot.data ?? const [];
              if (sanctions.isEmpty) {
                return const Padding(
                  padding: EdgeInsets.all(24),
                  child: Text('No sanctions recorded for this user.'),
                );
              }
              return ListView.separated(
                padding: const EdgeInsets.all(16),
                separatorBuilder: (_, __) => const Divider(height: 1),
                itemCount: sanctions.length,
                itemBuilder: (context, index) {
                  final sanction = sanctions[index];
                  final createdAt = _formatDateTime(sanction.createdAt);
                  final expiresAt = sanction.expiresAt == null
                      ? 'No expiry'
                      : _formatDateTime(sanction.expiresAt!);
                  return ListTile(
                    title: Text(
                      '${sanction.type.label} • ${sanction.reason ?? '-'}',
                    ),
                    subtitle: Text(
                      'Created $createdAt • ${sanction.createdByName}\nExpires $expiresAt',
                    ),
                  );
                },
              );
            },
          ),
        ),
      ),
    );
  }

  Widget _buildRoomsTab() {
    final scheme = Theme.of(context).colorScheme;
    final theme = Theme.of(context);
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
          child: _sectionCard(
            padding: const EdgeInsets.all(12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Room visibility',
                  style: theme.textTheme.labelLarge?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 12),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    _buildFilterPill(
                      label: 'All rooms',
                      selected: _roomVisibilityFilter == null,
                      onSelected: () =>
                          setState(() => _roomVisibilityFilter = null),
                    ),
                    ...RoomVisibility.values.map(
                      (visibility) => _buildFilterPill(
                        label: visibility.label,
                        selected: _roomVisibilityFilter == visibility,
                        onSelected: () =>
                            setState(() => _roomVisibilityFilter = visibility),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Align(
                  alignment: Alignment.centerRight,
                  child: FilledButton.icon(
                    style: FilledButton.styleFrom(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 20,
                        vertical: 12,
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                    ),
                    onPressed: () => _openRoomEditor(),
                    icon: const Icon(Icons.add),
                    label: const Text('Create room'),
                  ),
                ),
              ],
            ),
          ),
        ),
        Expanded(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
            child: _sectionCard(
              padding: EdgeInsets.zero,
              child: StreamBuilder<List<Room>>(
                stream: _adminService.watchRooms(
                  visibility: _roomVisibilityFilter,
                ),
                builder: (context, snapshot) {
                  final rooms = snapshot.data ?? const [];
                  if (rooms.isEmpty) {
                    return _buildEmptyPlaceholder(
                      'No rooms available for this visibility',
                      icon: Icons.meeting_room_outlined,
                    );
                  }
                  return ListView.separated(
                    padding: const EdgeInsets.all(16),
                    itemCount: rooms.length,
                    separatorBuilder: (_, __) => Divider(
                      color: scheme.outlineVariant.withValues(alpha: 0.3),
                    ),
                    itemBuilder: (context, index) {
                      final room = rooms[index];
                      return ListTile(
                        contentPadding: const EdgeInsets.symmetric(vertical: 8),
                        title: Text(
                          room.name,
                          style: theme.textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        subtitle: Text(
                          '${room.visibility.label} • ${room.memberCount} members • ${room.activeMemberCount} active',
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: scheme.onSurfaceVariant,
                          ),
                        ),
                        trailing: PopupMenuButton<String>(
                          icon: const Icon(Icons.more_horiz),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          onSelected: (value) {
                            if (value == 'edit') {
                              _openRoomEditor(room: room);
                            } else if (value == 'delete') {
                              _deleteRoom(room.id);
                            }
                          },
                          itemBuilder: (_) => const [
                            PopupMenuItem(value: 'edit', child: Text('Edit')),
                            PopupMenuItem(
                              value: 'delete',
                              child: Text('Delete'),
                            ),
                          ],
                        ),
                      );
                    },
                  );
                },
              ),
            ),
          ),
        ),
      ],
    );
  }

  Future<void> _openRoomEditor({Room? room}) async {
    final nameController = TextEditingController(text: room?.name ?? '');
    final descriptionController = TextEditingController(
      text: room?.description ?? '',
    );
    var visibility = room?.visibility ?? RoomVisibility.public;
    final passcodeController = TextEditingController();

    final saved = await showDialog<bool>(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setModalState) => AlertDialog(
          title: Text(room == null ? 'Create room' : 'Edit room'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: nameController,
                  decoration: const InputDecoration(labelText: 'Name'),
                ),
                const SizedBox(height: 8),
                TextField(
                  controller: descriptionController,
                  decoration: const InputDecoration(labelText: 'Description'),
                  maxLines: 2,
                ),
                const SizedBox(height: 8),
                _buildDropdownField<RoomVisibility>(
                  label: 'Visibility',
                  value: visibility,
                  items: RoomVisibility.values
                      .map(
                        (value) => DropdownMenuItem(
                          value: value,
                          child: Text(value.label),
                        ),
                      )
                      .toList(),
                  onChanged: (value) => setModalState(() {
                    visibility = value;
                  }),
                ),
                const SizedBox(height: 8),
                TextField(
                  controller: passcodeController,
                  decoration: const InputDecoration(
                    labelText: 'Passcode (optional)',
                  ),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(false),
              child: const Text('Cancel'),
            ),
            FilledButton(
              onPressed: () => Navigator.of(context).pop(true),
              child: const Text('Save'),
            ),
          ],
        ),
      ),
    );

    if (saved != true || !mounted) return;
    try {
      await _adminService.saveRoom(
        Room(
          id: room?.id ?? '',
          name: nameController.text.trim(),
          description: descriptionController.text.trim(),
          visibility: visibility,
          memberCount: room?.memberCount ?? 0,
          activeMemberCount: room?.activeMemberCount ?? 0,
          createdAt: room?.createdAt ?? DateTime.now(),
          createdBy:
              room?.createdBy ?? FirebaseAuth.instance.currentUser?.uid ?? '',
          coverUrl: room?.coverUrl,
          stats: room?.stats,
          moderatorIds: room?.moderatorIds ?? const [],
          requiresPasscode:
              passcodeController.text.isNotEmpty ||
              (room?.requiresPasscode ?? false),
        ),
        passcode: passcodeController.text.trim().isEmpty
            ? null
            : passcodeController.text.trim(),
      );
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(room == null ? 'Room created' : 'Room updated'),
          ),
        );
      }
    } catch (error) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Failed to save room: $error')));
      }
    }
  }

  Future<void> _deleteRoom(String roomId) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete room'),
        content: const Text(
          'This action will remove the room and related data. Continue?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
    if (confirmed != true || !mounted) return;
    try {
      await _adminService.deleteRoom(roomId);
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text('Room deleted')));
      }
    } catch (error) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to delete room: $error')),
        );
      }
    }
  }

  Widget _buildReportsTab() {
    final currentAdmin = FirebaseAuth.instance.currentUser;
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
          child: _sectionCard(
            padding: const EdgeInsets.all(12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Report status',
                  style: theme.textTheme.labelLarge?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 8),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    _buildFilterPill(
                      label: 'All reports',
                      selected: _reportStatusFilter == null,
                      onSelected: () =>
                          setState(() => _reportStatusFilter = null),
                    ),
                    ...ReportStatus.values.map(
                      (status) => _buildFilterPill(
                        label: status.label,
                        selected: _reportStatusFilter == status,
                        onSelected: () =>
                            setState(() => _reportStatusFilter = status),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
        Expanded(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
            child: _sectionCard(
              padding: EdgeInsets.zero,
              child: StreamBuilder<List<ReportItem>>(
                stream: _adminService.watchReports(status: _reportStatusFilter),
                builder: (context, snapshot) {
                  final reports = snapshot.data ?? const [];
                  if (reports.isEmpty) {
                    return _buildEmptyPlaceholder(
                      'No reports in this queue',
                      icon: Icons.report_gmailerrorred_outlined,
                    );
                  }
                  return ListView.separated(
                    padding: const EdgeInsets.all(16),
                    itemCount: reports.length,
                    separatorBuilder: (_, __) => Divider(
                      color: scheme.outlineVariant.withValues(alpha: 0.3),
                    ),
                    itemBuilder: (context, index) {
                      final report = reports[index];
                      return ListTile(
                        contentPadding: const EdgeInsets.symmetric(vertical: 8),
                        title: Text(
                          report.reason ?? 'No reason provided',
                          style: theme.textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        subtitle: Text(
                          '${report.status.label} • Reporter: ${report.reporterName ?? report.reporterId}\n'
                          'Target: ${report.targetUserId ?? '-'} • Room: ${report.roomName ?? '-'}',
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: scheme.onSurfaceVariant,
                          ),
                        ),
                        isThreeLine: true,
                        trailing: PopupMenuButton<String>(
                          icon: const Icon(Icons.more_horiz),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          onSelected: (value) {
                            switch (value) {
                              case 'assign':
                                if (currentAdmin != null) {
                                  _adminService.assignReport(
                                    reportId: report.id,
                                    adminId: currentAdmin.uid,
                                  );
                                }
                                break;
                              case 'resolve':
                                _resolveReport(report, ReportStatus.resolved);
                                break;
                              case 'reject':
                                _resolveReport(report, ReportStatus.rejected);
                                break;
                            }
                          },
                          itemBuilder: (_) => const [
                            PopupMenuItem(
                              value: 'assign',
                              child: Text('Assign to me'),
                            ),
                            PopupMenuItem(
                              value: 'resolve',
                              child: Text('Resolve'),
                            ),
                            PopupMenuItem(
                              value: 'reject',
                              child: Text('Reject'),
                            ),
                          ],
                        ),
                      );
                    },
                  );
                },
              ),
            ),
          ),
        ),
      ],
    );
  }

  Future<void> _resolveReport(ReportItem report, ReportStatus status) async {
    final controller = TextEditingController();
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(
          status == ReportStatus.resolved ? 'Resolve report' : 'Reject report',
        ),
        content: TextField(
          controller: controller,
          decoration: const InputDecoration(labelText: 'Notes'),
          maxLines: 3,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('Submit'),
          ),
        ],
      ),
    );
    if (confirmed != true || !mounted) return;
    try {
      await _adminService.resolveReport(
        reportId: report.id,
        status: status,
        resolutionNotes: controller.text.trim(),
      );
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Report ${status.label.toLowerCase()}')),
        );
      }
    } catch (error) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to update report: $error')),
        );
      }
    }
  }

  Widget _buildAnnouncementsTab() {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
          child: _sectionCard(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        'Announcements',
                        style: theme.textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Broadcast updates, maintenance news, or spotlight content.',
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: scheme.onSurfaceVariant,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 12),
                FilledButton.icon(
                  style: FilledButton.styleFrom(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 20,
                      vertical: 14,
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                  ),
                  onPressed: () => _openAnnouncementDialog(),
                  icon: const Icon(Icons.add_alert),
                  label: const Text('Create'),
                ),
              ],
            ),
          ),
        ),
        Expanded(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
            child: _sectionCard(
              padding: EdgeInsets.zero,
              child: StreamBuilder<List<Announcement>>(
                stream: _adminService.watchAnnouncements(),
                builder: (context, snapshot) {
                  final announcements = snapshot.data ?? const [];
                  if (announcements.isEmpty) {
                    return _buildEmptyPlaceholder(
                      'No announcements yet',
                      icon: Icons.campaign_outlined,
                    );
                  }
                  return ListView.separated(
                    padding: const EdgeInsets.all(16),
                    itemCount: announcements.length,
                    separatorBuilder: (_, __) => Divider(
                      color: scheme.outlineVariant.withValues(alpha: 0.3),
                    ),
                    itemBuilder: (context, index) {
                      final announcement = announcements[index];
                      return ListTile(
                        contentPadding: const EdgeInsets.symmetric(vertical: 8),
                        title: Text(
                          announcement.title,
                          style: theme.textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        subtitle: Text(
                          '${announcement.scope.label} • ${announcement.status.label}',
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: scheme.onSurfaceVariant,
                          ),
                        ),
                        trailing: PopupMenuButton<String>(
                          icon: const Icon(Icons.more_horiz),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          onSelected: (value) {
                            if (value == 'edit') {
                              _openAnnouncementDialog(existing: announcement);
                            } else if (value == 'delete') {
                              _deleteAnnouncement(announcement.id);
                            }
                          },
                          itemBuilder: (_) => const [
                            PopupMenuItem(value: 'edit', child: Text('Edit')),
                            PopupMenuItem(
                              value: 'delete',
                              child: Text('Delete'),
                            ),
                          ],
                        ),
                      );
                    },
                  );
                },
              ),
            ),
          ),
        ),
      ],
    );
  }

  Future<void> _openAnnouncementDialog({Announcement? existing}) async {
    _announcementTitleController.text = existing?.title ?? '';
    _announcementBodyController.text = existing?.body ?? '';
    var scopeValue = existing?.scope ?? AnnouncementScope.global;
    var statusValue = existing?.status ?? AnnouncementStatus.draft;
    var sendPushValue = existing?.sendPush ?? false;

    final saved = await showDialog<bool>(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setState) => AlertDialog(
          title: Text(
            existing == null ? 'Create announcement' : 'Edit announcement',
          ),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: _announcementTitleController,
                  decoration: const InputDecoration(labelText: 'Title'),
                ),
                const SizedBox(height: 8),
                TextField(
                  controller: _announcementBodyController,
                  decoration: const InputDecoration(labelText: 'Message'),
                  maxLines: 3,
                ),
                const SizedBox(height: 8),
                _buildDropdownField<AnnouncementScope>(
                  label: 'Scope',
                  value: scopeValue,
                  items: AnnouncementScope.values
                      .map(
                        (value) => DropdownMenuItem(
                          value: value,
                          child: Text(value.label),
                        ),
                      )
                      .toList(),
                  onChanged: (value) => setState(() => scopeValue = value),
                ),
                const SizedBox(height: 8),
                _buildDropdownField<AnnouncementStatus>(
                  label: 'Status',
                  value: statusValue,
                  items: AnnouncementStatus.values
                      .map(
                        (value) => DropdownMenuItem(
                          value: value,
                          child: Text(value.label),
                        ),
                      )
                      .toList(),
                  onChanged: (value) => setState(() => statusValue = value),
                ),
                const SizedBox(height: 8),
                SwitchListTile(
                  value: sendPushValue,
                  title: const Text('Send push notification'),
                  onChanged: (value) => setState(() => sendPushValue = value),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(false),
              child: const Text('Cancel'),
            ),
            FilledButton(
              onPressed: () => Navigator.of(context).pop(true),
              child: const Text('Save'),
            ),
          ],
        ),
      ),
    );

    if (saved != true || !mounted) return;
    try {
      final announcement = Announcement(
        id: existing?.id ?? '',
        title: _announcementTitleController.text.trim(),
        body: _announcementBodyController.text.trim(),
        scope: scopeValue,
        status: statusValue,
        createdAt: existing?.createdAt ?? DateTime.now(),
        roomIds: existing?.roomIds ?? const [],
        publishAt: existing?.publishAt,
        sendPush: sendPushValue,
      );
      await _adminService.saveAnnouncement(announcement);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              existing == null
                  ? 'Announcement created'
                  : 'Announcement updated',
            ),
          ),
        );
      }
    } catch (error) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to save announcement: $error')),
        );
      }
    }
  }

  Future<void> _deleteAnnouncement(String announcementId) async {
    try {
      await _adminService.deleteAnnouncement(announcementId);
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text('Announcement deleted')));
      }
    } catch (error) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to delete announcement: $error')),
        );
      }
    }
  }

  Widget _buildAuditTab() {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    return Padding(
      padding: const EdgeInsets.all(16),
      child: _sectionCard(
        padding: EdgeInsets.zero,
        child: StreamBuilder<List<AuditLogEntry>>(
          stream: _adminService.watchAuditLogs(limit: 200),
          builder: (context, snapshot) {
            final logs = snapshot.data ?? const [];
            if (logs.isEmpty) {
              return _buildEmptyPlaceholder(
                'No audit entries yet',
                icon: Icons.history_toggle_off,
              );
            }
            return ListView.separated(
              padding: const EdgeInsets.all(16),
              itemCount: logs.length,
              separatorBuilder: (_, __) =>
                  Divider(color: scheme.outlineVariant.withValues(alpha: 0.3)),
              itemBuilder: (context, index) {
                final log = logs[index];
                return ListTile(
                  contentPadding: const EdgeInsets.symmetric(vertical: 8),
                  leading: CircleAvatar(
                    backgroundColor: scheme.secondaryContainer,
                    foregroundColor: scheme.onSecondaryContainer,
                    child: Text(
                      log.actorName.isNotEmpty
                          ? log.actorName.substring(0, 1).toUpperCase()
                          : '?',
                    ),
                  ),
                  title: Text(
                    '${log.actorName} • ${log.action}',
                    style: theme.textTheme.titleSmall?.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  subtitle: Text(
                    '${log.objectType} (${log.objectId})\n${log.details ?? {}}',
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: scheme.onSurfaceVariant,
                    ),
                  ),
                  isThreeLine: true,
                );
              },
            );
          },
        ),
      ),
    );
  }

  Widget _statusChip(UserStatus status, ColorScheme scheme) {
    Color bg;
    Color fg;
    IconData icon;
    switch (status) {
      case UserStatus.muted:
        bg = scheme.errorContainer;
        fg = scheme.onErrorContainer;
        icon = Icons.volume_off;
        break;
      case UserStatus.banned:
        bg = scheme.error.withValues(alpha: 0.14);
        fg = scheme.error;
        icon = Icons.gavel;
        break;
      case UserStatus.shadowBanned:
        bg = scheme.surfaceVariant;
        fg = scheme.onSurfaceVariant;
        icon = Icons.visibility_off_outlined;
        break;
      case UserStatus.active:
      default:
        bg = scheme.secondaryContainer;
        fg = scheme.onSecondaryContainer;
        icon = Icons.verified_user_outlined;
    }
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(14),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 16, color: fg),
          const SizedBox(width: 6),
          Text(status.label, style: TextStyle(color: fg)),
        ],
      ),
    );
  }

  Widget _metaPill({
    required String label,
    required IconData icon,
    required Color color,
    required Color textColor,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: textColor),
          const SizedBox(width: 6),
          Text(
            label,
            style: TextStyle(
              color: textColor,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }

  String? _muteCountdown(DateTime? until) {
    if (until == null) return null;
    final remaining = until.difference(_now);
    if (remaining.isNegative) return null;
    if (remaining.inDays >= 1) {
      final hours = remaining.inHours.remainder(24);
      return '${remaining.inDays}d ${hours}h left';
    }
    if (remaining.inHours >= 1) {
      final mins = remaining.inMinutes.remainder(60);
      return '${remaining.inHours}h ${mins}m left';
    }
    return '${remaining.inMinutes}m left';
  }

  Widget _sectionCard({
    required Widget child,
    EdgeInsetsGeometry padding = const EdgeInsets.all(16),
  }) {
    final scheme = Theme.of(context).colorScheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Container(
      padding: padding,
      decoration: BoxDecoration(
        color: scheme.surfaceContainerHighest.withValues(
          alpha: isDark ? 0.7 : 0.95,
        ),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: scheme.outlineVariant.withValues(alpha: 0.5)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: isDark ? 0.4 : 0.08),
            blurRadius: 30,
            offset: const Offset(0, 14),
          ),
        ],
      ),
      child: child,
    );
  }

  Widget _buildFilterPill({
    required String label,
    required bool selected,
    required VoidCallback onSelected,
  }) {
    final scheme = Theme.of(context).colorScheme;
    return Padding(
      padding: const EdgeInsets.only(right: 8),
      child: ChoiceChip(
        label: Text(label),
        selected: selected,
        onSelected: (_) => onSelected(),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(28)),
        materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
        labelStyle: TextStyle(
          color: selected ? scheme.onPrimaryContainer : scheme.onSurfaceVariant,
          fontWeight: FontWeight.w600,
        ),
        selectedColor: scheme.primaryContainer.withValues(alpha: 0.9),
        backgroundColor: scheme.surfaceContainerHighest.withValues(alpha: 0.5),
        side: BorderSide(
          color: selected
              ? scheme.primary
              : scheme.outlineVariant.withValues(alpha: 0.4),
        ),
      ),
    );
  }

  Widget _buildEmptyPlaceholder(
    String message, {
    IconData icon = Icons.inbox_outlined,
  }) {
    final scheme = Theme.of(context).colorScheme;
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 40, color: scheme.onSurfaceVariant),
          const SizedBox(height: 12),
          Text(message, style: TextStyle(color: scheme.onSurfaceVariant)),
        ],
      ),
    );
  }

  BoxDecoration _dashboardBackground(ColorScheme scheme) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return BoxDecoration(
      gradient: LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: [
          scheme.surfaceContainerHighest.withValues(
            alpha: isDark ? 0.65 : 0.95,
          ),
          scheme.surface,
        ],
      ),
    );
  }

  Widget _buildDropdownField<T>({
    required String label,
    required T value,
    required List<DropdownMenuItem<T>> items,
    required ValueChanged<T> onChanged,
  }) {
    return InputDecorator(
      decoration: InputDecoration(
        labelText: label,
        border: const OutlineInputBorder(),
        contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
      ),
      child: DropdownButton<T>(
        value: value,
        isExpanded: true,
        underline: const SizedBox.shrink(),
        items: items,
        onChanged: (selected) {
          if (selected != null) onChanged(selected);
        },
      ),
    );
  }

  String _formatDuration(Duration duration) {
    if (duration.inDays >= 1) {
      return '${duration.inDays} day${duration.inDays > 1 ? 's' : ''}';
    }
    if (duration.inHours >= 1) {
      return '${duration.inHours} hour${duration.inHours > 1 ? 's' : ''}';
    }
    return '${duration.inMinutes} min';
  }
}
