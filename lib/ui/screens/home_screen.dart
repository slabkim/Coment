import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/constants.dart'; // AppConst, AppColors
import '../../data/models/nandogami_item.dart';
import '../../state/item_provider.dart';
import 'detail_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  @override
  void initState() {
    super.initState();
    context.read<ItemProvider>().init();
  }

  @override
  Widget build(BuildContext context) {
    final prov = context.watch<ItemProvider>();

    return Scaffold(
      backgroundColor: AppColors.black,
      appBar: AppBar(
        backgroundColor: AppColors.black,
        elevation: 0,
        scrolledUnderElevation: 0,
        titleSpacing: 0,
        title: Padding(
          padding: const EdgeInsets.only(left: 16),
          child: Text(
            AppConst.appName,
            style: const TextStyle(
              color: AppColors.white,
              fontSize: 24,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
        centerTitle: false,
        actions: [
          IconButton(
            tooltip: 'DM',
            icon: const Icon(Icons.send, color: AppColors.white, size: 22),
            onPressed: () {},
          ),
          const SizedBox(width: 4),
          Padding(
            padding: const EdgeInsets.only(right: 16),
            child: CircleAvatar(
              radius: 20,
              backgroundColor: AppColors.white,
              child: const Icon(Icons.person, color: AppColors.black),
            ),
          ),
        ],
      ),
      body: prov.isLoading
          ? const Center(child: CircularProgressIndicator())
          : ScrollConfiguration(
              behavior: const _NoGlowScrollBehavior(),
              child: SingleChildScrollView(
                padding: const EdgeInsets.only(
                  left: 16,
                  right: 16,
                  bottom: 100,
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const SizedBox(height: 16),
                    _SectionTitle('Featured Titles'),
                    const SizedBox(height: 8),
                    _HorizontalStrip(
                      height: 220, // pastikan cukup untuk kartu + radius
                      items: prov.getFeatured,
                      onTap: (it) => _openDetail(context, it),
                      isFavorite: (id) => prov.isFavorite(id),
                      onFavTap: (id) => prov.toggleFavorite(id),
                    ),

                    const SizedBox(height: 24),
                    _SectionTitle('Categories'),
                    const SizedBox(height: 8),
                    _HorizontalStrip(
                      height: 180,
                      items: prov.getCategories,
                      onTap: (it) => _openDetail(context, it),
                      isFavorite: (id) => prov.isFavorite(id),
                      onFavTap: (id) => prov.toggleFavorite(id),
                    ),

                    const SizedBox(height: 24),
                    _SectionTitle('Popular This Week'),
                    const SizedBox(height: 8),
                    _HorizontalStrip(
                      height: 200,
                      items: prov.getPopular,
                      onTap: (it) => _openDetail(context, it),
                      isFavorite: (id) => prov.isFavorite(id),
                      onFavTap: (id) => prov.toggleFavorite(id),
                    ),

                    const SizedBox(height: 24),
                    _SectionTitle('New Releases'),
                    const SizedBox(height: 8),
                    _HorizontalStrip(
                      height: 200,
                      items: prov.getNewReleases,
                      onTap: (it) => _openDetail(context, it),
                      isFavorite: (id) => prov.isFavorite(id),
                      onFavTap: (id) => prov.toggleFavorite(id),
                    ),
                  ],
                ),
              ),
            ),
    );
  }

  void _openDetail(BuildContext context, NandogamiItem it) {
    Navigator.of(
      context,
    ).push(MaterialPageRoute(builder: (_) => DetailScreen(item: it)));
  }
}

/// ===== Section Title (putih, tebal) =====
class _SectionTitle extends StatelessWidget {
  final String text;
  const _SectionTitle(this.text);

  @override
  Widget build(BuildContext context) {
    final base = Theme.of(context).textTheme.titleMedium;
    return Text(
      text,
      style:
          base?.copyWith(color: AppColors.white, fontWeight: FontWeight.bold) ??
          const TextStyle(
            color: AppColors.white,
            fontWeight: FontWeight.bold,
            fontSize: 18,
          ),
    );
  }
}

/// ===== Horizontal Strip yang aman dari overflow =====
/// Memakai kartu khusus `_PosterCard` dengan tinggi tetap dan AspectRatio di dalamnya.
class _HorizontalStrip extends StatelessWidget {
  final double height;
  final List<NandogamiItem> items;
  final void Function(NandogamiItem) onTap;
  final bool Function(String id) isFavorite;
  final void Function(String id) onFavTap;

  const _HorizontalStrip({
    required this.height,
    required this.items,
    required this.onTap,
    required this.isFavorite,
    required this.onFavTap,
  });

  @override
  Widget build(BuildContext context) {
    if (items.isEmpty) {
      return const SizedBox(
        height: 80,
        child: Align(
          alignment: Alignment.centerLeft,
          child: Text(
            'Belum ada item.',
            style: TextStyle(color: Colors.white70),
          ),
        ),
      );
    }

    final screenW = MediaQuery.sizeOf(context).width;
    final cardW =
        (screenW - 16 - 16 - 12) * 0.72; // padding kiri/kanan & separator

    return SizedBox(
      height: height,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        physics: const BouncingScrollPhysics(),
        itemCount: items.length,
        separatorBuilder: (_, __) => const SizedBox(width: 12),
        itemBuilder: (context, i) {
          final it = items[i];
          return SizedBox(
            width: cardW,
            height: height, // penting: jaga tinggi kartu = tinggi strip
            child: _PosterCard(
              item: it,
              onTap: () => onTap(it),
              isFav: isFavorite(it.id),
              onFavTap: () => onFavTap(it.id),
            ),
          );
        },
      ),
    );
  }
}

/// ===== Kartu horizontal aman (no overflow) =====
/// - Seluruh konten masuk dalam kotak dengan tinggi fix.
/// - Gambar pakai AspectRatio(16/9) + overlay teks favorite di dalam,
///   tidak ada widget di luar yang menambah tinggi.
class _PosterCard extends StatelessWidget {
  final NandogamiItem item;
  final VoidCallback onTap;
  final bool isFav;
  final VoidCallback onFavTap;

  const _PosterCard({
    required this.item,
    required this.onTap,
    required this.isFav,
    required this.onFavTap,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      clipBehavior: Clip.antiAlias,
      borderRadius: BorderRadius.circular(16),
      child: InkWell(
        onTap: onTap,
        child: Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            color: const Color(0xFF13161B),
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // Poster image + overlay in one block
              Expanded(
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(16),
                  child: Stack(
                    fit: StackFit.expand,
                    children: [
                      // jaga rasio supaya tak melebihi tinggi parent
                      Center(
                        child: AspectRatio(
                          aspectRatio: 16 / 9,
                          child: Image.network(
                            item.imageUrl,
                            fit: BoxFit.cover,
                            errorBuilder: (_, __, ___) => const ColoredBox(
                              color: Color(0xFF2A2E35),
                              child: Center(
                                child: Icon(
                                  Icons.broken_image,
                                  color: Colors.white54,
                                ),
                              ),
                            ),
                          ),
                        ),
                      ),
                      // gradient bawah
                      const Positioned.fill(
                        child: DecoratedBox(
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              begin: Alignment.center,
                              end: Alignment.bottomCenter,
                              colors: [Colors.transparent, Colors.black54],
                            ),
                          ),
                        ),
                      ),
                      // title + fav
                      Positioned(
                        left: 12,
                        right: 12,
                        bottom: 10,
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.end,
                          children: [
                            Expanded(
                              child: Text(
                                item.title,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontWeight: FontWeight.w700,
                                  fontSize: 16,
                                  shadows: [
                                    Shadow(
                                      blurRadius: 4,
                                      color: Colors.black45,
                                    ),
                                  ],
                                ),
                              ),
                            ),
                            const SizedBox(width: 8),
                            InkWell(
                              onTap: onFavTap,
                              child: Icon(
                                isFav ? Icons.favorite : Icons.favorite_border,
                                color: isFav ? Colors.pinkAccent : Colors.white,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              // optional spacer kecil agar konten tidak terlalu mepet
              const SizedBox(height: 4),
            ],
          ),
        ),
      ),
    );
  }
}

/// ===== Matikan efek glow/overscroll =====
class _NoGlowScrollBehavior extends ScrollBehavior {
  const _NoGlowScrollBehavior();
  @override
  Widget buildViewportChrome(
    BuildContext context,
    Widget child,
    AxisDirection axisDirection,
  ) => child;
  @override
  Widget buildOverscrollIndicator(
    BuildContext context,
    Widget child,
    ScrollableDetails details,
  ) => child;
}
