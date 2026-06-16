import 'package:dio/dio.dart';
import 'package:riff/core/networks/api_constants.dart';
import '../models/notification_model.dart';

class NotificationsRepo {
  final Dio _dio;
  NotificationsRepo(this._dio);

  Future<NotificationsResponse> getNotifications() async {
    final res = await _dio.get(ApiConstants.notifications);
    return NotificationsResponse.fromJson(res.data as Map<String, dynamic>);
  }

  Future<void> markAllRead() async {
    await _dio.patch(ApiConstants.markNotificationsRead);
  }

  Future<void> deleteNotification(int id) async {
    await _dio.delete('${ApiConstants.notifications}/$id');
  }

  Future<void> deleteAllNotifications() async {
    await _dio.delete(ApiConstants.notifications);
  }
}
