import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:share_plus/share_plus.dart';
import 'package:flutter/services.dart';

import '../../core/auth_helper.dart'; 
import '../../data/models/nandogami_item.dart';
import '../../data/services/favorite_service.dart';
import '../../data/services/reading_status_service.dart';
import '../widgets/comic_detail_header.dart';
import '../widgets/about_tab.dart';
import '../widgets/detail/where_to_read_tab.dart';
import '../widgets/detail/comments_tab.dart';

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
              length: 3, // 3 tabs: About, Where to Read, Comments
              child: NestedScrollView(
          headerSliverBuilder: (context, innerBoxIsScrolled) {
            return [
              StreamBuilder<bool>(
                stream: currentUid != null 
                    ? favService.isFavoriteStream(
                        userId: currentUid,
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
                    flexibleSpace: LayoutBuilder(
                      builder: (BuildContext context, BoxConstraints constraints) {
                        // Calculate if AppBar is collapsed
                        final top = constraints.biggest.height;
                        final isCollapsed = top <= kToolbarHeight + MediaQuery.of(context).padding.top;
                        
                        return FlexibleSpaceBar(
                          // Show title when collapsed
                          title: isCollapsed
                              ? Text(
                                  item.title,
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: TextStyle(
                                    color: Theme.of(context).colorScheme.onSurface,
                                    fontSize: 16,
                                    fontWeight: FontWeight.w600,
                                  ),
                                )
                              : null,
                          titlePadding: const EdgeInsets.only(left: 56, right: 56, bottom: 16),
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
                              userId: currentUid,
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
                        );
                      },
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
                    dividerColor: Colors.transparent,
                    dividerHeight: 0,
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
                    AboutTab(
                      item: item,
                      uid: currentUid,
                      statusService: statusService,
                    ),
                    WhereToReadTab(item: item),
                    CommentsTab(titleId: item.id),
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

