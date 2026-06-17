import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:riff/core/networks/api_result.dart';
import 'package:riff/features/auth/login/data/models/login_request_body.dart';
import 'package:riff/features/auth/login/data/repos/login_repo.dart';
import 'package:riff/features/auth/signup/data/models/signup_request_body.dart';
import 'package:riff/features/auth/signup/data/repos/signup_repo.dart';
import 'package:riff/features/auth/signup/logic/cubit/signup_state.dart';

class SignupCubit extends Cubit<SignupState> {
  final SignupRepo _signupRepo;
  final LoginRepo _loginRepo;
  SignupCubit(this._signupRepo, this._loginRepo) : super(const SignupState.initial());

  TextEditingController mailController = TextEditingController();
  TextEditingController passwordController = TextEditingController();
  TextEditingController fullNameController = TextEditingController();
  TextEditingController usernameController = TextEditingController();
  TextEditingController confirmPasswordController = TextEditingController();
  GlobalKey<FormState> formKey = GlobalKey<FormState>();
  List<String> selectedInstruments = [];
  List<String> selectedGenres = [];

  void emitSignupStates() async {
    emit(const SignupState.loading());

    final signupResponse = await _signupRepo.signUp(
      SignupRequestBody(
        email: mailController.text,
        password: passwordController.text,
        fullName: fullNameController.text,
        username: usernameController.text,
        instruments: selectedInstruments,
        genres: selectedGenres,
      ),
    );

    signupResponse.when(
      success: (_) async {
        // Auto-login so the JWT is saved before phone verify
        final loginResult = await _loginRepo.login(
          LoginRequestBody(
            email: mailController.text,
            password: passwordController.text,
          ),
        );
        loginResult.when(
          success: (_) => emit(const SignupState.success(null)),
          failure: (_) => emit(const SignupState.success(null)), // proceed anyway
        );
      },
      failure: (apiErrorModel) {
        emit(SignupState.failure(apiErrorModel));
      },
    );
  }
}
