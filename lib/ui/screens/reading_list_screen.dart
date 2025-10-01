import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:provider/provider.dart';
import '../../core/constants.dart';
import '../../data/services/reading_status_service.dart';
import '../../state/item_provider.dart';
import '../../data/models/nandogami_item.dart';
import 'detail_screen.dart';

class ReadingListScreen extends StatelessWidget {
  const ReadingListScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final tabs = ['Plan to Read', 'Reading', 'Completed', 'Dropped', 'On Hold'];
    return DefaultTabController(
      length: tabs.length,
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Reading List'),
          backgroundColor: AppColors.black,
          foregroundColor: AppColors.white,
          bottom: TabBar(
            isScrollable: true,
            indicatorColor: AppColors.purpleAccent,
            labelColor: AppColors.purpleAccent,
            unselectedLabelColor: AppColors.whiteSecondary,
            tabs: tabs.map((e) => Tab(text: e)).toList(),
          ),
        ),
        backgroundColor: AppColors.black,
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
      return const Center(
        child: Text('Login required', style: TextStyle(color: AppColors.white)),
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
          return const Center(
            child: Text(
              'No titles yet',
              style: TextStyle(color: AppColors.whiteSecondary),
            ),
          );
        }
        final items = ids
            .map((id) => prov.findById(id))
            .whereType<NandogamiItem>()
            .toList();
        if (items.isEmpty) {
          return const Center(
            child: Text(
              'No data available',
              style: TextStyle(color: AppColors.whiteSecondary),
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
                color: const Color(0xFF1E232B),
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
                  style: const TextStyle(
                    color: AppColors.white,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                subtitle: Text(
                  (it.categories ?? const []).join(', '),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(color: AppColors.whiteSecondary),
                ),
                trailing: const Icon(
                  Icons.chevron_right,
                  color: AppColors.whiteSecondary,
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
  }
}

String _mapTabToStatus(String tab) {
  final t = tab.toLowerCase();
  if (t.contains('plan')) return 'plan';
  if (t.contains('reading')) return 'reading';
  if (t.contains('completed')) return 'completed';
  if (t.contains('dropped')) return 'dropped';
  if (t.contains('hold')) return 'on_hold';
  return 'reading';
}
