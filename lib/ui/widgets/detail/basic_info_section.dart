import 'package:flutter/material.dart';
import '../../../core/constants.dart';
import '../../../data/models/nandogami_item.dart';
import 'about_helpers.dart';

/// Widget for displaying basic information about an item.
/// Shows title, format, status, dates, chapters, volumes, and source.
class BasicInfoSection extends StatelessWidget {
  final NandogamiItem item;

  const BasicInfoSection({
    super.key,
    required this.item,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context).textTheme;
    
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Title
        Text(
          item.title,
          style: theme.titleLarge?.copyWith(
            color: Theme.of(context).colorScheme.onSurface,
            fontWeight: FontWeight.w700,
          ),
        ),
        const SizedBox(height: 8),
        
        // Format & Status
        Row(
          children: [
            if (item.format != null) ...[
              _InfoChip(label: 'Format', value: AboutHelpers.formatFormat(item.format!)),
              const SizedBox(width: 8),
            ],
            if (item.status != null) ...[
              _InfoChip(label: 'Status', value: AboutHelpers.formatStatus(item.status!)),
              const SizedBox(width: 8),
            ],
          ],
        ),
        const SizedBox(height: 8),
        
        // Start Date
        if (item.startDate != null) ...[
          _InfoRow(label: 'Start Date', value: AboutHelpers.formatDate(item.startDate!)),
          const SizedBox(height: 4),
        ],
        
        // End Date
        if (item.endDate != null) ...[
          _InfoRow(label: 'End Date', value: AboutHelpers.formatDate(item.endDate!)),
          const SizedBox(height: 4),
        ],
        
        // Source
        if (item.source != null) ...[
          _InfoRow(label: 'Source', value: AboutHelpers.formatSource(item.source!)),
          const SizedBox(height: 4),
        ],
        
        // Chapters & Volumes
        if (item.chapters != null || item.volumes != null) ...[
          Wrap(
            children: [
              if (item.chapters != null && item.chapters! > 0) ...[
                _InfoRow(label: 'Chapters', value: item.chapters.toString()),
                const SizedBox(width: 16),
              ],
              if (item.volumes != null && item.volumes! > 0) ...[
                _InfoRow(label: 'Volumes', value: item.volumes.toString()),
              ],
            ],
          ),
        ],
      ],
    );
  }
}

/// A chip widget for displaying label and value with custom styling.
class _InfoChip extends StatelessWidget {
  final String label;
  final String value;

  const _InfoChip({
    required this.label,
    required this.value,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: AppColors.blueAccent.withValues(alpha: 0.2),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: AppColors.blueAccent.withValues(alpha: 0.5),
          width: 1,
        ),
      ),
      child: Text(
        '$label: $value',
        style: const TextStyle(
          color: AppColors.blueAccent,
          fontSize: 12,
          fontWeight: FontWeight.w500,
        ),
      ),
    );
  }
}

/// A row widget for displaying label and value with consistent layout.
class _InfoRow extends StatelessWidget {
  final String label;
  final String value;

  const _InfoRow({
    required this.label,
    required this.value,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      child: Row(
        children: [
          SizedBox(
            width: 80,
            child: Text(
              '$label:',
              style: const TextStyle(
                color: AppColors.whiteSecondary,
                fontSize: 14,
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(
                color: AppColors.white,
                fontSize: 14,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

