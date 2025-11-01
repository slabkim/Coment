import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import '../../../core/constants.dart';
import '../../../data/models/manga.dart';

/// Widget for displaying recommendations with lazy loading support.
class RecommendationsSection extends StatelessWidget {
  final bool loading;
  final List<Manga>? recommendations;
  final void Function(Manga) onRecommendationTap;

  const RecommendationsSection({
    super.key,
    required this.loading,
    this.recommendations,
    required this.onRecommendationTap,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context).textTheme;
    
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Recommendations',
          style: theme.titleMedium?.copyWith(color: Theme.of(context).colorScheme.onSurface),
        ),
        const SizedBox(height: 12),
        if (loading)
          const Center(
            child: CircularProgressIndicator(),
          )
        else if (recommendations?.isNotEmpty == true)
          SizedBox(
            height: 200,
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              itemCount: recommendations!.length,
              itemBuilder: (context, index) {
                final recommendation = recommendations![index];
                return GestureDetector(
                  onTap: () => onRecommendationTap(recommendation),
                  child: Container(
                    width: 120,
                    margin: const EdgeInsets.only(right: 12),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        // Cover Image
                        ClipRRect(
                          borderRadius: BorderRadius.circular(8),
                          child: CachedNetworkImage(
                            imageUrl: recommendation.coverImage ?? '',
                            width: 120,
                            height: 160,
                            fit: BoxFit.cover,
                            placeholder: (context, url) => Container(
                              width: 120,
                              height: 160,
                              color: AppColors.grayDark,
                              child: const Center(
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                ),
                              ),
                            ),
                            errorWidget: (context, url, error) => Container(
                              width: 120,
                              height: 160,
                              color: AppColors.grayDark,
                              child: const Icon(
                                Icons.broken_image,
                                color: AppColors.whiteSecondary,
                                size: 32,
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(height: 8),
                        
                        // Title
                        Expanded(
                          child: Text(
                            recommendation.bestTitle,
                            style: TextStyle(
                              color: Theme.of(context).colorScheme.onSurface,
                              fontSize: 12,
                              fontWeight: FontWeight.w500,
                            ),
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        const SizedBox(height: 4),
                        
                        // Rating
                        if (recommendation.averageScore != null)
                          Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              const Icon(
                                Icons.star,
                                color: AppColors.orange,
                                size: 12,
                              ),
                              const SizedBox(width: 4),
                              Flexible(
                                child: Text(
                                  (recommendation.averageScore! / 10).toStringAsFixed(1),
                                  style: const TextStyle(
                                    color: AppColors.whiteSecondary,
                                    fontSize: 10,
                                  ),
                                ),
                              ),
                            ],
                          ),
                      ],
                    ),
                  ),
                );
              },
            ),
          )
        else if (recommendations?.isEmpty == true)
          const Text(
            'No recommendations available',
            style: TextStyle(color: AppColors.whiteSecondary),
          ),
      ],
    );
  }
}
