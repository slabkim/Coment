import 'package:flutter/material.dart';
import '../../../core/logger.dart';
import '../../../data/models/nandogami_item.dart';
import '../../../data/models/external_link.dart';
import '../../../data/services/simple_anilist_service.dart';
import 'external_link_card.dart';

/// Tab widget for displaying "Where to Read" section.
/// Shows external links for reading/watching the manga.
class WhereToReadTab extends StatefulWidget {
  final NandogamiItem item;
  
  const WhereToReadTab({super.key, required this.item});

  @override
  State<WhereToReadTab> createState() => _WhereToReadTabState();
}

class _WhereToReadTabState extends State<WhereToReadTab> {
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
    } catch (e, stackTrace) {
      AppLogger.apiError('loading external links', e, stackTrace);
      if (!mounted) return;
      setState(() {
        _externalLinks = [];
        _loadingExternalLinks = false;
      });
    }
  }

  /// Refreshes external links by clearing cache and reloading.
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
            ...streamingLinks.map((link) => ExternalLinkCard(link: link)),
            const SizedBox(height: 24),
          ],
          
          if (readingLinks.isNotEmpty) ...[
            _buildSectionHeader('Reading Platforms', Icons.menu_book),
            const SizedBox(height: 12),
            ...readingLinks.map((link) => ExternalLinkCard(link: link)),
            const SizedBox(height: 24),
          ],
          
          if (merchandiseLinks.isNotEmpty) ...[
            _buildSectionHeader('Merchandise', Icons.shopping_bag),
            const SizedBox(height: 12),
            ...merchandiseLinks.map((link) => ExternalLinkCard(link: link)),
            const SizedBox(height: 24),
          ],
          
          if (otherLinks.isNotEmpty) ...[
            _buildSectionHeader('Other Links', Icons.link),
            const SizedBox(height: 12),
            ...otherLinks.map((link) => ExternalLinkCard(link: link)),
          ],
        ],
      ),
    );
  }

  Widget _buildSectionHeader(String title, IconData icon) {
    return Row(
      children: [
        Icon(icon, color: Theme.of(context).colorScheme.onSurface, size: 20),
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

