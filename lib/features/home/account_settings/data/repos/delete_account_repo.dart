import 'package:riff/core/networks/api_error_handler.dart';
import 'package:riff/core/networks/api_result.dart';
import 'package:riff/core/networks/api_services.dart';

/// Deletes the signed-in user's account.
///
/// Required in-app by App Store guideline 5.1.1(v): an app that lets people
/// create an account has to let them delete it from inside the app, not by
/// emailing support.
class DeleteAccountRepo {
  final ApiService _apiService;
  DeleteAccountRepo(this._apiService);

  /// Sends the deletion request with whichever confirmation this account uses.
  ///
  /// Password accounts re-enter their password; accounts created through
  /// Google have none, so they type their username instead. Exactly one of
  /// [password] and [confirmUsername] is expected — the server re-checks
  /// whichever applies and rejects the other.
  Future<ApiResult<void>> deleteAccount({
    String? password,
    String? confirmUsername,
  }) async {
    try {
      final body = <String, dynamic>{};
      if (password != null) body['password'] = password;
      if (confirmUsername != null) body['confirmUsername'] = confirmUsername;

      await _apiService.deleteAccount(body);
      return const ApiResult.success(null);
    } catch (e) {
      return ApiResult.failure(ApiErrorHandler.handle(e));
    }
  }
}
