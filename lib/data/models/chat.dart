class Chat {
  final String id;
  final List<String> participants;
  final String? lastMessage;
  final DateTime? lastMessageTime;
  final String? lastMessageSenderId;
  final String? lastMessageSenderName;

  const Chat({
    required this.id,
    required this.participants,
    this.lastMessage,
    this.lastMessageTime,
    this.lastMessageSenderId,
    this.lastMessageSenderName,
  });

  factory Chat.fromMap(String id, Map<String, dynamic> data) {
    return Chat(
      id: id,
      participants: (data['participants'] as List<dynamic>? ?? const [])
          .map((e) => e.toString())
          .toList(),
      lastMessage: data['lastMessage'] as String?,
      lastMessageTime: (data['lastMessageTime'] as Object?) is int
          ? DateTime.fromMillisecondsSinceEpoch(data['lastMessageTime'] as int)
          : (data['lastMessageTime'] as Object?) is double
              ? DateTime.fromMillisecondsSinceEpoch(
                  (data['lastMessageTime'] as double).toInt(),
                )
              : null,
      lastMessageSenderId: data['lastMessageSenderId'] as String?,
      lastMessageSenderName: data['lastMessageSenderName'] as String?,
    );
  }

  Map<String, dynamic> toMap() => {
        'participants': participants,
        if (lastMessage != null) 'lastMessage': lastMessage,
        if (lastMessageTime != null)
          'lastMessageTime': lastMessageTime!.millisecondsSinceEpoch,
        if (lastMessageSenderId != null)
          'lastMessageSenderId': lastMessageSenderId,
        if (lastMessageSenderName != null)
          'lastMessageSenderName': lastMessageSenderName,
      };
}


