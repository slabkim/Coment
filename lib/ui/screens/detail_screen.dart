import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../data/models/comic_item.dart';
import '../../state/item_provider.dart';
import '../../core/constants.dart'; // pastikan punya AppColors & AppConst

class DetailScreen extends StatelessWidget {
  final ComicItem item;
  const DetailScreen({super.key, required this.item});

  @override
  Widget build(BuildContext context) {
    final prov = context.watch<ItemProvider>();
    final isFav = prov.isFavorite(item.id);

    return DefaultTabController(
      length: 3,
      child: Scaffold(
        backgroundColor: AppColors.black,
        body: NestedScrollView(
          headerSliverBuilder: (context, inner) => [
            SliverAppBar(
              backgroundColor: AppColors.black,
              expandedHeight: 300,
              pinned: true,
              elevation: 0,
              centerTitle: false,
              leading: IconButton(
                icon: const Icon(Icons.arrow_back),
                onPressed: () => Navigator.pop(context),
              ),
              actions: [
                IconButton(
                  icon: const Icon(Icons.share),
                  onPressed: () {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Share coming soon')),
                    );
                  },
                ),
              ],
              flexibleSpace: FlexibleSpaceBar(
                collapseMode: CollapseMode.parallax,
                background: Stack(
                  fit: StackFit.expand,
                  children: [
                    // Cover
                    CachedNetworkImage(
                      imageUrl: item.imageUrl,
                      fit: BoxFit.cover,
                      placeholder: (c, _) =>
                          const Center(child: CircularProgressIndicator()),
                      errorWidget: (c, _, __) => const ColoredBox(
                        color: Colors.black,
                        child: Center(
                          child: Icon(
                            Icons.broken_image,
                            color: Colors.white54,
                          ),
                        ),
                      ),
                    ),
                    // dark gradient scrim
                    const DecoratedBox(
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.topCenter,
                          end: Alignment.bottomCenter,
                          colors: [Colors.transparent, Colors.black54],
                        ),
                      ),
                    ),
                    // Favorite big button (56dp) bottom|end
                    Positioned(
                      right: 16,
                      bottom: 16,
                      child: Material(
                        color: Colors.black.withOpacity(.45),
                        shape: const CircleBorder(),
                        clipBehavior: Clip.antiAlias,
                        child: IconButton(
                          iconSize: 28,
                          color: isFav ? Colors.pinkAccent : Colors.white,
                          icon: Icon(
                            isFav ? Icons.favorite : Icons.favorite_border,
                          ),
                          onPressed: () => prov.toggleFavorite(item.id),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              bottom: const TabBar(
                labelColor: AppColors.purpleAccent,
                unselectedLabelColor: AppColors.whiteSecondary,
                indicatorColor: AppColors.purpleAccent,
                tabs: [
                  Tab(text: 'About'),
                  Tab(text: 'Where to Read'),
                  Tab(text: 'Comments'),
                ],
              ),
            ),
          ],
          body: const TabBarView(
            children: [_AboutTab(), _WhereToReadTab(), _CommentsTab()],
          ),
        ),
      ),
    );
  }
}

/// ---------------- ABOUT TAB ----------------
class _AboutTab extends StatelessWidget {
  const _AboutTab();

  @override
  Widget build(BuildContext context) {
    final item = (context.findAncestorWidgetOfExactType<DetailScreen>()!).item;
    final theme = Theme.of(context).textTheme;

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
              color: AppColors.white,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 4),

          // Author
          if ((item.author ?? '').isNotEmpty)
            Text(
              item.author!,
              style: theme.bodyMedium?.copyWith(
                color: AppColors.whiteSecondary,
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
                style: const TextStyle(
                  color: AppColors.white,
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
                '${(item.rating ?? 0).toStringAsFixed(1)}',
                style: const TextStyle(color: AppColors.white),
              ),
              if ((item.ratingCount ?? 0) > 0) ...[
                const SizedBox(width: 4),
                Text(
                  '(${item.ratingCount} ratings)',
                  style: const TextStyle(color: AppColors.whiteSecondary),
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
                      backgroundColor: const Color(0xFF2A2E35),
                      labelStyle: const TextStyle(color: AppColors.white),
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
            item.synopsis ?? item.description ?? 'No synopsis available',
            style: const TextStyle(
              color: AppColors.whiteSecondary,
              height: 1.35,
            ),
          ),

          // Reading Status (2 baris tombol)
          const SizedBox(height: 24),
          _ReadingStatusPanel(),

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
                      backgroundColor: const Color(0xFF2A2E35),
                      labelStyle: const TextStyle(color: AppColors.white),
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
}

/// ---------------- WHERE TO READ TAB ----------------
class _WhereToReadTab extends StatelessWidget {
  const _WhereToReadTab();

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: const [
          _ServiceCard(
            title: 'Manga Plus',
            subtitle: 'Official Shueisha platform',
            badge: 'FREE',
          ),
          SizedBox(height: 12),
          _ServiceCard(
            title: 'VIZ Media',
            subtitle: 'Official English publisher',
            badge: '\$1.99',
          ),
          SizedBox(height: 12),
          _ServiceCard(
            title: 'Crunchyroll Manga',
            subtitle: 'Subscription required',
            badge: 'PREMIUM',
          ),
        ],
      ),
    );
  }
}

/// ---------------- COMMENTS TAB ----------------
class _CommentsTab extends StatelessWidget {
  const _CommentsTab();

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Comments',
            style: TextStyle(
              color: AppColors.white,
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              IconButton(
                onPressed: () {},
                icon: const Icon(Icons.image, color: AppColors.white),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: TextField(
                  minLines: 1,
                  maxLines: 3,
                  style: const TextStyle(color: AppColors.white),
                  decoration: InputDecoration(
                    hintText: 'Add a comment...',
                    hintStyle: const TextStyle(color: AppColors.whiteSecondary),
                    filled: true,
                    fillColor: const Color(0xFF2A2E35),
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 12,
                    ),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10),
                      borderSide: BorderSide.none,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 8),
              FilledButton(
                onPressed: () {},
                style: FilledButton.styleFrom(
                  backgroundColor: AppColors.purpleAccent,
                ),
                child: const Text('Post'),
              ),
            ],
          ),
          const SizedBox(height: 16),
          // dummy comments
          ...List.generate(
            3,
            (i) => Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: ListTile(
                contentPadding: EdgeInsets.zero,
                leading: const CircleAvatar(child: Icon(Icons.person)),
                title: Text(
                  'User $i',
                  style: const TextStyle(
                    color: AppColors.white,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                subtitle: const Text(
                  'Great recommendation!',
                  style: TextStyle(color: AppColors.whiteSecondary),
                ),
              ),
            ),
          ),
        ],
      ),
    );
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
  const _ReadingStatusPanel();

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
          Row(
            children: [
              Expanded(
                child: _statusBtn('Plan to Read', const Color(0xFF2563EB)),
              ),
              const SizedBox(width: 8),
              Expanded(child: _statusBtn('Reading', const Color(0xFF16A34A))),
              const SizedBox(width: 8),
              Expanded(child: _statusBtn('Completed', const Color(0xFF7C3AED))),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(child: _statusBtn('Dropped', const Color(0xFFDC2626))),
              const SizedBox(width: 8),
              Expanded(child: _statusBtn('On Hold', const Color(0xFFF59E0B))),
            ],
          ),
        ],
      ),
    );
  }

  Widget _statusBtn(String text, Color color) {
    return SizedBox(
      height: 40,
      child: FilledButton(
        onPressed: () {},
        style: FilledButton.styleFrom(backgroundColor: color),
        child: Text(text, style: const TextStyle(fontSize: 12)),
      ),
    );
  }
}
