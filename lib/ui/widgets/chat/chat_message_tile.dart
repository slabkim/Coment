import 'package:flutter/material.dart';
import '../../../data/models/chat_message.dart';

/// Widget for displaying a single chat message bubble.
/// Shows text, image/GIF, sender info, and read status.
class ChatMessageTile extends StatelessWidget {
  final ChatMessage message;
  final bool isMe;
  final bool isRead;

  const ChatMessageTile({
    super.key,
    required this.message,
    required this.isMe,
    required this.isRead,
  });

  @override
  Widget build(BuildContext context) {
    final content = message.imageUrl != null && message.imageUrl!.isNotEmpty
        ? Image.network(message.imageUrl!, width: 180)
        : Text(
            message.text ?? '',
            softWrap: true,
            overflow: TextOverflow.clip,
            maxLines: null,
            style: const TextStyle(color: Colors.white),
          );

    return Align(
      alignment: isMe ? Alignment.centerRight : Alignment.centerLeft,
      child: Column(
        crossAxisAlignment: isMe ? CrossAxisAlignment.end : CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Flexible(
                child: ConstrainedBox(
                  constraints: BoxConstraints(
                    maxWidth: MediaQuery.of(context).size.width * 0.72,
                  ),
                  child: Container(
                    margin: const EdgeInsets.symmetric(vertical: 2),
                    padding: const EdgeInsets.symmetric(
                      vertical: 8,
                      horizontal: 12,
                    ),
                    decoration: BoxDecoration(
                      color: Theme.of(context).brightness == Brightness.light
                          ? Colors.black87
                          : Colors.grey[800],
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: content,
                  ),
                ),
              ),
              if (isMe) ...[
                const SizedBox(width: 6),
                Icon(
                  isRead ? Icons.done_all : Icons.check,
                  size: 16,
                  color: isRead
                      ? const Color(0xFF4FC3F7)
                      : Colors.grey.shade400,
                ),
              ],
            ],
          ),
          Padding(
            padding: EdgeInsets.only(
              left: isMe ? 0 : 12,
              right: isMe ? 12 : 0,
              top: 2,
              bottom: 4,
            ),
            child: Text(
              _formatMessageTime(message.createdAt),
              style: TextStyle(
                color: Theme.of(context).colorScheme.onSurfaceVariant,
                fontSize: 10,
              ),
            ),
          ),
        ],
      ),
    );
  }

  String _formatMessageTime(DateTime time) {
    final now = DateTime.now();
    final diff = now.difference(time);
    
    // If message is from today, show time only
    if (diff.inDays == 0 && now.day == time.day) {
      final hour = time.hour.toString().padLeft(2, '0');
      final minute = time.minute.toString().padLeft(2, '0');
      return '$hour:$minute';
    }
    
    // If message is from yesterday
    if (diff.inDays == 1 || (diff.inHours >= 24 && now.day - time.day == 1)) {
      return 'Yesterday';
    }
    
    // If message is within this week, show day name
    if (diff.inDays < 7) {
      const days = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];
      return days[time.weekday - 1];
    }
    
    // Otherwise show date
    final day = time.day.toString().padLeft(2, '0');
    final month = time.month.toString().padLeft(2, '0');
    final year = time.year.toString().substring(2);
    return '$day/$month/$year';
  }
}

