import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:riff/core/networks/api_result.dart';
import 'package:riff/features/home/account_settings/data/repos/delete_account_repo.dart';

part 'delete_account_state.dart';

/// Drives the permanent account deletion.
///
/// The cubit deliberately does *not* sign the user out itself — the screen
/// does that on [DeleteAccountStatus.success], so the confirmation is shown and
/// the navigation happens in one place with a BuildContext to hand.
class DeleteAccountCubit extends Cubit<DeleteAccountState> {
  final DeleteAccountRepo _repo;

  DeleteAccountCubit(this._repo) : super(const DeleteAccountState());

  /// Deletes the account, confirming with a password or with the user's own
  /// username (accounts created through Google have no password to check).
  Future<void> deleteAccount({
    String? password,
    String? confirmUsername,
  }) async {
    emit(state.copyWith(
      status: DeleteAccountStatus.loading,
      clearError: true,
    ));

    final result = await _repo.deleteAccount(
      password: password,
      confirmUsername: confirmUsername,
    );

    result.when(
      success: (_) {
        if (!isClosed) {
          emit(state.copyWith(status: DeleteAccountStatus.success));
        }
      },
      failure: (err) {
        if (!isClosed) {
          emit(state.copyWith(
            status: DeleteAccountStatus.failure,
            // 401 is the server saying the password or username didn't match,
            // which is worth distinguishing from "something went wrong" — it's
            // the one failure the user can actually do something about.
            wrongCredential: err.statusCode == 401,
            errorMessage: err.getAllErrorMessages(),
          ));
        }
      },
    );
  }

  void reset() => emit(const DeleteAccountState());
}
