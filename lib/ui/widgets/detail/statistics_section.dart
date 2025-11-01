import 'package:flutter/material.dart';
import '../../../core/constants.dart';
import '../../../data/models/nandogami_item.dart';

/// Widget for displaying item statistics.
/// Shows average score, mean score, popularity, and favorites count.
class StatisticsSection extends StatelessWidget {
  final NandogamiItem item;

  const StatisticsSection({
    super.key,
    required this.item,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context).textTheme;
    
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Statistics',
          style: theme.titleMedium?.copyWith(color: Theme.of(context).colorScheme.onSurface),
        ),
        const SizedBox(height: 12),
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: AppColors.grayDark.withValues(alpha: 0.3),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: AppColors.grayDark.withValues(alpha: 0.5),
              width: 1,
            ),
          ),
          child: Column(
            children: [
              if (item.averageScore != null) ...[
                _StatRow(label: 'Average Score', value: '${item.averageScore!.toStringAsFixed(1)}/100'),
                const SizedBox(height: 8),
              ],
              if (item.meanScore != null) ...[
                _StatRow(label: 'Mean Score', value: '${item.meanScore}/100'),
                const SizedBox(height: 8),
              ],
              if (item.popularity != null) ...[
                _StatRow(label: 'Popularity', value: item.popularity.toString()),
                const SizedBox(height: 8),
              ],
              if (item.favourites != null) ...[
                _StatRow(label: 'Favorites', value: item.favourites.toString()),
              ],
            ],
          ),
        ),
      ],
    );
  }
}

class _StatRow extends StatelessWidget {
  final String label;
  final String value;

  const _StatRow({
    required this.label,
    required this.value,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: TextStyle(
            color: Theme.of(context).colorScheme.onSurfaceVariant,
            fontSize: 14,
          ),
        ),
        Text(
          value,
          style: TextStyle(
            color: Theme.of(context).colorScheme.onSurface,
            fontSize: 14,
            fontWeight: FontWeight.w500,
          ),
        ),
      ],
    );
  }
}

