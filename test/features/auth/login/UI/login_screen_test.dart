import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/mockito.dart';
import 'package:riff/core/networks/api_error_model.dart';
import 'package:riff/core/networks/api_result.dart';
import 'package:riff/features/auth/login/UI/login_screen.dart';
import 'package:riff/features/auth/login/data/models/login_request_body.dart';
import 'package:riff/features/auth/login/data/models/login_response.dart';
import 'package:riff/features/auth/login/data/models/user.dart';
import 'package:riff/features/auth/login/logic/cubit/login_cubit.dart';
import 'package:riff/generated/l10n.dart';

import '../../../../helpers/pump_app.dart';
import '../logic/cubit/login_cubit_test.mocks.dart';

void main() {
  late MockLoginRepo mockLoginRepo;
  late LoginCubit loginCubit;

  setUp(() {
    mockLoginRepo = MockLoginRepo();
    loginCubit = LoginCubit(mockLoginRepo);
  });

  tearDown(() => loginCubit.close());

  Future<void> pumpLoginScreen(WidgetTester tester) async {
    await pumpApp(
      tester,
      BlocProvider<LoginCubit>.value(
        value: loginCubit,
        child: LoginScreen(onLoginSuccess: () async {}),
      ),
      routes: {
        '/home': (_) => const Scaffold(body: Text('HOME')),
        '/signup': (_) => const Scaffold(body: Text('SIGNUP')),
        '/forgotPassword': (_) => const Scaffold(body: Text('FORGOT')),
      },
    );
  }

  testWidgets('renders the login form with title and CTA', (tester) async {
    await pumpLoginScreen(tester);

    final s = S.current;
    expect(find.text(s.loginTitle), findsOneWidget);
    expect(find.text(s.loginBtn), findsOneWidget);
    expect(find.text(s.continueWithGoogle), findsOneWidget);
    verifyNever(mockLoginRepo.login(any));
  });

  testWidgets('does not call the repo when the form is invalid',
      (tester) async {
    await pumpLoginScreen(tester);

    await tester.tap(find.text(S.current.loginBtn));
    await tester.pumpAndSettle();

    expect(find.text(S.current.thisFieldIsRequired), findsOneWidget);
    expect(find.text(S.current.passwordIsRequired), findsOneWidget);
    verifyNever(mockLoginRepo.login(any));
  });

  testWidgets('submits the entered credentials and navigates home on success',
      (tester) async {
    when(mockLoginRepo.login(any)).thenAnswer(
      (_) async => ApiResult.success(
        LoginResponse(
          user: User(
            id: 'u1',
            email: 'user@example.com',
            fullName: 'Test User',
            username: 'testuser',
          ),
        ),
      ),
    );
    await pumpLoginScreen(tester);

    await tester.enterText(
        find.byType(TextFormField).first, 'user@example.com');
    await tester.enterText(find.byType(TextFormField).last, 'Password123');
    await tester.tap(find.text(S.current.loginBtn));
    await tester.pumpAndSettle();

    final captured =
        verify(mockLoginRepo.login(captureAny)).captured.single
            as LoginRequestBody;
    expect(captured.email, 'user@example.com');
    expect(captured.password, 'Password123');
    expect(find.text('HOME'), findsOneWidget);
  });

  testWidgets('shows an error dialog when the credentials are rejected',
      (tester) async {
    when(mockLoginRepo.login(any)).thenAnswer(
      (_) async => ApiResult.failure(
        ApiErrorModel(statusCode: 401, message: 'Invalid credentials'),
      ),
    );
    await pumpLoginScreen(tester);

    await tester.enterText(
        find.byType(TextFormField).first, 'user@example.com');
    await tester.enterText(find.byType(TextFormField).last, 'wrong-pass');
    await tester.tap(find.text(S.current.loginBtn));
    await tester.pumpAndSettle();

    expect(find.text('Invalid credentials'), findsOneWidget);
    expect(find.text('HOME'), findsNothing);
  });

  testWidgets('navigates to signup when "Join" is tapped', (tester) async {
    await pumpLoginScreen(tester);

    await tester.tap(find.text(S.current.joinBtn));
    await tester.pumpAndSettle();

    expect(find.text('SIGNUP'), findsOneWidget);
  });

  testWidgets('navigates to forgot password when reset link is tapped',
      (tester) async {
    await pumpLoginScreen(tester);

    await tester.tap(find.text(S.current.resetYourPassword));
    await tester.pumpAndSettle();

    expect(find.text('FORGOT'), findsOneWidget);
  });
}
