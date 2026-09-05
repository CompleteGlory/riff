import 'package:bloc_test/bloc_test.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/annotations.dart';
import 'package:mockito/mockito.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:riff/core/helpers/constants.dart';
import 'package:riff/core/networks/api_error_model.dart';
import 'package:riff/core/networks/api_result.dart' hide Success, Failure;
import 'package:riff/features/auth/forgot_password/data/models/request_otp_request_body.dart';
import 'package:riff/features/auth/forgot_password/data/models/reset_password_request_body.dart';
import 'package:riff/features/auth/forgot_password/data/models/verify_otp_request_body.dart';
import 'package:riff/features/auth/forgot_password/data/repos/forgot_pasword_repo.dart';
import 'package:riff/features/auth/forgot_password/logic/cubit/forgot_password_cubit.dart';
import 'package:riff/features/auth/forgot_password/logic/cubit/forgot_password_state.dart';

import 'forgot_password_cubit_test.mocks.dart';

@GenerateMocks([ForgotPasswordRepo])
void main() {
  late MockForgotPasswordRepo mockRepo;
  late ForgotPasswordCubit cubit;

  setUp(() {
    SharedPreferences.setMockInitialValues({});
    mockRepo = MockForgotPasswordRepo();
    cubit = ForgotPasswordCubit(mockRepo);
  });

  group('emitForgotPasswordStates', () {
    blocTest<ForgotPasswordCubit, ForgotPasswordState>(
      'emits [loading, success] and captures the request-otp email',
      build: () {
        when(mockRepo.requestOtp(any))
            .thenAnswer((_) async => const ApiResult.success('reset-tok'));
        return cubit;
      },
      act: (c) {
        c.mailController.text = 'user@example.com';
        c.emitForgotPasswordStates();
      },
      expect: () => [
        const ForgotPasswordState.loading(),
        isA<Success>().having((s) => s.data, 'data', 'OTP sent successfully'),
      ],
      verify: (_) {
        final captured =
            verify(mockRepo.requestOtp(captureAny)).captured.single
                as RequestOtpRequestBody;
        expect(captured.email, 'user@example.com');
      },
    );

    blocTest<ForgotPasswordCubit, ForgotPasswordState>(
      'emits [loading, failure] when the repo fails',
      build: () {
        when(mockRepo.requestOtp(any)).thenAnswer(
          (_) async => ApiResult.failure(ApiErrorModel(message: 'No such user')),
        );
        return cubit;
      },
      act: (c) {
        c.mailController.text = 'nouser@example.com';
        c.emitForgotPasswordStates();
      },
      expect: () => [
        const ForgotPasswordState.loading(),
        isA<Error>()
            .having((s) => s.apiErrorModel.message, 'message', 'No such user'),
      ],
    );
  });

  group('emitVerifyOtpState', () {
    blocTest<ForgotPasswordCubit, ForgotPasswordState>(
      'emits [otpVerificationLoading, otpVerified] and sends the entered otp',
      build: () {
        when(mockRepo.verifyOtp(any))
            .thenAnswer((_) async => const ApiResult.success('verify-tok'));
        return cubit;
      },
      act: (c) {
        c.mailController.text = 'user@example.com';
        c.otp = '123456';
        c.emitVerifyOtpState();
      },
      expect: () => [
        const ForgotPasswordState.otpVerificationLoading(),
        isA<OtpVerified>(),
      ],
      verify: (_) {
        final captured =
            verify(mockRepo.verifyOtp(captureAny)).captured.single
                as VerifyOtpRequestBody;
        expect(captured.email, 'user@example.com');
        expect(captured.otp, '123456');
      },
    );

    blocTest<ForgotPasswordCubit, ForgotPasswordState>(
      'emits [otpVerificationLoading, otpVerificationFailed] on wrong otp',
      build: () {
        when(mockRepo.verifyOtp(any)).thenAnswer(
          (_) async => ApiResult.failure(ApiErrorModel(message: 'Invalid OTP')),
        );
        return cubit;
      },
      act: (c) {
        c.mailController.text = 'user@example.com';
        c.otp = '000000';
        c.emitVerifyOtpState();
      },
      expect: () => [
        const ForgotPasswordState.otpVerificationLoading(),
        isA<OtpVerificationFailed>(),
      ],
    );
  });

  group('emitResetPasswordState', () {
    blocTest<ForgotPasswordCubit, ForgotPasswordState>(
      'uses the token captured earlier from verifyOtp',
      build: () {
        when(mockRepo.verifyOtp(any))
            .thenAnswer((_) async => const ApiResult.success('in-memory-tok'));
        when(mockRepo.resetPassword(any))
            .thenAnswer((_) async => const ApiResult.success(null));
        return cubit;
      },
      act: (c) async {
        c.otp = '123456';
        await c.emitVerifyOtpState();
        c.newPasswordController.text = 'NewPass123';
        c.emitResetPasswordState();
      },
      skip: 2, // otpVerificationLoading, otpVerified — already covered above
      expect: () => [
        const ForgotPasswordState.resetPasswordLoading(),
        isA<ResetPasswordSuccess>(),
      ],
      verify: (_) {
        final captured =
            verify(mockRepo.resetPassword(captureAny)).captured.single
                as ResetPasswordRequestBody;
        expect(captured.resetToken, 'in-memory-tok');
        expect(captured.newPassword, 'NewPass123');
      },
    );

    blocTest<ForgotPasswordCubit, ForgotPasswordState>(
      'uses the token it was seeded with, not the stored session token',
      build: () {
        when(mockRepo.resetPassword(any))
            .thenAnswer((_) async => const ApiResult.success(null));
        return cubit;
      },
      setUp: () {
        // A signed-in session sitting in storage. The cubit used to fall back
        // to reading exactly this key when it held no token of its own —
        // which only worked because the repo had overwritten the live session
        // with the reset token. It must be ignored entirely now.
        SharedPreferences.setMockInitialValues({
          SharedPrefKeys.userToken: 'the-live-session-token',
        });
      },
      act: (c) {
        c.seedResetToken('seeded-reset-tok');
        c.newPasswordController.text = 'NewPass123';
        c.emitResetPasswordState();
      },
      expect: () => [
        const ForgotPasswordState.resetPasswordLoading(),
        isA<ResetPasswordSuccess>(),
      ],
      verify: (_) {
        final captured =
            verify(mockRepo.resetPassword(captureAny)).captured.single
                as ResetPasswordRequestBody;
        expect(captured.resetToken, 'seeded-reset-tok');
      },
    );

    blocTest<ForgotPasswordCubit, ForgotPasswordState>(
      'never reads the session token, even with no reset token seeded',
      build: () {
        when(mockRepo.resetPassword(any))
            .thenAnswer((_) async => const ApiResult.success(null));
        return cubit;
      },
      setUp: () {
        SharedPreferences.setMockInitialValues({
          SharedPrefKeys.userToken: 'the-live-session-token',
        });
      },
      act: (c) {
        c.newPasswordController.text = 'NewPass123';
        c.emitResetPasswordState();
      },
      expect: () => [
        const ForgotPasswordState.resetPasswordLoading(),
        isA<ResetPasswordSuccess>(),
      ],
      verify: (_) {
        final captured =
            verify(mockRepo.resetPassword(captureAny)).captured.single
                as ResetPasswordRequestBody;
        // Empty, and the server rejects it. Sending the user's *real* access
        // token to a password-reset endpoint is the failure mode being
        // guarded against.
        expect(captured.resetToken, isEmpty);
      },
    );

    blocTest<ForgotPasswordCubit, ForgotPasswordState>(
      'emits [resetPasswordLoading, resetPasswordFailed] when the repo fails',
      build: () {
        when(mockRepo.resetPassword(any)).thenAnswer(
          (_) async => ApiResult.failure(ApiErrorModel(message: 'Token expired')),
        );
        return cubit;
      },
      act: (c) {
        c.newPasswordController.text = 'NewPass123';
        c.emitResetPasswordState();
      },
      expect: () => [
        const ForgotPasswordState.resetPasswordLoading(),
        isA<ResetPasswordFailed>(),
      ],
    );
  });
}
