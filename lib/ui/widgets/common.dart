import 'package:flutter/material.dart';

import '../../core/constants.dart';

/// A widget that displays a section title with consistent styling.
class SectionTitle extends StatelessWidget {
  final String text;
  const SectionTitle(this.text, {super.key});

  @override
  Widget build(BuildContext context) {
    final base = Theme.of(context).textTheme.titleMedium;
    return Text(
      text,
      style: base?.copyWith(
            color: AppColors.white,
            fontWeight: FontWeight.bold,
          ) ??
          const TextStyle(
            color: AppColors.white,
            fontWeight: FontWeight.bold,
            fontSize: 18,
          ),
    );
  }
}

/// A styled list tile widget with dark theme support and a divider.
class DarkListTile extends StatelessWidget {
  final Widget? leading;
  final Widget? title;
  final Widget? subtitle;
  final Widget? trailing;
  final VoidCallback? onTap;

  const DarkListTile({
    super.key,
    this.leading,
    this.title,
    this.subtitle,
    this.trailing,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        ListTile(
          leading: leading,
          title: title,
          subtitle: subtitle,
          trailing: trailing ??
              const Icon(Icons.chevron_right, color: AppColors.whiteSecondary),
          onTap: onTap,
        ),
        const Divider(height: 1, color: Color(0xFF22252B)),
      ],
    );
  }
}

/// A styled chip widget for displaying tags.
class TagChip extends StatelessWidget {
  final String text;
  final VoidCallback? onPressed;
  const TagChip(this.text, {super.key, this.onPressed});

  @override
  Widget build(BuildContext context) {
    return ActionChip(
      label: Text(text),
      onPressed: onPressed,
      backgroundColor: const Color(0xFF2A2E35),
      labelStyle: const TextStyle(color: AppColors.white),
    );
  }
}


