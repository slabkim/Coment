import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../../core/constants.dart';
import '../../data/models/forum.dart';
import '../../data/services/forum_service.dart';
import '../../data/services/forum_member_service.dart';
import 'forum_chat_screen.dart';
import 'create_forum_screen.dart';

class ForumsListScreen extends StatefulWidget {
  const ForumsListScreen({super.key});

  @override
  State<ForumsListScreen> createState() => _ForumsListScreenState();
}

class _ForumsListScreenState extends State<ForumsListScreen> with SingleTickerProviderStateMixin {
  final _forumService = ForumService();
  final _memberService = ForumMemberService();
  late TabController _tabController;
  
  Stream<List<Forum>>? _allForumsStream;
  Stream<Set<String>>? _userForumIdsStream;
  
  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _initStreams();
  }
  
  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }
  
  void _initStreams() {
    final userId = FirebaseAuth.instance.currentUser?.uid;
    if (userId == null) return;
    
    // Watch all forums in realtime
    _allForumsStream = _forumService.watchAllForums();
    
    // Watch user's joined forums in realtime (already returns List<String>)
    _userForumIdsStream = _memberService.watchUserForums(userId).map((forumIds) {
      return forumIds.toSet();
    });
  }
  
  Future<void> _refresh() async {
    // Streams auto-refresh, just force rebuild
    setState(() {
      _initStreams();
    });
  }
  
  void _navigateToCreateForum() {
    Navigator.of(context).push(
      MaterialPageRoute(builder: (context) => const CreateForumScreen()),
    );
  }
  
  void _navigateToForum(Forum forum) {
    Navigator.of(context).push(
      MaterialPageRoute(builder: (context) => ForumChatScreen(forum: forum)),
    );
  }
  
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Forums'),
        actions: [
          IconButton(
            onPressed: _navigateToCreateForum,
            icon: const Icon(Icons.add),
            tooltip: 'Create Forum',
          ),
        ],
        bottom: TabBar(
          controller: _tabController,
          labelColor: Theme.of(context).brightness == Brightness.light
              ? const Color(0xFF3B82F6) // Blue for light mode
              : AppColors.purpleAccent, // Purple for dark mode
          unselectedLabelColor: Theme.of(context).colorScheme.onSurface.withOpacity(0.6),
          indicatorColor: Theme.of(context).brightness == Brightness.light
              ? const Color(0xFF3B82F6) // Blue for light mode
              : AppColors.purpleAccent, // Purple for dark mode
          tabs: const [
            Tab(text: 'My Forums'),
            Tab(text: 'All Forums'),
          ],
        ),
      ),
      body: RefreshIndicator(
        onRefresh: _refresh,
        child: StreamBuilder<List<Forum>>(
          stream: _allForumsStream,
          builder: (context, forumsSnapshot) {
            if (forumsSnapshot.connectionState == ConnectionState.waiting) {
              return const Center(child: CircularProgressIndicator());
            }
            
            if (forumsSnapshot.hasError) {
              return Center(child: Text('Error: ${forumsSnapshot.error}'));
            }
            
            final allForums = forumsSnapshot.data ?? [];
            
            return StreamBuilder<Set<String>>(
              stream: _userForumIdsStream,
              builder: (context, idsSnapshot) {
                final userForumIds = idsSnapshot.data ?? {};
                
                return TabBarView(
                  controller: _tabController,
                  children: [
                    _buildMyForumsList(allForums, userForumIds),
                    _buildAllForumsList(allForums, userForumIds),
                  ],
                );
              },
            );
          },
        ),
      ),
      
      // Floating Action Button for easy forum creation
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _navigateToCreateForum,
        backgroundColor: Theme.of(context).brightness == Brightness.light
            ? const Color(0xFF3B82F6) // Blue for light mode
            : AppColors.purpleAccent, // Purple for dark mode
        foregroundColor: Theme.of(context).brightness == Brightness.light
            ? Colors.black87 // Dark text for light mode
            : Colors.white, // White text for dark mode
        icon: const Icon(Icons.add),
        label: const Text('Create Forum'),
      ),
    );
  }

  Widget _buildMyForumsList(List<Forum> allForums, Set<String> userForumIds) {
    final myForums = allForums.where((f) => userForumIds.contains(f.id)).toList();
    
    if (myForums.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.forum_outlined,
              size: 64,
              color: Theme.of(context).colorScheme.onSurface.withOpacity(0.3),
            ),
            const SizedBox(height: 16),
            Text(
              'No forums joined yet',
              style: TextStyle(
                color: Theme.of(context).colorScheme.onSurface.withOpacity(0.6),
                fontSize: 16,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Tap the + button below to create your first forum!',
              style: TextStyle(
                color: Theme.of(context).colorScheme.onSurface.withOpacity(0.4),
                fontSize: 14,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      );
    }
    
    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: myForums.length,
      itemBuilder: (context, index) {
        final forum = myForums[index];
        
        return _ForumCard(
          forum: forum,
          isJoined: true,
          onTap: () => _navigateToForum(forum),
          onJoinToggle: () async {
            final userId = FirebaseAuth.instance.currentUser?.uid;
            if (userId == null) return;
            
            // Capture context from State before async operation
            final stateContext = context;
            
            try {
              await _memberService.leaveForum(forum.id, userId);
              // Streams auto-update!
            } catch (e) {
              if (!mounted || !stateContext.mounted) return;
              ScaffoldMessenger.of(stateContext).showSnackBar(
                SnackBar(content: Text('Error: $e')),
              );
            }
          },
        );
      },
    );
  }

  Widget _buildAllForumsList(List<Forum> allForums, Set<String> userForumIds) {
    if (allForums.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.forum_outlined,
              size: 64,
              color: Theme.of(context).colorScheme.onSurface.withOpacity(0.3),
            ),
            const SizedBox(height: 16),
            Text(
              'No forums available',
              style: TextStyle(
                color: Theme.of(context).colorScheme.onSurface.withOpacity(0.6),
                fontSize: 16,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Tap the + button below to create the first forum!',
              style: TextStyle(
                color: Theme.of(context).colorScheme.onSurface.withOpacity(0.4),
                fontSize: 14,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      );
    }
    
    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: allForums.length,
      itemBuilder: (context, index) {
        final forum = allForums[index];
        final isJoined = userForumIds.contains(forum.id);
        
        return _ForumCard(
          forum: forum,
          isJoined: isJoined,
          onTap: () => _navigateToForum(forum),
          onJoinToggle: () async {
            final userId = FirebaseAuth.instance.currentUser?.uid;
            if (userId == null) return;
            
            // Capture context from State before async operation
            final stateContext = context;
            
            try {
              if (isJoined) {
                await _memberService.leaveForum(forum.id, userId);
              } else {
                await _memberService.joinForum(forum.id, userId);
              }
              // Streams auto-update!
            } catch (e) {
              if (!mounted || !stateContext.mounted) return;
              ScaffoldMessenger.of(stateContext).showSnackBar(
                SnackBar(content: Text('Error: $e')),
              );
            }
          },
        );
      },
    );
  }
}

// Forum Card Widget
class _ForumCard extends StatefulWidget {
  final Forum forum;
  final bool isJoined;
  final VoidCallback onTap;
  final Future<void> Function() onJoinToggle;
  
  const _ForumCard({
    required this.forum,
    required this.isJoined,
    required this.onTap,
    required this.onJoinToggle,
  });

  @override
  State<_ForumCard> createState() => _ForumCardState();
}

class _ForumCardState extends State<_ForumCard> {
  bool _isLoading = false;

  Future<void> _handleJoinToggle() async {
    if (_isLoading) return;
    
    setState(() => _isLoading = true);
    try {
      await widget.onJoinToggle();
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  Widget _buildPlaceholder() {
    return Container(
      width: 60,
      height: 60,
      decoration: BoxDecoration(
        color: AppColors.purpleAccent.withOpacity(0.2),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Icon(
        Icons.forum,
        color: AppColors.purpleAccent,
        size: 30,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: InkWell(
        onTap: widget.onTap,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Row(
            children: [
              // Forum cover image
              ClipRRect(
                borderRadius: BorderRadius.circular(8),
                child: widget.forum.coverImage != null && widget.forum.coverImage!.isNotEmpty
                    ? CachedNetworkImage(
                        imageUrl: widget.forum.coverImage!,
                        width: 60,
                        height: 60,
                        fit: BoxFit.cover,
                        placeholder: (context, url) => _buildPlaceholder(),
                        errorWidget: (context, url, error) => _buildPlaceholder(),
                      )
                    : _buildPlaceholder(),
              ),
              
              const SizedBox(width: 12),
              
              // Forum info
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      widget.forum.name,
                      style: TextStyle(
                        color: Theme.of(context).colorScheme.onSurface,
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 4),
                    Text(
                      widget.forum.description,
                      style: TextStyle(
                        color: Theme.of(context).colorScheme.onSurface.withOpacity(0.6),
                        fontSize: 13,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        Icon(
                          Icons.person_outline,
                          size: 14,
                          color: Theme.of(context).colorScheme.onSurface.withOpacity(0.5),
                        ),
                        const SizedBox(width: 4),
                        Flexible(
                          child: Text(
                            widget.forum.createdByName,
                            style: TextStyle(
                              color: Theme.of(context).colorScheme.onSurface.withOpacity(0.5),
                              fontSize: 11,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        const SizedBox(width: 8),
                        Icon(
                          Icons.people,
                          size: 14,
                          color: Theme.of(context).colorScheme.onSurface.withOpacity(0.5),
                        ),
                        const SizedBox(width: 4),
                        Text(
                          '${widget.forum.memberCount}',
                          style: TextStyle(
                            color: Theme.of(context).colorScheme.onSurface.withOpacity(0.5),
                            fontSize: 12,
                          ),
                        ),
                        const SizedBox(width: 8),
                        Icon(
                          Icons.chat_bubble_outline,
                          size: 14,
                          color: Theme.of(context).colorScheme.onSurface.withOpacity(0.5),
                        ),
                        const SizedBox(width: 4),
                        Text(
                          '${widget.forum.messageCount}',
                          style: TextStyle(
                            color: Theme.of(context).colorScheme.onSurface.withOpacity(0.5),
                            fontSize: 12,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              
              // Join button with loading state
              _isLoading
                  ? Container(
                      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
                      child: const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      ),
                    )
                  : TextButton(
                      onPressed: _handleJoinToggle,
                      style: TextButton.styleFrom(
                        backgroundColor: widget.isJoined
                            ? Colors.grey.withOpacity(0.2)
                            : (Theme.of(context).brightness == Brightness.light
                                ? const Color(0xFF3B82F6).withOpacity(0.2) // Blue for light mode
                                : AppColors.purpleAccent.withOpacity(0.2)), // Purple for dark mode
                        foregroundColor: widget.isJoined
                            ? Theme.of(context).colorScheme.onSurface
                            : (Theme.of(context).brightness == Brightness.light
                                ? const Color(0xFF3B82F6) // Blue for light mode
                                : AppColors.purpleAccent), // Purple for dark mode
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                      ),
                      child: Text(
                        widget.isJoined ? 'Joined' : 'Join',
                        style: const TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
            ],
          ),
        ),
      ),
    );
  }
}
