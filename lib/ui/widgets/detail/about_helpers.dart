import 'package:flutter/material.dart';
import '../../../core/constants.dart';
import '../../../data/models/nandogami_item.dart';

/// Helper functions for formatting about tab data
class AboutHelpers {
  static String formatStatus(String status) {
    switch (status) {
      case 'FINISHED': return 'Finished';
      case 'RELEASING': return 'Releasing';
      case 'NOT_YET_RELEASED': return 'Not Yet Released';
      case 'CANCELLED': return 'Cancelled';
      case 'HIATUS': return 'Hiatus';
      default: return status;
    }
  }

  static String formatDate(dynamic date) {
    if (date == null) return 'Unknown';
    
    if (date is String) {
      try {
        final parts = date.split('-');
        if (parts.length == 3) {
          return '${parts[2]}/${parts[1]}/${parts[0]}';
        }
        return date;
      } catch (e) {
        return date;
      }
    } else if (date is Map<String, dynamic>) {
      final year = date['year'];
      final month = date['month'];
      final day = date['day'];
      
      if (year != null && month != null && day != null) {
        return '${day.toString().padLeft(2, '0')}/${month.toString().padLeft(2, '0')}/$year';
      } else if (year != null && month != null) {
        return '${month.toString().padLeft(2, '0')}/$year';
      } else if (year != null) {
        return year.toString();
      }
    }
    
    return 'Unknown';
  }

  static String formatFormat(String format) {
    switch (format.toUpperCase()) {
      case 'MANGA':
      case 'MANHWA':
      case 'MANHUA':
        return 'Manga';
      case 'NOVEL':
      case 'LIGHT_NOVEL':
      case 'WEB_NOVEL':
        return 'Novel';
      case 'ONE_SHOT':
        return 'One Shot';
      case 'DOUJINSHI':
        return 'Doujinshi';
      case 'OEL':
        return 'OEL';
      case 'VISUAL_NOVEL':
        return 'Visual Novel';
      case 'GAME':
        return 'Game';
      case 'COMIC':
        return 'Comic';
      case 'PICTURE_BOOK':
        return 'Picture Book';
      default:
        return format;
    }
  }

  static String formatSource(String source) {
    switch (source) {
      case 'ORIGINAL': return 'Original';
      case 'MANGA': return 'Manga';
      case 'LIGHT_NOVEL': return 'Light Novel';
      case 'VISUAL_NOVEL': return 'Visual Novel';
      case 'VIDEO_GAME': return 'Video Game';
      case 'OTHER': return 'Other';
      case 'NOVEL': return 'Novel';
      case 'DOUJINSHI': return 'Doujinshi';
      case 'ANIME': return 'Anime';
      default: return source;
    }
  }

  static String formatRelationType(String relationType) {
    switch (relationType) {
      case 'ADAPTATION': return 'Adaptation';
      case 'PREQUEL': return 'Prequel';
      case 'SEQUEL': return 'Sequel';
      case 'PARENT': return 'Parent';
      case 'SIDE_STORY': return 'Side Story';
      case 'CHARACTER': return 'Character';
      case 'SUMMARY': return 'Summary';
      case 'ALTERNATIVE': return 'Alternative';
      case 'SPIN_OFF': return 'Spin-off';
      case 'OTHER': return 'Other';
      case 'SOURCE': return 'Source';
      case 'COMPILATION': return 'Compilation';
      case 'CONTAINS': return 'Contains';
      default: return relationType;
    }
  }

  static Color getRelationTypeColor(String type) {
    switch (type.toUpperCase()) {
      case 'PREQUEL':
        return AppColors.blueAccent;
      case 'SEQUEL':
        return AppColors.green;
      case 'SIDE_STORY':
        return AppColors.orange;
      case 'ADAPTATION':
        return AppColors.purpleAccent;
      case 'ALTERNATIVE':
        return AppColors.pinkAccent;
      case 'SPIN_OFF':
        return AppColors.yellow;
      case 'CHARACTER':
        return AppColors.red;
      default:
        return AppColors.whiteSecondary;
    }
  }

  static String cleanHtmlTags(String text) {
    if (text.isEmpty) return text;
    
    // Remove HTML tags but preserve line breaks
    String cleaned = text
        .replaceAll(RegExp(r'<br\s*/?>', caseSensitive: false), '\n')
        .replaceAll(RegExp(r'<[^>]*>'), '');
    
    // Decode HTML entities
    cleaned = cleaned
        .replaceAll('&amp;', '&')
        .replaceAll('&lt;', '<')
        .replaceAll('&gt;', '>')
        .replaceAll('&quot;', '"')
        .replaceAll('&#39;', "'")
        .replaceAll('&nbsp;', ' ')
        .replaceAll('&hellip;', '...')
        .replaceAll('&mdash;', '—')
        .replaceAll('&ndash;', '–')
        .replaceAll('&apos;', "'")
        .replaceAll('&rsquo;', "'")
        .replaceAll('&lsquo;', "'")
        .replaceAll('&rdquo;', '"')
        .replaceAll('&ldquo;', '"');
    
    // Clean up extra whitespace but preserve paragraph breaks
    cleaned = cleaned
        .replaceAll(RegExp(r'[ \t]+'), ' ') // Multiple spaces/tabs to single space
        .replaceAll(RegExp(r'\n\s*\n'), '\n\n') // Multiple newlines to double newline
        .replaceAll(RegExp(r'^\s+|\s+$', multiLine: true), '') // Trim each line
        .trim();
    
    return cleaned;
  }

  static String resolveSynopsis(NandogamiItem item) {
    final synopsis = item.synopsis;
    if (synopsis != null && synopsis.trim().isNotEmpty) {
      return cleanHtmlTags(synopsis);
    }
    return cleanHtmlTags(item.description);
  }
}

