import 'package:flutter/material.dart';
import '../../../core/logger.dart';
import '../../../data/models/nandogami_item.dart';
import '../../../data/services/favorite_service.dart';
import '../../../data/services/simple_anilist_service.dart';
import '../../screens/detail_screen.dart';

/// Favorite Manga Showcase
class FavoriteMangaShowcase extends StatefulWidget {
  final String userId;
  
  const FavoriteMangaShowcase({
    super.key,
    required this.userId,
  });

  @override
  State<FavoriteMangaShowcase> createState() => _FavoriteMangaShowcaseState();
}

class _FavoriteMangaShowcaseState extends State<FavoriteMangaShowcase> {
  final _favoriteService = FavoriteService();
  final _mangaService = SimpleAniListService();
  List<NandogamiItem> _favoriteManga = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _loadFavorites();
  }

  Future<void> _loadFavorites() async {
    try {
      // Get favorite IDs
      final favoriteIdsStream = _favoriteService.watchFavorites(widget.userId);
      final favoriteIds = await favoriteIdsStream.first;
      
      // Get manga details (limit to 10 for showcase)
      final showcaseIds = favoriteIds.take(10).toList();
      final manga = <NandogamiItem>[];
      
      for (final id in showcaseIds) {
        try {
          final mangaId = int.tryParse(id);
          if (mangaId == null) continue;
          
          final mangaData = await _mangaService.getMangaById(mangaId);
          if (mangaData != null) {
            // Get author from staff (first author/story role)
            String? authorName;
            if (mangaData.staff != null && mangaData.staff!.isNotEmpty) {
              final author = mangaData.staff!.firstWhere(
                (s) => s.role.toLowerCase().contains('author') || 
                       s.role.toLowerCase().contains('story'),
                orElse: () => mangaData.staff!.first,
              );
              authorName = author.staff.name;
            }
            
            // Get year from seasonYear or startDate
            int? year = mangaData.seasonYear;
            if (year == null && mangaData.startDate != null) {
              try {
                year = int.tryParse(mangaData.startDate!.split('-').first);
              } catch (e) {
                year = null;
              }
            }
            
            // Convert Manga to NandogamiItem
            final item = NandogamiItem(
              id: mangaData.id.toString(),
              title: mangaData.title,
              description: mangaData.description ?? '',
              imageUrl: mangaData.coverImage ?? '',
              coverImage: mangaData.coverImage,
              bannerImage: mangaData.bannerImage,
              rating: mangaData.rating,
              categories: mangaData.genres,
              genres: mangaData.genres,
              chapters: mangaData.chapters,
              volumes: mangaData.volumes,
              author: authorName,
              type: mangaData.format,
              format: mangaData.format,
              status: mangaData.status,
              releaseYear: year,
              seasonYear: mangaData.seasonYear,
              season: mangaData.season,
              startDate: mangaData.startDate,
              endDate: mangaData.endDate,
              averageScore: mangaData.averageScore,
              meanScore: mangaData.meanScore,
              popularity: mangaData.popularity,
              favourites: mangaData.favourites,
              source: mangaData.source,
              englishTitle: mangaData.englishTitle,
              nativeTitle: mangaData.nativeTitle,
              synonyms: mangaData.synonyms,
              tags: mangaData.tags,
              relations: mangaData.relations,
              characters: mangaData.characters,
              staff: mangaData.staff,
              externalLinks: mangaData.externalLinks,
              trailer: mangaData.trailer,
            );
            manga.add(item);
          }
        } catch (e) {
          // Skip if manga not found
        }
      }
      
      if (mounted) {
        setState(() {
          _favoriteManga = manga;
          _loading = false;
        });
      }
    } catch (e, stackTrace) {
      AppLogger.error('Loading favorite manga', e, stackTrace);
      if (mounted) {
        setState(() => _loading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return const Padding(
        padding: EdgeInsets.all(16),
        child: Center(child: CircularProgressIndicator()),
      );
    }

    if (_favoriteManga.isEmpty) {
      return const SizedBox.shrink();
    }

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Favorite Manga',
                style: TextStyle(
                  color: Theme.of(context).colorScheme.onSurface,
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                ),
              ),
              if (_favoriteManga.length >= 10)
                TextButton(
                  onPressed: () {
                    // TODO: Navigate to full favorites page
                  },
                  child: const Text('See All'),
                ),
            ],
          ),
          const SizedBox(height: 12),
          SizedBox(
            height: 160,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              itemCount: _favoriteManga.length,
              separatorBuilder: (_, __) => const SizedBox(width: 12),
              itemBuilder: (context, index) {
                final manga = _favoriteManga[index];
                return GestureDetector(
                  onTap: () {
                    Navigator.of(context).push(
                      MaterialPageRoute(
                        builder: (_) => DetailScreen(item: manga),
                      ),
                    );
                  },
                  child: Container(
                    width: 110,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(12),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.2),
                          blurRadius: 8,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(12),
                      child: Stack(
                        fit: StackFit.expand,
                        children: [
                          Image.network(
                            manga.imageUrl,
                            fit: BoxFit.cover,
                            errorBuilder: (context, error, stackTrace) {
                              return Container(
                                color: Theme.of(context).colorScheme.surfaceContainerHighest,
                                child: Icon(
                                  Icons.broken_image,
                                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                                  size: 32,
                                ),
                              );
                            },
                          ),
                          Positioned(
                            bottom: 0,
                            left: 0,
                            right: 0,
                            child: Container(
                              padding: const EdgeInsets.all(6),
                              decoration: BoxDecoration(
                                gradient: LinearGradient(
                                  begin: Alignment.topCenter,
                                  end: Alignment.bottomCenter,
                                  colors: [
                                    Colors.transparent,
                                    Colors.black.withValues(alpha: 0.8),
                                  ],
                                ),
                              ),
                              child: Text(
                                manga.title,
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 11,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

