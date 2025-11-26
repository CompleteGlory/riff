import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:riff/core/helpers/shared_pref_helper.dart';
import 'package:riff/core/networks/api_result.dart';
import 'package:riff/features/auth/login/data/models/login_request_body.dart';
import 'package:riff/features/auth/login/data/models/login_response.dart';
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

    _handleResponse(response);
  }

  Future<void> loginWithGoogle(String idToken) async {
    emit(const LoginState.loading());

    final response = await _loginRepo.loginWithGoogle(idToken);

    _handleResponse(response);
  }

  void _handleResponse(ApiResult<LoginResponse> response) {
    response.when(
      success: (data) {
        // ✅ Token and userId are already saved in LoginRepo
        emit(LoginState.success(data));
      },
      failure: (apiErrorModel) {
        emit(LoginState.failure(apiErrorModel));
      },
    );
  }

  @override
  Future<void> close() {
    mailController.dispose();
    passwordController.dispose();
    return super.close();
  }
}