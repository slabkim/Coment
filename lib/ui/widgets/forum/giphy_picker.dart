import 'package:flutter/material.dart';
import '../../../core/logger.dart';
import '../../../data/services/giphy_service.dart';

/// Widget for selecting GIFs from Giphy.
/// Provides a modal bottom sheet with search functionality.
class GiphyPicker extends StatefulWidget {
  final GiphyService giphy;
  
  const GiphyPicker({super.key, required this.giphy});

  @override
  State<GiphyPicker> createState() => _GiphyPickerState();
}

class _GiphyPickerState extends State<GiphyPicker> {
  final _queryController = TextEditingController(text: 'anime');
  List<String> _results = const [];
  bool _loading = false;

  @override
  void initState() {
    super.initState();
    // Auto-search with default query on init
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _search();
    });
  }

  @override
  void dispose() {
    _queryController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isLight = Theme.of(context).brightness == Brightness.light;
    
    return SafeArea(
      top: false,
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _queryController,
                    style: TextStyle(
                      color: isLight ? Colors.black87 : Colors.white,
                    ),
                    decoration: InputDecoration(
                      hintText: 'Search GIFs',
                      hintStyle: TextStyle(
                        color: Theme.of(context).colorScheme.onSurfaceVariant,
                      ),
                      filled: true,
                      fillColor: isLight
                          ? Colors.grey[200]
                          : const Color(0xFF121316),
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 10,
                      ),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(10),
                        borderSide: BorderSide.none,
                      ),
                    ),
                    onSubmitted: (_) => _search(),
                  ),
                ),
                const SizedBox(width: 8),
                FilledButton(
                  onPressed: _loading ? null : _search,
                  style: FilledButton.styleFrom(
                    backgroundColor: isLight
                        ? const Color(0xFF3B82F6)
                        : Theme.of(context).colorScheme.primary,
                  ),
                  child: _loading
                      ? const SizedBox(
                          width: 16,
                          height: 16,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Icon(Icons.search),
                ),
              ],
            ),
            const SizedBox(height: 12),
            SizedBox(
              height: 300,
              child: _loading
                  ? const Center(child: CircularProgressIndicator())
                  : _results.isEmpty
                      ? _buildEmptyState()
                      : _buildGifGrid(),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.gif_box_outlined,
            size: 64,
            color: Theme.of(context).colorScheme.onSurfaceVariant,
          ),
          const SizedBox(height: 16),
          Text(
            'No GIFs found',
            style: TextStyle(
              color: Theme.of(context).colorScheme.onSurfaceVariant,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildGifGrid() {
    return GridView.builder(
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 3,
        mainAxisSpacing: 6,
        crossAxisSpacing: 6,
      ),
      itemCount: _results.length,
      itemBuilder: (context, index) => GestureDetector(
        onTap: () => Navigator.pop(context, _results[index]),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(8),
          child: Image.network(
            _results[index],
            fit: BoxFit.cover,
            errorBuilder: (context, error, stackTrace) => Container(
              color: const Color(0xFF121316),
              child: const Icon(Icons.error),
            ),
          ),
        ),
      ),
    );
  }

  Future<void> _search() async {
    setState(() => _loading = true);
    try {
      final query = _queryController.text.trim().isEmpty 
          ? 'anime' 
          : _queryController.text.trim();
      final res = await widget.giphy.searchGifs(query: query);
      setState(() => _results = res);
    } catch (e, stackTrace) {
      AppLogger.apiError('searching GIFs', e, stackTrace);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error loading GIFs: $e')),
        );
      }
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }
}

