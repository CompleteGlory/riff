import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:riff/core/networks/api_result.dart';
import 'package:riff/features/auth/forgot_password/data/models/request_otp_request_body.dart';
import 'package:riff/features/auth/forgot_password/data/models/reset_password_request_body.dart';
import 'package:riff/features/auth/forgot_password/data/models/verify_otp_request_body.dart';
import 'package:riff/features/auth/forgot_password/data/repos/forgot_pasword_repo.dart';
import 'package:riff/features/auth/forgot_password/logic/cubit/forgot_password_state.dart';

class ForgotPasswordCubit extends Cubit<ForgotPasswordState> {
  final ForgotPasswordRepo _forgotPasswordRepo;
  ForgotPasswordCubit(this._forgotPasswordRepo)
      : super(const ForgotPasswordState.initial());

  // Controllers
  TextEditingController mailController = TextEditingController();
  TextEditingController newPasswordController = TextEditingController();
  TextEditingController confirmPasswordController = TextEditingController();
  
  // Form keys
  GlobalKey<FormState> formKey = GlobalKey<FormState>();
  GlobalKey<FormState> resetFormKey = GlobalKey<FormState>();

  // State
  String otp = "";
  String email = "";
  String _resetToken = "";

  /// Hands this cubit the token minted by the previous screen.
  ///
  /// The three reset screens each get their own cubit from the router, so the
  /// token set while verifying the OTP is on a *different instance* from the
  /// one that resets the password. That gap used to be bridged by writing the
  /// token into SharedPreferences under the live session key — which is what
  /// signed the user out of their real account. It now travels as a route
  /// argument, the same way `email` already does.
  void seedResetToken(String token) => _resetToken = token;

  /// Exposed so the screen that verified the OTP can pass it onward.
  String get resetToken => _resetToken;

  Future<void> emitForgotPasswordStates() async {
    email = mailController.text;
    emit(const ForgotPasswordState.loading());

    final response = await _forgotPasswordRepo.requestOtp(
      RequestOtpRequestBody(email: mailController.text),
    );
    response.when(
      success: (resetToken) async {
        if (resetToken != null) {
          _resetToken = resetToken; // Store token from requestOtp
        }
        emit(ForgotPasswordState.success("OTP sent successfully"));
      },
      failure: (apiErrorModel) {
        emit(ForgotPasswordState.failure(apiErrorModel));
      },
    );
  }

  Future<void> emitVerifyOtpState() async {
    emit(const ForgotPasswordState.otpVerificationLoading());

    final response = await _forgotPasswordRepo.verifyOtp(
      VerifyOtpRequestBody(email: mailController.text, otp: otp),
    );
    response.when(
      success: (resetToken) async {
        if (resetToken != null) {
          _resetToken = resetToken;  // Store token from verifyOtp
        }
        emit(const ForgotPasswordState.otpVerified("OTP verified successfully"));
      },
      failure: (apiErrorModel) {
        emit(ForgotPasswordState.otpVerificationFailed(apiErrorModel));
      },
    );
  }

  Future<void> emitResetPasswordState() async {
    emit(const ForgotPasswordState.resetPasswordLoading());

    final response = await _forgotPasswordRepo.resetPassword(
      ResetPasswordRequestBody(resetToken: _resetToken, newPassword: newPasswordController.text),
    );
    response.when(
      success: (data) async {
        emit(const ForgotPasswordState.resetPasswordSuccess("Password reset successfully"));
      },
      failure: (apiErrorModel) {
        emit(ForgotPasswordState.resetPasswordFailed(apiErrorModel));
      },
    );
  }
  @override
  Future<void> close() {
    mailController.dispose();
    newPasswordController.dispose();
    confirmPasswordController.dispose();
    return super.close();
  }
}
