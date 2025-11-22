import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:riff/core/helpers/constants.dart';
import 'package:riff/core/helpers/shared_pref_helper.dart';
import 'package:riff/core/networks/api_result.dart';
import 'package:riff/features/auth/login/data/models/login_request_body.dart';
import 'package:riff/features/auth/login/data/repos/login_repo.dart';
import 'package:riff/features/auth/login/logic/cubit/login_state.dart';

class LoginCubit extends Cubit<LoginState> {
  final LoginRepo _loginRepo;

  LoginCubit(this._loginRepo) : super(const LoginState.initial());

  final TextEditingController mailController = TextEditingController();
  final TextEditingController passwordController = TextEditingController();
  final GlobalKey<FormState> formKey = GlobalKey<FormState>();

  Future<void> emitLoginStates() async {
    emit(const LoginState.loading());

    final response = await _loginRepo.login(
      LoginRequestBody(
        email: mailController.text,
        password: passwordController.text,
      ),
    );

    response.when(
      success: (data) async {
        await saveUserId(data.user.id);
        emit(LoginState.success(data));
      },
      failure: (apiErrorModel) {
        emit(LoginState.failure(apiErrorModel));
      },
    );
  }

  Future<void> saveToken(String? token) async {
    await SharedPrefHelper.setData(SharedPrefKeys.userToken, token);
  }

  Future<void> saveUserId(String? id) async {
    await SharedPrefHelper.setData(SharedPrefKeys.userId, id);
  }
}
