import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import '../../core/constants.dart';
import '../../data/models/nandogami_item.dart';
import '../../data/models/manga.dart';
import '../../data/models/external_link.dart';
import '../../data/services/reading_status_service.dart';
import '../../data/services/simple_anilist_service.dart';
import '../screens/detail_screen.dart';

class AboutTabNew extends StatefulWidget {
  final NandogamiItem item;
  final String? uid;
  final ReadingStatusService statusService;
  const AboutTabNew({
    super.key,
    required this.item,
    required this.uid,
    required this.statusService,
  });

  @override
  State<AboutTabNew> createState() => _AboutTabNewState();
}

class _AboutTabNewState extends State<AboutTabNew> {
  bool _loadingCharacters = false;
  bool _loadingRelations = false;
  bool _loadingRecommendations = false;
  bool _loadingExternalLinks = false;
  List<MangaCharacter>? _characters;
  List<MangaRelation>? _relations;
  List<Manga>? _recommendations;
  List<ExternalLink>? _externalLinks;

  @override
  void initState() {
    super.initState();
    // Load characters, relations, recommendations, and external links automatically
    _loadCharacters();
    _loadRelations();
    _loadRecommendations();
    _loadExternalLinks();
  }

  @override
  Widget build(BuildContext context) {
    final item = widget.item;
    final theme = Theme.of(context).textTheme;
    final currentUid = widget.uid;

    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Basic Information Section
          _buildBasicInfoSection(theme),
          const SizedBox(height: 24),
          
          // Statistics Section
          _buildStatisticsSection(theme),
          const SizedBox(height: 24),
          
          // Titles Section
          _buildTitlesSection(theme),
          const SizedBox(height: 24),
          
          // Genres & Tags Section
          _buildGenresTagsSection(theme),
          const SizedBox(height: 24),
          
          // Synopsis Section
          _buildSynopsisSection(theme),
          const SizedBox(height: 24),
          
          // Characters Section - Lazy Loading
          _buildCharactersSectionLazy(theme),
          const SizedBox(height: 24),
          
                 // Relations Section - Lazy Loading
                 _buildRelationsSectionLazy(theme),
                 const SizedBox(height: 24),
                 
                 // Recommendations Section - Lazy Loading
                 _buildRecommendationsSectionLazy(theme),
                 const SizedBox(height: 24),
                 
                 // Reading Status Panel
                 if (currentUid != null)
                   _ReadingStatusPanel(
                     uid: currentUid,
                     titleId: widget.item.id,
                     statusService: widget.statusService,
                   ),
        ],
      ),
    );
  }

  Widget _buildBasicInfoSection(TextTheme theme) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Title
        Text(
          widget.item.title,
          style: theme.titleLarge?.copyWith(
            color: Theme.of(context).colorScheme.onSurface,
            fontWeight: FontWeight.w700,
          ),
        ),
        const SizedBox(height: 8),
        
        // Format & Status
        Row(
          children: [
            if (widget.item.format != null) ...[
              _buildInfoChip('Format', _formatFormat(widget.item.format!)),
              const SizedBox(width: 8),
            ],
            if (widget.item.status != null) ...[
              _buildInfoChip('Status', _formatStatus(widget.item.status!)),
              const SizedBox(width: 8),
            ],
          ],
        ),
        const SizedBox(height: 8),
        
        // Start Date
        if (widget.item.startDate != null) ...[
          _buildInfoRow('Start Date', _formatDate(widget.item.startDate!)),
          const SizedBox(height: 4),
        ],
        
        // End Date
        if (widget.item.endDate != null) ...[
          _buildInfoRow('End Date', _formatDate(widget.item.endDate!)),
          const SizedBox(height: 4),
        ],
        
        // Source
        if (widget.item.source != null) ...[
          _buildInfoRow('Source', _formatSource(widget.item.source!)),
          const SizedBox(height: 4),
        ],
        
        // Chapters & Volumes
        if (widget.item.chapters != null || widget.item.volumes != null) ...[
          Wrap(
            children: [
              if (widget.item.chapters != null && widget.item.chapters! > 0) ...[
                _buildInfoRow('Chapters', widget.item.chapters.toString()),
                const SizedBox(width: 16),
              ],
              if (widget.item.volumes != null && widget.item.volumes! > 0) ...[
                _buildInfoRow('Volumes', widget.item.volumes.toString()),
              ],
            ],
          ),
        ],
      ],
    );
  }

  Widget _buildStatisticsSection(TextTheme theme) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Statistics',
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
            children: [
              if (widget.item.averageScore != null) ...[
                _buildStatRow('Average Score', '${widget.item.averageScore!.toStringAsFixed(1)}/100'),
                const SizedBox(height: 8),
              ],
              if (widget.item.meanScore != null) ...[
                _buildStatRow('Mean Score', '${widget.item.meanScore}/100'),
                const SizedBox(height: 8),
              ],
              if (widget.item.popularity != null) ...[
                _buildStatRow('Popularity', widget.item.popularity.toString()),
                const SizedBox(height: 8),
              ],
              if (widget.item.favourites != null) ...[
                _buildStatRow('Favorites', widget.item.favourites.toString()),
              ],
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildTitlesSection(TextTheme theme) {
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
              if (widget.item.englishTitle != null) ...[
                _buildTitleRow('English', widget.item.englishTitle!),
                const SizedBox(height: 8),
              ],
              if (widget.item.nativeTitle != null) ...[
                _buildTitleRow('Native', widget.item.nativeTitle!),
                const SizedBox(height: 8),
              ],
              if (widget.item.synonyms?.isNotEmpty == true) ...[
                _buildTitleRow('Synonyms', widget.item.synonyms!.join(', ')),
              ],
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildGenresTagsSection(TextTheme theme) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (widget.item.genres?.isNotEmpty == true) ...[
          Text(
            'Genres',
            style: theme.titleMedium?.copyWith(color: Theme.of(context).colorScheme.onSurface),
          ),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: widget.item.genres!
                .map((genre) => Chip(
                      label: Text(genre),
                      backgroundColor: Theme.of(context).colorScheme.surfaceContainerHighest,
                      labelStyle: TextStyle(color: Theme.of(context).colorScheme.onSurface),
                    ))
                .toList(),
          ),
          const SizedBox(height: 16),
        ],
        if (widget.item.tags?.isNotEmpty == true) ...[
          Text(
            'Tags',
            style: theme.titleMedium?.copyWith(color: AppColors.white),
          ),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: widget.item.tags!
                .take(10) // Limit to first 10 tags
                .map((tag) => Chip(
                      label: Text(tag),
                      backgroundColor: AppColors.grayDark.withValues(alpha: 0.5),
                      labelStyle: const TextStyle(color: AppColors.whiteSecondary),
                    ))
                .toList(),
          ),
        ],
      ],
    );
  }

  Widget _buildSynopsisSection(TextTheme theme) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Synopsis',
          style: theme.titleMedium?.copyWith(color: Theme.of(context).colorScheme.onSurface),
        ),
        const SizedBox(height: 8),
        Text(
          _resolveSynopsis(widget.item),
          style: TextStyle(
            color: Theme.of(context).colorScheme.onSurface,
            height: 1.5,
          ),
        ),
      ],
    );
  }

  Widget _buildCharactersSectionLazy(TextTheme theme) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Characters',
          style: theme.titleMedium?.copyWith(color: Theme.of(context).colorScheme.onSurface),
        ),
        const SizedBox(height: 12),
        if (_loadingCharacters)
          const Center(
            child: CircularProgressIndicator(color: AppColors.purpleAccent),
          )
        else if (_characters?.isNotEmpty == true)
          SizedBox(
            height: 120,
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              itemCount: _characters!.length,
              itemBuilder: (context, index) {
                final character = _characters![index];
                return Container(
                  width: 80,
                  margin: const EdgeInsets.only(right: 12),
                  child: Column(
                    children: [
                      ClipRRect(
                        borderRadius: BorderRadius.circular(8),
                        child: CachedNetworkImage(
                          imageUrl: character.character.image ?? '',
                          width: 60,
                          height: 60,
                          fit: BoxFit.cover,
                          placeholder: (context, url) => Container(
                            width: 60,
                            height: 60,
                            color: AppColors.grayDark,
                            child: const Icon(Icons.person, color: AppColors.whiteSecondary),
                          ),
                          errorWidget: (context, url, error) => Container(
                            width: 60,
                            height: 60,
                            color: AppColors.grayDark,
                            child: const Icon(Icons.person, color: AppColors.whiteSecondary),
                          ),
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        character.character.name,
                        style: TextStyle(
                          color: Theme.of(context).colorScheme.onSurface,
                          fontSize: 10,
                        ),
                        textAlign: TextAlign.center,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                      Text(
                        character.role,
                        style: TextStyle(
                          color: Theme.of(context).colorScheme.onSurfaceVariant,
                          fontSize: 8,
                        ),
                        textAlign: TextAlign.center,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                );
              },
            ),
          )
        else if (_characters?.isEmpty == true)
          const Text(
            'No characters available',
            style: TextStyle(color: AppColors.whiteSecondary),
          ),
      ],
    );
  }

  Widget _buildCharactersSection(TextTheme theme) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Characters',
          style: theme.titleMedium?.copyWith(color: AppColors.white),
        ),
        const SizedBox(height: 12),
        SizedBox(
          height: 120,
          child: ListView.builder(
            scrollDirection: Axis.horizontal,
            itemCount: widget.item.characters!.length,
            itemBuilder: (context, index) {
              final character = widget.item.characters![index];
              return Container(
                width: 80,
                margin: const EdgeInsets.only(right: 12),
                child: Column(
                  children: [
                    ClipRRect(
                      borderRadius: BorderRadius.circular(8),
                      child: CachedNetworkImage(
                        imageUrl: character.character.image ?? '',
                        width: 60,
                        height: 60,
                        fit: BoxFit.cover,
                        placeholder: (context, url) => Container(
                          width: 60,
                          height: 60,
                          color: AppColors.grayDark,
                          child: const Icon(Icons.person, color: AppColors.whiteSecondary),
                        ),
                        errorWidget: (context, url, error) => Container(
                          width: 60,
                          height: 60,
                          color: AppColors.grayDark,
                          child: const Icon(Icons.person, color: AppColors.whiteSecondary),
                        ),
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      character.character.name,
                      style: const TextStyle(
                        color: AppColors.white,
                        fontSize: 10,
                      ),
                      textAlign: TextAlign.center,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    Text(
                      character.role,
                      style: const TextStyle(
                        color: AppColors.whiteSecondary,
                        fontSize: 8,
                      ),
                      textAlign: TextAlign.center,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              );
            },
          ),
        ),
      ],
    );
  }

  Widget _buildRelationsSectionLazy(TextTheme theme) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Relations',
          style: theme.titleMedium?.copyWith(color: Theme.of(context).colorScheme.onSurface),
        ),
        const SizedBox(height: 12),
        if (_loadingRelations)
          const Center(
            child: CircularProgressIndicator(color: AppColors.purpleAccent),
          )
        else if (_relations?.isNotEmpty == true)
          ..._relations!.take(5).map((relation) => GestureDetector(
            onTap: () => _onRelationTap(relation),
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
                    offset: const Offset(0, 2),
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
                            offset: const Offset(0, 2),
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
                                color: AppColors.purpleAccent,
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
                            color: _getRelationTypeColor(relation.relationType).withValues(alpha: 0.2),
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(
                              color: _getRelationTypeColor(relation.relationType).withValues(alpha: 0.5),
                              width: 1,
                            ),
                          ),
                          child: Text(
                            _formatRelationType(relation.relationType),
                            style: TextStyle(
                              color: _getRelationTypeColor(relation.relationType),
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
               else if (_relations?.isEmpty == true)
                 const Text(
                   'No relations available',
                   style: TextStyle(color: AppColors.whiteSecondary),
                 ),
      ],
    );
  }

  Widget _buildRelationsSection(TextTheme theme) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Relations',
          style: theme.titleMedium?.copyWith(color: AppColors.white),
        ),
        const SizedBox(height: 12),
        ...widget.item.relations!.take(5).map((relation) => Container(
          margin: const EdgeInsets.only(bottom: 8),
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: AppColors.grayDark.withValues(alpha: 0.3),
            borderRadius: BorderRadius.circular(8),
            border: Border.all(
              color: AppColors.grayDark.withValues(alpha: 0.5),
              width: 1,
            ),
          ),
          child: Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      relation.manga.title,
                      style: const TextStyle(
                        color: AppColors.white,
                        fontWeight: FontWeight.w500,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 2),
                    Text(
                      _formatRelationType(relation.relationType),
                      style: const TextStyle(
                        color: AppColors.whiteSecondary,
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              ),
              if (relation.manga.coverImage != null)
                ClipRRect(
                  borderRadius: BorderRadius.circular(4),
                  child: CachedNetworkImage(
                    imageUrl: relation.manga.coverImage!,
                    width: 40,
                    height: 56,
                    fit: BoxFit.cover,
                    placeholder: (context, url) => Container(
                      width: 40,
                      height: 56,
                      color: AppColors.grayDark,
                    ),
                    errorWidget: (context, url, error) => Container(
                      width: 40,
                      height: 56,
                      color: AppColors.grayDark,
                    ),
                  ),
                ),
            ],
          ),
        )),
      ],
    );
  }

  Widget _buildRecommendationsSectionLazy(TextTheme theme) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Recommendations',
          style: theme.titleMedium?.copyWith(color: Theme.of(context).colorScheme.onSurface),
        ),
        const SizedBox(height: 12),
        if (_loadingRecommendations)
          const Center(
            child: CircularProgressIndicator(color: AppColors.purpleAccent),
          )
        else if (_recommendations?.isNotEmpty == true)
          SizedBox(
            height: 200,
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              itemCount: _recommendations!.length,
              itemBuilder: (context, index) {
                final recommendation = _recommendations![index];
                return GestureDetector(
                  onTap: () => _onRecommendationTap(recommendation),
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
                                  color: AppColors.purpleAccent,
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
        else if (_recommendations?.isEmpty == true)
          const Text(
            'No recommendations available',
            style: TextStyle(color: AppColors.whiteSecondary),
          ),
      ],
    );
  }

  Future<void> _loadCharacters() async {
    setState(() {
      _loadingCharacters = true;
    });

    try {
      // Import SimpleAniListService to fetch characters
      final mangaService = SimpleAniListService();
      final mangaId = int.tryParse(widget.item.id);
      
      if (mangaId != null) {
        // Fetch characters using a separate query
        final characters = await mangaService.getMangaCharacters(mangaId);
        setState(() {
          _characters = characters;
          _loadingCharacters = false;
        });
      } else {
        setState(() {
          _characters = [];
          _loadingCharacters = false;
        });
      }
    } catch (e) {
      debugPrint('Error loading characters: $e');
      setState(() {
        _characters = [];
        _loadingCharacters = false;
      });
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
        // Fetch relations using a separate query
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
      debugPrint('Error loading relations: $e');
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
      // Import SimpleAniListService to fetch recommendations
      final mangaService = SimpleAniListService();
      final mangaId = int.tryParse(widget.item.id);
      
      if (mangaId != null) {
        // Fetch recommendations using a separate query
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
      debugPrint('Error loading recommendations: $e');
      if (mounted) {
        setState(() {
          _recommendations = [];
          _loadingRecommendations = false;
        });
      }
    }
  }

  Future<void> _loadExternalLinks() async {
    if (!mounted) return;
    
    setState(() {
      _loadingExternalLinks = true;
    });

    try {
      final mangaService = SimpleAniListService();
      final mangaId = int.tryParse(widget.item.id);
      
      if (mangaId != null) {
        final externalLinks = await mangaService.getMangaExternalLinks(mangaId);
        if (!mounted) return;
        setState(() {
          _externalLinks = externalLinks;
          _loadingExternalLinks = false;
        });
      } else {
        if (!mounted) return;
        setState(() {
          _externalLinks = [];
          _loadingExternalLinks = false;
        });
      }
    } catch (e) {
      debugPrint('Error loading external links: $e');
      if (!mounted) return;
      setState(() {
        _externalLinks = [];
        _loadingExternalLinks = false;
      });
    }
  }

  Widget _buildInfoChip(String label, String value) {
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

  Widget _buildInfoRow(String label, String value) {
    return Container(
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

  Widget _buildStatRow(String label, String value) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: TextStyle(
            color: Theme.of(context).colorScheme.onSurfaceVariant,
            fontSize: 14,
          ),
        ),
        Text(
          value,
          style: TextStyle(
            color: Theme.of(context).colorScheme.onSurface,
            fontSize: 14,
            fontWeight: FontWeight.w500,
          ),
        ),
      ],
    );
  }

  Widget _buildTitleRow(String label, String value) {
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

  String _formatStatus(String status) {
    switch (status) {
      case 'FINISHED': return 'Finished';
      case 'RELEASING': return 'Releasing';
      case 'NOT_YET_RELEASED': return 'Not Yet Released';
      case 'CANCELLED': return 'Cancelled';
      case 'HIATUS': return 'Hiatus';
      default: return status;
    }
  }

  String _formatDate(dynamic date) {
    if (date == null) return 'Unknown';
    
    if (date is String) {
      try {
        final parts = date.split('-');
        if (parts.length == 3) {
          return '${parts[2]}/${parts[1]}/${parts[0]}';
        }
        return date;
      } catch (e) {
        return date;
      }
    } else if (date is Map<String, dynamic>) {
      final year = date['year'];
      final month = date['month'];
      final day = date['day'];
      
      if (year != null && month != null && day != null) {
        return '${day.toString().padLeft(2, '0')}/${month.toString().padLeft(2, '0')}/$year';
      } else if (year != null && month != null) {
        return '${month.toString().padLeft(2, '0')}/$year';
      } else if (year != null) {
        return year.toString();
      }
    }
    
    return 'Unknown';
  }

  String _formatFormat(String format) {
    switch (format.toUpperCase()) {
      case 'MANGA':
      case 'MANHWA':
      case 'MANHUA':
        return 'Manga';
      case 'NOVEL':
      case 'LIGHT_NOVEL':
      case 'WEB_NOVEL':
        return 'Novel';
      case 'ONE_SHOT':
        return 'One Shot';
      case 'DOUJINSHI':
        return 'Doujinshi';
      case 'OEL':
        return 'OEL';
      case 'VISUAL_NOVEL':
        return 'Visual Novel';
      case 'GAME':
        return 'Game';
      case 'COMIC':
        return 'Comic';
      case 'PICTURE_BOOK':
        return 'Picture Book';
      default:
        return format;
    }
  }

  String _formatSource(String source) {
    switch (source) {
      case 'ORIGINAL': return 'Original';
      case 'MANGA': return 'Manga';
      case 'LIGHT_NOVEL': return 'Light Novel';
      case 'VISUAL_NOVEL': return 'Visual Novel';
      case 'VIDEO_GAME': return 'Video Game';
      case 'OTHER': return 'Other';
      case 'NOVEL': return 'Novel';
      case 'DOUJINSHI': return 'Doujinshi';
      case 'ANIME': return 'Anime';
      default: return source;
    }
  }

  String _formatRelationType(String relationType) {
    switch (relationType) {
      case 'ADAPTATION': return 'Adaptation';
      case 'PREQUEL': return 'Prequel';
      case 'SEQUEL': return 'Sequel';
      case 'PARENT': return 'Parent';
      case 'SIDE_STORY': return 'Side Story';
      case 'CHARACTER': return 'Character';
      case 'SUMMARY': return 'Summary';
      case 'ALTERNATIVE': return 'Alternative';
      case 'SPIN_OFF': return 'Spin-off';
      case 'OTHER': return 'Other';
      case 'SOURCE': return 'Source';
      case 'COMPILATION': return 'Compilation';
      case 'CONTAINS': return 'Contains';
      default: return relationType;
    }
  }

  Color _getRelationTypeColor(String type) {
    switch (type.toUpperCase()) {
      case 'PREQUEL':
        return AppColors.blueAccent;
      case 'SEQUEL':
        return AppColors.green;
      case 'SIDE_STORY':
        return AppColors.orange;
      case 'ADAPTATION':
        return AppColors.purpleAccent;
      case 'ALTERNATIVE':
        return AppColors.pinkAccent;
      case 'SPIN_OFF':
        return AppColors.yellow;
      case 'CHARACTER':
        return AppColors.red;
      default:
        return AppColors.whiteSecondary;
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

  String _resolveSynopsis(NandogamiItem item) {
    final synopsis = widget.item.synopsis;
    if (synopsis != null && synopsis.trim().isNotEmpty) {
      return _cleanHtmlTags(synopsis);
    }
    return _cleanHtmlTags(widget.item.description);
  }

  String _cleanHtmlTags(String text) {
    if (text.isEmpty) return text;
    
    // Remove HTML tags but preserve line breaks
    String cleaned = text
        .replaceAll(RegExp(r'<br\s*/?>', caseSensitive: false), '\n')
        .replaceAll(RegExp(r'<[^>]*>'), '');
    
    // Decode HTML entities
    cleaned = cleaned
        .replaceAll('&amp;', '&')
        .replaceAll('&lt;', '<')
        .replaceAll('&gt;', '>')
        .replaceAll('&quot;', '"')
        .replaceAll('&#39;', "'")
        .replaceAll('&nbsp;', ' ')
        .replaceAll('&hellip;', '...')
        .replaceAll('&mdash;', '—')
        .replaceAll('&ndash;', '–')
        .replaceAll('&apos;', "'")
        .replaceAll('&rsquo;', "'")
        .replaceAll('&lsquo;', "'")
        .replaceAll('&rdquo;', '"')
        .replaceAll('&ldquo;', '"');
    
    // Clean up extra whitespace but preserve paragraph breaks
    cleaned = cleaned
        .replaceAll(RegExp(r'[ \t]+'), ' ') // Multiple spaces/tabs to single space
        .replaceAll(RegExp(r'\n\s*\n'), '\n\n') // Multiple newlines to double newline
        .replaceAll(RegExp(r'^\s+|\s+$', multiLine: true), '') // Trim each line
        .trim();
    
    return cleaned;
  }
}

// Reading Status Panel (copied from detail_screen.dart)
class _ReadingStatusPanel extends StatelessWidget {
  final String uid;
  final String titleId;
  final ReadingStatusService statusService;

  const _ReadingStatusPanel({
    required this.uid,
    required this.titleId,
    required this.statusService,
  });

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<String?>(
      stream: statusService.watchStatus(userId: uid, titleId: titleId),
      builder: (context, snapshot) {
        final currentStatus = snapshot.data;
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Reading Status',
              style: TextStyle(
                color: Theme.of(context).colorScheme.onSurface,
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 12),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                _StatusButton(
                  label: 'Want to Read',
                  isSelected: currentStatus == 'WANT_TO_READ',
                  onTap: () => statusService.setStatus(
                    userId: uid, 
                    titleId: titleId, 
                    status: 'WANT_TO_READ'
                  ),
                ),
                _StatusButton(
                  label: 'Reading',
                  isSelected: currentStatus == 'READING',
                  onTap: () => statusService.setStatus(
                    userId: uid, 
                    titleId: titleId, 
                    status: 'READING'
                  ),
                ),
                _StatusButton(
                  label: 'Completed',
                  isSelected: currentStatus == 'COMPLETED',
                  onTap: () => statusService.setStatus(
                    userId: uid, 
                    titleId: titleId, 
                    status: 'COMPLETED'
                  ),
                ),
                _StatusButton(
                  label: 'Dropped',
                  isSelected: currentStatus == 'DROPPED',
                  onTap: () => statusService.setStatus(
                    userId: uid, 
                    titleId: titleId, 
                    status: 'DROPPED'
                  ),
                ),
                _StatusButton(
                  label: 'Paused',
                  isSelected: currentStatus == 'PAUSED',
                  onTap: () => statusService.setStatus(
                    userId: uid, 
                    titleId: titleId, 
                    status: 'PAUSED'
                  ),
                ),
                _StatusButton(
                  label: 'Remove',
                  isSelected: currentStatus == null,
                  onTap: () => statusService.setStatus(
                    userId: uid, 
                    titleId: titleId, 
                    status: 'REMOVED'
                  ),
                ),
              ],
            ),
          ],
        );
      },
    );
  }
}

class _StatusButton extends StatelessWidget {
  final String label;
  final bool isSelected;
  final VoidCallback onTap;

  const _StatusButton({
    required this.label,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          color: isSelected
              ? Theme.of(context).colorScheme.primary
              : Theme.of(context).colorScheme.surfaceContainerHighest,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: isSelected
                ? Theme.of(context).colorScheme.primary
                : Theme.of(context).colorScheme.outline,
            width: 1,
          ),
        ),
        child: Text(
          label,
          style: TextStyle(
            color: isSelected ? Colors.white : Theme.of(context).colorScheme.onSurface,
            fontSize: 12,
            fontWeight: FontWeight.w500,
          ),
        ),
      ),
    );
  }
}
