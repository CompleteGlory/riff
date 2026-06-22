part of 'change_password_cubit.dart';

enum ChangePasswordStatus { idle, loading, success, failure }

class ChangePasswordState {
  final ChangePasswordStatus status;
  final String? errorMessage;

  const ChangePasswordState({
    this.status = ChangePasswordStatus.idle,
    this.errorMessage,
  });

  ChangePasswordState copyWith({
    ChangePasswordStatus? status,
    String? errorMessage,
    bool clearError = false,
  }) {
    return ChangePasswordState(
      status: status ?? this.status,
      errorMessage: clearError ? null : (errorMessage ?? this.errorMessage),
    );
  }
}
