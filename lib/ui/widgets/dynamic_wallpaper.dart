import 'package:flutter/material.dart';
import '../../core/constants.dart';

class DynamicWallpaper extends StatelessWidget {
  final List<String> genres;
  final String mood;
  final Widget child;
  final double opacity;

  const DynamicWallpaper({
    super.key,
    required this.genres,
    required this.child,
    this.mood = 'happy',
    this.opacity = 0.3,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        gradient: _getGradientForGenres(genres),
      ),
      child: Stack(
        children: [
          // Dark overlay for better text readability
          Positioned.fill(
            child: Container(
              color: Colors.black.withValues(alpha: opacity),
            ),
          ),
          
          // Content
          child,
        ],
      ),
    );
  }

  /// Generate gradient based on genres
  LinearGradient _getGradientForGenres(List<String> genres) {
    if (genres.isEmpty) {
      return const LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: [
          AppColors.black,
          Color(0xFF1a1a1a),
        ],
      );
    }

    // Map genres to gradient colors
    final genreColors = {
      'Action': [const Color(0xFF2D1B69), const Color(0xFF11998E)],
      'Romance': [const Color(0xFFFF6B6B), const Color(0xFFFFE66D)],
      'Comedy': [const Color(0xFF4ECDC4), const Color(0xFF44A08D)],
      'Drama': [const Color(0xFF667eea), const Color(0xFF764ba2)],
      'Fantasy': [const Color(0xFFf093fb), const Color(0xFFf5576c)],
      'Horror': [const Color(0xFF2C3E50), const Color(0xFF34495E)],
      'Sci-Fi': [const Color(0xFF00c6ff), const Color(0xFF0072ff)],
    };

    // Get colors for the first genre, fallback to default
    final colors = genreColors[genres.first] ?? [AppColors.black, const Color(0xFF1a1a1a)];

    return LinearGradient(
      begin: Alignment.topLeft,
      end: Alignment.bottomRight,
      colors: colors,
    );
  }
}

class GenreWallpaperCard extends StatelessWidget {
  final String genre;
  final VoidCallback? onTap;

  const GenreWallpaperCard({
    super.key,
    required this.genre,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        height: 120,
        width: 200,
        margin: const EdgeInsets.only(right: 12),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(12),
          gradient: _getGradientForGenre(genre),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.3),
              blurRadius: 8,
            ),
          ],
        ),
        child: Stack(
          children: [
            // Gradient overlay
            Positioned.fill(
              child: Container(
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(12),
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [
                      Colors.transparent,
                      Colors.black.withValues(alpha: 0.7),
                    ],
                  ),
                ),
              ),
            ),
            // Genre text
            Positioned(
              bottom: 12,
              left: 12,
              right: 12,
              child: Text(
                genre,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  shadows: [
                    Shadow(
                      color: Colors.black,
                      blurRadius: 4,
                    ),
                  ],
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// Generate gradient for specific genre
  LinearGradient _getGradientForGenre(String genre) {
    final genreColors = {
      'Action': [const Color(0xFF2D1B69), const Color(0xFF11998E)],
      'Romance': [const Color(0xFFFF6B6B), const Color(0xFFFFE66D)],
      'Comedy': [const Color(0xFF4ECDC4), const Color(0xFF44A08D)],
      'Drama': [const Color(0xFF667eea), const Color(0xFF764ba2)],
      'Fantasy': [const Color(0xFFf093fb), const Color(0xFFf5576c)],
      'Horror': [const Color(0xFF2C3E50), const Color(0xFF34495E)],
      'Sci-Fi': [const Color(0xFF00c6ff), const Color(0xFF0072ff)],
    };

    final colors = genreColors[genre] ?? [AppColors.purplePrimary, AppColors.purpleSecondary];

    return LinearGradient(
      begin: Alignment.topLeft,
      end: Alignment.bottomRight,
      colors: colors,
    );
  }
}
