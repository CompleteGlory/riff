import 'package:dio/dio.dart';
import 'package:riff/core/networks/api_constants.dart';
import 'package:riff/features/home/follow/data/models/follow_user.dart';

class FollowRepo {
  final Dio _dio;
  FollowRepo(this._dio);

  Future<String> followUser(String userId) async {
    final res = await _dio.post(ApiConstants.followUser(userId));
    final raw = (res.data as Map<String, dynamic>)['status'] as String;
    // Server returns 'accepted' | 'pending' — map to our UI status strings
    return raw == 'accepted' ? 'following' : 'pending';
  }

  Future<void> unfollowUser(String userId) async {
    await _dio.delete(ApiConstants.unfollowUser(userId));
  }

  Future<void> acceptFollow(String userId) async {
    await _dio.post(ApiConstants.acceptFollow(userId));
  }

  Future<void> rejectFollow(String userId) async {
    await _dio.delete(ApiConstants.rejectFollow(userId));
  }

  Future<void> removeFollower(String userId) async {
    await _dio.delete(ApiConstants.removeFollower(userId));
  }

  Future<void> updatePrivacy(bool isPrivate) async {
    await _dio.patch(
      ApiConstants.updatePrivacy,
      data: {'is_private': isPrivate},
    );
  }

  Future<List<FollowUser>> getFollowers(String userId) async {
    final res = await _dio.get(ApiConstants.userFollowers(userId));
    return (res.data as List<dynamic>)
        .map((e) => FollowUser.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  Future<List<FollowUser>> getFollowing(String userId) async {
    final res = await _dio.get(ApiConstants.userFollowing(userId));
    return (res.data as List<dynamic>)
        .map((e) => FollowUser.fromJson(e as Map<String, dynamic>))
        .toList();
  }
}
