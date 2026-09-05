import 'package:dio/dio.dart';
import 'package:riff/core/networks/api_constants.dart';
import '../models/chat_models.dart';
import 'package:riff/core/networks/dio_factory.dart';

class ChatRepo {
  final Dio _dio;
  ChatRepo(this._dio);

  Future<Conversation> getConversationById(String id) async {
    final res = await _dio.get(ApiConstants.chatConversation(id));
    return Conversation.fromJson(res.data as Map<String, dynamic>);
  }

  Future<List<Conversation>> getConversations() async {
    final res = await _dio.get(ApiConstants.chatConversations);
    return (res.data as List).map((e) => Conversation.fromJson(e as Map<String, dynamic>)).toList();
  }

  Future<List<Conversation>> getMessageRequests() async {
    final res = await _dio.get(ApiConstants.chatRequests);
    return (res.data as List).map((e) => Conversation.fromJson(e as Map<String, dynamic>)).toList();
  }

  Future<Conversation> startDirectConversation(String userId) async {
    final res = await _dio.post(ApiConstants.chatDirectConversation, data: {'user_id': userId});
    return Conversation.fromJson(res.data as Map<String, dynamic>);
  }

  Future<Conversation> createGroupConversation({
    required String name,
    String? description,
    String? imageUrl,
    required List<String> memberIds,
  }) async {
    final res = await _dio.post(ApiConstants.chatGroupConversation, data: {
      'name': name,
      if (description != null) 'description': description,
      if (imageUrl != null) 'image_url': imageUrl,
      'member_ids': memberIds,
    });
    return Conversation.fromJson(res.data as Map<String, dynamic>);
  }

  Future<List<ChatMessage>> getMessages(String conversationId, {String? beforeId}) async {
    final res = await _dio.get(
      ApiConstants.chatMessages(conversationId),
      queryParameters: {if (beforeId != null) 'before_id': beforeId},
    );
    return (res.data as List).map((e) => ChatMessage.fromJson(e as Map<String, dynamic>)).toList();
  }

  /// Uploads a group photo and returns the stored URL.
  ///
  /// This lived in two widgets, which each built the `FormData`, called
  /// `getIt<Dio>()` directly and dug the URL out of the response map. HTTP and
  /// payload parsing belong here; the screens now ask a cubit for a picture.
  Future<String> uploadGroupPhoto(String filePath, String fileName) async {
    final formData = FormData.fromMap({
      'file': await MultipartFile.fromFile(filePath, filename: fileName),
    });
    final res = await _dio.post(
      ApiConstants.chatGroupPhotoUpload,
      data: formData,
      options: DioFactory.uploadOptions,
    );
    final url = (res.data as Map<String, dynamic>)['url'] as String?;
    if (url == null || url.isEmpty) {
      throw StateError('Group photo upload returned no URL');
    }
    return url;
  }

  Future<ChatMessage> uploadMedia(
    String conversationId,
    String filePath,
    String fileName,
    String mimeType, {
    int? duration,
    String? clientId,
    String? replyToId,
  }) async {
    final formData = FormData.fromMap({
      'file': await MultipartFile.fromFile(filePath,
          filename: fileName, contentType: DioMediaType.parse(mimeType)),
      if (duration != null) 'duration': duration.toString(),
      // Echoed back on the saved message so the optimistic bubble can be
      // replaced rather than duplicated — see ChatCubit.sendMedia.
      if (clientId != null) 'client_id': clientId,
      if (replyToId != null) 'reply_to_id': replyToId,
    });
    final res = await _dio.post(
      ApiConstants.chatUpload(conversationId),
      data: formData,
      options: DioFactory.uploadOptions,
    );
    return ChatMessage.fromJson(res.data as Map<String, dynamic>);
  }

  Future<void> acceptRequest(String conversationId) async {
    await _dio.patch(ApiConstants.chatAcceptRequest(conversationId));
  }

  Future<void> declineRequest(String conversationId) async {
    await _dio.delete(ApiConstants.chatDeclineRequest(conversationId));
  }

  Future<void> deleteMessage(String conversationId, String messageId) async {
    await _dio.delete(ApiConstants.chatDeleteMessage(conversationId, messageId));
  }

  /// Rewrites a message's text and returns the server's copy, which carries the
  /// authoritative `edited_at`.
  Future<ChatMessage> editMessage(
    String conversationId,
    String messageId,
    String content,
  ) async {
    final res = await _dio.patch(
      ApiConstants.chatEditMessage(conversationId, messageId),
      data: {'content': content},
    );
    return ChatMessage.fromJson(res.data as Map<String, dynamic>);
  }

  /// Sets the signed-in user's reaction, or clears it when [emoji] is the one
  /// they already picked. Returns the message's full reaction list afterwards —
  /// the whole list rather than a delta, so two people reacting at once can't
  /// leave a client applying its change to a list that has moved on.
  Future<List<MessageReaction>> reactToMessage(
    String conversationId,
    String messageId,
    String emoji,
  ) async {
    final res = await _dio.post(
      ApiConstants.chatMessageReactions(conversationId, messageId),
      data: {'emoji': emoji},
    );
    return _reactionsFrom(res.data);
  }

  Future<List<MessageReaction>> removeReaction(
    String conversationId,
    String messageId,
  ) async {
    final res = await _dio.delete(
      ApiConstants.chatMessageReactions(conversationId, messageId),
    );
    return _reactionsFrom(res.data);
  }

  List<MessageReaction> _reactionsFrom(dynamic data) {
    final list = (data as Map<String, dynamic>)['reactions'] as List<dynamic>?;
    return (list ?? const [])
        .map((r) => MessageReaction.fromJson(Map<String, dynamic>.from(r as Map)))
        .toList();
  }

  Future<void> deleteConversation(String conversationId) async {
    await _dio.delete(ApiConstants.chatConversation(conversationId));
  }

  Future<Conversation> updateGroup(
    String conversationId, {
    String? name,
    String? description,
    String? imageUrl,
  }) async {
    final res = await _dio.patch(
      ApiConstants.chatGroupUpdate(conversationId),
      data: {
        if (name != null) 'name': name,
        if (description != null) 'description': description,
        if (imageUrl != null) 'image_url': imageUrl,
      },
    );
    return Conversation.fromJson(res.data as Map<String, dynamic>);
  }
}
