class ChatMessage {
  final String id;
  final String chatId;
  final String senderId;
  final String? text;
  final String? imageUrl; // gif/url
  final DateTime createdAt;

  const ChatMessage({
    required this.id,
    required this.chatId,
    required this.senderId,
    this.text,
    this.imageUrl,
    required this.createdAt,
  });

  factory ChatMessage.fromMap(String id, Map<String, dynamic> data) {
    return ChatMessage(
      id: id,
      chatId: data['chatId'] as String,
      senderId: data['senderId'] as String,
      text: data['text'] as String?,
      imageUrl: data['imageUrl'] as String?,
      createdAt: DateTime.fromMillisecondsSinceEpoch((data['createdAt'] as num).toInt()),
    );
  }

  Map<String, dynamic> toMap() => {
        'chatId': chatId,
        'senderId': senderId,
        if (text != null) 'text': text,
        if (imageUrl != null) 'imageUrl': imageUrl,
        'createdAt': createdAt.millisecondsSinceEpoch,
      };
}


