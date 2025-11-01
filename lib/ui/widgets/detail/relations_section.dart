import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import '../../../core/constants.dart';
import '../../../data/models/manga.dart';
import 'about_helpers.dart';

/// Widget for displaying related manga with lazy loading support.
class RelationsSection extends StatelessWidget {
  final bool loading;
  final List<MangaRelation>? relations;
  final void Function(MangaRelation) onRelationTap;

  const RelationsSection({
    super.key,
    required this.loading,
    this.relations,
    required this.onRelationTap,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context).textTheme;
    
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Relations',
          style: theme.titleMedium?.copyWith(color: Theme.of(context).colorScheme.onSurface),
        ),
        const SizedBox(height: 12),
        if (loading)
          const Center(
            child: CircularProgressIndicator(),
          )
        else if (relations?.isNotEmpty == true)
          ...relations!.take(5).map((relation) => GestureDetector(
            onTap: () => onRelationTap(relation),
            child: Container(
              margin: const EdgeInsets.only(bottom: 12),
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: AppColors.grayDark.withValues(alpha: 0.4),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: AppColors.purpleAccent.withValues(alpha: 0.3),
                  width: 1,
                ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.2),
                    blurRadius: 4,
                  ),
                ],
              ),
              child: Row(
                children: [
                  // Cover Image
                  if (relation.manga.coverImage != null)
                    Container(
                      width: 50,
                      height: 70,
                      margin: const EdgeInsets.only(right: 16),
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(8),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withValues(alpha: 0.3),
                            blurRadius: 4,
                          ),
                        ],
                      ),
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(8),
                        child: CachedNetworkImage(
                          imageUrl: relation.manga.coverImage!,
                          fit: BoxFit.cover,
                          placeholder: (context, url) => Container(
                            color: AppColors.grayDark,
                            child: const Center(
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                              ),
                            ),
                          ),
                          errorWidget: (context, url, error) => Container(
                            color: AppColors.grayDark,
                            child: const Icon(
                              Icons.broken_image,
                              color: AppColors.whiteSecondary,
                              size: 20,
                            ),
                          ),
                        ),
                      ),
                    ),
                  
                  // Content
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Title
                        Text(
                          relation.manga.bestTitle,
                          style: const TextStyle(
                            color: AppColors.white,
                            fontWeight: FontWeight.w600,
                            fontSize: 14,
                          ),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 6),
                        
                        // Relation Type Badge
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 4,
                          ),
                          decoration: BoxDecoration(
                            color: AboutHelpers.getRelationTypeColor(relation.relationType).withValues(alpha: 0.2),
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(
                              color: AboutHelpers.getRelationTypeColor(relation.relationType).withValues(alpha: 0.5),
                              width: 1,
                            ),
                          ),
                          child: Text(
                            AboutHelpers.formatRelationType(relation.relationType),
                            style: TextStyle(
                              color: AboutHelpers.getRelationTypeColor(relation.relationType),
                              fontSize: 11,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ),
                        const SizedBox(height: 6),
                        
                        // Format
                        if (relation.manga.format != null) ...[
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 6,
                              vertical: 2,
                            ),
                            decoration: BoxDecoration(
                              color: AppColors.blueAccent.withValues(alpha: 0.2),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Text(
                              relation.manga.format!,
                              style: const TextStyle(
                                color: AppColors.blueAccent,
                                fontSize: 10,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                  
                  // Arrow Icon
                  const Icon(
                    Icons.arrow_forward_ios,
                    color: AppColors.whiteSecondary,
                    size: 16,
                  ),
                ],
              ),
            ),
          ))
        else if (relations?.isEmpty == true)
          const Text(
            'No relations available',
            style: TextStyle(color: AppColors.whiteSecondary),
          ),
      ],
    );
  }
}
