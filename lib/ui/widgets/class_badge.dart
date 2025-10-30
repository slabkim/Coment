import 'package:flutter/material.dart';
import '../../data/models/user_class.dart';

/// Visual badge displaying user's class rank
class ClassBadge extends StatelessWidget {
  final UserClass userClass;
  final double size;
  final bool showLabel;

  const ClassBadge({
    super.key,
    required this.userClass,
    this.size = 24,
    this.showLabel = true,
  });

  @override
  Widget build(BuildContext context) {
    final color1 = Color(int.parse('FF${userClass.gradient1}', radix: 16));
    final color2 = Color(int.parse('FF${userClass.gradient2}', radix: 16));
    
    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: size * 0.33,
        vertical: size * 0.17,
      ),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [color1, color2],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(size * 0.33),
        boxShadow: userClass.hasGlow
            ? [
                BoxShadow(
                  color: color1.withValues(alpha: 0.5),
                  blurRadius: size * 0.33,
                  offset: Offset(0, size * 0.08),
                ),
              ]
            : null,
        border: Border.all(
          color: Colors.white.withValues(alpha: 0.3),
          width: 1.5,
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            userClass.icon,
            style: TextStyle(
              fontSize: size * 0.5,
              height: 1.0,
            ),
          ),
          if (showLabel) ...[
            SizedBox(width: size * 0.17),
            Text(
              userClass.name,
              style: TextStyle(
                color: Colors.white,
                fontSize: size * 0.5,
                fontWeight: FontWeight.w800,
                letterSpacing: 0.5,
                height: 1.0,
              ),
            ),
          ],
        ],
      ),
    );
  }
}

/// Compact class badge (icon only)
class CompactClassBadge extends StatelessWidget {
  final UserClass userClass;
  final double size;

  const CompactClassBadge({
    super.key,
    required this.userClass,
    this.size = 20,
  });

  @override
  Widget build(BuildContext context) {
    return ClassBadge(
      userClass: userClass,
      size: size,
      showLabel: false,
    );
  }
}

/// Simple class badge for public profiles (no XP details)
class SimpleClassBadge extends StatelessWidget {
  final UserClass userClass;

  const SimpleClassBadge({
    super.key,
    required this.userClass,
  });

  @override
  Widget build(BuildContext context) {
    final color1 = Color(int.parse('FF${userClass.gradient1}', radix: 16));
    final color2 = Color(int.parse('FF${userClass.gradient2}', radix: 16));
    
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            color1.withValues(alpha: 0.15),
            color2.withValues(alpha: 0.1),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: color1.withValues(alpha: 0.3),
          width: 2,
        ),
      ),
      child: Row(
        children: [
          // Large badge
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [color1, color2],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              shape: BoxShape.circle,
              boxShadow: userClass.hasGlow
                  ? [
                      BoxShadow(
                        color: color1.withValues(alpha: 0.5),
                        blurRadius: 12,
                        offset: const Offset(0, 4),
                      ),
                    ]
                  : null,
            ),
            child: Text(
              userClass.icon,
              style: const TextStyle(fontSize: 32),
            ),
          ),
          const SizedBox(width: 16),
          
          // Class name only (no XP)
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '${userClass.name} Class',
                  style: TextStyle(
                    color: Theme.of(context).colorScheme.onSurface,
                    fontSize: 24,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  userClass.toString(),
                  style: TextStyle(
                    color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.6),
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// Large class badge for profile display
class LargeClassBadge extends StatelessWidget {
  final UserClass userClass;
  final int xp;

  const LargeClassBadge({
    super.key,
    required this.userClass,
    required this.xp,
  });

  @override
  Widget build(BuildContext context) {
    final color1 = Color(int.parse('FF${userClass.gradient1}', radix: 16));
    final color2 = Color(int.parse('FF${userClass.gradient2}', radix: 16));
    final progress = userClass.getProgressPercentage(xp);
    final xpToNext = userClass.getXPToNextClass(xp);
    
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            color1.withValues(alpha: 0.15),
            color2.withValues(alpha: 0.1),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: color1.withValues(alpha: 0.3),
          width: 2,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Class badge and name
          Row(
            children: [
              // Large badge
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [color1, color2],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  shape: BoxShape.circle,
                  boxShadow: userClass.hasGlow
                      ? [
                          BoxShadow(
                            color: color1.withValues(alpha: 0.5),
                            blurRadius: 12,
                            offset: const Offset(0, 4),
                          ),
                        ]
                      : null,
                ),
                child: Text(
                  userClass.icon,
                  style: const TextStyle(fontSize: 32),
                ),
              ),
              const SizedBox(width: 16),
              
              // Class name and XP
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '${userClass.name} Class',
                      style: TextStyle(
                        color: Theme.of(context).colorScheme.onSurface,
                        fontSize: 24,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '$xp XP',
                      style: TextStyle(
                        color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.6),
                        fontSize: 16,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          
          // Progress to next class
          if (xpToNext != null) ...[
            const SizedBox(height: 16),
            
            // Progress bar
            ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: LinearProgressIndicator(
                value: progress,
                minHeight: 8,
                backgroundColor: color1.withValues(alpha: 0.2),
                valueColor: AlwaysStoppedAnimation(color1),
              ),
            ),
            
            const SizedBox(height: 8),
            
            // XP to next class
            Text(
              '$xpToNext XP to ${UserClass.allClasses[UserClass.allClasses.indexOf(userClass) + 1].name} Class',
              style: TextStyle(
                color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.5),
                fontSize: 12,
                fontWeight: FontWeight.w500,
              ),
            ),
          ] else ...[
            const SizedBox(height: 12),
            Text(
              'MAX RANK! 🏆',
              style: TextStyle(
                color: color1,
                fontSize: 14,
                fontWeight: FontWeight.w700,
                letterSpacing: 1,
              ),
            ),
          ],
        ],
      ),
    );
  }
}

