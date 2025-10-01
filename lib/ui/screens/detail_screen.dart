import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:provider/provider.dart';
import 'package:share_plus/share_plus.dart';

import '../../core/constants.dart'; // pastikan punya AppColors & AppConst
import '../../data/models/nandogami_item.dart';
import '../../data/services/comments_service.dart';
import '../../data/services/favorite_service.dart';
import '../../data/services/reading_status_service.dart';
import '../../state/item_provider.dart';
import 'user_public_profile_screen.dart';

class DetailScreen extends StatelessWidget {
  final NandogamiItem item;
  const DetailScreen({super.key, required this.item});

  @override
  Widget build(BuildContext context) {
    final currentUid = FirebaseAuth.instance.currentUser?.uid;
    final favService = FavoriteService();
    final statusService = ReadingStatusService();

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
                  onPressed: () async {
                    final uri = Uri(
                      scheme: 'https',
                      host: 'nandogami.app',
                      path: '/title/${item.id}',
                    );
                    // Use share_plus
                    await Share.share('Check this out: $uri');
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
                    if (currentUid != null)
                      Positioned(
                        right: 16,
                        bottom: 16,
                        child: StreamBuilder<bool>(
                          stream: favService.isFavoriteStream(
                            userId: currentUid,
                            titleId: item.id,
                          ),
                          builder: (context, snap) {
                            final isFav = snap.data ?? false;
                            return Material(
                              color: Colors.black.withValues(alpha: 0.45),
                              shape: const CircleBorder(),
                              clipBehavior: Clip.antiAlias,
                              child: IconButton(
                                iconSize: 28,
                                color: isFav ? Colors.pinkAccent : Colors.white,
                                icon: Icon(
                                  isFav
                                      ? Icons.favorite
                                      : Icons.favorite_border,
                                ),
                                onPressed: () => favService.toggleFavorite(
                                  userId: currentUid,
                                  titleId: item.id,
                                ),
                              ),
                            );
                          },
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
          body: TabBarView(
            children: [
              _AboutTab(
                item: item,
                uid: currentUid,
                statusService: statusService,
              ),
              const _WhereToReadTab(),
              _CommentsTab(titleId: item.id),
            ],
          ),
        ),
      ),
    );
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
                (item.rating ?? 0).toStringAsFixed(1),
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

  String _resolveSynopsis(NandogamiItem item) {
    final synopsis = item.synopsis;
    if (synopsis != null && synopsis.trim().isNotEmpty) {
      return synopsis;
    }
    return item.description;
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
                  onSubmitted: (_) => _post(uid),
                ),
              ),
              const SizedBox(width: 8),
              FilledButton(
                onPressed: () => _post(uid),
                style: FilledButton.styleFrom(
                  backgroundColor: AppColors.purpleAccent,
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
                return const Center(
                  child: Text(
                    'No comments yet',
                    style: TextStyle(color: AppColors.whiteSecondary),
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
    if (uid == null) return;
    final text = _c.text.trim();
    if (text.isEmpty) return;
    final user = FirebaseAuth.instance.currentUser;
    await _svc.addComment(
      titleId: widget.titleId,
      userId: uid,
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
        color: const Color(0xFF1E232B),
        borderRadius: BorderRadius.circular(10),
      ),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 12,
          vertical: 12,
        ),
        leading: CircleAvatar(
          backgroundColor: AppColors.purpleAccent.withValues(alpha: 0.2),
          backgroundImage:
              (model.userAvatar != null && model.userAvatar!.isNotEmpty)
              ? NetworkImage(model.userAvatar!)
              : null,
          child: (model.userAvatar == null || model.userAvatar!.isEmpty)
              ? Text(
                  _initials(model.userName),
                  style: const TextStyle(color: AppColors.white),
                )
              : null,
        ),
        title: Text(
          model.userName ?? 'Anon',
          style: const TextStyle(
            color: AppColors.white,
            fontWeight: FontWeight.w600,
          ),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 4),
            if (model.text.isNotEmpty)
              Text(model.text, style: const TextStyle(color: AppColors.white)),
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
              style: const TextStyle(
                color: AppColors.whiteSecondary,
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
                    color: liked ? Colors.pinkAccent : AppColors.whiteSecondary,
                    onPressed: () => liked
                        ? svc.unlike(commentId: model.id, userId: uid!)
                        : svc.like(commentId: model.id, userId: uid!),
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
                          'plan',
                          'Plan to Read',
                          const Color(0xFF2563EB),
                          current,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: _statusBtn(
                          'reading',
                          'Reading',
                          const Color(0xFF16A34A),
                          current,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: _statusBtn(
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
                          'dropped',
                          'Dropped',
                          const Color(0xFFDC2626),
                          current,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: _statusBtn(
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

  Widget _statusBtn(String value, String text, Color color, String? current) {
    return SizedBox(
      height: 40,
      child: FilledButton(
        onPressed: () => statusService.setStatus(
          userId: uid,
          titleId: titleId,
          status: value,
        ),
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
