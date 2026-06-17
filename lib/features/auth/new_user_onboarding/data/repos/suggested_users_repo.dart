import 'package:dio/dio.dart';
import 'package:riff/core/networks/api_constants.dart';
import 'package:riff/core/networks/api_error_handler.dart';
import 'package:riff/core/networks/api_result.dart';
import 'package:riff/features/home/search/data/models/search_user.dart';

class SuggestedUsersRepo {
  final Dio _dio;
  SuggestedUsersRepo(this._dio);

  Future<ApiResult<List<SearchUser>>> getSuggested() async {
    try {
      final resp = await _dio.get(
        '${ApiConstants.apiBASEURL}${ApiConstants.discoverUsers}',
        queryParameters: {'limit': 3},
      );
      final data = resp.data;
      final usersJson = data is List
          ? data
          : data is Map<String, dynamic>
          ? data['data'] as List? ?? []
          : const [];
      final list = usersJson
          .map((e) => SearchUser.fromJson(e as Map<String, dynamic>))
          .toList();
      return ApiResult.success(list);
    } catch (e) {
      return ApiResult.failure(ApiErrorHandler.handle(e));
    }
  }

  Future<ApiResult<List<SearchUser>>> findContacts(
      List<String> phoneNumbers) async {
    try {
      final resp = await _dio.post(
        '${ApiConstants.apiBASEURL}${ApiConstants.findContacts}',
        data: {'phone_numbers': phoneNumbers},
      );
      final list = (resp.data as List? ?? [])
          .map((e) => SearchUser.fromJson(e as Map<String, dynamic>))
          .toList();
      return ApiResult.success(list);
    } catch (e) {
      return ApiResult.failure(ApiErrorHandler.handle(e));
    }
  }
}
