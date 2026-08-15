part of 'delete_account_cubit.dart';

enum DeleteAccountStatus { idle, loading, success, failure }

class DeleteAccountState {
  final DeleteAccountStatus status;
  final String? errorMessage;

  /// The server rejected the password or the typed username, as opposed to the
  /// request failing for some other reason. The screen shows this against the
  /// field instead of as a general error.
  final bool wrongCredential;

  const DeleteAccountState({
    this.status = DeleteAccountStatus.idle,
    this.errorMessage,
    this.wrongCredential = false,
  });

  DeleteAccountState copyWith({
    DeleteAccountStatus? status,
    String? errorMessage,
    bool? wrongCredential,
    bool clearError = false,
  }) {
    return DeleteAccountState(
      status: status ?? this.status,
      errorMessage: clearError ? null : (errorMessage ?? this.errorMessage),
      wrongCredential:
          clearError ? false : (wrongCredential ?? this.wrongCredential),
    );
  }
}
