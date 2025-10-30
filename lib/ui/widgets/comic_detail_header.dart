import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../../core/constants.dart';
import '../../data/models/nandogami_item.dart';

class ComicDetailHeader extends StatelessWidget {
  final NandogamiItem item;
  final bool isFavorite;
  final VoidCallback onFavoriteToggle;
  final VoidCallback onShare;

  const ComicDetailHeader({
    super.key,
    required this.item,
    required this.isFavorite,
    required this.onFavoriteToggle,
    required this.onShare,
  });

  @override
  Widget build(BuildContext context) {
    final backgroundUrl = (item.bannerImage != null && item.bannerImage!.isNotEmpty) 
        ? item.bannerImage! 
        : item.coverImage ?? item.imageUrl;
    final frameUrl = item.coverImage ?? item.imageUrl;
    
    return Container(
      height: 280, // Reduced height for better proportions
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.3),
            blurRadius: 20,
          ),
        ],
      ),
      child: Stack(
        fit: StackFit.expand,
        children: [
          // Background Image with Blur (using bannerImage)
          Positioned.fill(
            child: ClipRRect(
              borderRadius: BorderRadius.circular(24),
              child: CachedNetworkImage(
                imageUrl: (item.bannerImage != null && item.bannerImage!.isNotEmpty) 
                    ? item.bannerImage! 
                    : item.coverImage ?? item.imageUrl,
                fit: BoxFit.cover,
                alignment: (item.bannerImage != null && item.bannerImage!.isNotEmpty) 
                    ? Alignment.topCenter 
                    : Alignment.center,
                placeholder: (context, url) => Container(
                  color: AppColors.grayDark,
                  child: const Center(
                    child: CircularProgressIndicator(),
                  ),
                ),
                errorWidget: (context, url, error) => Container(
                  color: AppColors.grayDark,
                  child: const Center(
                    child: Icon(
                      Icons.broken_image,
                      color: AppColors.whiteSecondary,
                      size: 48,
                    ),
                  ),
                ),
              ),
            ),
          ),
          
          // Blurred Background with stronger overlay
          Positioned.fill(
            child: Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    Colors.black.withValues(alpha: 0.4),
                    Colors.black.withValues(alpha: 0.6),
                    Colors.black.withValues(alpha: 0.8),
                    Colors.black.withValues(alpha: 0.95),
                  ],
                  stops: const [0.0, 0.3, 0.7, 1.0],
                ),
              ),
            ),
          ),

          // Comic Cover with Frame
          Positioned(
            left: 20,
            bottom: 20,
            child: Container(
              width: 120,
              height: 180,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(12),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.5),
                    blurRadius: 15,
                  ),
                ],
                border: Border.all(
                  color: Theme.of(context).colorScheme.primary,
                  width: 3,
                ),
              ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(9),
                  child: CachedNetworkImage(
                    imageUrl: item.coverImage ?? item.imageUrl,
                    fit: BoxFit.cover,
                    placeholder: (context, url) => Container(
                      color: AppColors.grayDark,
                      child: const Center(
                        child: CircularProgressIndicator(),
                      ),
                    ),
                    errorWidget: (context, url, error) => Container(
                      color: AppColors.grayDark,
                      child: const Icon(
                        Icons.broken_image,
                        color: AppColors.whiteSecondary,
                      ),
                    ),
                  ),
                ),
            ),
          ),

          // Comic Info
          Positioned(
            left: 160,
            right: 20,
            bottom: 20,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                Text(
                  item.title,
                  style: const TextStyle(
                    color: AppColors.white,
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    shadows: [
                      Shadow(
                        blurRadius: 4,
                        color: Colors.black54,
                      ),
                    ],
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 8),
                
                if (item.description != null && item.description!.isNotEmpty)
                  Text(
                    item.description!,
                    style: TextStyle(
                      color: AppColors.whiteSecondary,
                      fontSize: 14,
                      shadows: const [
                        Shadow(
                          blurRadius: 2,
                          color: Colors.black54,
                        ),
                      ],
                    ),
                    maxLines: 3,
                    overflow: TextOverflow.ellipsis,
                  ),
                
                const SizedBox(height: 12),
                
                // Rating and Info Row
                Wrap(
                  spacing: 8,
                  runSpacing: 4,
                  children: [
                    if (item.rating != null && item.rating! > 0) ...[
                      Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(
                            Icons.star,
                            color: AppColors.orange,
                            size: 16,
                          ),
                          const SizedBox(width: 4),
                          Text(
                            item.rating!.toStringAsFixed(1),
                            style: const TextStyle(
                              color: AppColors.white,
                              fontSize: 14,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                    ],
                    
                    if (item.format != null) ...[
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 6,
                          vertical: 3,
                        ),
                        decoration: BoxDecoration(
                          color: AppColors.purpleAccent.withValues(alpha: 0.2),
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(
                            color: AppColors.purpleAccent.withValues(alpha: 0.5),
                            width: 1,
                          ),
                        ),
                        child: Text(
                          item.format!,
                          style: const TextStyle(
                            color: AppColors.purpleAccent,
                            fontSize: 11,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ),
                    ],
                    
                    if (item.chapters != null) ...[
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 6,
                          vertical: 3,
                        ),
                        decoration: BoxDecoration(
                          color: AppColors.blueAccent.withValues(alpha: 0.2),
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(
                            color: AppColors.blueAccent.withValues(alpha: 0.5),
                            width: 1,
                          ),
                        ),
                        child: Text(
                          '${item.chapters} Ch.',
                          style: const TextStyle(
                            color: AppColors.blueAccent,
                            fontSize: 11,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
              ],
            ),
          ),

          // Action Buttons
          Positioned(
            top: 50,
            right: 20,
            child: Column(
              children: [
                
                // Favorite Button
                Container(
                  decoration: BoxDecoration(
                    color: Colors.black.withValues(alpha: 0.6),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: AppColors.grayDark.withValues(alpha: 0.3),
                      width: 1,
                    ),
                  ),
                  child: IconButton(
                    icon: Icon(
                      isFavorite ? Icons.favorite : Icons.favorite_border,
                      color: isFavorite ? AppColors.red : Colors.white,
                    ),
                    onPressed: onFavoriteToggle,
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
