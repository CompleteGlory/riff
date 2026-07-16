import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/mockito.dart';
import 'package:riff/core/networks/api_error_model.dart';
import 'package:riff/core/networks/api_result.dart';
import 'package:riff/features/auth/login/UI/widgets/login_bloc_listener.dart';
import 'package:riff/features/auth/login/data/models/login_response.dart';
import 'package:riff/features/auth/login/data/models/user.dart';
import 'package:riff/features/auth/login/logic/cubit/login_cubit.dart';
import 'package:riff/generated/l10n.dart';

import '../../../../../helpers/pump_app.dart';
import '../../logic/cubit/login_cubit_test.mocks.dart';

void main() {
  late MockLoginRepo mockLoginRepo;
  late LoginCubit loginCubit;
  bool onLoginSuccessCalled = false;

  final user = User(
    id: 'u1',
    email: 'user@example.com',
    fullName: 'Test User',
    username: 'testuser',
  );

  setUp(() {
    mockLoginRepo = MockLoginRepo();
    loginCubit = LoginCubit(mockLoginRepo);
    onLoginSuccessCalled = false;
  });

  tearDown(() => loginCubit.close());

  Future<void> pumpListener(
    WidgetTester tester, {
    bool isSignupFlow = false,
  }) async {
    await pumpApp(
      tester,
      BlocProvider<LoginCubit>.value(
        value: loginCubit,
        child: Scaffold(
          body: LoginBlocListener(
            isSignupFlow: isSignupFlow,
            onLoginSuccess: () async {
              onLoginSuccessCalled = true;
            },
          ),
        ),
      ),
      routes: {'/home': (_) => const Scaffold(body: Text('HOME'))},
    );
  }

  testWidgets('shows a loading dialog while the cubit is loading',
      (tester) async {
    when(mockLoginRepo.login(any)).thenAnswer(
      (_) async {
        await Future.delayed(const Duration(milliseconds: 300));
        return ApiResult.success(LoginResponse(user: user));
      },
    );
    await pumpListener(tester);

    loginCubit.emitLoginStates();
    await tester.pump(); // deliver the Loading state to the BlocListener
    await tester.pump(); // flush the addPostFrameCallback that calls showDialog
    await tester.pump(); // build/paint the pushed dialog route

    expect(find.byType(CircularProgressIndicator), findsOneWidget);

    await tester.pumpAndSettle();
  });

  testWidgets('dismisses loading and navigates home on success',
      (tester) async {
    when(mockLoginRepo.login(any)).thenAnswer(
      (_) async => ApiResult.success(LoginResponse(user: user)),
    );
    await pumpListener(tester);

    await loginCubit.emitLoginStates();
    await tester.pumpAndSettle();

    expect(find.byType(CircularProgressIndicator), findsNothing);
    expect(find.text('HOME'), findsOneWidget);
    expect(onLoginSuccessCalled, isTrue);
  });

  testWidgets('shows an error dialog with the API message on failure',
      (tester) async {
    when(mockLoginRepo.login(any)).thenAnswer(
      (_) async => ApiResult.failure(
        ApiErrorModel(statusCode: 401, message: 'Invalid credentials'),
      ),
    );
    await pumpListener(tester);

    await loginCubit.emitLoginStates();
    await tester.pumpAndSettle();

    expect(find.byType(CircularProgressIndicator), findsNothing);
    expect(find.text('Invalid credentials'), findsOneWidget);
    expect(find.text(S.current.gotItBtn), findsOneWidget);

    await tester.tap(find.text(S.current.gotItBtn));
    await tester.pumpAndSettle();
    expect(find.text('Invalid credentials'), findsNothing);
  });

  testWidgets(
      'shows the "already linked" dialog during signup when Google account exists',
      (tester) async {
    when(mockLoginRepo.loginWithGoogle(any)).thenAnswer(
      (_) async => ApiResult.success(
        LoginResponse(user: user, isNewUser: false),
      ),
    );
    await pumpListener(tester, isSignupFlow: true);

    await loginCubit.loginWithGoogle('id-token');
    await tester.pumpAndSettle();

    expect(find.text(S.current.gmailAlreadyLinkedTitle), findsOneWidget);

    await tester.tap(find.text(S.current.gotItBtn));
    await tester.pumpAndSettle();

    expect(find.text('HOME'), findsOneWidget);
    expect(onLoginSuccessCalled, isTrue);
  });

  testWidgets(
      'skips the "already linked" dialog outside of the signup flow',
      (tester) async {
    when(mockLoginRepo.loginWithGoogle(any)).thenAnswer(
      (_) async => ApiResult.success(
        LoginResponse(user: user, isNewUser: false),
      ),
    );
    await pumpListener(tester);

    await loginCubit.loginWithGoogle('id-token');
    await tester.pumpAndSettle();

    expect(find.text(S.current.gmailAlreadyLinkedTitle), findsNothing);
    expect(find.text('HOME'), findsOneWidget);
  });
}
