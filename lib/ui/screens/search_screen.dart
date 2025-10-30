import 'dart:async';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/constants.dart';
import '../../core/auth_helper.dart';
import '../../state/item_provider.dart';
import '../../data/services/search_service.dart';
import '../../data/services/user_service.dart';
import '../../data/models/user_profile.dart';
import '../widgets/common.dart';
import 'user_public_profile_screen.dart';
import 'detail_screen.dart';

class SearchScreen extends StatefulWidget {
  const SearchScreen({super.key});

  @override
  State<SearchScreen> createState() => _SearchScreenState();
}

class _SearchScreenState extends State<SearchScreen> {
  final _c = TextEditingController();
  final _svc = SearchService();
  List<String> _recent = const [];
  Timer? _debounceTimer;

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
    _debounceTimer?.cancel();
    _c.dispose();
    super.dispose();
  }
  
  void _onSearchChanged(String value) {
    // Cancel previous timer
    _debounceTimer?.cancel();
    
    // Update UI immediately for clear button
    setState(() {});
    
    // Debounce search API call
    _debounceTimer = Timer(const Duration(milliseconds: 500), () {
      final prov = Provider.of<ItemProvider>(context, listen: false);
      prov.search(value);
    });
  }

  @override
  Widget build(BuildContext context) {
    final prov = context.watch<ItemProvider>();
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Theme.of(context).scaffoldBackgroundColor,
        elevation: 0,
        centerTitle: true,
        title: Container(
          margin: const EdgeInsets.symmetric(horizontal: 16),
          decoration: BoxDecoration(
            color: Theme.of(context).colorScheme.surfaceContainerHighest,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: Theme.of(context).colorScheme.outline,
              width: 1,
            ),
          ),
          child: TextField(
            controller: _c,
            style: TextStyle(color: Theme.of(context).colorScheme.onSurface),
            decoration: InputDecoration(
              hintText: 'Search manga, authors, genres...',
              hintStyle: TextStyle(
                color: Theme.of(context).colorScheme.onSurfaceVariant,
              ),
              border: InputBorder.none,
              contentPadding: const EdgeInsets.symmetric(
                horizontal: 16,
                vertical: 12,
              ),
              prefixIcon: Icon(
                Icons.search,
                color: Theme.of(context).colorScheme.onSurfaceVariant,
                size: 20,
              ),
              suffixIcon: _c.text.isNotEmpty
                  ? IconButton(
                      icon: Icon(
                        Icons.clear,
                        color: Theme.of(context).colorScheme.onSurfaceVariant,
                        size: 20,
                      ),
                      onPressed: () {
                        _debounceTimer?.cancel();
                        _c.clear();
                        prov.search('');
                        setState(() {});
                      },
                    )
                  : null,
            ),
            onChanged: _onSearchChanged,
            onSubmitted: (v) async {
              // Cancel debounce and search immediately on submit
              _debounceTimer?.cancel();
              final prov = Provider.of<ItemProvider>(context, listen: false);
              prov.search(v);
              await _svc.pushRecent(v);
              _loadRecent();
            },
          ),
        ),
      ),
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      body: prov.query.isEmpty
          ? _RecentAndSuggestions(
              recent: _recent,
              onTap: (q) {
                _c.text = q;
                prov.search(q);
              },
            )
          : (_c.text.trim().startsWith('@')
                ? _UserResults(_c.text.trim().substring(1))
                : _SearchResults()),
    );
  }
}

class _RecentAndSuggestions extends StatelessWidget {
  final List<String> recent;
  final void Function(String) onTap;
  const _RecentAndSuggestions({required this.recent, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final prov = context.watch<ItemProvider>();
    final trending = prov.getPopular.take(6).toList();
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        if (recent.isNotEmpty) ...[
          Text(
            'Recent searches',
            style: TextStyle(
              color: Theme.of(context).colorScheme.onSurface,
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
                    backgroundColor: Theme.of(
                      context,
                    ).colorScheme.surfaceContainerHighest,
                    labelStyle: TextStyle(
                      color: Theme.of(context).colorScheme.onSurface,
                    ),
                  ),
                )
                .toList(),
          ),
          const SizedBox(height: 16),
        ],
        const SectionTitle('Trending titles'),
        const SizedBox(height: 8),
        SizedBox(
          height: 180,
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            itemCount: trending.length,
            separatorBuilder: (_, __) => const SizedBox(width: 12),
            itemBuilder: (context, i) {
              final it = trending[i];
              return SizedBox(
                width: 220,
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(12),
                  child: Stack(
                    fit: StackFit.expand,
                    children: [
                      Image.network(it.imageUrl, fit: BoxFit.cover),
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
                            fontWeight: FontWeight.bold,
                            shadows: [
                              Shadow(blurRadius: 4, color: Colors.black87),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
        ),
        const SizedBox(height: 16),
        Text(
          'Popular tags',
          style: Theme.of(
            context,
          ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
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
      backgroundColor: Theme.of(context).colorScheme.surfaceContainerHighest,
      labelStyle: TextStyle(color: Theme.of(context).colorScheme.onSurface),
    );
  }
}

class _SearchResults extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final prov = context.watch<ItemProvider>();
    final items = prov.items;
    final isLoading = prov.isLoading;
    
    // Show loading animation while searching
    if (isLoading) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const CircularProgressIndicator(
              strokeWidth: 3,
            ),
            const SizedBox(height: 20),
            Text(
              'Searching...',
              style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                color: Theme.of(context).colorScheme.onSurfaceVariant,
                fontWeight: FontWeight.w500,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Please wait',
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: Theme.of(context).colorScheme.onSurfaceVariant.withValues(alpha: 0.7),
              ),
            ),
          ],
        ),
      );
    }
    
    // Show empty state only after loading is done
    if (items.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.search_off,
              size: 80,
              color: Theme.of(context).colorScheme.onSurfaceVariant.withValues(alpha: 0.5),
            ),
            const SizedBox(height: 16),
            Text(
              'No results found',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                color: Theme.of(context).colorScheme.onSurface,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 8),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 48),
              child: Text(
                'Try different keywords or check your spelling',
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                ),
              ),
            ),
          ],
        ),
      );
    }
    
    // Show results
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
              errorBuilder: (_, __, ___) => Container(
                width: 56,
                height: 56,
                color: Theme.of(context).colorScheme.surfaceContainerHighest,
                child: Icon(
                  Icons.broken_image,
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                ),
              ),
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
            style: Theme.of(context).textTheme.bodyMedium,
          ),
          onTap: () {
            Navigator.of(
              context,
            ).push(MaterialPageRoute(builder: (_) => DetailScreen(item: it)));
          },
        );
      },
    );
  }
}

// Optional: user search when query starts with '@'
class _UserResults extends StatelessWidget {
  final String query;
  const _UserResults(this.query);

  @override
  Widget build(BuildContext context) {
    final userSvc = UserService();
    return StreamBuilder<List<UserProfile>>(
      stream: userSvc.searchUsers(query),
      builder: (context, snapshot) {
        // Show loading animation while searching users
        if (snapshot.connectionState == ConnectionState.waiting) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const CircularProgressIndicator(
                  strokeWidth: 3,
                ),
                const SizedBox(height: 20),
                Text(
                  'Searching users...',
                  style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'Please wait',
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: Theme.of(context).colorScheme.onSurfaceVariant.withValues(alpha: 0.7),
                  ),
                ),
              ],
            ),
          );
        }
        
        final users = snapshot.data ?? const [];
        
        // Show empty state only after loading is done
        if (users.isEmpty) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.person_search,
                  size: 80,
                  color: Theme.of(context).colorScheme.onSurfaceVariant.withValues(alpha: 0.5),
                ),
                const SizedBox(height: 16),
                Text(
                  'No users found',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    color: Theme.of(context).colorScheme.onSurface,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 8),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 48),
                  child: Text(
                    'Try searching with @username or @handle',
                    textAlign: TextAlign.center,
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: Theme.of(context).colorScheme.onSurfaceVariant,
                    ),
                  ),
                ),
              ],
            ),
          );
        }
        
        // Show user results
        return ListView.separated(
          padding: const EdgeInsets.all(16),
          itemCount: users.length,
          separatorBuilder: (_, __) => const SizedBox(height: 8),
          itemBuilder: (context, i) {
            final u = users[i];
            return ListTile(
              leading: CircleAvatar(
                backgroundColor: AppColors.purpleAccent.withValues(alpha: 0.2),
                backgroundImage: (u.photoUrl != null && u.photoUrl!.isNotEmpty)
                    ? NetworkImage(u.photoUrl!)
                    : null,
                child: (u.photoUrl == null || u.photoUrl!.isEmpty)
                    ? Icon(Icons.person, color: AppColors.purpleAccent)
                    : null,
              ),
              title: Text(
                u.username ?? u.handle ?? 'User',
                style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                  fontWeight: FontWeight.w600,
                ),
              ),
              subtitle: Text(
                (u.handle ?? u.email ?? ''),
                style: Theme.of(context).textTheme.bodyMedium,
              ),
              onTap: () async {
                final success = await AuthHelper.requireAuthWithDialog(
                  context,
                  'view user profile',
                );
                if (success) {
                  Navigator.of(context).push(
                    MaterialPageRoute(
                      builder: (_) => UserPublicProfileScreen(userId: u.id),
                    ),
                  );
                }
              },
            );
          },
        );
      },
    );
  }
}
