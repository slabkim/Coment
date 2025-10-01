import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

import '../../core/constants.dart';
import '../../data/models/chat_message.dart';
import '../../data/models/user_profile.dart';
import '../../data/services/chat_history_service.dart';
import '../../data/services/chat_service.dart';
import '../../data/services/giphy_service.dart';
import '../../data/services/user_service.dart';

class ChatScreen extends StatefulWidget {
  final String peerUserId;
  final String peerDisplayName;
  final String? peerPhotoUrl;
  const ChatScreen({
    super.key,
    required this.peerUserId,
    required this.peerDisplayName,
    this.peerPhotoUrl,
  });

  @override
  State<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> {
  final _messageC = TextEditingController();
  final _scrollC = ScrollController();
  final _giphy = GiphyService();
  final _chat = ChatService();
  String? _chatId;
  final _history = ChatHistoryService();
  final _userService = UserService();
  String? _selfName;

  @override
  void dispose() {
    _messageC.dispose();
    _scrollC.dispose();
    super.dispose();
  }

  @override
  void initState() {
    super.initState();
    _loadSelfProfile();
  }

  @override
  Widget build(BuildContext context) {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    return Scaffold(
      appBar: AppBar(
        backgroundColor: AppColors.black,
        foregroundColor: AppColors.white,
        title: StreamBuilder<UserProfile?>(
          stream: _userService.watchProfile(widget.peerUserId),
          builder: (context, snapshot) {
            final profile = snapshot.data;
            final name = profile?.username ?? widget.peerDisplayName;
            final photo = profile?.photoUrl ?? widget.peerPhotoUrl;
            return Row(
              children: [
                CircleAvatar(
                  radius: 18,
                  backgroundColor: AppColors.purpleAccent.withValues(
                    alpha: 0.2,
                  ),
                  backgroundImage: (photo != null && photo.isNotEmpty)
                      ? NetworkImage(photo)
                      : null,
                  child: (photo == null || photo.isEmpty)
                      ? Text(
                          _initials(name),
                          style: const TextStyle(color: Colors.white),
                        )
                      : null,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    name,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            );
          },
        ),
      ),
      backgroundColor: AppColors.black,
      body: Column(
        children: [
          Expanded(
            child: uid == null
                ? const Center(
                    child: Text(
                      'Login required',
                      style: TextStyle(color: AppColors.white),
                    ),
                  )
                : FutureBuilder<String>(
                    future: _initChat(uid),
                    builder: (context, snap) {
                      if (!snap.hasData) {
                        return const Center(child: CircularProgressIndicator());
                      }
                      final cid = snap.data!;
                      return StreamBuilder<List<ChatMessage>>(
                        stream: _chat.watchMessages(cid),
                        builder: (context, s2) {
                          final msgs = s2.data ?? const [];
                          // mark read when list updates
                          WidgetsBinding.instance.addPostFrameCallback((_) {
                            _history.markReadNow(cid, uid);
                          });
                          return ListView.builder(
                            controller: _scrollC,
                            reverse: true,
                            padding: const EdgeInsets.symmetric(
                              vertical: 8,
                              horizontal: 12,
                            ),
                            itemCount: msgs.length,
                            itemBuilder: (context, i) {
                              final m = msgs[i];
                              final isMe = m.senderId == uid;
                              final content =
                                  m.imageUrl != null && m.imageUrl!.isNotEmpty
                                  ? Image.network(m.imageUrl!, width: 180)
                                  : Text(
                                      m.text ?? '',
                                      style: const TextStyle(
                                        color: Colors.white,
                                      ),
                                    );
                              return Align(
                                alignment: isMe
                                    ? Alignment.centerRight
                                    : Alignment.centerLeft,
                                child: Container(
                                  margin: const EdgeInsets.symmetric(
                                    vertical: 4,
                                  ),
                                  padding: const EdgeInsets.symmetric(
                                    vertical: 8,
                                    horizontal: 12,
                                  ),
                                  decoration: BoxDecoration(
                                    color: isMe
                                        ? const Color(0xFF3B2A58)
                                        : const Color(0xFF1E232B),
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  child: content,
                                ),
                              );
                            },
                          );
                        },
                      );
                    },
                  ),
          ),
          const Divider(height: 1, color: Color(0xFF22252B)),
          SafeArea(
            top: false,
            child: Padding(
              padding: const EdgeInsets.fromLTRB(8, 6, 8, 8),
              child: Row(
                children: [
                  IconButton(
                    onPressed: _pickGif,
                    icon: const Icon(
                      Icons.gif_box_outlined,
                      color: AppColors.white,
                    ),
                  ),
                  Expanded(
                    child: TextField(
                      controller: _messageC,
                      minLines: 1,
                      maxLines: 4,
                      style: const TextStyle(color: Colors.white),
                      decoration: InputDecoration(
                        hintText: 'Type a message',
                        hintStyle: const TextStyle(
                          color: AppColors.whiteSecondary,
                        ),
                        filled: true,
                        fillColor: const Color(0xFF121316),
                        contentPadding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 10,
                        ),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(10),
                          borderSide: BorderSide.none,
                        ),
                      ),
                      onSubmitted: (_) => _send(),
                    ),
                  ),
                  const SizedBox(width: 8),
                  FilledButton(
                    onPressed: _send,
                    style: FilledButton.styleFrom(
                      backgroundColor: AppColors.purpleAccent,
                    ),
                    child: const Icon(Icons.send),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _send() {
    if (_messageC.text.trim().isEmpty) return;
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null || _chatId == null) return;
    final senderName =
        _selfName ??
        FirebaseAuth.instance.currentUser?.displayName ??
        FirebaseAuth.instance.currentUser?.email?.split('@').first;
    _chat.sendText(
      chatId: _chatId!,
      senderId: uid,
      text: _messageC.text.trim(),
      senderName: senderName,
    );
    _messageC.clear();
    _scrollC.animateTo(
      0,
      duration: const Duration(milliseconds: 250),
      curve: Curves.easeOut,
    );
  }

  Future<void> _pickGif() async {
    final url = await showModalBottomSheet<String>(
      context: context,
      backgroundColor: const Color(0xFF0E0F12),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (_) => _GifPicker(giphy: _giphy),
    );
    if (url != null && url.isNotEmpty) {
      final uid = FirebaseAuth.instance.currentUser?.uid;
      if (uid != null && _chatId != null) {
        final senderName =
            _selfName ??
            FirebaseAuth.instance.currentUser?.displayName ??
            FirebaseAuth.instance.currentUser?.email?.split('@').first;
        await _chat.sendImage(
          chatId: _chatId!,
          senderId: uid,
          imageUrl: url,
          senderName: senderName,
        );
      }
    }
  }

  Future<String> _initChat(String uid) async {
    if (_chatId != null) return _chatId!;
    final peer = widget.peerUserId;
    final id = await _chat.ensureChat(uid, peer);
    _chatId = id;
    return id;
  }

  Future<void> _loadSelfProfile() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;
    final profile = await _userService.fetchProfile(user.uid);
    if (!mounted) return;
    setState(() {
      _selfName =
          profile?.username ?? user.displayName ?? user.email?.split('@').first;
    });
  }
}

String _initials(String name) {
  final parts = name.trim().split(' ');
  final first = parts.isNotEmpty && parts.first.isNotEmpty
      ? parts.first[0]
      : 'U';
  final second = parts.length > 1 && parts.last.isNotEmpty ? parts.last[0] : '';
  return (first + second).toUpperCase();
}

class _GifPicker extends StatefulWidget {
  final GiphyService giphy;
  const _GifPicker({required this.giphy});

  @override
  State<_GifPicker> createState() => _GifPickerState();
}

class _GifPickerState extends State<_GifPicker> {
  final _q = TextEditingController(text: 'anime');
  List<String> _results = const [];
  bool _loading = false;

  @override
  void initState() {
    super.initState();
    _search();
  }

  @override
  void dispose() {
    _q.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      top: false,
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _q,
                    style: const TextStyle(color: Colors.white),
                    decoration: InputDecoration(
                      hintText: 'Search GIFs',
                      hintStyle: const TextStyle(
                        color: AppColors.whiteSecondary,
                      ),
                      filled: true,
                      fillColor: const Color(0xFF121316),
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 10,
                      ),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(10),
                        borderSide: BorderSide.none,
                      ),
                    ),
                    onSubmitted: (_) => _search(),
                  ),
                ),
                const SizedBox(width: 8),
                FilledButton(
                  onPressed: _loading ? null : _search,
                  style: FilledButton.styleFrom(
                    backgroundColor: AppColors.purpleAccent,
                  ),
                  child: _loading
                      ? const SizedBox(
                          width: 16,
                          height: 16,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Icon(Icons.search),
                ),
              ],
            ),
            const SizedBox(height: 12),
            SizedBox(
              height: 300,
              child: _loading
                  ? const Center(child: CircularProgressIndicator())
                  : GridView.builder(
                      gridDelegate:
                          const SliverGridDelegateWithFixedCrossAxisCount(
                            crossAxisCount: 3,
                            mainAxisSpacing: 6,
                            crossAxisSpacing: 6,
                          ),
                      itemCount: _results.length,
                      itemBuilder: (context, i) => GestureDetector(
                        onTap: () => Navigator.pop(context, _results[i]),
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(8),
                          child: Image.network(_results[i], fit: BoxFit.cover),
                        ),
                      ),
                    ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _search() async {
    setState(() => _loading = true);
    try {
      final res = await widget.giphy.searchGifs(
        query: _q.text.trim().isEmpty ? 'anime' : _q.text.trim(),
      );
      setState(() => _results = res);
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }
}
