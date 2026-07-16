import 'package:bloc_test/bloc_test.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/annotations.dart';
import 'package:mockito/mockito.dart';
import 'package:riff/core/networks/api_error_model.dart';
import 'package:riff/core/networks/api_result.dart' hide Success, Failure;
import 'package:riff/features/auth/login/data/models/login_response.dart';
import 'package:riff/features/auth/login/data/models/user.dart';
import 'package:riff/features/auth/login/data/repos/login_repo.dart';
import 'package:riff/features/auth/login/logic/cubit/login_cubit.dart';
import 'package:riff/features/auth/login/logic/cubit/login_state.dart';

import 'login_cubit_test.mocks.dart';

@GenerateMocks([LoginRepo])
void main() {
  late MockLoginRepo mockLoginRepo;
  late LoginCubit loginCubit;

  final user = User(
    id: 'u1',
    email: 'user@example.com',
    fullName: 'Test User',
    username: 'testuser',
  );

  setUp(() {
    mockLoginRepo = MockLoginRepo();
    loginCubit = LoginCubit(mockLoginRepo);
  });

  test('initial state is LoginState.initial', () async {
    expect(loginCubit.state, const LoginState<LoginResponse>.initial());
    await loginCubit.close();
  });

  group('emitLoginStates', () {
    blocTest<LoginCubit, LoginState<LoginResponse>>(
      'emits [loading, success] when the repo returns a successful login',
      build: () {
        when(mockLoginRepo.login(any)).thenAnswer(
          (_) async => ApiResult.success(LoginResponse(user: user)),
        );
        return loginCubit;
      },
      act: (cubit) {
        cubit.mailController.text = 'user@example.com';
        cubit.passwordController.text = 'Password123';
        cubit.emitLoginStates();
      },
      expect: () => [
        const LoginState<LoginResponse>.loading(),
        isA<Success<LoginResponse>>()
            .having((s) => s.data.user.id, 'user.id', 'u1'),
      ],
      verify: (_) {
        final captured =
            verify(mockLoginRepo.login(captureAny)).captured.single;
        expect(captured.email, 'user@example.com');
        expect(captured.password, 'Password123');
      },
    );

    blocTest<LoginCubit, LoginState<LoginResponse>>(
      'emits [loading, failure] when the repo returns an error',
      build: () {
        when(mockLoginRepo.login(any)).thenAnswer(
          (_) async => ApiResult.failure(
            ApiErrorModel(statusCode: 401, message: 'Invalid credentials'),
          ),
        );
        return loginCubit;
      },
      act: (cubit) {
        cubit.mailController.text = 'user@example.com';
        cubit.passwordController.text = 'wrong-password';
        cubit.emitLoginStates();
      },
      expect: () => [
        const LoginState<LoginResponse>.loading(),
        isA<Error<LoginResponse>>().having(
          (s) => s.apiErrorModel.message,
          'error message',
          'Invalid credentials',
        ),
      ],
    );
  });

  group('loginWithGoogle', () {
    blocTest<LoginCubit, LoginState<LoginResponse>>(
      'emits [loading, success] when Google login succeeds',
      build: () {
        when(mockLoginRepo.loginWithGoogle(any)).thenAnswer(
          (_) async => ApiResult.success(
            LoginResponse(user: user, isNewUser: false),
          ),
        );
        return loginCubit;
      },
      act: (cubit) => cubit.loginWithGoogle('id-token'),
      expect: () => [
        const LoginState<LoginResponse>.loading(),
        isA<Success<LoginResponse>>()
            .having((s) => s.data.isNewUser, 'isNewUser', isFalse),
      ],
      verify: (_) {
        verify(mockLoginRepo.loginWithGoogle('id-token')).called(1);
      },
    );

    blocTest<LoginCubit, LoginState<LoginResponse>>(
      'emits [loading, failure] when Google login fails',
      build: () {
        when(mockLoginRepo.loginWithGoogle(any)).thenAnswer(
          (_) async => ApiResult.failure(
            ApiErrorModel(message: 'Google sign-in failed'),
          ),
        );
        return loginCubit;
      },
      act: (cubit) => cubit.loginWithGoogle('bad-token'),
      expect: () => [
        const LoginState<LoginResponse>.loading(),
        isA<Error<LoginResponse>>(),
      ],
    );
  });
}
