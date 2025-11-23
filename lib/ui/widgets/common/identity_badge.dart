import 'package:flutter/material.dart';

enum IdentityBadgeType { developer, admin }

enum IdentityBadgeSize { regular, compact }

class IdentityBadge extends StatelessWidget {
  final IdentityBadgeType type;
  final IdentityBadgeSize size;

  const IdentityBadge({
    super.key,
    required this.type,
    this.size = IdentityBadgeSize.regular,
  });

  @override
  Widget build(BuildContext context) {
    final config = _badgeConfigs[type]!;
    final compact = size == IdentityBadgeSize.compact;
    final padding = compact
        ? const EdgeInsets.symmetric(horizontal: 6, vertical: 2)
        : const EdgeInsets.symmetric(horizontal: 8, vertical: 3);
    final borderRadius = BorderRadius.circular(compact ? 8 : 12);
    final iconSize = compact ? 8.0 : 12.0;
    final fontSize = compact ? 8.0 : 10.0;
    final spacing = compact ? 2.0 : 4.0;
    final boxShadow = [
      BoxShadow(
        color: config.shadowColor.withValues(alpha: compact ? 0.25 : 0.35),
        blurRadius: compact ? 4 : 8,
        offset: const Offset(0, 2),
      ),
    ];

    return Container(
      padding: padding,
      decoration: BoxDecoration(
        gradient: LinearGradient(colors: config.colors),
        borderRadius: borderRadius,
        boxShadow: boxShadow,
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(config.icon, size: iconSize, color: Colors.white),
          SizedBox(width: spacing),
          Text(
            config.label,
            style: TextStyle(
              color: Colors.white,
              fontSize: fontSize,
              fontWeight: FontWeight.w700,
              letterSpacing: compact ? 0.3 : 0.5,
            ),
          ),
        ],
      ),
    );
  }
}

class _BadgeConfig {
  final String label;
  final List<Color> colors;
  final IconData icon;
  final Color shadowColor;

  const _BadgeConfig({
    required this.label,
    required this.colors,
    required this.icon,
    required this.shadowColor,
  });
}

const _badgeConfigs = <IdentityBadgeType, _BadgeConfig>{
  IdentityBadgeType.developer: _BadgeConfig(
    label: 'DEV',
    colors: [Color(0xFF6366F1), Color(0xFF8B5CF6)],
    icon: Icons.verified,
    shadowColor: Color(0xFF6366F1),
  ),
  IdentityBadgeType.admin: _BadgeConfig(
    label: 'ADMIN',
    colors: [Color(0xFFF97316), Color(0xFFE11D48)],
    icon: Icons.shield,
    shadowColor: Color(0xFFE11D48),
  ),
};
