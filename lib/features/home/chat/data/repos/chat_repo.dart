import 'package:dio/dio.dart';
import 'package:riff/core/networks/api_constants.dart';
import '../models/chat_models.dart';

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

  Future<ChatMessage> uploadMedia(
    String conversationId,
    String filePath,
    String fileName,
    String mimeType, {
    int? duration,
  }) async {
    final formData = FormData.fromMap({
      'file': await MultipartFile.fromFile(filePath,
          filename: fileName, contentType: DioMediaType.parse(mimeType)),
      if (duration != null) 'duration': duration.toString(),
    });
    final res = await _dio.post(ApiConstants.chatUpload(conversationId), data: formData);
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
