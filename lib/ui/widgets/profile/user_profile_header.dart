import 'package:flutter/material.dart';
import '../../../data/models/user_profile.dart';

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
              if (profile.isDeveloper) ...[
                const SizedBox(width: 6),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      colors: [Color(0xFF6366F1), Color(0xFF8B5CF6)],
                    ),
                    borderRadius: BorderRadius.circular(12),
                    boxShadow: [
                      BoxShadow(
                        color: const Color(0xFF6366F1).withValues(alpha: 0.3),
                        blurRadius: 8,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: const Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.verified, size: 12, color: Colors.white),
                      SizedBox(width: 3),
                      Text(
                        'DEV',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 10,
                          fontWeight: FontWeight.w700,
                          letterSpacing: 0.5,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
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
}

