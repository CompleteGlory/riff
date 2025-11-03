import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:riff/core/networks/api_result.dart';
import 'package:riff/features/auth/forgot_password/data/models/request_otp_request_body.dart';
import 'package:riff/features/auth/forgot_password/data/models/reset_password_request_body.dart';
import 'package:riff/features/auth/forgot_password/data/models/verify_otp_request_body.dart';
import 'package:riff/features/auth/forgot_password/data/repos/forgot_pasword_repo.dart';
import 'package:riff/features/auth/forgot_password/logic/cubit/forgot_password_state.dart';
import 'package:riff/core/helpers/shared_pref_helper.dart';
import 'package:riff/core/helpers/constants.dart';

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

  void emitForgotPasswordStates() async {
    email = mailController.text;
    emit(const ForgotPasswordState.loading());

    final response = await _forgotPasswordRepo.requestOtp(
      RequestOtpRequestBody(email: mailController.text),
    );
    response.when(
      success: (resetToken) async {
        if (resetToken != null) {
          _resetToken = resetToken; // Store token from requestOtp
           print('Debug: Token received from requestOtp: "$resetToken"');
        }
        emit(ForgotPasswordState.success("OTP sent successfully"));
      },
      failure: (apiErrorModel) {
        emit(ForgotPasswordState.failure(apiErrorModel));
      },
    );
  }

  void emitVerifyOtpState() async {
    emit(const ForgotPasswordState.otpVerificationLoading());

    final response = await _forgotPasswordRepo.verifyOtp(
      VerifyOtpRequestBody(email: mailController.text, otp: otp),
    );
    response.when(
      success: (resetToken) async {
        if (resetToken != null) {
          _resetToken = resetToken;  // Store token from verifyOtp
           print('Debug: Token received from verifyOtp: "$resetToken"');
        }
        emit(const ForgotPasswordState.otpVerified("OTP verified successfully"));
      },
      failure: (apiErrorModel) {
        emit(ForgotPasswordState.otpVerificationFailed(apiErrorModel));
      },
    );
  }

  void emitResetPasswordState() async {
    emit(const ForgotPasswordState.resetPasswordLoading());
    print('Debug: Reset token before request: "$_resetToken"');

    // If token not present in memory, try to recover it from SharedPreferences
    if (_resetToken.isEmpty) {
      final stored = await SharedPrefHelper.getString(SharedPrefKeys.userToken);
      if (stored != null && stored.isNotEmpty) {
        _resetToken = stored;
        print('Debug: Reset token recovered from SharedPrefs: "$_resetToken"');
      } else {
        print('Debug: No reset token available in SharedPrefs');
      }
    }

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
}