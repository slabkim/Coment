import 'package:flutter/material.dart';
import '../../core/logger.dart';
import '../../data/models/nandogami_item.dart';
import '../../data/models/manga.dart';
import '../../data/services/reading_status_service.dart';
import '../../data/services/simple_anilist_service.dart';
import '../screens/detail_screen.dart';
import 'detail/basic_info_section.dart';
import 'detail/statistics_section.dart';
import 'detail/titles_section.dart';
import 'detail/genres_tags_section.dart';
import 'detail/synopsis_section.dart';
import 'detail/trailer_section.dart';
import 'detail/characters_section.dart';
import 'detail/relations_section.dart';
import 'detail/recommendations_section.dart';
import 'detail/reading_status_panel.dart';

/// Tab widget for displaying the "About" section of a manga detail screen.
/// Shows basic information, statistics, titles, genres, synopsis, trailer,
/// characters, relations, recommendations, and reading status.
class AboutTab extends StatefulWidget {
  final NandogamiItem item;
  final String? uid;
  final ReadingStatusService statusService;
  const AboutTab({
    super.key,
    required this.item,
    required this.uid,
    required this.statusService,
  });

  @override
  State<AboutTab> createState() => _AboutTabState();
}

class _AboutTabState extends State<AboutTab> {
  bool _loadingCharacters = false;
  bool _loadingRelations = false;
  bool _loadingRecommendations = false;
  List<MangaCharacter>? _characters;
  List<MangaRelation>? _relations;
  List<Manga>? _recommendations;

  @override
  void initState() {
    super.initState();
    // Load data with delays to avoid rate limiting
    _loadCharacters();
    
    Future.delayed(Duration(milliseconds: 1500), () {
      if (mounted) _loadRelations();
    });
    
    Future.delayed(Duration(milliseconds: 3000), () {
      if (mounted) _loadRecommendations();
    });
  }

  @override
  Widget build(BuildContext context) {
    final item = widget.item;
    final currentUid = widget.uid;

    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Basic Information Section
          BasicInfoSection(item: item),
          const SizedBox(height: 24),
          
          // Statistics Section
          StatisticsSection(item: item),
          const SizedBox(height: 24),
          
          // Titles Section
          TitlesSection(item: item),
          const SizedBox(height: 24),
          
          // Genres & Tags Section
          GenresTagsSection(item: item),
          const SizedBox(height: 24),
          
          // Synopsis Section
          SynopsisSection(item: item),
          const SizedBox(height: 24),
          
          // Trailer Section
          if (item.trailer != null) ...[
            TrailerSection(trailer: item.trailer),
            const SizedBox(height: 24),
          ],
          
          // Characters Section - Lazy Loading
          CharactersSection(
            loading: _loadingCharacters,
            characters: _characters,
          ),
          const SizedBox(height: 24),
          
                 // Relations Section - Lazy Loading
          RelationsSection(
            loading: _loadingRelations,
            relations: _relations,
            onRelationTap: _onRelationTap,
          ),
                 const SizedBox(height: 24),
                 
                 // Recommendations Section - Lazy Loading
          RecommendationsSection(
            loading: _loadingRecommendations,
            recommendations: _recommendations,
            onRecommendationTap: _onRecommendationTap,
          ),
                 const SizedBox(height: 24),
                 
                 // Reading Status Panel
                 if (currentUid != null)
            ReadingStatusPanel(
                     uid: currentUid,
                     titleId: widget.item.id,
                     statusService: widget.statusService,
                   ),
        ],
      ),
    );
  }



  Future<void> _loadCharacters() async {
    if (!mounted) return;
    
    setState(() {
      _loadingCharacters = true;
    });

    try {
      final mangaService = SimpleAniListService();
      final mangaId = int.tryParse(widget.item.id);
      
      if (mangaId != null) {
        final characters = await mangaService.getMangaCharacters(mangaId);
        if (mounted) {
          setState(() {
            _characters = characters;
            _loadingCharacters = false;
          });
        }
      } else {
        if (mounted) {
          setState(() {
            _characters = [];
            _loadingCharacters = false;
          });
        }
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _characters = [];
          _loadingCharacters = false;
        });
      }
    }
  }

  Future<void> _loadRelations() async {
    if (!mounted) return;
    
    setState(() {
      _loadingRelations = true;
    });

    try {
      // Import SimpleAniListService to fetch relations
      final mangaService = SimpleAniListService();
      final mangaId = int.tryParse(widget.item.id);
      
      if (mangaId != null) {
        final relations = await mangaService.getMangaRelations(mangaId);
        if (mounted) {
          setState(() {
            _relations = relations;
            _loadingRelations = false;
          });
        }
      } else {
        if (mounted) {
          setState(() {
            _relations = [];
            _loadingRelations = false;
          });
        }
      }
    } catch (e) {
      AppLogger.apiError('loading relations', e);
      if (mounted) {
        setState(() {
          _relations = [];
          _loadingRelations = false;
        });
      }
    }
  }

  Future<void> _loadRecommendations() async {
    if (!mounted) return;
    
    setState(() {
      _loadingRecommendations = true;
    });

    try {
      final mangaService = SimpleAniListService();
      final mangaId = int.tryParse(widget.item.id);
      
      if (mangaId != null) {
        final recommendations = await mangaService.getMangaRecommendations(mangaId);
        if (mounted) {
          setState(() {
            _recommendations = recommendations;
            _loadingRecommendations = false;
          });
        }
      } else {
        if (mounted) {
          setState(() {
            _recommendations = [];
            _loadingRecommendations = false;
          });
        }
      }
    } catch (e) {
      AppLogger.apiError('loading recommendations', e);
      if (mounted) {
        setState(() {
          _recommendations = [];
          _loadingRecommendations = false;
        });
      }
    }
  }



  void _onRelationTap(MangaRelation relation) {
    // Convert Manga to NandogamiItem for DetailScreen
    final nandogamiItem = NandogamiItem(
      id: relation.manga.id.toString(),
      title: relation.manga.bestTitle,
      description: relation.manga.description ?? '',
      imageUrl: relation.manga.coverImage ?? '',
      coverImage: relation.manga.coverImage,
      bannerImage: relation.manga.bannerImage,
      categories: relation.manga.genres,
      chapters: relation.manga.chapters,
      format: relation.manga.format,
      rating: relation.manga.rating,
      ratingCount: relation.manga.ratingCount,
      releaseYear: relation.manga.seasonYear,
      synopsis: relation.manga.description,
      type: 'Manga',
      isFeatured: false,
      isNewRelease: false,
      isPopular: false,
      // AniList specific fields
      englishTitle: relation.manga.englishTitle,
      nativeTitle: relation.manga.nativeTitle,
      genres: relation.manga.genres,
      tags: relation.manga.tags,
      status: relation.manga.status,
      volumes: relation.manga.volumes,
      source: relation.manga.source,
      seasonYear: relation.manga.seasonYear,
      season: relation.manga.season,
      averageScore: relation.manga.averageScore,
      meanScore: relation.manga.meanScore,
      popularity: relation.manga.popularity,
      favourites: relation.manga.favourites,
      startDate: relation.manga.startDate,
      endDate: relation.manga.endDate,
      synonyms: relation.manga.synonyms,
      relations: relation.manga.relations,
      characters: relation.manga.characters,
      staff: relation.manga.staff,
      trailer: relation.manga.trailer, // Include trailer data
    );

    // Navigate to DetailScreen
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => DetailScreen(item: nandogamiItem),
      ),
    );
  }

  void _onRecommendationTap(Manga recommendation) {
    // Convert Manga to NandogamiItem for DetailScreen
    final nandogamiItem = NandogamiItem(
      id: recommendation.id.toString(),
      title: recommendation.bestTitle,
      description: recommendation.description ?? '',
      imageUrl: recommendation.coverImage ?? '',
      coverImage: recommendation.coverImage,
      bannerImage: recommendation.bannerImage,
      categories: recommendation.genres,
      chapters: recommendation.chapters,
      format: recommendation.format,
      rating: recommendation.rating,
      ratingCount: recommendation.ratingCount,
      releaseYear: recommendation.seasonYear,
      synopsis: recommendation.description,
      type: 'Manga',
      isFeatured: false,
      isNewRelease: false,
      isPopular: false,
      // AniList specific fields
      englishTitle: recommendation.englishTitle,
      nativeTitle: recommendation.nativeTitle,
      genres: recommendation.genres,
      tags: recommendation.tags,
      status: recommendation.status,
      volumes: recommendation.volumes,
      source: recommendation.source,
      seasonYear: recommendation.seasonYear,
      season: recommendation.season,
      averageScore: recommendation.averageScore,
      meanScore: recommendation.meanScore,
      popularity: recommendation.popularity,
      favourites: recommendation.favourites,
      startDate: recommendation.startDate,
      endDate: recommendation.endDate,
      synonyms: recommendation.synonyms,
      relations: recommendation.relations,
      characters: recommendation.characters,
      staff: recommendation.staff,
    );

    // Navigate to DetailScreen
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => DetailScreen(item: nandogamiItem),
      ),
    );
  }

}

