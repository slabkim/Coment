import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../state/theme_provider.dart';

class ProfileThemeSheet extends StatelessWidget {
  const ProfileThemeSheet({super.key});

  @override
  Widget build(BuildContext context) {
    final tp = context.watch<ThemeProvider>();
    final current = tp.mode;
    
    return SafeArea(
      top: false,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'App Theme',
              style: TextStyle(
                color: Theme.of(context).colorScheme.onSurface,
                fontWeight: FontWeight.bold,
                fontSize: 18,
              ),
            ),
            const SizedBox(height: 12),
            _themeOption(context, 'System Default', ThemeMode.system, current),
            _themeOption(context, 'Light', ThemeMode.light, current),
            _themeOption(context, 'Dark', ThemeMode.dark, current),
            const SizedBox(height: 12),
          ],
        ),
      ),
    );
  }

  Widget _themeOption(BuildContext context, String label, ThemeMode mode, ThemeMode current) {
    final tp = context.read<ThemeProvider>();
    final selected = mode == current;
    
    return ListTile(
      contentPadding: EdgeInsets.zero,
      leading: Icon(
        selected ? Icons.radio_button_checked : Icons.radio_button_off,
        color: selected 
            ? Theme.of(context).colorScheme.primary 
            : Theme.of(context).colorScheme.onSurfaceVariant,
      ),
      title: Text(
        label, 
        style: TextStyle(
          color: Theme.of(context).colorScheme.onSurface,
          fontWeight: selected ? FontWeight.bold : FontWeight.normal,
        ),
      ),
      onTap: () async {
        await tp.setMode(mode);
        if (context.mounted) Navigator.pop(context);
      },
    );
  }
}

