import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:provider/provider.dart';
import 'package:share_plus/share_plus.dart';
import 'package:flutter/services.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../core/constants.dart';
import '../../core/auth_helper.dart'; 
import '../../data/models/nandogami_item.dart';
import '../../data/models/external_link.dart';
import '../../data/repositories/comic_repository.dart';
import '../../data/services/comments_service.dart';
import '../../data/services/favorite_service.dart';
import '../../data/services/reading_status_service.dart';
import '../../data/services/simple_anilist_service.dart';
import '../../state/item_provider.dart';
import '../widgets/dynamic_wallpaper.dart';
import '../widgets/comic_detail_header.dart';
import '../widgets/about_tab_new.dart';
import 'user_public_profile_screen.dart';

class DetailScreen extends StatelessWidget {
  final NandogamiItem item;
  const DetailScreen({super.key, required this.item});

  @override
  Widget build(BuildContext context) {
    final currentUid = FirebaseAuth.instance.currentUser?.uid;
    final favService = FavoriteService();
    final statusService = ReadingStatusService();

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
             body: DefaultTabController(
               length: 3, // Only 3 tabs: About, Where to Read, Comments
               child: NestedScrollView(
          headerSliverBuilder: (context, innerBoxIsScrolled) {
            return [
              StreamBuilder<bool>(
                stream: currentUid != null 
                    ? favService.isFavoriteStream(
                        userId: currentUid!,
                        titleId: item.id,
                      )
                    : Stream.value(false),
                builder: (context, snap) {
                  final isFav = snap.data ?? false;
                  return SliverAppBar(
                    expandedHeight: 280,
                    floating: false,
                    pinned: true,
                    backgroundColor: Theme.of(context).scaffoldBackgroundColor,
                    flexibleSpace: FlexibleSpaceBar(
                      background: ComicDetailHeader(
                        item: item,
                        isFavorite: isFav,
                        onFavoriteToggle: () async {
                          final success = await AuthHelper.requireAuthWithDialog(
                            context, 
                            'add this manga to your favorites'
                          );
                          if (success && currentUid != null) {
                            HapticFeedback.lightImpact();
                            await favService.toggleFavorite(
                              userId: currentUid!,
                              titleId: item.id,
                            );
                          }
                        },
                        onShare: () async {
                          final uri = Uri(
                            scheme: 'https',
                            host: 'nandogami.app',
                            path: '/title/${item.id}',
                          );
                          await Share.share('Check this out: $uri');
                        },
                      ),
                    ),
                    actions: [
                      IconButton(
                        icon: Icon(Icons.share, color: Theme.of(context).colorScheme.onSurface),
                        onPressed: () async {
                          final uri = Uri(
                            scheme: 'https',
                            host: 'nandogami.app',
                            path: '/title/${item.id}',
                          );
                          await Share.share('Check this out: $uri');
                        },
                      ),
                    ],
                  );
                },
              ),
              SliverPersistentHeader(
                pinned: true,
                delegate: _SliverAppBarDelegate(
                  TabBar(
                    labelColor: Theme.of(context).colorScheme.primary,
                    unselectedLabelColor: Theme.of(context).colorScheme.onSurfaceVariant,
                    indicatorColor: Theme.of(context).colorScheme.primary,
                                 tabs: const [
                                   Tab(text: 'About'),
                                   Tab(text: 'Where to Read'),
                                   Tab(text: 'Comments'),
                                 ],
                  ),
                ),
              ),
            ];
          },
                 body: TabBarView(
                   children: [
                     AboutTabNew(
                       item: item,
                       uid: currentUid,
                       statusService: statusService,
                     ),
                     _WhereToReadTab(item: item),
                     _CommentsTab(titleId: item.id),
                   ],
                 ),
        ),
      ),
    );
  }
}

class _SliverAppBarDelegate extends SliverPersistentHeaderDelegate {
  final TabBar _tabBar;

  _SliverAppBarDelegate(this._tabBar);

  @override
  double get minExtent => _tabBar.preferredSize.height;

  @override
  double get maxExtent => _tabBar.preferredSize.height;

  @override
  Widget build(BuildContext context, double shrinkOffset, bool overlapsContent) {
    return Container(
      color: Theme.of(context).scaffoldBackgroundColor,
      child: _tabBar,
    );
  }

  @override
  bool shouldRebuild(_SliverAppBarDelegate oldDelegate) {
    return false;
  }
}

/// ---------------- ABOUT TAB ----------------
class _AboutTab extends StatelessWidget {
  final NandogamiItem item;
  final String? uid;
  final ReadingStatusService statusService;
  const _AboutTab({
    required this.item,
    required this.uid,
    required this.statusService,
  });

  @override
  Widget build(BuildContext context) {
    final item = this.item;
    final theme = Theme.of(context).textTheme;
    final currentUid = uid;

    final categories = item.categories ?? const <String>[];
    final themes = item.themes ?? const <String>[];
    final altTitles = item.alternativeTitles ?? const <String>[];

    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
      child: Column(
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
          const SizedBox(height: 4),

          // Author
          if ((item.author ?? '').isNotEmpty)
            Text(
              item.author!,
              style: theme.bodyMedium?.copyWith(
                color: Theme.of(context).colorScheme.onSurfaceVariant,
                fontWeight: FontWeight.w500,
              ),
            ),

          // Type badge
          if ((item.type ?? '').isNotEmpty) ...[
            const SizedBox(height: 8),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(8),
                color: const Color(0xFF2A2E35),
              ),
              child: Text(
                item.type!,
                style: TextStyle(
                  color: Theme.of(context).colorScheme.onSurface,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ],

          // Rating row
          const SizedBox(height: 8),
          Row(
            children: [
              _Stars(rating: (item.rating ?? 0).toDouble()),
              const SizedBox(width: 8),
              Text(
                (item.rating ?? 0).toStringAsFixed(1),
                style: TextStyle(color: Theme.of(context).colorScheme.onSurface),
              ),
              if ((item.ratingCount ?? 0) > 0) ...[
                const SizedBox(width: 4),
                Text(
                  '(${item.ratingCount} ratings)',
                  style: TextStyle(color: Theme.of(context).colorScheme.onSurfaceVariant),
                ),
              ],
            ],
          ),

          // Categories chips
          if (categories.isNotEmpty) ...[
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              runSpacing: -6,
              children: categories
                  .map(
                    (e) => Chip(
                      label: Text(e),
                      backgroundColor: Theme.of(context).colorScheme.surfaceContainerHighest,
                      labelStyle: TextStyle(color: Theme.of(context).colorScheme.onSurface),
                    ),
                  )
                  .toList(),
            ),
          ],

          // Synopsis
          const SizedBox(height: 24),
          Text(
            'Synopsis',
            style: theme.titleMedium?.copyWith(color: AppColors.white),
          ),
          const SizedBox(height: 8),
          Text(
            _resolveSynopsis(item),
            style: const TextStyle(
              color: AppColors.whiteSecondary,
              height: 1.35,
            ),
          ),

          // Reading Status (2 baris tombol)
          const SizedBox(height: 24),
          if (currentUid != null)
            _ReadingStatusPanel(
              uid: currentUid,
              titleId: item.id,
              statusService: statusService,
            ),

          // Alternative titles
          if (altTitles.isNotEmpty) ...[
            const SizedBox(height: 24),
            Text(
              'Alternative Titles',
              style: theme.titleMedium?.copyWith(color: AppColors.white),
            ),
            const SizedBox(height: 8),
            Text(
              altTitles.join('\n'),
              style: const TextStyle(
                color: AppColors.whiteSecondary,
                height: 1.35,
              ),
            ),
          ],

          // Information grid (Type, Format, Release Year, Chapters)
          const SizedBox(height: 24),
          Text(
            'Information',
            style: theme.titleMedium?.copyWith(color: AppColors.white),
          ),
          const SizedBox(height: 8),
          _InfoGrid(
            rows: [
              _InfoRow('Type', item.type ?? 'Unknown'),
              _InfoRow('Format', item.format ?? 'Unknown'),
              _InfoRow('Release Year', (item.releaseYear ?? 0).toString()),
              _InfoRow('Chapters', (item.chapters ?? 0).toString()),
            ],
          ),

          // Themes chips
          if (themes.isNotEmpty) ...[
            const SizedBox(height: 24),
            Text(
              'Themes',
              style: theme.titleMedium?.copyWith(color: AppColors.white),
            ),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              runSpacing: -6,
              children: themes
                  .map(
                    (e) => Chip(
                      label: Text(e),
                      backgroundColor: Theme.of(context).colorScheme.surfaceContainerHighest,
                      labelStyle: TextStyle(color: Theme.of(context).colorScheme.onSurface),
                    ),
                  )
                  .toList(),
            ),
          ],

          // Adaptations (placeholder list)
          const SizedBox(height: 24),
          Text(
            'Adaptations',
            style: theme.titleMedium?.copyWith(color: AppColors.white),
          ),
          const SizedBox(height: 8),
          Column(
            children: [
              _AdaptationTile(
                title: 'Anime (Season 1)',
                subtitle: 'Studio XYZ',
              ),
              _AdaptationTile(title: 'Light Novel', subtitle: 'Publisher ABC'),
            ],
          ),

          // Visual Inspiration
          const SizedBox(height: 24),
          Text(
            'Visual Inspiration',
            style: theme.titleMedium?.copyWith(color: AppColors.white),
          ),
          const SizedBox(height: 8),
          SizedBox(
            height: 120,
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              itemCount: categories.length,
              itemBuilder: (context, index) {
                return GenreWallpaperCard(
                  genre: categories[index],
                  onTap: () {
                    // Optional: Show full screen wallpaper
                  },
                );
              },
            ),
          ),

          // Discover horizontal
          const SizedBox(height: 24),
          Text(
            'Discover',
            style: theme.titleMedium?.copyWith(color: AppColors.white),
          ),
          const SizedBox(height: 8),
          _DiscoverRow(),
        ],
      ),
    );
  }

  String _resolveSynopsis(NandogamiItem item) {
    final synopsis = item.synopsis;
    if (synopsis != null && synopsis.trim().isNotEmpty) {
      return synopsis;
    }
    return item.description;
  }
}

/// ---------------- WHERE TO READ TAB ----------------
class _WhereToReadTab extends StatefulWidget {
  final NandogamiItem item;
  
  const _WhereToReadTab({required this.item});

  @override
  State<_WhereToReadTab> createState() => _WhereToReadTabState();
}

class _WhereToReadTabState extends State<_WhereToReadTab> {
  List<ExternalLink>? _externalLinks;
  bool _loadingExternalLinks = false;

  @override
  void initState() {
    super.initState();
    _loadExternalLinks();
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
        // Use retry mechanism for better reliability
        final externalLinks = await mangaService.getMangaExternalLinksWithRetry(mangaId);
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

  /// Refresh external links (clear cache and reload)
  Future<void> _refreshExternalLinks() async {
    // Clear cache before reloading
    SimpleAniListService.clearExternalLinksCache();
    await _loadExternalLinks();
  }

  @override
  Widget build(BuildContext context) {
    if (_loadingExternalLinks) {
      return const Center(
        child: CircularProgressIndicator(),
      );
    }

    final links = _externalLinks ?? [];
    
    if (links.isEmpty) {
      return SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.link_off,
                color: Theme.of(context).colorScheme.onSurfaceVariant,
                size: 64,
              ),
              const SizedBox(height: 16),
              Text(
                'No External Links Available',
                style: TextStyle(
                  color: Theme.of(context).colorScheme.onSurface,
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'This manga doesn\'t have any official external links yet.',
                style: TextStyle(
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                  fontSize: 14,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 24),
              ElevatedButton.icon(
                onPressed: _refreshExternalLinks,
                icon: const Icon(Icons.refresh),
                label: const Text('Retry'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Theme.of(context).colorScheme.primary,
                  foregroundColor: Colors.white,
                ),
              ),
            ],
          ),
        ),
      );
    }

    // Group links by type
    final streamingLinks = links.where((link) => link.isStreaming).toList();
    final readingLinks = links.where((link) => link.isReading).toList();
    final merchandiseLinks = links.where((link) => link.isMerchandise).toList();
    final otherLinks = links.where((link) => 
      !link.isStreaming && !link.isReading && !link.isMerchandise
    ).toList();

    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (streamingLinks.isNotEmpty) ...[
            _buildSectionHeader('Streaming Services', Icons.play_circle_outline),
            const SizedBox(height: 12),
            ...streamingLinks.map((link) => _ExternalLinkCard(link: link)),
            const SizedBox(height: 24),
          ],
          
          if (readingLinks.isNotEmpty) ...[
            _buildSectionHeader('Reading Platforms', Icons.menu_book),
            const SizedBox(height: 12),
            ...readingLinks.map((link) => _ExternalLinkCard(link: link)),
            const SizedBox(height: 24),
          ],
          
          if (merchandiseLinks.isNotEmpty) ...[
            _buildSectionHeader('Merchandise', Icons.shopping_bag),
            const SizedBox(height: 12),
            ...merchandiseLinks.map((link) => _ExternalLinkCard(link: link)),
            const SizedBox(height: 24),
          ],
          
          if (otherLinks.isNotEmpty) ...[
            _buildSectionHeader('Other Links', Icons.link),
            const SizedBox(height: 12),
            ...otherLinks.map((link) => _ExternalLinkCard(link: link)),
          ],
        ],
      ),
    );
  }

  Widget _buildSectionHeader(String title, IconData icon) {
    return Row(
      children: [
        Icon(icon, color: Theme.of(context).colorScheme.primary, size: 20),
        const SizedBox(width: 8),
        Text(
          title,
          style: TextStyle(
            color: Theme.of(context).colorScheme.onSurface,
            fontSize: 18,
            fontWeight: FontWeight.w600,
          ),
        ),
      ],
    );
  }
}

/// ---------------- EXTERNAL LINK CARD ----------------
class _ExternalLinkCard extends StatelessWidget {
  final ExternalLink link;
  
  const _ExternalLinkCard({required this.link});

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
                // Icon
                Container(
                  width: 48,
                  height: 48,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(8),
                    color: _getIconBackgroundColor(),
                  ),
                  child: _buildIcon(),
                ),
                
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
    // Try to use AniList icon URL first (these are usually good quality)
    if (link.icon != null && link.icon!.isNotEmpty) {
      return ClipRRect(
        borderRadius: BorderRadius.circular(8),
        child: CachedNetworkImage(
          imageUrl: link.icon!,
          width: 48,
          height: 48,
          fit: BoxFit.cover,
          placeholder: (context, url) => _buildColoredIcon(),
          errorWidget: (context, url, error) => _buildColoredIcon(),
        ),
      );
    }
    
    // Fallback to colored Material icon only if no AniList icon
    return _buildColoredIcon();
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
        color: _getIconColor(),
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

  Color _getIconColor() {
    return Colors.white;
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

/// ---------------- COMMENTS TAB ----------------
class _CommentsTab extends StatefulWidget {
  final String titleId;
  const _CommentsTab({required this.titleId});

  @override
  State<_CommentsTab> createState() => _CommentsTabState();
}

class _CommentsTabState extends State<_CommentsTab> {
  final _c = TextEditingController();
  final _svc = CommentsService();

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 12),
          child: Row(
            children: [
              const CircleAvatar(child: Icon(Icons.person)),
              const SizedBox(width: 8),
              Expanded(
                child: TextField(
                  controller: _c,
                  minLines: 1,
                  maxLines: 3,
                  style: TextStyle(color: Theme.of(context).colorScheme.onSurface),
                  decoration: InputDecoration(
                    hintText: 'Add a comment...',
                    hintStyle: TextStyle(color: Theme.of(context).colorScheme.onSurfaceVariant),
                    filled: true,
                    fillColor: Theme.of(context).colorScheme.surfaceContainerHighest,
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 12,
                    ),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10),
                      borderSide: BorderSide.none,
                    ),
                  ),
                  onSubmitted: (_) => _post(uid),
                ),
              ),
              const SizedBox(width: 8),
              FilledButton(
                onPressed: () => _post(uid),
                style: FilledButton.styleFrom(
                  backgroundColor: Theme.of(context).colorScheme.primary,
                ),
                child: const Text('Post'),
              ),
            ],
          ),
        ),
        Expanded(
          child: StreamBuilder<List<CommentModel>>(
            stream: _svc.watchComments(widget.titleId),
            builder: (context, snapshot) {
              final items = snapshot.data ?? const [];
              if (items.isEmpty) {
                return Center(
                  child: Text(
                    'No comments yet',
                    style: TextStyle(color: Theme.of(context).colorScheme.onSurfaceVariant),
                  ),
                );
              }
              return ListView.separated(
                padding: const EdgeInsets.fromLTRB(16, 0, 16, 24),
                itemCount: items.length,
                separatorBuilder: (_, __) => const SizedBox(height: 8),
                itemBuilder: (context, i) {
                  final m = items[i];
                  return _CommentTile(model: m, uid: uid, svc: _svc);
                },
              );
            },
          ),
        ),
      ],
    );
  }

  Future<void> _post(String? uid) async {
    final text = _c.text.trim();
    if (text.isEmpty) return;
    
    // Cek autentikasi dulu
    final success = await AuthHelper.requireAuthWithDialog(
      context, 
      'post a comment'
    );
    if (!success) return;
    
    final currentUid = FirebaseAuth.instance.currentUser?.uid;
    if (currentUid == null) return;
    
    final user = FirebaseAuth.instance.currentUser;
    await _svc.addComment(
      titleId: widget.titleId,
      userId: currentUid,
      text: text,
      userName: user?.displayName,
      userAvatar: user?.photoURL,
    );
    _c.clear();
  }
}

class _CommentTile extends StatelessWidget {
  final CommentModel model;
  final String? uid;
  final CommentsService svc;
  const _CommentTile({
    required this.model,
    required this.uid,
    required this.svc,
  });

  @override
  Widget build(BuildContext context) {
    final likeLabel = '${model.likeCount} likes';
    final timeLabel = _timeAgo(model.createdAt);
    return Container(
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(10),
      ),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 12,
          vertical: 12,
        ),
        leading: CircleAvatar(
          backgroundColor: Theme.of(context).colorScheme.primary.withValues(alpha: 0.2),
          backgroundImage:
              (model.userAvatar != null && model.userAvatar!.isNotEmpty)
              ? NetworkImage(model.userAvatar!)
              : null,
          child: (model.userAvatar == null || model.userAvatar!.isEmpty)
              ? Text(
                  _initials(model.userName),
                  style: TextStyle(color: Theme.of(context).colorScheme.onSurface),
                )
              : null,
        ),
        title: Text(
          model.userName ?? 'Anon',
          style: TextStyle(
            color: Theme.of(context).colorScheme.onSurface,
            fontWeight: FontWeight.w600,
          ),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 4),
            if (model.text.isNotEmpty)
              Text(model.text, style: TextStyle(color: Theme.of(context).colorScheme.onSurface)),
            if (model.imageUrl != null)
              Padding(
                padding: const EdgeInsets.only(top: 8),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(8),
                  child: Image.network(
                    model.imageUrl!,
                    height: 140,
                    width: double.infinity,
                    fit: BoxFit.cover,
                  ),
                ),
              ),
            const SizedBox(height: 8),
            Text(
              '$timeLabel • $likeLabel',
              style: TextStyle(
                color: Theme.of(context).colorScheme.onSurfaceVariant,
                fontSize: 12,
              ),
            ),
          ],
        ),
        onTap: () {
          if (model.userId.isEmpty) return;
          Navigator.of(context).push(
            MaterialPageRoute(
              builder: (_) => UserPublicProfileScreen(userId: model.userId),
            ),
          );
        },
        trailing: uid == null
            ? null
            : StreamBuilder<bool>(
                stream: svc.isLiked(commentId: model.id, userId: uid!),
                builder: (context, snap) {
                  final liked = snap.data ?? false;
                  return IconButton(
                    icon: Icon(liked ? Icons.favorite : Icons.favorite_border),
                    color: liked ? Colors.pinkAccent : Theme.of(context).colorScheme.onSurfaceVariant,
                    onPressed: () async {
                      final success = await AuthHelper.requireAuthWithDialog(
                        context, 
                        'like this comment'
                      );
                      if (success && uid != null) {
                        if (liked) {
                          await svc.unlike(commentId: model.id, userId: uid!);
                        } else {
                          await svc.like(commentId: model.id, userId: uid!);
                        }
                      }
                    },
                  );
                },
              ),
      ),
    );
  }

  String _initials(String? name) {
    if (name == null || name.trim().isEmpty) return '?';
    final parts = name.trim().split(' ');
    final first = parts.first.isNotEmpty ? parts.first[0] : '';
    final second = parts.length > 1 && parts.last.isNotEmpty
        ? parts.last[0]
        : '';
    return (first + second).toUpperCase();
  }

  String _timeAgo(DateTime time) {
    final diff = DateTime.now().difference(time);
    if (diff.inSeconds < 60) return 'Just now';
    if (diff.inMinutes < 60) return '${diff.inMinutes}m ago';
    if (diff.inHours < 24) return '${diff.inHours}h ago';
    if (diff.inDays < 7) return '${diff.inDays}d ago';
    final weeks = (diff.inDays / 7).floor();
    if (weeks < 4) return '${weeks}w ago';
    final months = (diff.inDays / 30).floor();
    if (months < 12) return '${months}mo ago';
    final years = (diff.inDays / 365).floor();
    return '${years}y ago';
  }
}

/// ============= WIDGET KECIL PENDUKUNG =============

class _Stars extends StatelessWidget {
  final double rating; // 0..5 atau 0..10 terserah datanya
  const _Stars({required this.rating});

  @override
  Widget build(BuildContext context) {
    final value = rating.clamp(0, 5);
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: List.generate(5, (i) {
        final filled = i + 1 <= value;
        final half = !filled && (value - i) > 0 && (value - i) < 1;
        return Icon(
          half ? Icons.star_half : (filled ? Icons.star : Icons.star_border),
          size: 18,
          color: AppColors.purpleAccent,
        );
      }),
    );
  }
}

class _InfoRow {
  final String label;
  final String value;
  _InfoRow(this.label, this.value);
}

class _InfoGrid extends StatelessWidget {
  final List<_InfoRow> rows;
  const _InfoGrid({required this.rows});

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, c) {
        final twoCols = c.maxWidth > 360;
        return GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: rows.length * 2,
          gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: twoCols ? 2 : 1,
            childAspectRatio: twoCols ? 6 : 10,
            mainAxisSpacing: 6,
            crossAxisSpacing: 8,
          ),
          itemBuilder: (context, i) {
            final idx = i ~/ 2;
            final isLabel = i.isEven;
            final row = rows[idx];
            return Align(
              alignment: Alignment.centerLeft,
              child: Text(
                isLabel ? row.label : row.value,
                style: TextStyle(
                  color: isLabel ? AppColors.white : AppColors.whiteSecondary,
                  fontWeight: isLabel ? FontWeight.bold : FontWeight.normal,
                ),
              ),
            );
          },
        );
      },
    );
  }
}

class _AdaptationTile extends StatelessWidget {
  final String title;
  final String subtitle;
  const _AdaptationTile({required this.title, required this.subtitle});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: const Color(0xFF2A2E35),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Row(
        children: [
          const Icon(Icons.movie, color: AppColors.whiteSecondary),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              title,
              style: const TextStyle(
                color: AppColors.white,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          Text(
            subtitle,
            style: const TextStyle(color: AppColors.whiteSecondary),
          ),
        ],
      ),
    );
  }
}

class _DiscoverRow extends StatelessWidget {
  const _DiscoverRow();

  @override
  Widget build(BuildContext context) {
    final prov = context.watch<ItemProvider>();
    final items = prov.getPopular; // pakai popular sebagai rekomendasi
    if (items.isEmpty) {
      return const SizedBox.shrink();
    }
    final w = MediaQuery.sizeOf(context).width;
    final cardW = w * 0.56;
    const h = 180.0;

    return SizedBox(
      height: h,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        itemCount: items.length,
        separatorBuilder: (_, __) => const SizedBox(width: 12),
        itemBuilder: (context, i) {
          final it = items[i];
          return SizedBox(
            width: cardW,
            child: ClipRRect(
              borderRadius: BorderRadius.circular(12),
              child: Stack(
                fit: StackFit.expand,
                children: [
                  CachedNetworkImage(imageUrl: it.imageUrl, fit: BoxFit.cover),
                  Positioned(
                    left: 8,
                    right: 8,
                    bottom: 8,
                    child: Text(
                      it.title,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.w700,
                        shadows: [Shadow(blurRadius: 4, color: Colors.black87)],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}

class _ServiceCard extends StatelessWidget {
  final String title;
  final String subtitle;
  final String badge;
  const _ServiceCard({
    required this.title,
    required this.subtitle,
    required this.badge,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      color: const Color(0xFF2A2E35),
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            Container(
              width: 40,
              height: 40,
              decoration: const BoxDecoration(
                color: Colors.black54,
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.menu_book, color: Colors.white),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: const TextStyle(
                      color: AppColors.white,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    subtitle,
                    style: const TextStyle(
                      color: AppColors.whiteSecondary,
                      fontSize: 12,
                    ),
                  ),
                ],
              ),
            ),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: const Color(0xFF3B2A58),
                borderRadius: BorderRadius.circular(6),
              ),
              child: Text(
                badge,
                style: const TextStyle(
                  color: AppColors.purpleAccent,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

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
    // dua baris tombol status
    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFF1E232B),
        borderRadius: BorderRadius.circular(12),
      ),
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Reading Status',
            style: TextStyle(
              color: AppColors.white,
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 12),
          StreamBuilder<String?>(
            stream: statusService.watchStatus(userId: uid, titleId: titleId),
            builder: (context, snap) {
              final current = snap.data;
              return Column(
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: _statusBtn(
                          context,
                          'plan',
                          'Plan to Read',
                          const Color(0xFF2563EB),
                          current,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: _statusBtn(
                          context,
                          'reading',
                          'Reading',
                          const Color(0xFF16A34A),
                          current,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: _statusBtn(
                          context,
                          'completed',
                          'Completed',
                          const Color(0xFF7C3AED),
                          current,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Expanded(
                        child: _statusBtn(
                          context,
                          'dropped',
                          'Dropped',
                          const Color(0xFFDC2626),
                          current,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: _statusBtn(
                          context,
                          'on_hold',
                          'On Hold',
                          const Color(0xFFF59E0B),
                          current,
                        ),
                      ),
                    ],
                  ),
                ],
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _statusBtn(BuildContext context, String value, String text, Color color, String? current) {
    return SizedBox(
      height: 40,
      child: FilledButton(
        onPressed: () async {
          final success = await AuthHelper.requireAuthWithDialog(
            context, 
            'update your reading status'
          );
          if (success) {
            await statusService.setStatus(
              userId: uid,
              titleId: titleId,
              status: value,
            );
          }
        },
        style: FilledButton.styleFrom(
          backgroundColor: current == value ? color : const Color(0xFF2A2E35),
          foregroundColor: current == value
              ? Colors.white
              : AppColors.whiteSecondary,
        ),
        child: Text(text, style: const TextStyle(fontSize: 12)),
      ),
    );
  }
}

