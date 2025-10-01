class FsPaths {
  static const titles = 'titles';
  static const users = 'users';
  static const favorites = 'favorites';
  static const comments = 'comments';
  static const commentLikes = 'comment_likes';
  static const readingStatus = 'reading_status';
  static const follows = 'follows';
  static const chats = 'chats';
  static const chatMessages = 'chat_messages';
  static const chatHistory = 'chat_history';
  static const forums = 'forums';
  static const forumMessages = 'forum_messages';
  static const userRecommendations = 'user_recommendations';

  // helpers
  static String chatDoc(String chatId) => '$chats/$chatId';
  static String chatMessagesQuery(String chatId) =>
      chatMessages; // top-level per rules
}
