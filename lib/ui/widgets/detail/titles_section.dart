import 'package:flutter/material.dart';
import '../../../core/constants.dart';
import '../../../data/models/nandogami_item.dart';

/// Widget for displaying various titles of an item.
/// Shows English title, native title, and synonyms.
class TitlesSection extends StatelessWidget {
  final NandogamiItem item;

  const TitlesSection({
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
          'Titles',
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
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (item.englishTitle != null) ...[
                _TitleRow(label: 'English', value: item.englishTitle!),
                const SizedBox(height: 8),
              ],
              if (item.nativeTitle != null) ...[
                _TitleRow(label: 'Native', value: item.nativeTitle!),
                const SizedBox(height: 8),
              ],
              if (item.synonyms?.isNotEmpty == true) ...[
                _TitleRow(label: 'Synonyms', value: item.synonyms!.join(', ')),
              ],
            ],
          ),
        ),
      ],
    );
  }
}

class _TitleRow extends StatelessWidget {
  final String label;
  final String value;

  const _TitleRow({
    required this.label,
    required this.value,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: TextStyle(
            color: Theme.of(context).colorScheme.onSurfaceVariant,
            fontSize: 12,
            fontWeight: FontWeight.w500,
          ),
        ),
        const SizedBox(height: 2),
        Text(
          value,
          style: TextStyle(
            color: Theme.of(context).colorScheme.onSurface,
            fontSize: 14,
          ),
        ),
      ],
    );
  }
}

