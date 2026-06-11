import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:riff/core/networks/api_result.dart';
import 'package:riff/features/auth/signup/data/models/signup_request_body.dart';
import 'package:riff/features/auth/signup/data/repos/signup_repo.dart';
import 'package:riff/features/auth/signup/logic/cubit/signup_state.dart';

class SignupCubit extends Cubit<SignupState> {
  final SignupRepo _signupRepo;
  SignupCubit(this._signupRepo) : super(const SignupState.initial());

  TextEditingController mailController = TextEditingController();
  TextEditingController passwordController = TextEditingController();
  TextEditingController fullNameController = TextEditingController();
  TextEditingController usernameController = TextEditingController();
  GlobalKey<FormState> formKey = GlobalKey<FormState>();
  List<String> selectedInstruments = [];
  List<String> selectedGenres = [];

  void emitSignupStates() async {
    emit(const SignupState.loading());

    final response = await _signupRepo.signUp(
      SignupRequestBody(
        email: mailController.text,
        password: passwordController.text,
        fullName: fullNameController.text,
        username: usernameController.text,
        instruments: selectedInstruments,
        genres: selectedGenres,
      ),
    );
    response.when(
      success: (_) async {
        emit(const SignupState.success(null));
      },
      failure: (apiErrorModel) {
        emit(SignupState.failure(apiErrorModel));
      },
    );
  }
}
