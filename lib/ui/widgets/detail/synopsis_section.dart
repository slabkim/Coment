import 'package:flutter/material.dart';
import '../../../data/models/nandogami_item.dart';
import 'about_helpers.dart';

/// Widget for displaying the synopsis of an item.
/// Cleans HTML tags from the synopsis text.
class SynopsisSection extends StatelessWidget {
  final NandogamiItem item;

  const SynopsisSection({
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
          'Synopsis',
          style: theme.titleMedium?.copyWith(color: Theme.of(context).colorScheme.onSurface),
        ),
        const SizedBox(height: 8),
        Text(
          AboutHelpers.resolveSynopsis(item),
          style: TextStyle(
            color: Theme.of(context).colorScheme.onSurface,
            height: 1.5,
          ),
        ),
      ],
    );
  }
}

