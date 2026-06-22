import 'package:dio/dio.dart';
import 'package:riff/core/networks/api_constants.dart';
import '../models/blocked_user.dart';

class BlockRepo {
  final Dio _dio;
  BlockRepo(this._dio);

  Future<List<BlockedUser>> getBlockedUsers() async {
    final res = await _dio.get(ApiConstants.blockedUsers);
    return (res.data as List).map((e) => BlockedUser.fromJson(e as Map<String, dynamic>)).toList();
  }

  Future<void> blockUser(String userId) async {
    await _dio.post(ApiConstants.blockUser(userId));
  }

  Future<void> unblockUser(String userId) async {
    await _dio.delete(ApiConstants.blockUser(userId));
  }
}
