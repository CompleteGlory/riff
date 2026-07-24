import 'package:bloc_test/bloc_test.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/annotations.dart';
import 'package:mockito/mockito.dart';
import 'package:riff/core/networks/api_error_model.dart';
import 'package:riff/core/networks/api_result.dart';
import 'package:riff/features/auth/phone_verify/data/repos/phone_verify_repo.dart';
import 'package:riff/features/auth/phone_verify/logic/cubit/phone_verify_cubit.dart';
import 'package:riff/features/auth/phone_verify/logic/cubit/phone_verify_state.dart';

import 'phone_verify_cubit_test.mocks.dart';

@GenerateMocks([PhoneVerifyRepo])
void main() {
  late MockPhoneVerifyRepo mockRepo;
  late PhoneVerifyCubit cubit;

  setUp(() {
    mockRepo = MockPhoneVerifyRepo();
    cubit = PhoneVerifyCubit(mockRepo);
  });

  test('initial state is PhoneVerifyInitial', () {
    expect(cubit.state, isA<PhoneVerifyInitial>());
  });

  group('sendOtp', () {
    blocTest<PhoneVerifyCubit, PhoneVerifyState>(
      'normalizes the phone number, emits [loading, otpSent]',
      build: () {
        when(mockRepo.sendOtp(any))
            .thenAnswer((_) async => const ApiResult.success(null));
        return cubit;
      },
      act: (c) => c.sendOtp('+20 100-123-4567'),
      expect: () => [
        isA<PhoneVerifyLoading>(),
        isA<PhoneVerifyOtpSent>()
            .having((s) => s.phoneNumber, 'phoneNumber', '201001234567'),
      ],
      verify: (c) {
        expect(c.phoneNumber, '201001234567');
        verify(mockRepo.sendOtp('201001234567')).called(1);
      },
    );

    blocTest<PhoneVerifyCubit, PhoneVerifyState>(
      'maps a 409 conflict to PHONE_ALREADY_TAKEN',
      build: () {
        when(mockRepo.sendOtp(any)).thenAnswer(
          (_) async => ApiResult.failure(ApiErrorModel(statusCode: 409)),
        );
        return cubit;
      },
      act: (c) => c.sendOtp('01001234567'),
      expect: () => [
        isA<PhoneVerifyLoading>(),
        isA<PhoneVerifyError>()
            .having((s) => s.message, 'message', 'PHONE_ALREADY_TAKEN'),
      ],
    );

    blocTest<PhoneVerifyCubit, PhoneVerifyState>(
      'surfaces the server message for other failures',
      build: () {
        when(mockRepo.sendOtp(any)).thenAnswer(
          (_) async =>
              ApiResult.failure(ApiErrorModel(message: 'Server unavailable')),
        );
        return cubit;
      },
      act: (c) => c.sendOtp('01001234567'),
      expect: () => [
        isA<PhoneVerifyLoading>(),
        isA<PhoneVerifyError>()
            .having((s) => s.message, 'message', 'Server unavailable'),
      ],
    );
  });

  group('verifyOtp', () {
    blocTest<PhoneVerifyCubit, PhoneVerifyState>(
      'emits [loading, success] with the previously sent phone number',
      build: () {
        when(mockRepo.sendOtp(any))
            .thenAnswer((_) async => const ApiResult.success(null));
        when(mockRepo.verifyOtp(any, any))
            .thenAnswer((_) async => const ApiResult.success(null));
        return cubit;
      },
      act: (c) async {
        await c.sendOtp('01001234567');
        await c.verifyOtp('123456');
      },
      skip: 2, // loading, otpSent from sendOtp — covered above
      expect: () => [
        isA<PhoneVerifyLoading>(),
        isA<PhoneVerifySuccess>(),
      ],
      verify: (_) {
        verify(mockRepo.verifyOtp('01001234567', '123456')).called(1);
      },
    );

    blocTest<PhoneVerifyCubit, PhoneVerifyState>(
      'emits [loading, error] on an invalid code',
      build: () {
        when(mockRepo.sendOtp(any))
            .thenAnswer((_) async => const ApiResult.success(null));
        when(mockRepo.verifyOtp(any, any)).thenAnswer(
          (_) async => ApiResult.failure(ApiErrorModel(message: 'Invalid OTP')),
        );
        return cubit;
      },
      act: (c) async {
        await c.sendOtp('01001234567');
        await c.verifyOtp('000000');
      },
      skip: 2,
      expect: () => [
        isA<PhoneVerifyLoading>(),
        isA<PhoneVerifyError>()
            .having((s) => s.message, 'message', 'Invalid OTP'),
      ],
    );

    blocTest<PhoneVerifyCubit, PhoneVerifyState>(
      'does nothing when no phone number has been sent yet',
      build: () => cubit,
      act: (c) => c.verifyOtp('123456'),
      expect: () => <PhoneVerifyState>[],
      verify: (_) {
        verifyNever(mockRepo.verifyOtp(any, any));
      },
    );

    blocTest<PhoneVerifyCubit, PhoneVerifyState>(
      'does nothing when a verification is already in flight',
      build: () => cubit,
      seed: () => PhoneVerifyLoading(),
      act: (c) => c.verifyOtp('123456'),
      expect: () => <PhoneVerifyState>[],
      verify: (_) {
        verifyNever(mockRepo.verifyOtp(any, any));
      },
    );
  });

  blocTest<PhoneVerifyCubit, PhoneVerifyState>(
    'resetToInitial emits PhoneVerifyInitial',
    build: () => cubit,
    seed: () => PhoneVerifyError('boom'),
    act: (c) => c.resetToInitial(),
    expect: () => [isA<PhoneVerifyInitial>()],
  );
}
