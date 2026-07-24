import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/mockito.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:riff/core/networks/api_error_model.dart';
import 'package:riff/core/networks/api_result.dart';
import 'package:riff/features/auth/forgot_password/UI/widgets/reset_password_bloc_listener.dart';
import 'package:riff/features/auth/forgot_password/logic/cubit/forgot_password_cubit.dart';
import 'package:riff/generated/l10n.dart';

import '../../../../../helpers/pump_app.dart';
import '../../logic/cubit/forgot_password_cubit_test.mocks.dart';

void main() {
  late MockForgotPasswordRepo mockRepo;
  late ForgotPasswordCubit cubit;

  setUp(() {
    // ForgotPasswordCubit.emitResetPasswordState() falls back to reading a
    // stored token from SharedPreferences when none is held in memory (which
    // is always the case in this file, since these tests call it directly
    // without a prior requestOtp/verifyOtp) — without this, the real
    // SharedPreferences platform channel call never resolves in a widget
    // test and hangs the test indefinitely.
    SharedPreferences.setMockInitialValues({});
    mockRepo = MockForgotPasswordRepo();
    cubit = ForgotPasswordCubit(mockRepo);
  });

  tearDown(() => cubit.close());

  Future<void> pumpListener(WidgetTester tester) async {
    await pumpApp(
      tester,
      BlocProvider<ForgotPasswordCubit>.value(
        value: cubit,
        child: const Scaffold(body: ResetPasswordBlocListener()),
      ),
      routes: {
        '/login': (_) => const Scaffold(body: Text('LOGIN')),
      },
    );
  }

  testWidgets('shows a loading dialog while resetting the password',
      (tester) async {
    when(mockRepo.resetPassword(any)).thenAnswer((_) async {
      await Future.delayed(const Duration(milliseconds: 300));
      return const ApiResult.success(null);
    });
    await pumpListener(tester);

    cubit.newPasswordController.text = 'NewPass123';
    cubit.emitResetPasswordState();
    await tester.pump();
    await tester.pump();
    await tester.pump();

    expect(find.byType(CircularProgressIndicator), findsOneWidget);
    await tester.pumpAndSettle();
  });

  testWidgets(
      'shows the success dialog and navigates to login when proceeding',
      (tester) async {
    when(mockRepo.resetPassword(any))
        .thenAnswer((_) async => const ApiResult.success(null));
    await pumpListener(tester);

    cubit.newPasswordController.text = 'NewPass123';
    await cubit.emitResetPasswordState();
    await tester.pumpAndSettle();

    expect(find.byType(CircularProgressIndicator), findsNothing);
    expect(find.text(S.current.successTitle), findsOneWidget);

    await tester.tap(find.text(S.current.proceedToLogin));
    await tester.pumpAndSettle();
    expect(find.text('LOGIN'), findsOneWidget);
  });

  testWidgets('shows an error dialog when the reset fails', (tester) async {
    when(mockRepo.resetPassword(any)).thenAnswer(
      (_) async => ApiResult.failure(ApiErrorModel(message: 'Token expired')),
    );
    await pumpListener(tester);

    cubit.newPasswordController.text = 'NewPass123';
    await cubit.emitResetPasswordState();
    await tester.pumpAndSettle();

    expect(find.text('Token expired'), findsOneWidget);
    expect(find.text(S.current.successTitle), findsNothing);
  });
}
