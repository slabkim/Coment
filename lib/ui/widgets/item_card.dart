import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import '../../data/models/nandogami_item.dart';

class ItemCard extends StatelessWidget {
  final NandogamiItem item;
  final VoidCallback onTap;
  final bool isFavorite;
  final VoidCallback onFavTap;
  final bool isHorizontal;

  const ItemCard({
    super.key,
    required this.item,
    required this.onTap,
    required this.isFavorite,
    required this.onFavTap,
    this.isHorizontal = false,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: isHorizontal ? 150 : null,
      margin: isHorizontal
          ? const EdgeInsets.symmetric(horizontal: 8, vertical: 4)
          : const EdgeInsets.symmetric(vertical: 8),
      child: Card(
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: onTap,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              AspectRatio(
                aspectRatio: 3 / 2,
                child: CachedNetworkImage(
                  imageUrl: item.imageUrl,
                  fit: BoxFit.cover,
                  placeholder: (c, _) =>
                      const Center(child: CircularProgressIndicator()),
                  errorWidget: (c, _, __) => const Icon(Icons.broken_image),
                ),
              ),
              ListTile(
                title: Text(
                  item.title,
                  style: TextStyle(fontSize: isHorizontal ? 14 : null),
                ),
                subtitle: isHorizontal
                    ? null
                    : Text(
                        item.description,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                trailing: IconButton(
                  icon: Icon(
                    isFavorite ? Icons.favorite : Icons.favorite_border,
                  ),
                  onPressed: onFavTap,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
