import 'package:bloc_test/bloc_test.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/annotations.dart';
import 'package:mockito/mockito.dart';
import 'package:riff/core/networks/api_error_model.dart';
import 'package:riff/core/networks/api_result.dart' hide Success, Failure;
import 'package:riff/features/auth/login/data/models/login_request_body.dart';
import 'package:riff/features/auth/login/data/models/login_response.dart';
import 'package:riff/features/auth/login/data/models/user.dart';
import 'package:riff/features/auth/login/data/repos/login_repo.dart';
import 'package:riff/features/auth/signup/data/models/signup_request_body.dart';
import 'package:riff/features/auth/signup/data/repos/signup_repo.dart';
import 'package:riff/features/auth/signup/logic/cubit/signup_cubit.dart';
import 'package:riff/features/auth/signup/logic/cubit/signup_state.dart';

import 'signup_cubit_test.mocks.dart';

@GenerateMocks([SignupRepo, LoginRepo])
void main() {
  late MockSignupRepo mockSignupRepo;
  late MockLoginRepo mockLoginRepo;
  late SignupCubit cubit;

  final user = User(
    id: 'u1',
    email: 'user@example.com',
    fullName: 'Test User',
    username: 'testuser',
  );

  setUp(() {
    mockSignupRepo = MockSignupRepo();
    mockLoginRepo = MockLoginRepo();
    cubit = SignupCubit(mockSignupRepo, mockLoginRepo);
  });

  void fillForm(SignupCubit c) {
    c.mailController.text = 'user@example.com';
    c.passwordController.text = 'Password123';
    c.fullNameController.text = 'Test User';
    c.usernameController.text = 'testuser';
    c.selectedInstruments = ['guitar'];
    c.selectedGenres = ['rock'];
  }

  blocTest<SignupCubit, SignupState<void>>(
    'emits [loading, success] and auto-logs in when both calls succeed',
    build: () {
      when(mockSignupRepo.signUp(any))
          .thenAnswer((_) async => const ApiResult.success(null));
      when(mockLoginRepo.login(any))
          .thenAnswer((_) async => ApiResult.success(LoginResponse(user: user)));
      return cubit;
    },
    act: (c) {
      fillForm(c);
      c.emitSignupStates();
    },
    expect: () => [
      const SignupState<void>.loading(),
      isA<Success>(),
    ],
    verify: (_) {
      final signupCaptured =
          verify(mockSignupRepo.signUp(captureAny)).captured.single
              as SignupRequestBody;
      expect(signupCaptured.email, 'user@example.com');
      expect(signupCaptured.instruments, ['guitar']);
      expect(signupCaptured.genres, ['rock']);

      final loginCaptured =
          verify(mockLoginRepo.login(captureAny)).captured.single
              as LoginRequestBody;
      expect(loginCaptured.email, 'user@example.com');
      expect(loginCaptured.password, 'Password123');
    },
  );

  blocTest<SignupCubit, SignupState<void>>(
    'still emits success when signup succeeds but the auto-login fails',
    build: () {
      when(mockSignupRepo.signUp(any))
          .thenAnswer((_) async => const ApiResult.success(null));
      when(mockLoginRepo.login(any)).thenAnswer(
        (_) async => ApiResult.failure(ApiErrorModel(message: 'boom')),
      );
      return cubit;
    },
    act: (c) {
      fillForm(c);
      c.emitSignupStates();
    },
    expect: () => [
      const SignupState<void>.loading(),
      isA<Success>(),
    ],
  );

  blocTest<SignupCubit, SignupState<void>>(
    'emits [loading, failure] when signup itself fails',
    build: () {
      when(mockSignupRepo.signUp(any)).thenAnswer(
        (_) async =>
            ApiResult.failure(ApiErrorModel(message: 'Username already taken')),
      );
      return cubit;
    },
    act: (c) {
      fillForm(c);
      c.emitSignupStates();
    },
    expect: () => [
      const SignupState<void>.loading(),
      isA<Error>().having(
        (s) => s.apiErrorModel.message,
        'message',
        'Username already taken',
      ),
    ],
    verify: (_) {
      verifyNever(mockLoginRepo.login(any));
    },
  );
}
