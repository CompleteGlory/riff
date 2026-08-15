import 'package:bloc_test/bloc_test.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/annotations.dart';
import 'package:mockito/mockito.dart';
import 'package:riff/core/networks/api_error_model.dart';
import 'package:riff/core/networks/api_result.dart';
import 'package:riff/features/home/account_settings/data/repos/delete_account_repo.dart';
import 'package:riff/features/home/account_settings/logic/delete_account_cubit.dart';

import 'delete_account_cubit_test.mocks.dart';

@GenerateMocks([DeleteAccountRepo])
void main() {
  late MockDeleteAccountRepo mockRepo;

  setUp(() => mockRepo = MockDeleteAccountRepo());

  blocTest<DeleteAccountCubit, DeleteAccountState>(
    'goes loading then success when the server accepts',
    build: () {
      when(mockRepo.deleteAccount(
        password: anyNamed('password'),
        confirmUsername: anyNamed('confirmUsername'),
      )).thenAnswer((_) async => const ApiResult.success(null));
      return DeleteAccountCubit(mockRepo);
    },
    act: (cubit) => cubit.deleteAccount(password: 'hunter2'),
    expect: () => [
      isA<DeleteAccountState>()
          .having((s) => s.status, 'status', DeleteAccountStatus.loading),
      isA<DeleteAccountState>()
          .having((s) => s.status, 'status', DeleteAccountStatus.success),
    ],
  );

  blocTest<DeleteAccountCubit, DeleteAccountState>(
    'flags a 401 as a wrong credential rather than a general failure',
    build: () {
      when(mockRepo.deleteAccount(
        password: anyNamed('password'),
        confirmUsername: anyNamed('confirmUsername'),
      )).thenAnswer((_) async => ApiResult.failure(
            ApiErrorModel(statusCode: 401, message: 'Incorrect password'),
          ));
      return DeleteAccountCubit(mockRepo);
    },
    act: (cubit) => cubit.deleteAccount(password: 'wrong'),
    // The screen shows this against the password field; anything else becomes
    // a "couldn't delete your account" snackbar, which would be the wrong
    // advice for a typo.
    expect: () => [
      isA<DeleteAccountState>()
          .having((s) => s.status, 'status', DeleteAccountStatus.loading),
      isA<DeleteAccountState>()
          .having((s) => s.status, 'status', DeleteAccountStatus.failure)
          .having((s) => s.wrongCredential, 'wrongCredential', true),
    ],
  );

  blocTest<DeleteAccountCubit, DeleteAccountState>(
    'treats any other failure as a general one',
    build: () {
      when(mockRepo.deleteAccount(
        password: anyNamed('password'),
        confirmUsername: anyNamed('confirmUsername'),
      )).thenAnswer((_) async => ApiResult.failure(
            ApiErrorModel(statusCode: 500, message: 'Server error'),
          ));
      return DeleteAccountCubit(mockRepo);
    },
    act: (cubit) => cubit.deleteAccount(password: 'hunter2'),
    expect: () => [
      isA<DeleteAccountState>()
          .having((s) => s.status, 'status', DeleteAccountStatus.loading),
      isA<DeleteAccountState>()
          .having((s) => s.status, 'status', DeleteAccountStatus.failure)
          .having((s) => s.wrongCredential, 'wrongCredential', false)
          .having((s) => s.errorMessage, 'errorMessage', 'Server error'),
    ],
  );

  blocTest<DeleteAccountCubit, DeleteAccountState>(
    'passes the typed username through for an OAuth account',
    build: () {
      when(mockRepo.deleteAccount(
        password: anyNamed('password'),
        confirmUsername: anyNamed('confirmUsername'),
      )).thenAnswer((_) async => const ApiResult.success(null));
      return DeleteAccountCubit(mockRepo);
    },
    act: (cubit) => cubit.deleteAccount(confirmUsername: 'magd'),
    verify: (_) {
      verify(mockRepo.deleteAccount(password: null, confirmUsername: 'magd'))
          .called(1);
    },
  );

  blocTest<DeleteAccountCubit, DeleteAccountState>(
    'clears a previous error when a retry starts',
    build: () {
      when(mockRepo.deleteAccount(
        password: anyNamed('password'),
        confirmUsername: anyNamed('confirmUsername'),
      )).thenAnswer((_) async => const ApiResult.success(null));
      return DeleteAccountCubit(mockRepo);
    },
    seed: () => const DeleteAccountState(
      status: DeleteAccountStatus.failure,
      errorMessage: 'Incorrect password',
      wrongCredential: true,
    ),
    act: (cubit) => cubit.deleteAccount(password: 'right-this-time'),
    expect: () => [
      isA<DeleteAccountState>()
          .having((s) => s.status, 'status', DeleteAccountStatus.loading)
          .having((s) => s.errorMessage, 'errorMessage', isNull)
          .having((s) => s.wrongCredential, 'wrongCredential', false),
      isA<DeleteAccountState>()
          .having((s) => s.status, 'status', DeleteAccountStatus.success),
    ],
  );
}
