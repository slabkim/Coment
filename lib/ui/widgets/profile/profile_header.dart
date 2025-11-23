import 'package:flutter/material.dart';
import '../../../data/models/user_profile.dart';
import '../../../data/models/user_role.dart';
import '../common/identity_badge.dart';
import '../profile/profile_stats.dart';

/// Enhanced Profile Header with Cover Photo
class ProfileHeader extends StatelessWidget {
  final UserProfile? profile;
  final String uid;
  
  const ProfileHeader({
    super.key,
    required this.profile,
    required this.uid,
  });

  @override
  Widget build(BuildContext context) {
    final name = profile?.username ?? 'Your Name';
    final handle = profile?.handle ?? profile?.email;
    final photo = profile?.photoUrl;
    final coverPhoto = profile?.coverPhotoUrl;
    
    return Column(
      children: [
        // Cover Photo
        Stack(
          clipBehavior: Clip.none,
          children: [
            Container(
              height: 180,
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.primaryContainer,
              ),
              child: coverPhoto != null && coverPhoto.isNotEmpty
                  ? Image.network(
                      coverPhoto,
                      width: double.infinity,
                      fit: BoxFit.cover,
                      errorBuilder: (context, error, stackTrace) {
                        // Fallback gradient when image fails to load
                        return Container(
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight,
                              colors: [
                                Theme.of(context).colorScheme.primary.withValues(alpha: 0.3),
                                Theme.of(context).colorScheme.secondary.withValues(alpha: 0.3),
                              ],
                            ),
                          ),
                        );
                      },
                    )
                  : Container(
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                          colors: [
                            Theme.of(context).colorScheme.primary.withValues(alpha: 0.3),
                            Theme.of(context).colorScheme.secondary.withValues(alpha: 0.3),
                          ],
                        ),
                      ),
                    ),
            ),
            
            // Avatar (positioned at bottom of cover)
            Positioned(
              bottom: -40,
              left: 0,
              right: 0,
              child: Center(
                child: Container(
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: Theme.of(context).scaffoldBackgroundColor,
                      width: 4,
                    ),
                  ),
                  child: CircleAvatar(
                    radius: 48,
                    backgroundColor: Theme.of(context).colorScheme.primaryContainer,
                    backgroundImage: (photo != null && photo.isNotEmpty)
                        ? NetworkImage(photo)
                        : null,
                    child: (photo == null || photo.isEmpty)
                        ? Text(
                            _initials(name),
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 24,
                              fontWeight: FontWeight.bold,
                            ),
                          )
                        : null,
                  ),
                ),
              ),
            ),
          ],
        ),
        
        const SizedBox(height: 48),
        
        // Name & Handle (with Dev Badge)
        Row(
          mainAxisSize: MainAxisSize.min,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              name,
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                fontSize: 20,
                fontWeight: FontWeight.w700,
              ),
            ),
            ..._buildIdentityBadges(),
          ],
        ),
        if (handle != null && handle.isNotEmpty)
          Padding(
            padding: const EdgeInsets.only(top: 4),
            child: Text(
              handle.startsWith('@') ? handle : '@$handle',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: Theme.of(context).colorScheme.onSurfaceVariant,
              ),
            ),
          ),
        
        // Bio
        if ((profile?.bio ?? '').isNotEmpty) ...[
          const SizedBox(height: 12),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 32),
            child: Text(
              profile!.bio!,
              textAlign: TextAlign.center,
              style: TextStyle(
                color: Theme.of(context).colorScheme.onSurfaceVariant,
              ),
            ),
          ),
        ],
        
        const SizedBox(height: 18),
        
        // Stats Row
        ProfileStats(userId: uid),
        
        const SizedBox(height: 16),
      ],
    );
  }
  
  String _initials(String value) {
    final parts = value.split(' ');
    final first = parts.isNotEmpty && parts.first.isNotEmpty
        ? parts.first[0]
        : 'U';
    final second = parts.length > 1 && parts.last.isNotEmpty
        ? parts.last[0]
        : '';
    return (first + second).toUpperCase();
  }

  List<Widget> _buildIdentityBadges() {
    final widgets = <Widget>[];
    void addBadge(IdentityBadgeType type) {
      if (widgets.isNotEmpty) widgets.add(const SizedBox(width: 6));
      widgets.add(IdentityBadge(type: type));
    }

    if (profile?.role == UserRole.admin) {
      addBadge(IdentityBadgeType.admin);
    }
    if (profile?.isDeveloper ?? false) {
      addBadge(IdentityBadgeType.developer);
    }
    return widgets;
  }
}

