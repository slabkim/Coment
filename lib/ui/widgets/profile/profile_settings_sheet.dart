import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../screens/edit_profile_screen.dart';
import '../../screens/reading_list_screen.dart';
import '../../screens/about_screen.dart';
import '../../screens/remove_ads_screen.dart';
import '../../../state/monetization_provider.dart';
import 'profile_helpers.dart';

class ProfileSettingsSheet extends StatelessWidget {
  const ProfileSettingsSheet({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
      ),
      child: SafeArea(
        top: false,
        child: Builder(
          builder: (context) {
            final bottomInset = MediaQuery.of(context).viewInsets.bottom;
            return SingleChildScrollView(
              padding: EdgeInsets.only(bottom: bottomInset + 16),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
            // Handle bar
            Container(
              margin: const EdgeInsets.only(top: 12, bottom: 8),
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.onSurfaceVariant.withValues(alpha: 0.4),
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            
            // Title
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 8, 20, 16),
              child: Row(
                children: [
                  const Icon(
                    Icons.settings,
                    color: Colors.white,
                    size: 24,
                  ),
                  const SizedBox(width: 12),
                  Text(
                    'Settings',
                    style: TextStyle(
                      color: Theme.of(context).colorScheme.onSurface,
                      fontWeight: FontWeight.bold,
                      fontSize: 20,
                    ),
                  ),
                ],
              ),
            ),
            
            // Menu items
            _settingsOption(
              context,
              icon: Icons.person_outline,
              label: 'Edit Profile',
              onTap: () {
                Navigator.pop(context);
                Navigator.of(context).push(
                  MaterialPageRoute(builder: (_) => const EditProfileScreen()),
                );
              },
            ),
            _settingsOption(
              context,
              icon: Icons.palette_outlined,
              label: 'Change Theme',
              onTap: () {
                Navigator.pop(context);
                ProfileHelpers.showThemeSheet(context);
              },
            ),
            _settingsOption(
              context,
              icon: Icons.library_books_outlined,
              label: 'Reading List',
              onTap: () {
                Navigator.pop(context);
                Navigator.of(context).push(
                  MaterialPageRoute(builder: (_) => const ReadingListScreen()),
                );
              },
            ),
            _settingsOption(
              context,
              icon: Icons.info_outline,
              label: 'About',
              onTap: () {
                Navigator.pop(context);
                Navigator.of(context).push(
                  MaterialPageRoute(builder: (_) => const AboutScreen()),
                );
              },
            ),
            Consumer<MonetizationProvider>(
              builder: (context, monetization, _) {
                final unlocked = monetization.adsRemoved;
                return _settingsOption(
                  context,
                  icon: unlocked ? Icons.verified_outlined : Icons.workspace_premium_outlined,
                  label: unlocked ? 'Iklan dimatikan' : 'Hilangkan Iklan',
                  trailing: unlocked
                      ? const Icon(Icons.check, color: Colors.green)
                      : const Icon(Icons.lock_open, color: Colors.white70),
                  onTap: () {
                    Navigator.pop(context);
                    Navigator.of(context).push(
                      MaterialPageRoute(builder: (_) => const RemoveAdsScreen()),
                    );
                  },
                );
              },
            ),
            
            const SizedBox(height: 8),
            
            // Logout button (different style)
            Container(
              margin: const EdgeInsets.symmetric(horizontal: 16),
              decoration: BoxDecoration(
                color: Colors.red.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: ListTile(
                contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                leading: const Icon(Icons.logout, color: Colors.red),
                title: const Text(
                  'Logout',
                  style: TextStyle(
                    color: Colors.red,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                trailing: const Icon(Icons.chevron_right, color: Colors.red),
                onTap: () {
                  Navigator.pop(context);
                  ProfileHelpers.showLogoutDialog(context);
                },
              ),
            ),
            
            const SizedBox(height: 24),
          ],
              ),
            );
          },
        ),
      ),
    );
  }

  Widget _settingsOption(
    BuildContext context, {
    required IconData icon,
    required String label,
    required VoidCallback onTap,
    Widget? trailing,
  }) {
    return ListTile(
      contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 4),
      leading: Icon(
        icon,
        color: Colors.white,
        size: 24,
      ),
      title: Text(
        label,
        style: TextStyle(
          color: Theme.of(context).colorScheme.onSurface,
          fontWeight: FontWeight.w500,
          fontSize: 16,
        ),
      ),
      trailing: trailing ??
          Icon(
            Icons.chevron_right,
            color: Theme.of(context).colorScheme.onSurfaceVariant,
          ),
      onTap: onTap,
    );
  }
}

