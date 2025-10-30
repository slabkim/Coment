import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../../core/constants.dart';
import '../../data/models/manga.dart';

class MangaSection extends StatelessWidget {
  final String title;
  final List<Manga> manga;
  final bool isLoading;
  final String? error;
  final VoidCallback? onRetry;
  final VoidCallback? onViewAll;
  final Function(Manga) onMangaTap;

  const MangaSection({
    super.key,
    required this.title,
    required this.manga,
    this.isLoading = false,
    this.error,
    this.onRetry,
    this.onViewAll,
    required this.onMangaTap,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Flexible(
                child: Text(
                  title,
                  style: TextStyle(
                    color: Theme.of(context).colorScheme.onSurface,
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                  overflow: TextOverflow.ellipsis,
                  maxLines: 2,
                ),
              ),
              if (onViewAll != null)
                TextButton(
                  onPressed: onViewAll,
                  child: Text(
                    'View All',
                    style: TextStyle(color: Theme.of(context).colorScheme.primary),
                  ),
                ),
            ],
          ),
        ),
        const SizedBox(height: 8),
        if (isLoading)
          const Center(
            child: Padding(
              padding: EdgeInsets.all(32),
              child: CircularProgressIndicator(),
            ),
          )
        else if (error != null)
          Center(
            child: Padding(
              padding: const EdgeInsets.all(32),
              child: Column(
                children: [
                  Text(
                    'Failed to load: $error',
                    style: const TextStyle(color: AppColors.red),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 8),
                  if (onRetry != null)
                    ElevatedButton(
                      onPressed: onRetry,
                      child: const Text('Retry'),
                    ),
                ],
              ),
            ),
          )
        else if (manga.isEmpty)
          const Center(
            child: Padding(
              padding: EdgeInsets.all(32),
              child: Text(
                'No manga found',
                style: TextStyle(color: AppColors.whiteSecondary),
              ),
            ),
          )
        else
          SizedBox(
            height: 280,
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 16),
              itemCount: manga.length,
              itemBuilder: (context, index) {
                return _buildMangaCard(context, manga[index]);
              },
            ),
          ),
        const SizedBox(height: 16),
      ],
    );
  }

  Widget _buildMangaCard(BuildContext context, Manga manga) {
    return Container(
      width: 140,
      margin: const EdgeInsets.only(right: 12),
      child: GestureDetector(
        onTap: () => onMangaTap(manga),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Cover Image
            ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: CachedNetworkImage(
                imageUrl: manga.coverImage ?? '',
                height: 200,
                width: 140,
                fit: BoxFit.cover,
                placeholder: (context, url) => Container(
                  height: 200,
                  width: 140,
                  color: AppColors.grayDark,
                  child: const Center(
                    child: CircularProgressIndicator(),
                  ),
                ),
                errorWidget: (context, url, error) => Container(
                  height: 200,
                  width: 140,
                  color: AppColors.grayDark,
                  child: const Icon(
                    Icons.broken_image,
                    color: AppColors.whiteSecondary,
                  ),
                ),
              ),
            ),
            const SizedBox(height: 8),
            
            // Title
            Text(
              manga.bestTitle,
              style: TextStyle(
                color: Theme.of(context).colorScheme.onSurface,
                fontSize: 14,
                fontWeight: FontWeight.w600,
              ),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
            const SizedBox(height: 4),
            
            // Rating
            if (manga.rating > 0)
              Row(
                children: [
                  const Icon(
                    Icons.star,
                    color: AppColors.orange,
                    size: 14,
                  ),
                  const SizedBox(width: 4),
                  Text(
                    manga.rating.toStringAsFixed(1),
                    style: TextStyle(
                      color: Theme.of(context).colorScheme.onSurfaceVariant,
                      fontSize: 12,
                    ),
                  ),
                ],
              ),
          ],
        ),
      ),
    );
  }

}
