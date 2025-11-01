import 'package:flutter/material.dart';
import '../../../core/constants.dart';
import '../../../data/models/nandogami_item.dart';

/// Widget for displaying genres and tags as chips.
class GenresTagsSection extends StatelessWidget {
  final NandogamiItem item;

  const GenresTagsSection({
    super.key,
    required this.item,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context).textTheme;
    
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (item.genres?.isNotEmpty == true) ...[
          Text(
            'Genres',
            style: theme.titleMedium?.copyWith(color: Theme.of(context).colorScheme.onSurface),
          ),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: item.genres!
                .map((genre) => Chip(
                      label: Text(genre),
                      backgroundColor: Theme.of(context).colorScheme.surfaceContainerHighest,
                      labelStyle: TextStyle(color: Theme.of(context).colorScheme.onSurface),
                    ))
                .toList(),
          ),
          const SizedBox(height: 16),
        ],
        if (item.tags?.isNotEmpty == true) ...[
          Text(
            'Tags',
            style: theme.titleMedium?.copyWith(color: AppColors.white),
          ),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: item.tags!
                .take(10) // Limit to first 10 tags
                .map((tag) => Chip(
                      label: Text(tag),
                      backgroundColor: AppColors.grayDark.withValues(alpha: 0.5),
                      labelStyle: const TextStyle(color: AppColors.whiteSecondary),
                    ))
                .toList(),
          ),
        ],
      ],
    );
  }
}

