import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:riff/core/helpers/constants.dart';
import 'package:riff/core/helpers/shared_pref_helper.dart';
import 'package:riff/core/networks/api_result.dart';
import 'package:riff/core/networks/dio_factory.dart';
import 'package:riff/features/login/data/models/login_request_body.dart';
import 'package:riff/features/login/data/repos/login_repo.dart';
import 'package:riff/features/login/logic/cubit/login_state.dart';

class LoginCubit extends Cubit<LoginState> {
  final LoginRepo _loginRepo;
  LoginCubit(this._loginRepo) : super(const LoginState.initial());

  TextEditingController mailController = TextEditingController();
  TextEditingController passwordController = TextEditingController();
  GlobalKey<FormState> formKey = GlobalKey<FormState>();

  void emitLoginStates() async {
    emit(const LoginState.loading());

    final response = await _loginRepo.login(LoginRequestBody(
        email: mailController.text, password: passwordController.text));
    response.when(
      success: (data) async {
       await saveToken(data.refreshToken ??'');
        await saveUserId(data.id);
        DioFactory.setTokenIntoHeaderAfterLogin(data.refreshToken ?? "");
        emit(LoginState.success(data));
      },

      failure: (apiErrorModel) {
        emit(LoginState.failure(apiErrorModel));
      },
    );
  }

  saveToken(String? token) async {
    // save token to shared preferences
    await SharedPrefHelper.setData(SharedPrefKeys.userToken, token);
  }

  saveUserId(String? id) async {
    await SharedPrefHelper.setData(SharedPrefKeys.userId, id);
  }

  

}