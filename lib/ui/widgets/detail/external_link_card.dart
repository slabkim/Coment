import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../../data/models/external_link.dart';

/// Widget for displaying an external link card with icon and information.
class ExternalLinkCard extends StatelessWidget {
  final ExternalLink link;
  
  const ExternalLinkCard({super.key, required this.link});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(12),
        color: Theme.of(context).colorScheme.surfaceContainerHighest,
        border: Border.all(
          color: Theme.of(context).colorScheme.outline,
          width: 1,
        ),
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () => _openLink(context, link.url),
          borderRadius: BorderRadius.circular(12),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                // Icon (no wrapper, icon handles its own background)
                _buildIcon(),
                
                const SizedBox(width: 16),
                
                // Content
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        link.displayName,
                        style: TextStyle(
                          color: Theme.of(context).colorScheme.onSurface,
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        _getSubtitle(),
                        style: TextStyle(
                          color: Theme.of(context).colorScheme.onSurfaceVariant,
                          fontSize: 14,
                        ),
                      ),
                    ],
                  ),
                ),
                
                // Arrow icon
                Icon(
                  Icons.arrow_forward_ios,
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                  size: 16,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildIcon() {
    // Try to get colored logo URL first
    final coloredLogoUrl = _getColoredLogoUrl();
    
    if (coloredLogoUrl != null) {
      return ClipRRect(
        borderRadius: BorderRadius.circular(8),
        child: CachedNetworkImage(
          imageUrl: coloredLogoUrl,
          width: 48,
          height: 48,
          fit: BoxFit.contain,
          // Optimize memory usage
          memCacheWidth: 96, // 2x for retina displays
          memCacheHeight: 96,
          // Faster fade-in animation
          fadeInDuration: const Duration(milliseconds: 200),
          fadeOutDuration: const Duration(milliseconds: 100),
          // Longer cache duration for logos (7 days)
          maxHeightDiskCache: 96,
          maxWidthDiskCache: 96,
          placeholder: (context, url) => Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(8),
              color: _getIconBackgroundColor(),
            ),
            child: Icon(
              _getIconData(),
              color: Colors.white,
              size: 24,
            ),
          ),
          errorWidget: (context, url, error) => _buildColoredIcon(),
        ),
      );
    }
    
    // Fallback to AniList icon if available
    if (link.icon != null && link.icon!.isNotEmpty) {
      return ClipRRect(
        borderRadius: BorderRadius.circular(8),
        child: CachedNetworkImage(
          imageUrl: link.icon!,
          width: 48,
          height: 48,
          fit: BoxFit.contain,
          // Optimize memory usage
          memCacheWidth: 96,
          memCacheHeight: 96,
          fadeInDuration: const Duration(milliseconds: 200),
          fadeOutDuration: const Duration(milliseconds: 100),
          maxHeightDiskCache: 96,
          maxWidthDiskCache: 96,
          placeholder: (context, url) => Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(8),
              color: _getIconBackgroundColor(),
            ),
            child: Icon(
              _getIconData(),
              color: Colors.white,
              size: 24,
            ),
          ),
          errorWidget: (context, url, error) => _buildColoredIcon(),
        ),
      );
    }
    
    // Fallback to colored Material icon
    return _buildColoredIcon();
  }

  String? _getColoredLogoUrl() {
    final site = link.site.toLowerCase().trim();
    
    // Use logo.clearbit.com for official colored logos
    if (site.contains('crunchyroll')) {
      return 'https://logo.clearbit.com/crunchyroll.com';
    }
    if (site.contains('netflix')) {
      return 'https://logo.clearbit.com/netflix.com';
    }
    if (site.contains('hulu')) {
      return 'https://logo.clearbit.com/hulu.com';
    }
    if (site.contains('amazon')) {
      return 'https://logo.clearbit.com/amazon.com';
    }
    if (site.contains('disney')) {
      return 'https://logo.clearbit.com/disneyplus.com';
    }
    if (site.contains('hbo')) {
      return 'https://logo.clearbit.com/hbomax.com';
    }
    if (site.contains('funimation')) {
      return 'https://logo.clearbit.com/funimation.com';
    }
    if (site.contains('hidive')) {
      return 'https://logo.clearbit.com/hidive.com';
    }
    if (site.contains('vrv')) {
      return 'https://logo.clearbit.com/vrv.co';
    }
    if (site.contains('webtoon')) {
      return 'https://logo.clearbit.com/webtoons.com';
    }
    if (site.contains('tapas')) {
      return 'https://logo.clearbit.com/tapas.io';
    }
    if (site.contains('viz')) {
      return 'https://logo.clearbit.com/viz.com';
    }
    if (site.contains('manga plus') || site.contains('mangaplus')) {
      return 'https://logo.clearbit.com/mangaplus.shueisha.co.jp';
    }
    
    // Try to extract domain from URL for generic sites
    try {
      final uri = Uri.parse(link.url);
      if (uri.host.isNotEmpty) {
        return 'https://logo.clearbit.com/${uri.host}';
      }
    } catch (e) {
      // Invalid URL, return null
    }
    
    return null;
  }

  Widget _buildColoredIcon() {
    return Container(
      width: 48,
      height: 48,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(8),
        color: _getIconBackgroundColor(),
      ),
      child: Icon(
        _getIconData(),
        color: Colors.white,
        size: 24,
      ),
    );
  }

  void _openLink(BuildContext context, String url) async {
    try {
      final uri = Uri.parse(url);
      if (await canLaunchUrl(uri)) {
        await launchUrl(uri, mode: LaunchMode.externalApplication);
      } else {
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Could not open $url'),
              backgroundColor: Theme.of(context).colorScheme.primary,
            ),
          );
        }
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error opening link: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  IconData _getIconData() {
    final site = link.site.toLowerCase().trim();
    
    // Reading platforms
    if (site.contains('webtoon')) return Icons.auto_stories;
    if (site.contains('tapas')) return Icons.menu_book;
    if (site.contains('kakaopage')) return Icons.library_books;
    if (site.contains('naver')) return Icons.web;
    if (site.contains('manga plus')) return Icons.auto_stories;
    if (site.contains('viz')) return Icons.library_books;
    if (site.contains('manga')) return Icons.book;
    if (site.contains('novel')) return Icons.book;
    if (site.contains('book')) return Icons.book;
    
    // Streaming platforms
    if (site.contains('crunchyroll')) return Icons.play_circle_filled;
    if (site.contains('netflix')) return Icons.play_circle_filled;
    if (site.contains('hulu')) return Icons.play_circle_filled;
    if (site.contains('amazon')) return Icons.shopping_cart;
    if (site.contains('disney')) return Icons.play_circle_filled;
    if (site.contains('hbo')) return Icons.play_circle_filled;
    if (site.contains('vrv')) return Icons.play_circle_filled;
    if (site.contains('hidive')) return Icons.play_circle_filled;
    if (site.contains('retrocrush')) return Icons.play_circle_filled;
    if (site.contains('tubi')) return Icons.play_circle_filled;
    if (site.contains('funimation')) return Icons.play_circle_filled;
    if (site.contains('anime')) return Icons.play_circle_filled;
    
    // Merchandise
    if (site.contains('dvd')) return Icons.movie;
    if (site.contains('blu-ray')) return Icons.movie;
    if (site.contains('cd')) return Icons.album;
    if (site.contains('vinyl')) return Icons.album;
    if (site.contains('cassette')) return Icons.album;
    if (site.contains('music')) return Icons.music_note;
    if (site.contains('game')) return Icons.sports_esports;
    
    // Default fallback
    return Icons.link;
  }

  Color _getIconBackgroundColor() {
    final site = link.site.toLowerCase().trim();
    
    // Reading platforms
    if (site.contains('webtoon')) return const Color(0xFF00D4AA); // Webtoon green
    if (site.contains('tapas')) return const Color(0xFFFF6B6B); // Tapas red
    if (site.contains('kakaopage')) return const Color(0xFFFFC107); // KakaoPage yellow
    if (site.contains('naver')) return const Color(0xFF03C75A); // Naver green
    if (site.contains('manga plus')) return const Color(0xFF2196F3); // Manga Plus blue
    if (site.contains('viz')) return const Color(0xFF4CAF50); // VIZ green
    if (site.contains('manga')) return const Color(0xFF9C27B0); // Manga purple
    if (site.contains('novel')) return const Color(0xFF795548); // Novel brown
    if (site.contains('book')) return const Color(0xFF795548); // Book brown
    
    // Streaming platforms
    if (site.contains('crunchyroll')) return const Color(0xFFF78C25); // Crunchyroll orange
    if (site.contains('netflix')) return const Color(0xFFE50914); // Netflix red
    if (site.contains('hulu')) return const Color(0xFF1CE783); // Hulu green
    if (site.contains('amazon')) return const Color(0xFFFF9900); // Amazon orange
    if (site.contains('disney')) return const Color(0xFF113CCF); // Disney blue
    if (site.contains('hbo')) return const Color(0xFF8B5CF6); // HBO purple
    if (site.contains('vrv')) return const Color(0xFF00D4AA); // VRV green
    if (site.contains('hidive')) return const Color(0xFF00D4AA); // HIDIVE green
    if (site.contains('retrocrush')) return const Color(0xFFFF6B6B); // RetroCrush red
    if (site.contains('tubi')) return const Color(0xFF00D4AA); // Tubi green
    if (site.contains('funimation')) return const Color(0xFF00D4AA); // Funimation green
    if (site.contains('anime')) return const Color(0xFF2196F3); // Anime blue
    
    // Merchandise
    if (site.contains('dvd')) return const Color(0xFF607D8B); // DVD grey
    if (site.contains('blu-ray')) return const Color(0xFF2196F3); // Blu-ray blue
    if (site.contains('cd')) return const Color(0xFF9C27B0); // CD purple
    if (site.contains('vinyl')) return const Color(0xFF795548); // Vinyl brown
    if (site.contains('cassette')) return const Color(0xFFFF9800); // Cassette orange
    if (site.contains('music')) return const Color(0xFF9C27B0); // Music purple
    if (site.contains('game')) return const Color(0xFF4CAF50); // Game green
    
    // Default fallback
    return const Color(0xFF6C757D); // Default grey
  }

  String _getSubtitle() {
    if (link.isStreaming) {
      return 'Stream this series';
    } else if (link.isReading) {
      return 'Read this series';
    } else if (link.isMerchandise) {
      return 'Buy merchandise';
    } else {
      return 'Visit official page';
    }
  }
}

