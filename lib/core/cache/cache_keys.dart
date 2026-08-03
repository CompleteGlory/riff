/// Names of every offline cache bucket, plus how much of each is kept.
///
/// The limits are deliberately small: this cache exists so the app has
/// *something* honest to show while offline, not so it can work fully offline.
/// Keeping it small also keeps writes cheap enough to run on every successful
/// first-page load.
class CacheKeys {
  const CacheKeys._();

  /// First page of the home feed.
  static const String feedPosts = 'feed_posts';
  static const int feedPostsLimit = 10;

  /// Conversations shown on the chats list.
  static const String conversations = 'conversations';
  static const int conversationsLimit = 10;

  /// Pending message requests on the chats list.
  static const String conversationRequests = 'conversation_requests';

  /// Reels.
  static const String reels = 'reels';
  static const int reelsLimit = 10;

  /// The signed-in user's own profile.
  static const String myProfile = 'my_profile';

  /// The signed-in user's own posts.
  static const String myPosts = 'my_posts';
  static const int myPostsLimit = 10;

  /// Search / discover posts.
  static const String discoverPosts = 'discover_posts';
  static const int discoverPostsLimit = 30;

  /// The newest chunk of messages for one conversation.
  static String conversationMessages(String conversationId) =>
      'messages_$conversationId';
  static const int conversationMessagesLimit = 30;
}
