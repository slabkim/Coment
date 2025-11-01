import 'dart:io';
import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../../../core/constants.dart';
import '../../../data/models/forum_message.dart';
import '../../../data/services/giphy_service.dart';
import 'giphy_picker.dart';

/// Widget for forum message input area.
/// Handles text input, image/GIF previews, and reply functionality.
class ForumMessageInput extends StatefulWidget {
  final TextEditingController messageController;
  final VoidCallback onSendMessage;
  final VoidCallback onPickImage;
  final Future<String?> Function(String) onPickGif;
  final ForumMessage? replyingTo;
  final VoidCallback onClearReply;
  final File? selectedImage;
  final VoidCallback onClearImage;
  final String? selectedGifUrl;
  final VoidCallback onClearGif;
  final bool isSending;
  final GiphyService giphyService;

  const ForumMessageInput({
    super.key,
    required this.messageController,
    required this.onSendMessage,
    required this.onPickImage,
    required this.onPickGif,
    this.replyingTo,
    required this.onClearReply,
    this.selectedImage,
    required this.onClearImage,
    this.selectedGifUrl,
    required this.onClearGif,
    required this.isSending,
    required this.giphyService,
  });

  @override
  State<ForumMessageInput> createState() => _ForumMessageInputState();
}

class _ForumMessageInputState extends State<ForumMessageInput> {
  Future<void> _pickGif() async {
    final url = await showModalBottomSheet<String>(
      context: context,
      backgroundColor: Theme.of(context).brightness == Brightness.light
          ? Colors.white
          : const Color(0xFF0E0F12),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.all(Radius.circular(16)),
      ),
      builder: (_) => GiphyPicker(giphy: widget.giphyService),
    );
    
    if (url != null && url.isNotEmpty) {
      await widget.onPickGif(url);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: Theme.of(context).scaffoldBackgroundColor,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Reply preview
          if (widget.replyingTo != null)
            _buildReplyPreview(),
          
          // Image preview
          if (widget.selectedImage != null)
            _buildImagePreview(),
          
          // GIF preview
          if (widget.selectedGifUrl != null)
            _buildGifPreview(),
          
          // Input row
          _buildInputRow(),
        ],
      ),
    );
  }

  Widget _buildReplyPreview() {
    if (widget.replyingTo == null) return const SizedBox.shrink();
    
    // Get preview text
    String previewText = '';
    if (widget.replyingTo!.text.isNotEmpty) {
      previewText = widget.replyingTo!.text.length > 50 
          ? '${widget.replyingTo!.text.substring(0, 50)}...' 
          : widget.replyingTo!.text;
    } else if (widget.replyingTo!.imageUrl != null) {
      previewText = '📷 Photo';
    } else if (widget.replyingTo!.gifUrl != null) {
      previewText = '🎬 GIF';
    }
    
    return Container(
      padding: const EdgeInsets.all(8),
      margin: const EdgeInsets.only(bottom: 8),
      decoration: BoxDecoration(
        color: AppColors.purpleAccent.withOpacity(0.1),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        children: [
          Icon(Icons.reply, size: 16, color: AppColors.purpleAccent),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Replying to ${widget.replyingTo!.userName}',
                  style: TextStyle(
                    color: Theme.of(context).brightness == Brightness.light
                        ? const Color(0xFF3B82F6)
                        : AppColors.purpleAccent,
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                if (previewText.isNotEmpty)
                  Text(
                    previewText,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      color: Theme.of(context).colorScheme.onSurface.withOpacity(0.7),
                      fontSize: 12,
                    ),
                  ),
              ],
            ),
          ),
          IconButton(
            icon: const Icon(Icons.close, size: 16),
            onPressed: widget.onClearReply,
            padding: EdgeInsets.zero,
            constraints: const BoxConstraints(),
          ),
        ],
      ),
    );
  }

  Widget _buildImagePreview() {
    if (widget.selectedImage == null) return const SizedBox.shrink();
    
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      height: 120,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.purpleAccent),
      ),
      child: Stack(
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(12),
            child: Image.file(
              widget.selectedImage!,
              width: double.infinity,
              height: 120,
              fit: BoxFit.cover,
            ),
          ),
          Positioned(
            top: 4,
            right: 4,
            child: IconButton(
              icon: Container(
                padding: const EdgeInsets.all(4),
                decoration: BoxDecoration(
                  color: Colors.black54,
                  borderRadius: BorderRadius.circular(20),
                ),
                child: const Icon(Icons.close, size: 16, color: Colors.white),
              ),
              onPressed: widget.onClearImage,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildGifPreview() {
    if (widget.selectedGifUrl == null) return const SizedBox.shrink();
    
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      height: 120,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.purpleAccent),
      ),
      child: Stack(
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(12),
            child: CachedNetworkImage(
              imageUrl: widget.selectedGifUrl!,
              width: double.infinity,
              height: 120,
              fit: BoxFit.cover,
              errorWidget: (context, url, error) => Container(
                width: double.infinity,
                height: 120,
                color: Theme.of(context).colorScheme.surfaceVariant,
                child: const Icon(Icons.error, size: 32),
              ),
            ),
          ),
          Positioned(
            top: 4,
            right: 4,
            child: IconButton(
              icon: Container(
                padding: const EdgeInsets.all(4),
                decoration: BoxDecoration(
                  color: Colors.black54,
                  borderRadius: BorderRadius.circular(20),
                ),
                child: const Icon(Icons.close, size: 16, color: Colors.white),
              ),
              onPressed: widget.onClearGif,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInputRow() {
    return Row(
      children: [
        IconButton(
          onPressed: widget.onPickImage,
          icon: Icon(
            Icons.image,
            color: Theme.of(context).colorScheme.onSurface,
          ),
          tooltip: 'Add Image',
        ),
        IconButton(
          onPressed: _pickGif,
          icon: Icon(
            Icons.gif_box,
            color: Theme.of(context).colorScheme.onSurface,
          ),
          tooltip: 'Add GIF',
        ),
        Expanded(
          child: TextField(
            controller: widget.messageController,
            decoration: InputDecoration(
              hintText: 'Type a message...',
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(24),
                borderSide: BorderSide.none,
              ),
              filled: true,
              fillColor: Theme.of(context).colorScheme.surfaceVariant.withOpacity(0.5),
              contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            ),
            maxLines: null,
            textInputAction: TextInputAction.send,
            onSubmitted: (_) => widget.onSendMessage(),
          ),
        ),
        const SizedBox(width: 8),
        IconButton(
          onPressed: widget.isSending ? null : widget.onSendMessage,
          icon: widget.isSending
              ? SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    valueColor: AlwaysStoppedAnimation<Color>(
                      Theme.of(context).colorScheme.onSurface.withOpacity(0.5),
                    ),
                  ),
                )
              : Icon(
                  Icons.send,
                  color: Theme.of(context).colorScheme.onSurface,
                ),
        ),
      ],
    );
  }
}

