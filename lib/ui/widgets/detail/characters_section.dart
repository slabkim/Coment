import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import '../../../core/constants.dart';
import '../../../data/models/manga.dart';

/// Widget for displaying characters with lazy loading support.
class CharactersSection extends StatelessWidget {
  final bool loading;
  final List<MangaCharacter>? characters;

  const CharactersSection({
    super.key,
    required this.loading,
    this.characters,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context).textTheme;
    
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Characters',
          style: theme.titleMedium?.copyWith(color: Theme.of(context).colorScheme.onSurface),
        ),
        const SizedBox(height: 12),
        if (loading)
          const Center(
            child: CircularProgressIndicator(),
          )
        else if (characters?.isNotEmpty == true)
          SizedBox(
            height: 120,
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              itemCount: characters!.length,
              itemBuilder: (context, index) {
                final character = characters![index];
                return Container(
                  width: 80,
                  margin: const EdgeInsets.only(right: 12),
                  child: Column(
                    children: [
                      ClipRRect(
                        borderRadius: BorderRadius.circular(8),
                        child: CachedNetworkImage(
                          imageUrl: character.character.image ?? '',
                          width: 60,
                          height: 60,
                          fit: BoxFit.cover,
                          placeholder: (context, url) => Container(
                            width: 60,
                            height: 60,
                            color: AppColors.grayDark,
                            child: const Icon(Icons.person, color: AppColors.whiteSecondary),
                          ),
                          errorWidget: (context, url, error) => Container(
                            width: 60,
                            height: 60,
                            color: AppColors.grayDark,
                            child: const Icon(Icons.person, color: AppColors.whiteSecondary),
                          ),
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        character.character.name,
                        style: TextStyle(
                          color: Theme.of(context).colorScheme.onSurface,
                          fontSize: 10,
                        ),
                        textAlign: TextAlign.center,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                      Text(
                        character.role,
                        style: TextStyle(
                          color: Theme.of(context).colorScheme.onSurfaceVariant,
                          fontSize: 8,
                        ),
                        textAlign: TextAlign.center,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                );
              },
            ),
          )
        else if (characters?.isEmpty == true)
          const Text(
            'No characters available',
            style: TextStyle(color: AppColors.whiteSecondary),
          ),
      ],
    );
  }
}
