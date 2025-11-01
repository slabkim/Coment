import 'dart:io';
import 'package:flutter/material.dart';
import '../../../core/constants.dart';
import '../../../data/services/giphy_service.dart';
import '../forum/giphy_picker.dart';

/// Widget for chat message input area.
/// Handles text input, image/GIF previews, and sending messages.
class ChatMessageInput extends StatefulWidget {
  final TextEditingController messageController;
  final VoidCallback onSendMessage;
  final VoidCallback onPickImage;
  final Function(String) onPickGif;
  final File? selectedImage;
  final VoidCallback onClearImage;
  final String? selectedGifUrl;
  final VoidCallback onClearGif;
  final bool isUploadingImage;
  final GiphyService giphyService;

  const ChatMessageInput({
    super.key,
    required this.messageController,
    required this.onSendMessage,
    required this.onPickImage,
    required this.onPickGif,
    this.selectedImage,
    required this.onClearImage,
    this.selectedGifUrl,
    required this.onClearGif,
    required this.isUploadingImage,
    required this.giphyService,
  });

  @override
  State<ChatMessageInput> createState() => _ChatMessageInputState();
}

class _ChatMessageInputState extends State<ChatMessageInput> {
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
      widget.onPickGif(url);
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

  Widget _buildImagePreview() {
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
          // Loading indicator overlay (only show when uploading)
          if (widget.isUploadingImage)
            Container(
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(12),
                color: Colors.black54,
              ),
              child: const Center(
                child: CircularProgressIndicator(
                  valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
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
              onPressed: widget.isUploadingImage ? null : widget.onClearImage,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildGifPreview() {
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
            child: Image.network(
              widget.selectedGifUrl!,
              width: double.infinity,
              height: 120,
              fit: BoxFit.cover,
              errorBuilder: (context, error, stackTrace) => Container(
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
          onPressed: widget.isUploadingImage ? null : widget.onSendMessage,
          icon: Icon(
            Icons.send,
            color: widget.isUploadingImage
                ? Theme.of(context).colorScheme.onSurface.withOpacity(0.5)
                : Theme.of(context).colorScheme.onSurface,
          ),
        ),
      ],
    );
  }
}

