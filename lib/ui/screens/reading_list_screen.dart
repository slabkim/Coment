import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:provider/provider.dart';
import '../../data/services/reading_status_service.dart';
import '../../state/item_provider.dart';
import '../../data/models/nandogami_item.dart';
import 'detail_screen.dart';

class ReadingListScreen extends StatelessWidget {
  const ReadingListScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final tabs = ['Want to Read', 'Reading', 'Completed', 'Dropped', 'Paused'];
    return DefaultTabController(
      length: tabs.length,
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Reading List'),
          backgroundColor: Theme.of(context).appBarTheme.backgroundColor,
          foregroundColor: Theme.of(context).appBarTheme.foregroundColor,
          bottom: TabBar(
            isScrollable: true,
            indicatorColor: Theme.of(context).colorScheme.primary,
            labelColor: Theme.of(context).colorScheme.primary,
            unselectedLabelColor: Theme.of(context).colorScheme.onSurfaceVariant,
            tabs: tabs.map((e) => Tab(text: e)).toList(),
          ),
        ),
        backgroundColor: Theme.of(context).scaffoldBackgroundColor,
        body: TabBarView(
          children: tabs.map((e) => _StatusList(title: e)).toList(),
        ),
      ),
    );
  }
}

class _StatusList extends StatelessWidget {
  final String title;
  const _StatusList({required this.title});

  @override
  Widget build(BuildContext context) {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) {
      return Center(
        child: Text(
          'Login required', 
          style: TextStyle(color: Theme.of(context).colorScheme.onSurface),
        ),
      );
    }
    final svc = ReadingStatusService();
    final prov = context.watch<ItemProvider>();

    final status = _mapTabToStatus(title);
    return StreamBuilder<List<String>>(
      stream: svc.watchTitlesByStatus(userId: uid, status: status),
      builder: (context, snap) {
        final ids = snap.data ?? const <String>[];
        if (ids.isEmpty) {
          return Center(
            child: Text(
              'No titles yet',
              style: TextStyle(color: Theme.of(context).colorScheme.onSurfaceVariant),
            ),
          );
        }
        
        // Use FutureBuilder to handle async fallback
        return FutureBuilder<List<NandogamiItem>>(
          future: _loadItemsWithFallback(ids, prov),
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return Center(
                child: CircularProgressIndicator(
                  color: Theme.of(context).colorScheme.primary,
                ),
              );
            }
            
            final items = snapshot.data ?? [];
            if (items.isEmpty) {
              return Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.library_books_outlined,
                      color: Theme.of(context).colorScheme.onSurfaceVariant,
                      size: 48,
                    ),
                    const SizedBox(height: 16),
                    Text(
                      'No data available',
                      style: TextStyle(color: Theme.of(context).colorScheme.onSurfaceVariant),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Status: $status\nIDs: ${ids.length}',
                      style: TextStyle(
                        color: Theme.of(context).colorScheme.onSurfaceVariant,
                        fontSize: 12,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ],
                ),
              );
            }
            
            return ListView.separated(
              padding: const EdgeInsets.all(12),
              itemCount: items.length,
              separatorBuilder: (_, __) => const SizedBox(height: 8),
              itemBuilder: (context, i) {
                final it = items[i];
                return Container(
                  decoration: BoxDecoration(
                    color: Theme.of(context).colorScheme.surfaceContainerHighest,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: ListTile(
                    leading: ClipRRect(
                      borderRadius: BorderRadius.circular(8),
                      child: Image.network(
                        it.imageUrl,
                        width: 48,
                        height: 48,
                        fit: BoxFit.cover,
                      ),
                    ),
                    title: Text(
                      it.title,
                      style: TextStyle(
                        color: Theme.of(context).colorScheme.onSurface,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    subtitle: Text(
                      (it.categories ?? const []).join(', '),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(color: Theme.of(context).colorScheme.onSurfaceVariant),
                    ),
                    trailing: Icon(
                      Icons.chevron_right,
                      color: Theme.of(context).colorScheme.onSurfaceVariant,
                    ),
                    onTap: () {
                      Navigator.of(context).push(
                        MaterialPageRoute(builder: (_) => DetailScreen(item: it)),
                      );
                    },
                  ),
                );
              },
            );
          },
        );
      },
    );
  }

  Future<List<NandogamiItem>> _loadItemsWithFallback(List<String> ids, ItemProvider prov) async {
    final items = <NandogamiItem>[];
    
    for (final id in ids) {
      final item = await prov.findByIdWithFallback(id);
      if (item != null) {
        items.add(item);
      }
    }
    
    return items;
  }
}

String _mapTabToStatus(String tab) {
  final t = tab.toLowerCase();
  if (t.contains('want')) return 'WANT_TO_READ';
  if (t.contains('reading')) return 'READING';
  if (t.contains('completed')) return 'COMPLETED';
  if (t.contains('dropped')) return 'DROPPED';
  if (t.contains('paused')) return 'PAUSED';
  return 'READING';
}
