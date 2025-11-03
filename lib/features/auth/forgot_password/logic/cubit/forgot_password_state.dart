// ignore_for_file: depend_on_referenced_packages
import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:riff/core/networks/api_error_model.dart';
part 'forgot_password_state.freezed.dart';


@freezed
 class ForgotPasswordState with _$ForgotPasswordState {
  const factory ForgotPasswordState.initial() = _Initial;
  const factory ForgotPasswordState.loading() = Loading;
  const factory ForgotPasswordState.success(String data) = Success;
  const factory ForgotPasswordState.failure(ApiErrorModel apiErrorModel) = Error;


  const factory ForgotPasswordState.otpVerificationLoading() = OtpVerificationLoading;
  const factory ForgotPasswordState.otpVerified(String data) = OtpVerified;
  const factory ForgotPasswordState.otpVerificationFailed(ApiErrorModel apiErrorModel) = OtpVerificationFailed;

  const factory ForgotPasswordState.resetPasswordLoading() = ResetPasswordLoading;
  const factory ForgotPasswordState.resetPasswordSuccess(String data) = ResetPasswordSuccess;
  const factory ForgotPasswordState.resetPasswordFailed(ApiErrorModel apiErrorModel) = ResetPasswordFailed;
 }