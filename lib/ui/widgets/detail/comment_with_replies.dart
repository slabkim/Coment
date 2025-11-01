import 'package:flutter/material.dart';

import '../../../data/services/comments_service.dart';
import 'comment_tile.dart';

/// Widget for displaying a comment with its nested replies
class CommentWithReplies extends StatefulWidget {
  final CommentModel model;
  final String? uid;
  final CommentsService svc;
  final void Function(CommentModel) onReply;
  
  const CommentWithReplies({
    super.key,
    required this.model,
    required this.uid,
    required this.svc,
    required this.onReply,
  });

  @override
  State<CommentWithReplies> createState() => _CommentWithRepliesState();
}

class _CommentWithRepliesState extends State<CommentWithReplies> {
  bool _showReplies = true;
  bool _loadingMore = false;
  int _displayedRepliesCount = 3; // Initially show 3 replies

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Main comment
        CommentTile(
          model: widget.model,
          uid: widget.uid,
          svc: widget.svc,
          onReply: () => widget.onReply(widget.model),
          isReply: false,
        ),
        
        // Replies section
        StreamBuilder<List<CommentModel>>(
          stream: widget.svc.watchReplies(widget.model.id),
          builder: (context, snapshot) {
            final replies = snapshot.data ?? [];
            if (replies.isEmpty) return const SizedBox.shrink();
            
            final displayedReplies = replies.take(_displayedRepliesCount).toList();
            final hasMore = replies.length > _displayedRepliesCount;
            
            return Padding(
              padding: const EdgeInsets.only(left: 40, top: 8),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Toggle replies button
                  if (replies.isNotEmpty)
                    TextButton.icon(
                      onPressed: () => setState(() => _showReplies = !_showReplies),
                      icon: Icon(
                        _showReplies ? Icons.expand_less : Icons.expand_more,
                        size: 16,
                        color: Theme.of(context).colorScheme.primary,
                      ),
                      label: Text(
                        _showReplies 
                            ? 'Hide ${replies.length} ${replies.length == 1 ? 'reply' : 'replies'}'
                            : 'Show ${replies.length} ${replies.length == 1 ? 'reply' : 'replies'}',
                        style: TextStyle(
                          fontSize: 12,
                          color: Theme.of(context).colorScheme.primary,
                        ),
                      ),
                      style: TextButton.styleFrom(
                        padding: EdgeInsets.zero,
                        minimumSize: Size.zero,
                        tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                      ),
                    ),
                  
                  // Replies list
                  if (_showReplies) ...[
                    const SizedBox(height: 8),
                    ...displayedReplies.map((reply) => Padding(
                      padding: const EdgeInsets.only(bottom: 8),
                      child: CommentTile(
                        model: reply,
                        uid: widget.uid,
                        svc: widget.svc,
                        onReply: () => widget.onReply(reply),
                        isReply: true,
                      ),
                    )),
                    
                    // Load more button
                    if (hasMore)
                      TextButton(
                        onPressed: _loadingMore 
                            ? null 
                            : () {
                                setState(() {
                                  _loadingMore = true;
                                  _displayedRepliesCount += 5;
                                });
                                Future.delayed(const Duration(milliseconds: 300), () {
                                  if (mounted) setState(() => _loadingMore = false);
                                });
                              },
                        child: _loadingMore
                            ? const SizedBox(
                                width: 14,
                                height: 14,
                                child: CircularProgressIndicator(strokeWidth: 2),
                              )
                            : Text(
                                'Load ${replies.length - _displayedRepliesCount} more ${replies.length - _displayedRepliesCount == 1 ? 'reply' : 'replies'}',
                                style: TextStyle(
                                  fontSize: 12,
                                  color: Theme.of(context).colorScheme.primary,
                                ),
                              ),
                      ),
                  ],
                ],
              ),
            );
          },
        ),
      ],
    );
  }
}

