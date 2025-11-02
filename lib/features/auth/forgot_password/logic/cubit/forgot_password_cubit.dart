import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:riff/core/helpers/constants.dart';
import 'package:riff/core/helpers/shared_pref_helper.dart';
import 'package:riff/core/networks/api_result.dart';
import 'package:riff/features/auth/forgot_password/data/models/request_otp_request_body.dart';
import 'package:riff/features/auth/forgot_password/data/repos/forgot_pasword_repo.dart';
import 'package:riff/features/auth/forgot_password/logic/cubit/forgot_password_state.dart';

class ForgotPasswordCubit extends Cubit<ForgotPasswordState> {
  final ForgotPasswordRepo _forgotPasswordRepo;
  ForgotPasswordCubit(this._forgotPasswordRepo) : super(const ForgotPasswordState.initial());

  TextEditingController mailController = TextEditingController();
  TextEditingController passwordController = TextEditingController();
  GlobalKey<FormState> formKey = GlobalKey<FormState>();

  void emitForgotPasswordStates() async {
    emit(const ForgotPasswordState.loading());

    final response = await _forgotPasswordRepo.requestOtp(RequestOtpRequestBody(
        email: mailController.text));
    response.when(
      success: (data) async {
        emit(ForgotPasswordState.success("OTP sent successfully"));
      },

      failure: (apiErrorModel) {
        emit(ForgotPasswordState.failure(apiErrorModel));
      },
    );
  }
  

  

  

}