import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:provider/provider.dart';
import '../../core/constants.dart';
import '../../data/models/nandogami_item.dart';
import '../../data/services/favorite_service.dart';
import '../../state/item_provider.dart';
import 'detail_screen.dart';

class RecommendationsScreen extends StatelessWidget {
  const RecommendationsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    final favs = FavoriteService();
    final prov = context.watch<ItemProvider>();
    return Scaffold(
      appBar: AppBar(
        title: const Text('User Recommendations'),
        backgroundColor: AppColors.black,
        foregroundColor: AppColors.white,
        actions: [
          IconButton(
            onPressed: () => _openSelector(context),
            icon: const Icon(Icons.person_add, color: AppColors.white),
          ),
        ],
      ),
      backgroundColor: AppColors.black,
      body: uid == null
          ? const Center(
              child: Text('Login required', style: TextStyle(color: AppColors.white)),
            )
          : StreamBuilder<List<String>>( 
              stream: favs.watchFavorites(uid),
              builder: (context, snap) {
                final myFavIds = snap.data ?? const <String>[];
                // naive recs: pick items that share categories with my favorites
                final myFavItems = myFavIds
                    .map((id) => prov.findById(id))
                    .whereType<NandogamiItem>()
                    .toList();
                final myCats = <String>{
                  for (final it in myFavItems)
                    ...((it.categories ?? const <String>[]))
                };
                final candidates = prov.items.where((e) {
                  if (myFavIds.contains(e.id)) return false; // exclude already fav
                  final cats = e.categories ?? const <String>[];
                  return cats.any((c) => myCats.contains(c));
                }).toList();
                if (candidates.isEmpty) {
                  return const Center(
                    child: Text(
                      'No recommendations yet',
                      style: TextStyle(color: AppColors.whiteSecondary),
                    ),
                  );
                }
                return ListView.separated(
                  padding: const EdgeInsets.all(12),
                  itemCount: candidates.length,
                  separatorBuilder: (_, __) => const SizedBox(height: 8),
                  itemBuilder: (context, i) {
                    final it = candidates[i];
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
                          style: const TextStyle(color: AppColors.white),
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
            ),
    );
  }

  void _openSelector(BuildContext context) {
    showModalBottomSheet(
      context: context,
      backgroundColor: const Color(0xFF0E0F12),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.all(Radius.circular(16)),
      ),
      builder: (_) => const _UserSelectorSheet(),
    );
  }
}

class _UserSelectorSheet extends StatelessWidget {
  const _UserSelectorSheet();

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      top: false,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Select Users',
              style: TextStyle(
                color: AppColors.white,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 12),
            SizedBox(
              height: 260,
              child: ListView.separated(
                itemCount: 12,
                separatorBuilder: (_, __) =>
                    const Divider(height: 1, color: Color(0xFF22252B)),
                itemBuilder: (context, i) => CheckboxListTile(
                  value: false,
                  onChanged: (_) {},
                  controlAffinity: ListTileControlAffinity.leading,
                  title: Text(
                    'User $i',
                    style: const TextStyle(color: AppColors.white),
                  ),
                  secondary: const CircleAvatar(child: Icon(Icons.person)),
                ),
              ),
            ),
            const SizedBox(height: 12),
            SizedBox(
              width: double.infinity,
              height: 46,
              child: FilledButton(
                onPressed: () => Navigator.pop(context),
                style: FilledButton.styleFrom(
                  backgroundColor: AppColors.purpleAccent,
                ),
                child: const Text('Apply Selection'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
