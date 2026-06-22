import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:riff/core/networks/api_result.dart';
import 'package:riff/features/home/core/data/repos/home_repo.dart';

part 'change_password_state.dart';

class ChangePasswordCubit extends Cubit<ChangePasswordState> {
  final HomeRepo _repo;

  ChangePasswordCubit(this._repo) : super(const ChangePasswordState());

  Future<void> changePassword({
    required String oldPassword,
    required String newPassword,
  }) async {
    emit(state.copyWith(
      status: ChangePasswordStatus.loading,
      clearError: true,
    ));

    final result = await _repo.changePassword(
      oldPassword: oldPassword,
      newPassword: newPassword,
    );

    result.when(
      success: (_) {
        if (!isClosed) {
          emit(state.copyWith(status: ChangePasswordStatus.success));
        }
      },
      failure: (err) {
        if (!isClosed) {
          emit(state.copyWith(
            status: ChangePasswordStatus.failure,
            errorMessage: err.errors?.first.message ?? 'Unknown error',
          ));
        }
      },
    );
  }

  void reset() => emit(const ChangePasswordState());
}
