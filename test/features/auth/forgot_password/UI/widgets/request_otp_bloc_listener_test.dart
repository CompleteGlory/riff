import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/mockito.dart';
import 'package:riff/core/networks/api_error_model.dart';
import 'package:riff/core/networks/api_result.dart';
import 'package:riff/features/auth/forgot_password/UI/widgets/request_otp_bloc_listener.dart';
import 'package:riff/features/auth/forgot_password/logic/cubit/forgot_password_cubit.dart';

import '../../../../../helpers/pump_app.dart';
import '../../logic/cubit/forgot_password_cubit_test.mocks.dart';

void main() {
  late MockForgotPasswordRepo mockRepo;
  late ForgotPasswordCubit cubit;

  setUp(() {
    mockRepo = MockForgotPasswordRepo();
    cubit = ForgotPasswordCubit(mockRepo);
  });

  tearDown(() => cubit.close());

  Future<void> pumpListener(WidgetTester tester) async {
    await pumpApp(
      tester,
      BlocProvider<ForgotPasswordCubit>.value(
        value: cubit,
        child: const Scaffold(body: VerifyOTPBlocListener()),
      ),
      routes: {
        '/resetPassword': (_) => const Scaffold(body: Text('RESET_PASSWORD')),
      },
    );
  }

  testWidgets('shows a loading dialog while verifying the OTP',
      (tester) async {
    when(mockRepo.verifyOtp(any)).thenAnswer((_) async {
      await Future.delayed(const Duration(milliseconds: 300));
      return const ApiResult.success('tok');
    });
    await pumpListener(tester);

    cubit.otp = '123456';
    cubit.emitVerifyOtpState();
    await tester.pump();
    await tester.pump();
    await tester.pump();

    expect(find.byType(CircularProgressIndicator), findsOneWidget);
    await tester.pumpAndSettle();
  });

  testWidgets('navigates to reset-password on success', (tester) async {
    when(mockRepo.verifyOtp(any))
        .thenAnswer((_) async => const ApiResult.success('tok'));
    await pumpListener(tester);

    cubit.otp = '123456';
    await cubit.emitVerifyOtpState();
    await tester.pumpAndSettle();

    expect(find.byType(CircularProgressIndicator), findsNothing);
    expect(find.text('RESET_PASSWORD'), findsOneWidget);
  });

  testWidgets('shows an error dialog on an invalid code', (tester) async {
    when(mockRepo.verifyOtp(any)).thenAnswer(
      (_) async => ApiResult.failure(ApiErrorModel(message: 'Invalid OTP')),
    );
    await pumpListener(tester);

    cubit.otp = '000000';
    await cubit.emitVerifyOtpState();
    await tester.pumpAndSettle();

    expect(find.text('Invalid OTP'), findsOneWidget);
    expect(find.text('RESET_PASSWORD'), findsNothing);
  });
}
