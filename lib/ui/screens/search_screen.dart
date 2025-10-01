import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/constants.dart';
import '../../state/item_provider.dart';
import '../../data/services/search_service.dart';

class SearchScreen extends StatefulWidget {
  const SearchScreen({super.key});

  @override
  State<SearchScreen> createState() => _SearchScreenState();
}

class _SearchScreenState extends State<SearchScreen> {
  final _c = TextEditingController();
  final _svc = SearchService();
  List<String> _recent = const [];

  @override
  void initState() {
    super.initState();
    _loadRecent();
  }

  Future<void> _loadRecent() async {
    _recent = await _svc.getRecent();
    if (mounted) setState(() {});
  }

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final prov = context.watch<ItemProvider>();
    return Scaffold(
      appBar: AppBar(
        title: TextField(
          controller: _c,
          style: const TextStyle(color: Colors.white),
          decoration: const InputDecoration(
            hintText: 'Search titles, tags...',
            hintStyle: TextStyle(color: AppColors.whiteSecondary),
            border: InputBorder.none,
          ),
          onChanged: (v) => prov.search(v),
          onSubmitted: (v) async {
            await _svc.pushRecent(v);
            _loadRecent();
          },
        ),
        backgroundColor: AppColors.black,
        foregroundColor: AppColors.white,
        actions: [
          IconButton(
            onPressed: () {
              _c.clear();
              prov.search('');
            },
            icon: const Icon(Icons.clear),
          ),
        ],
      ),
      backgroundColor: AppColors.black,
      body: prov.query.isEmpty
          ? _RecentAndSuggestions(
              recent: _recent,
              onTap: (q) {
                _c.text = q;
                prov.search(q);
              },
            )
          : _SearchResults(),
    );
  }
}

class _RecentAndSuggestions extends StatelessWidget {
  final List<String> recent;
  final void Function(String) onTap;
  const _RecentAndSuggestions({required this.recent, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        if (recent.isNotEmpty) ...[
          const Text(
            'Recent searches',
            style: TextStyle(
              color: AppColors.white,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            runSpacing: -6,
            children: recent
                .map(
                  (e) => ActionChip(
                    label: Text(e),
                    onPressed: () => onTap(e),
                    backgroundColor: const Color(0xFF2A2E35),
                    labelStyle: const TextStyle(color: AppColors.white),
                  ),
                )
                .toList(),
          ),
          const SizedBox(height: 16),
        ],
        const Text(
          'Popular tags',
          style: TextStyle(color: AppColors.white, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 8),
        Wrap(
          spacing: 8,
          runSpacing: -6,
          children: const [
            _TagChip('Action'),
            _TagChip('Romance'),
            _TagChip('Fantasy'),
            _TagChip('Comedy'),
            _TagChip('Isekai'),
            _TagChip('Slice of Life'),
          ],
        ),
      ],
    );
  }
}

class _TagChip extends StatelessWidget {
  final String text;
  const _TagChip(this.text);
  @override
  Widget build(BuildContext context) {
    return ActionChip(
      label: Text(text),
      onPressed: () => context.read<ItemProvider>().search(text),
      backgroundColor: const Color(0xFF2A2E35),
      labelStyle: const TextStyle(color: AppColors.white),
    );
  }
}

class _SearchResults extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final prov = context.watch<ItemProvider>();
    final items = prov.items;
    if (items.isEmpty) {
      return const Center(
        child: Text(
          'No results',
          style: TextStyle(color: AppColors.whiteSecondary),
        ),
      );
    }
    return ListView.separated(
      padding: const EdgeInsets.all(16),
      itemCount: items.length,
      separatorBuilder: (_, __) => const SizedBox(height: 8),
      itemBuilder: (context, i) {
        final it = items[i];
        return ListTile(
          leading: ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: Image.network(
              it.imageUrl,
              width: 56,
              height: 56,
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
          onTap: () {
            // optional: open detail directly
          },
        );
      },
    );
  }
}
