import 'package:flutter/material.dart';
import '../../../core/constants.dart';
import '../../../data/models/forum_message.dart';
import 'forum_message_tile.dart';

/// Widget for displaying a collapsible pinned messages section.
/// Shows pinned messages within a forum chat.
class PinnedMessagesSection extends StatelessWidget {
  final Stream<List<ForumMessage>> pinnedMessagesStream;
  final String forumId;
  final bool isModerator;
  final Function(ForumMessage) onPin;
  final Function(ForumMessage) onDelete;
  final Function(ForumMessage) onReply;

  const PinnedMessagesSection({
    super.key,
    required this.pinnedMessagesStream,
    required this.forumId,
    required this.isModerator,
    required this.onPin,
    required this.onDelete,
    required this.onReply,
  });

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<List<ForumMessage>>(
      stream: pinnedMessagesStream,
      builder: (context, snapshot) {
        if (!snapshot.hasData || snapshot.data!.isEmpty) {
          return const SizedBox.shrink();
        }
        
        return _PinnedMessagesSectionContent(
          pinnedMessages: snapshot.data!,
          forumId: forumId,
          isModerator: isModerator,
          onPin: onPin,
          onDelete: onDelete,
          onReply: onReply,
        );
      },
    );
  }
}

class _PinnedMessagesSectionContent extends StatefulWidget {
  final List<ForumMessage> pinnedMessages;
  final String forumId;
  final bool isModerator;
  final Function(ForumMessage) onPin;
  final Function(ForumMessage) onDelete;
  final Function(ForumMessage) onReply;

  const _PinnedMessagesSectionContent({
    required this.pinnedMessages,
    required this.forumId,
    required this.isModerator,
    required this.onPin,
    required this.onDelete,
    required this.onReply,
  });

  @override
  State<_PinnedMessagesSectionContent> createState() => _PinnedMessagesSectionContentState();
}

class _PinnedMessagesSectionContentState extends State<_PinnedMessagesSectionContent> {
  bool _showPinned = true;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        InkWell(
          onTap: () {
            setState(() => _showPinned = !_showPinned);
          },
          child: Container(
            color: AppColors.purpleAccent.withOpacity(0.1),
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: Row(
              children: [
                Icon(
                  Icons.push_pin,
                  size: 16,
                  color: AppColors.purpleAccent,
                ),
                const SizedBox(width: 8),
                Text(
                  '${widget.pinnedMessages.length} pinned message${widget.pinnedMessages.length > 1 ? "s" : ""}',
                  style: TextStyle(
                    color: AppColors.purpleAccent,
                    fontWeight: FontWeight.w600,
                    fontSize: 13,
                  ),
                ),
                const Spacer(),
                Icon(
                  _showPinned ? Icons.expand_less : Icons.expand_more,
                  color: AppColors.purpleAccent,
                ),
              ],
            ),
          ),
        ),
        if (_showPinned)
          ...widget.pinnedMessages.map((msg) => ForumMessageTile(
            message: msg,
            forumId: widget.forumId,
            isPinned: true,
            onPin: () => widget.onPin(msg),
            onDelete: () => widget.onDelete(msg),
            onReply: widget.onReply,
          )),
      ],
    );
  }
}

