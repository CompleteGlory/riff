import 'package:dio/dio.dart';
import 'package:riff/core/networks/api_constants.dart';
import 'package:riff/features/home/feed/data/models/post.dart';
import 'package:riff/features/home/search/data/models/search_user.dart';

class SearchRepo {
  final Dio _dio;
  SearchRepo(this._dio);

  Future<List<SearchUser>> searchUsers(String q) async {
    final res = await _dio.get(
      ApiConstants.searchUsers,
      queryParameters: {'q': q},
    );
    final list = res.data as List<dynamic>;
    return list
        .map((e) => SearchUser.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  Future<List<Post>> searchPosts(String q) async {
    final res = await _dio.get(
      ApiConstants.searchPosts,
      queryParameters: {'q': q},
    );
    final list = res.data as List<dynamic>;
    return list
        .map((e) => Post.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  Future<List<Post>> discoverPosts({
    String? genre,
    String? instrument,
    int page = 1,
    int limit = 30,
  }) async {
    final res = await _dio.get(
      ApiConstants.discoverPosts,
      queryParameters: {
        if (genre != null) 'genre': genre,
        if (instrument != null) 'instrument': instrument,
        'page': page,
        'limit': limit,
      },
    );
    final list = res.data as List<dynamic>;
    return list
        .map((e) => Post.fromJson(e as Map<String, dynamic>))
        .toList();
  }
}
