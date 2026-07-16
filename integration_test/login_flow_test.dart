// Integration test for the whole login feature: screen + widgets + cubit,
// driven end-to-end like a real user. The network layer is mocked (per
// https://docs.flutter.dev/cookbook/testing/unit/mocking) so the test is
// deterministic and never hits the real Riff API.
//
// Run with a device/emulator attached:
//   flutter test integration_test/login_flow_test.dart -d <device-id>
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:integration_test/integration_test.dart';
import 'package:mockito/mockito.dart';
import 'package:riff/core/networks/api_error_model.dart';
import 'package:riff/core/networks/api_result.dart';
import 'package:riff/features/auth/login/UI/login_screen.dart';
import 'package:riff/features/auth/login/data/models/login_request_body.dart';
import 'package:riff/features/auth/login/data/models/login_response.dart';
import 'package:riff/features/auth/login/data/models/user.dart';
import 'package:riff/features/auth/login/logic/cubit/login_cubit.dart';
import 'package:riff/generated/l10n.dart';

import '../test/features/auth/login/logic/cubit/login_cubit_test.mocks.dart';

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  late MockLoginRepo mockLoginRepo;

  final user = User(
    id: 'u1',
    email: 'user@example.com',
    fullName: 'Test User',
    username: 'testuser',
  );

  setUp(() {
    mockLoginRepo = MockLoginRepo();
  });

  Widget buildApp() {
    return ScreenUtilInit(
      designSize: const Size(375, 812),
      builder: (_, __) => MaterialApp(
        localizationsDelegates: const [
          S.delegate,
          GlobalMaterialLocalizations.delegate,
          GlobalWidgetsLocalizations.delegate,
          GlobalCupertinoLocalizations.delegate,
        ],
        supportedLocales: S.delegate.supportedLocales,
        routes: {
          '/home': (_) => const Scaffold(body: Text('HOME')),
          '/signup': (_) => const Scaffold(body: Text('SIGNUP')),
          '/forgotPassword': (_) => const Scaffold(body: Text('FORGOT')),
        },
        home: BlocProvider<LoginCubit>(
          create: (_) => LoginCubit(mockLoginRepo),
          child: const LoginScreen(),
        ),
      ),
    );
  }

  group('Login feature end-to-end', () {
    testWidgets(
      'a user with valid credentials can log in and lands on Home',
      (tester) async {
        when(mockLoginRepo.login(any)).thenAnswer(
          (_) async => ApiResult.success(LoginResponse(user: user)),
        );

        await tester.pumpWidget(buildApp());
        await tester.pumpAndSettle();

        final s = S.of(tester.element(find.byType(LoginScreen)));

        await tester.enterText(
          find.byType(TextFormField).first,
          'user@example.com',
        );
        await tester.enterText(
          find.byType(TextFormField).last,
          'Password123',
        );
        await tester.tap(find.text(s.loginBtn));

        // loading dialog shows briefly
        await tester.pump();
        expect(find.byType(CircularProgressIndicator), findsOneWidget);

        await tester.pumpAndSettle();

        final captured =
            verify(mockLoginRepo.login(captureAny)).captured.single
                as LoginRequestBody;
        expect(captured.email, 'user@example.com');
        expect(captured.password, 'Password123');
        expect(find.text('HOME'), findsOneWidget);
      },
    );

    testWidgets(
      'a user cannot submit the form with empty fields',
      (tester) async {
        await tester.pumpWidget(buildApp());
        await tester.pumpAndSettle();

        final s = S.of(tester.element(find.byType(LoginScreen)));
        await tester.tap(find.text(s.loginBtn));
        await tester.pumpAndSettle();

        expect(find.text(s.thisFieldIsRequired), findsOneWidget);
        expect(find.text(s.passwordIsRequired), findsOneWidget);
        verifyNever(mockLoginRepo.login(any));
      },
    );

    testWidgets(
      'a user with wrong credentials sees an error dialog and stays on Login',
      (tester) async {
        when(mockLoginRepo.login(any)).thenAnswer(
          (_) async => ApiResult.failure(
            ApiErrorModel(statusCode: 401, message: 'Invalid credentials'),
          ),
        );

        await tester.pumpWidget(buildApp());
        await tester.pumpAndSettle();

        final s = S.of(tester.element(find.byType(LoginScreen)));
        await tester.enterText(
          find.byType(TextFormField).first,
          'user@example.com',
        );
        await tester.enterText(find.byType(TextFormField).last, 'wrong');
        await tester.tap(find.text(s.loginBtn));
        await tester.pumpAndSettle();

        expect(find.text('Invalid credentials'), findsOneWidget);
        expect(find.byType(LoginScreen), findsOneWidget);

        await tester.tap(find.text(s.gotItBtn));
        await tester.pumpAndSettle();
        expect(find.text('Invalid credentials'), findsNothing);
      },
    );

    testWidgets(
      'a user can navigate to Signup and Forgot Password from Login',
      (tester) async {
        await tester.pumpWidget(buildApp());
        await tester.pumpAndSettle();

        final s = S.of(tester.element(find.byType(LoginScreen)));

        await tester.tap(find.text(s.resetYourPassword));
        await tester.pumpAndSettle();
        expect(find.text('FORGOT'), findsOneWidget);

        // Navigate back and try the signup link.
        await tester.pageBack();
        await tester.pumpAndSettle();

        await tester.tap(find.text(s.joinBtn));
        await tester.pumpAndSettle();
        expect(find.text('SIGNUP'), findsOneWidget);
      },
    );
  });
}
