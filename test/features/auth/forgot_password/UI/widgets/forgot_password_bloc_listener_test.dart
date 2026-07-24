import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/mockito.dart';
import 'package:riff/core/networks/api_error_model.dart';
import 'package:riff/core/networks/api_result.dart';
import 'package:riff/features/auth/forgot_password/UI/widgets/forgot_password_bloc_listener.dart';
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
        child: const Scaffold(body: ForgotPasswordBlocListener()),
      ),
      routes: {
        '/enterCode': (_) => const Scaffold(body: Text('ENTER_CODE')),
      },
    );
  }

  testWidgets('shows a loading dialog while requesting the OTP',
      (tester) async {
    when(mockRepo.requestOtp(any)).thenAnswer((_) async {
      await Future.delayed(const Duration(milliseconds: 300));
      return const ApiResult.success('tok');
    });
    await pumpListener(tester);

    cubit.mailController.text = 'user@example.com';
    cubit.emitForgotPasswordStates();
    await tester.pump();
    await tester.pump();
    await tester.pump();

    expect(find.byType(CircularProgressIndicator), findsOneWidget);
    await tester.pumpAndSettle();
  });

  testWidgets('navigates to enter-code on success', (tester) async {
    when(mockRepo.requestOtp(any))
        .thenAnswer((_) async => const ApiResult.success('tok'));
    await pumpListener(tester);

    cubit.mailController.text = 'user@example.com';
    await cubit.emitForgotPasswordStates();
    await tester.pumpAndSettle();

    expect(find.byType(CircularProgressIndicator), findsNothing);
    expect(find.text('ENTER_CODE'), findsOneWidget);
  });

  testWidgets('shows an error dialog on failure', (tester) async {
    when(mockRepo.requestOtp(any)).thenAnswer(
      (_) async => ApiResult.failure(ApiErrorModel(message: 'No such user')),
    );
    await pumpListener(tester);

    cubit.mailController.text = 'nouser@example.com';
    await cubit.emitForgotPasswordStates();
    await tester.pumpAndSettle();

    expect(find.text('No such user'), findsOneWidget);
    expect(find.text('ENTER_CODE'), findsNothing);
  });
}
