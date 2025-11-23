import 'dart:async';

import 'package:flutter/material.dart';

import '../../../data/models/user_profile.dart';
import '../../../data/models/user_role.dart';
import '../../../data/models/user_sanction.dart';
import '../../../data/services/admin_service.dart';

/// Admin-only moderation controls shown inside a user's public profile.
class AdminUserActionsSection extends StatefulWidget {
  final UserProfile target;
  const AdminUserActionsSection({super.key, required this.target});

  @override
  State<AdminUserActionsSection> createState() => _AdminUserActionsSectionState();
}

class _AdminUserActionsSectionState extends State<AdminUserActionsSection> {
  final _adminService = AdminService();
  Timer? _ticker;
  DateTime _now = DateTime.now();

  @override
  void initState() {
    super.initState();
    _ticker = Timer.periodic(
      const Duration(seconds: 30),
      (_) => setState(() => _now = DateTime.now()),
    );
  }

  @override
  void dispose() {
    _ticker?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final target = widget.target;
    final isBanned = target.status == UserStatus.banned;
    final isMuted = target.status == UserStatus.muted;
    final cardColor = Theme.of(context).colorScheme.surfaceContainerHighest;
    final remainingMute = _muteCountdown(target.mutedUntil);

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Admin Tools',
            style: Theme.of(context).textTheme.titleMedium,
          ),
          const SizedBox(height: 8),
          Card(
            color: cardColor,
            margin: EdgeInsets.zero,
            child: Column(
              children: [
                ListTile(
                  leading: const Icon(Icons.workspace_premium_outlined),
                  title: const Text('Change role'),
                  subtitle: Text('Current: ${target.role.label}'),
                  onTap: _showRolePicker,
                ),
                const Divider(height: 1),
                ListTile(
                  leading: Icon(
                    isMuted ? Icons.volume_up_outlined : Icons.volume_off_outlined,
                  ),
                  title: Text(isMuted ? 'Unmute / adjust mute' : 'Mute user'),
                  subtitle: Text(
                    isMuted
                        ? 'Muted until ${_formatDateTime(target.mutedUntil)}${remainingMute != null ? ' • $remainingMute' : ''}'
                        : 'Issue a temporary mute or quick unmute',
                  ),
                  onTap: _showMuteSheet,
                ),
                const Divider(height: 1),
                ListTile(
                  leading: Icon(isBanned ? Icons.lock_open : Icons.gavel_outlined),
                  title: Text(isBanned ? 'Unban user' : 'Ban user'),
                  subtitle: Text(
                    isBanned ? 'User is currently banned' : 'Permanently suspend account',
                  ),
                  onTap: _confirmBan,
                ),
                const Divider(height: 1),
                ListTile(
                  leading: const Icon(Icons.history),
                  title: const Text('Sanction history'),
                  subtitle: Text(
                    target.sanctionCount == 0
                        ? 'No prior sanctions'
                        : '${target.sanctionCount} past action${target.sanctionCount == 1 ? '' : 's'}',
                  ),
                  onTap: _showSanctionHistory,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _showRolePicker() async {
    final user = widget.target;
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
                      role == user.role ? Icons.check_circle : Icons.circle_outlined,
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

  Future<void> _showMuteSheet() async {
    final user = widget.target;
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
                  subtitle: const Text('Lift existing mute immediately'),
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
        await _handleUnmute();
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
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to mute user: $error')),
        );
      }
    }
  }

  Future<void> _handleUnmute() async {
    final user = widget.target;
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

  Future<void> _confirmBan() async {
    final user = widget.target;
    final isBanned = user.status == UserStatus.banned;

    if (isBanned) {
      try {
        await _adminService.unbanUser(user.id);
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('User unbanned')),
          );
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
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('User banned')),
        );
      }
    } catch (error) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to ban user: $error')),
        );
      }
    }
  }

  Future<void> _showSanctionHistory() async {
    final user = widget.target;
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
                itemCount: sanctions.length,
                separatorBuilder: (_, __) => const Divider(height: 1),
                itemBuilder: (context, index) {
                  final sanction = sanctions[index];
                  final createdAt = _formatDateTime(sanction.createdAt);
                  final expiresAt = sanction.expiresAt == null
                      ? 'No expiry'
                      : _formatDateTime(sanction.expiresAt!);
                  return ListTile(
                    title: Text('${sanction.type.label} • ${sanction.reason ?? '-'}'),
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

  String _formatDuration(Duration duration) {
    if (duration.inDays >= 1) {
      return '${duration.inDays} day${duration.inDays > 1 ? 's' : ''}';
    }
    if (duration.inHours >= 1) {
      return '${duration.inHours} hour${duration.inHours > 1 ? 's' : ''}';
    }
    return '${duration.inMinutes} min';
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

  String _formatDateTime(DateTime? value) {
    if (value == null) return '--';
    final local = value.toLocal();
    String two(int v) => v.toString().padLeft(2, '0');
    return '${local.year}-${two(local.month)}-${two(local.day)} ${two(local.hour)}:${two(local.minute)}';
  }
}
