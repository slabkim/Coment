import 'package:flutter/material.dart';
import '../../core/constants.dart';
import '../../data/services/simple_anilist_service.dart';

class CategoriesSection extends StatefulWidget {
  final Function(List<String>) onGenreSelected;
  final List<String> selectedGenres;

  const CategoriesSection({
    super.key,
    required this.onGenreSelected,
    this.selectedGenres = const [],
  });

  @override
  State<CategoriesSection> createState() => _CategoriesSectionState();
}

class _CategoriesSectionState extends State<CategoriesSection> {
  final SimpleAniListService _mangaService = SimpleAniListService();
  List<String> _genres = [];
  bool _loading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _loadGenres();
  }

  Future<void> _loadGenres() async {
    setState(() {
      _loading = true;
      _error = null;
    });

    try {
      final genres = await _mangaService.getAvailableGenres();
      setState(() {
        _genres = genres;
        _loading = false;
      });
    } catch (e) {
      setState(() {
        _error = e.toString();
        _loading = false;
      });
    }
  }

  void _toggleGenre(String genre) {
    setState(() {
      if (widget.selectedGenres.contains(genre)) {
        widget.onGenreSelected(
          widget.selectedGenres.where((g) => g != genre).toList(),
        );
      } else {
        widget.onGenreSelected([...widget.selectedGenres, genre]);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return const Center(
        child: CircularProgressIndicator(
          color: AppColors.purpleAccent,
        ),
      );
    }

    if (_error != null) {
      return Center(
        child: Column(
          children: [
            Text(
              'Failed to load genres: $_error',
              style: const TextStyle(color: AppColors.red),
            ),
            const SizedBox(height: 8),
            ElevatedButton(
              onPressed: _loadGenres,
              child: const Text('Retry'),
            ),
          ],
        ),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          child: Text(
            'Categories',
            style: TextStyle(
              color: Theme.of(context).colorScheme.onSurface,
              fontSize: 20,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
        const SizedBox(height: 8),
        SizedBox(
          height: 40,
          child: ListView.builder(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 16),
            itemCount: _genres.length,
            itemBuilder: (context, index) {
              final genre = _genres[index];
              return Padding(
                padding: const EdgeInsets.only(right: 8),
                child: _buildGenreChip(genre),
              );
            },
          ),
        ),
        const SizedBox(height: 16),
      ],
    );
  }

  Widget _buildGenreChip(String genre) {
    final isSelected = widget.selectedGenres.contains(genre);
    
    return GestureDetector(
      onTap: () => _toggleGenre(genre),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          color: isSelected 
              ? Theme.of(context).colorScheme.primary
              : Theme.of(context).colorScheme.surfaceContainerHighest,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: isSelected 
                ? Theme.of(context).colorScheme.primary
                : Theme.of(context).colorScheme.outline,
            width: 1,
          ),
        ),
        child: Text(
          genre,
          style: TextStyle(
            color: isSelected 
                ? Colors.white
                : Theme.of(context).colorScheme.onSurface,
            fontSize: 14,
            fontWeight: isSelected 
                ? FontWeight.w600 
                : FontWeight.normal,
          ),
        ),
      ),
    );
  }
}
