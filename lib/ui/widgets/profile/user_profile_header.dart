import 'package:flutter/material.dart';
import '../../../data/models/user_profile.dart';
import '../../../data/models/user_role.dart';
import '../common/identity_badge.dart';

/// Profile Header for Public User Profile (similar to ProfileHeader but simpler)
class UserProfileHeader extends StatelessWidget {
  final UserProfile profile;
  
  const UserProfileHeader({
    super.key,
    required this.profile,
  });

  @override
  Widget build(BuildContext context) {
    final name = profile.username ?? profile.handle ?? profile.email ?? 'User';
    final handle = profile.handle ?? profile.email ?? '';
    final photo = profile.photoUrl;
    final coverPhoto = profile.coverPhotoUrl;
    final bio = profile.bio ?? '';

    return Column(
      children: [
        // Cover Photo & Avatar
        Stack(
          clipBehavior: Clip.none,
          children: [
            // Cover Photo
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
                            style: TextStyle(
                              color: Theme.of(context).colorScheme.onPrimaryContainer,
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
        
        const SizedBox(height: 52),
        
        // Name & Handle (with Dev Badge)
        Center(
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                name,
                style: TextStyle(
                  color: Theme.of(context).colorScheme.onSurface,
                  fontSize: 22,
                  fontWeight: FontWeight.w700,
                ),
              ),
              ..._buildIdentityBadges(),
            ],
          ),
        ),
        if (handle.isNotEmpty)
          Center(
            child: Padding(
              padding: const EdgeInsets.only(top: 4),
              child: Text(
                handle.startsWith('@') ? handle : '@$handle',
                style: TextStyle(
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                  fontSize: 14,
                ),
              ),
            ),
          ),
        
        // Bio
        if (bio.isNotEmpty) ...[
          const SizedBox(height: 16),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Text(
              bio,
              textAlign: TextAlign.center,
              style: TextStyle(color: Theme.of(context).colorScheme.onSurfaceVariant),
            ),
          ),
        ],
      ],
    );
  }

  String _initials(String value) {
    final parts = value.trim().split(' ');
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

    if (profile.role == UserRole.admin) {
      addBadge(IdentityBadgeType.admin);
    }
    if (profile.isDeveloper) {
      addBadge(IdentityBadgeType.developer);
    }
    return widgets;
  }
}

