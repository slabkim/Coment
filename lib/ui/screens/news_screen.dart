import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../core/constants.dart';
import '../../core/auth_helper.dart';
import '../../data/services/anime_news_service.dart';
import '../../data/models/news_article.dart';

class NewsScreen extends StatefulWidget {
  const NewsScreen({super.key});

  @override
  State<NewsScreen> createState() => _NewsScreenState();
}

class _NewsScreenState extends State<NewsScreen> with TickerProviderStateMixin {
  final AnimeNewsService _newsService = AnimeNewsService();
  late TabController _tabController;
  
  List<NewsArticle> _latestNews = [];
  List<NewsArticle> _trendingNews = [];
  bool _loading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _loadNews();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _loadNews() async {
    setState(() {
      _loading = true;
      _error = null;
    });

    try {
      // Latest: Sorted by date
      final latest = await _newsService.getLatestNews(pageSize: 25);
      
      // Trending: Popular anime/manga news
      final trending = await _newsService.getTrendingNews(pageSize: 25);

      if (!mounted) return;
      
      setState(() {
        _latestNews = latest.articles;
        _trendingNews = trending.articles;
        _loading = false;
      });
    } catch (e) {
      // Fallback to sample data if API fails
      if (!mounted) return;
      
      setState(() {
        _latestNews = _getFallbackNews();
        _trendingNews = _getFallbackNews();
        _loading = false;
        _error = 'Tap to retry with real news';
      });
    }
  }

  List<NewsArticle> _getFallbackNews() {
    return [
      NewsArticle(
        title: 'One Piece Manga Reaches 1100 Chapters Milestone',
        description: 'Eiichiro Oda\'s legendary manga series One Piece celebrates another major milestone with its 1100th chapter, continuing to captivate readers worldwide.',
        url: 'https://www.crunchyroll.com',
        urlToImage: 'https://via.placeholder.com/400x200/FF6B6B/FFFFFF?text=One+Piece+News',
        publishedAt: DateTime.now().subtract(const Duration(hours: 2)).toIso8601String(),
        author: 'Crunchyroll News',
        source: 'Crunchyroll',
        content: 'One Piece continues to break records as it reaches its 1100th chapter milestone...',
      ),
      NewsArticle(
        title: 'Attack on Titan Final Season Part 3 Gets New Trailer',
        description: 'The highly anticipated conclusion to Attack on Titan anime series releases new trailer showcasing epic final battles and emotional moments.',
        url: 'https://www.animenewsnetwork.com',
        urlToImage: 'https://via.placeholder.com/400x200/4ECDC4/FFFFFF?text=Attack+on+Titan',
        publishedAt: DateTime.now().subtract(const Duration(hours: 5)).toIso8601String(),
        author: 'Anime News Network',
        source: 'ANN',
        content: 'Attack on Titan fans are in for a treat as the final season approaches...',
      ),
      NewsArticle(
        title: 'Demon Slayer: Kimetsu no Yaiba Manga Sales Surpass 150 Million',
        description: 'Koyoharu Gotouge\'s Demon Slayer manga continues its incredible success, reaching over 150 million copies sold worldwide.',
        url: 'https://mangaplus.shueisha.co.jp',
        urlToImage: 'https://via.placeholder.com/400x200/45B7D1/FFFFFF?text=Demon+Slayer',
        publishedAt: DateTime.now().subtract(const Duration(days: 1)).toIso8601String(),
        author: 'Manga Plus',
        source: 'Manga Plus',
        content: 'Demon Slayer\'s phenomenal success continues with record-breaking sales...',
      ),
      NewsArticle(
        title: 'New Shonen Jump Manga Series Debuts This Week',
        description: 'Weekly Shonen Jump introduces three new manga series, including a promising action-adventure story and a romantic comedy.',
        url: 'https://www.viz.com',
        urlToImage: 'https://via.placeholder.com/400x200/FF9800/FFFFFF?text=Shonen+Jump',
        publishedAt: DateTime.now().subtract(const Duration(days: 2)).toIso8601String(),
        author: 'VIZ Media',
        source: 'VIZ Media',
        content: 'Weekly Shonen Jump continues to bring fresh new stories to readers...',
      ),
      NewsArticle(
        title: 'Studio Ghibli Announces New Film Project',
        description: 'The legendary animation studio reveals details about their upcoming feature film, promising another masterpiece for anime fans.',
        url: 'https://www.ghibli.jp',
        urlToImage: 'https://via.placeholder.com/400x200/9C27B0/FFFFFF?text=Studio+Ghibli',
        publishedAt: DateTime.now().subtract(const Duration(days: 3)).toIso8601String(),
        author: 'Studio Ghibli',
        source: 'Studio Ghibli',
        content: 'Studio Ghibli fans worldwide are excited about the upcoming new film...',
      ),
    ];
  }

  Future<void> _openArticle(NewsArticle article) async {
    // Cek autentikasi dulu
    final success = await AuthHelper.requireAuthWithDialog(
      context, 
      'read this news article'
    );
    if (!success) return;
    
    try {
      // Validate URL format
      if (article.url.isEmpty || !article.url.startsWith('http')) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Invalid URL: ${article.url}'),
            backgroundColor: Theme.of(context).colorScheme.error,
            duration: const Duration(seconds: 3),
          ),
        );
        return;
      }

      final uri = Uri.parse(article.url);
      
      // Try to launch URL
      if (await canLaunchUrl(uri)) {
        try {
          final launched = await launchUrl(
            uri, 
            mode: LaunchMode.platformDefault,
          );
          
          if (!launched) {
            // Try alternative mode
            await launchUrl(
              uri, 
              mode: LaunchMode.externalApplication,
            );
          }
        } catch (e) {
          // If platform default fails, try external application
          try {
            await launchUrl(
              uri, 
              mode: LaunchMode.externalApplication,
            );
          } catch (e2) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text('Could not open: ${article.url}'),
                backgroundColor: Theme.of(context).colorScheme.error,
                duration: const Duration(seconds: 3),
              ),
            );
          }
        }
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Cannot open: ${article.url}'),
            backgroundColor: Theme.of(context).colorScheme.error,
            duration: const Duration(seconds: 3),
          ),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error opening article: $e'),
          backgroundColor: Theme.of(context).colorScheme.error,
          duration: const Duration(seconds: 3),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: AppBar(
        backgroundColor: Theme.of(context).appBarTheme.backgroundColor,
        title: Text(
          'Manga News',
          style: TextStyle(
            color: Theme.of(context).colorScheme.onSurface,
            fontWeight: FontWeight.bold,
          ),
        ),
        bottom: TabBar(
          controller: _tabController,
          labelColor: Theme.of(context).colorScheme.primary,
          unselectedLabelColor: Theme.of(context).colorScheme.onSurfaceVariant,
          indicatorColor: Theme.of(context).colorScheme.primary,
          tabs: const [
            Tab(text: 'Latest News'),
            Tab(text: 'Trending'),
          ],
        ),
      ),
      body: _loading
          ? Center(
              child: CircularProgressIndicator(
                color: Theme.of(context).colorScheme.primary,
              ),
            )
          : _error != null
              ? Column(
                  children: [
                    // Show error banner if using fallback data
                    if (_error!.contains('Using sample data'))
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(12),
                        margin: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: Theme.of(context).colorScheme.errorContainer.withValues(alpha: 0.2),
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(
                            color: Theme.of(context).colorScheme.error.withValues(alpha: 0.5),
                            width: 1,
                          ),
                        ),
                        child: Row(
                          children: [
                            Icon(
                              Icons.warning_amber,
                              color: Theme.of(context).colorScheme.error,
                              size: 20,
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                'Using sample data. Tap to retry with real news.',
                                style: TextStyle(
                                  color: Theme.of(context).colorScheme.error,
                                  fontSize: 14,
                                ),
                              ),
                            ),
                            TextButton(
                              onPressed: _loadNews,
                              child: Text(
                                'Retry',
                                style: TextStyle(color: Theme.of(context).colorScheme.error),
                              ),
                            ),
                          ],
                        ),
                      ),
                    // Show news content
                    Expanded(
                      child: TabBarView(
                        controller: _tabController,
                        children: [
                          _buildNewsList(_latestNews),
                          _buildNewsList(_trendingNews),
                        ],
                      ),
                    ),
                  ],
                )
              : TabBarView(
                  controller: _tabController,
                  children: [
                    _buildNewsList(_latestNews),
                    _buildNewsList(_trendingNews),
                  ],
                ),
    );
  }

  Widget _buildNewsList(List<NewsArticle> articles) {
    if (articles.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.article_outlined,
              color: Theme.of(context).colorScheme.onSurfaceVariant,
              size: 48,
            ),
            const SizedBox(height: 16),
            Text(
              'No news available',
              style: Theme.of(context).textTheme.bodyMedium,
            ),
          ],
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: _loadNews,
      color: Theme.of(context).colorScheme.primary,
      child: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: articles.length,
        itemBuilder: (context, index) {
          final article = articles[index];
          return _buildNewsCard(article);
        },
      ),
    );
  }

  Widget _buildNewsCard(NewsArticle article) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: Theme.of(context).colorScheme.outline,
          width: 1,
        ),
      ),
      child: InkWell(
        onTap: () => _openArticle(article),
        borderRadius: BorderRadius.circular(12),
        splashColor: Theme.of(context).colorScheme.primary.withValues(alpha: 0.1),
        highlightColor: Theme.of(context).colorScheme.primary.withValues(alpha: 0.05),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Image
              if (article.urlToImage.isNotEmpty)
                ClipRRect(
                  borderRadius: BorderRadius.circular(8),
                  child: Image.network(
                    article.urlToImage,
                    height: 200,
                    width: double.infinity,
                    fit: BoxFit.cover,
                    errorBuilder: (context, error, stackTrace) {
                      return Container(
                        height: 200,
                        color: Theme.of(context).colorScheme.surfaceContainerHighest,
                        child: Icon(
                          Icons.image_not_supported,
                          color: Theme.of(context).colorScheme.onSurfaceVariant,
                          size: 48,
                        ),
                      );
                    },
                  ),
                ),
              const SizedBox(height: 12),
              
              // Title
              Text(
                article.title,
                style: TextStyle(
                  color: Theme.of(context).colorScheme.onSurface,
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
              const SizedBox(height: 8),
              
              // Description
              Text(
                article.description,
                style: TextStyle(
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                  fontSize: 14,
                ),
                maxLines: 3,
                overflow: TextOverflow.ellipsis,
              ),
              const SizedBox(height: 12),
              
              // Source and Date
              Row(
                children: [
                  Icon(
                    Icons.source,
                    color: Theme.of(context).colorScheme.primary,
                    size: 16,
                  ),
                  const SizedBox(width: 4),
                  Text(
                    article.source,
                    style: TextStyle(
                      color: Theme.of(context).colorScheme.primary,
                      fontSize: 12,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  const Spacer(),
                  Icon(
                    Icons.access_time,
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                    size: 16,
                  ),
                  const SizedBox(width: 4),
                  Text(
                    _formatDate(article.publishedAt),
                    style: TextStyle(
                      color: Theme.of(context).colorScheme.onSurfaceVariant,
                      fontSize: 12,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Icon(
                    Icons.open_in_new,
                    color: Theme.of(context).colorScheme.primary,
                    size: 16,
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  String _formatDate(String dateString) {
    try {
      final date = DateTime.parse(dateString);
      final now = DateTime.now();
      final difference = now.difference(date);

      if (difference.inDays > 0) {
        return '${difference.inDays}d ago';
      } else if (difference.inHours > 0) {
        return '${difference.inHours}h ago';
      } else if (difference.inMinutes > 0) {
        return '${difference.inMinutes}m ago';
      } else {
        return 'Just now';
      }
    } catch (e) {
      return 'Unknown';
    }
  }
}
