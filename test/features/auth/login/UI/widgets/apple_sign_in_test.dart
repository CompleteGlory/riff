import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/mockito.dart';
import 'package:riff/core/networks/api_result.dart';
import 'package:riff/features/auth/login/UI/widgets/apple_sign_in_helper.dart';
import 'package:riff/features/auth/login/UI/widgets/google_sign_in_helper.dart';
import 'package:riff/features/auth/login/UI/widgets/social_login.dart';
import 'package:riff/features/auth/login/data/models/login_response.dart';
import 'package:riff/features/auth/login/data/models/user.dart';
import 'package:riff/features/auth/login/logic/cubit/login_cubit.dart';
import 'package:riff/generated/l10n.dart';

import '../../../../../helpers/pump_app.dart';
import '../../logic/cubit/login_cubit_test.mocks.dart';

/// Google seam stubbed out so these tests only exercise the Apple path.
class _StubGoogleAuthService implements GoogleAuthService {
  @override
  Future<GoogleSignInResult> signIn() async =>
      const GoogleSignInResult(GoogleSignInStatus.cancelled);
}

/// Fake Sign in with Apple seam — the real one drives a platform channel.
class FakeAppleAuthService implements AppleAuthService {
  FakeAppleAuthService({
    this.available = true,
    this.credential,
    this.status,
    this.detail,
  });

  final bool available;
  final AppleCredential? credential;

  /// Status used when [credential] is null — lets a test pick between a
  /// cancellation (silent) and a real failure (which must be reported).
  final AppleSignInStatus? status;
  final String? detail;
  int signInCount = 0;

  @override
  Future<bool> isAvailable() async => available;

  @override
  Future<AppleSignInResult> signIn() async {
    signInCount++;
    if (credential != null) {
      return AppleSignInResult(
        AppleSignInStatus.success,
        credential: credential,
      );
    }
    return AppleSignInResult(
      status ?? AppleSignInStatus.cancelled,
      detail: detail,
    );
  }
}

User _user() => User(
      id: 'u1',
      email: 'someone@privaterelay.appleid.com',
      fullName: 'Magd Kamal',
      username: 'someone',
    );

void main() {
  late MockLoginRepo mockLoginRepo;
  late LoginCubit loginCubit;

  setUp(() {
    mockLoginRepo = MockLoginRepo();
    loginCubit = LoginCubit(mockLoginRepo);
  });

  tearDown(() => loginCubit.close());

  Future<void> pumpSocialLogin(
    WidgetTester tester,
    AppleAuthService appleService,
  ) async {
    await pumpApp(
      tester,
      BlocProvider<LoginCubit>.value(
        value: loginCubit,
        child: Scaffold(
          body: SocialLogin(
            googleAuthService: _StubGoogleAuthService(),
            appleAuthService: appleService,
          ),
        ),
      ),
    );
  }

  testWidgets('shows the Apple button when the platform offers it',
      (tester) async {
    await pumpSocialLogin(tester, FakeAppleAuthService(available: true));
    final s = S.of(tester.element(find.byType(SocialLogin)));

    expect(find.text(s.continueWithApple), findsOneWidget);
  });

  testWidgets('hides the Apple button where it is unavailable', (tester) async {
    // Android has no Sign in with Apple here — guideline 4.8 is an iOS
    // requirement and the web flow needs a Services ID that does not exist.
    await pumpSocialLogin(tester, FakeAppleAuthService(available: false));
    final s = S.of(tester.element(find.byType(SocialLogin)));

    expect(find.text(s.continueWithApple), findsNothing);
    expect(find.text(s.continueWithGoogle), findsOneWidget);
  });

  testWidgets('Apple sits above Google, as the guidelines require',
      (tester) async {
    await pumpSocialLogin(tester, FakeAppleAuthService(available: true));
    final s = S.of(tester.element(find.byType(SocialLogin)));

    final appleY = tester.getTopLeft(find.text(s.continueWithApple)).dy;
    final googleY = tester.getTopLeft(find.text(s.continueWithGoogle)).dy;
    expect(appleY, lessThan(googleY));
  });

  testWidgets('forwards the identity token and first-time name to the cubit',
      (tester) async {
    when(mockLoginRepo.loginWithApple(any, fullName: anyNamed('fullName')))
        .thenAnswer((_) async => ApiResult.success(
              LoginResponse(user: _user(), isNewUser: true),
            ));

    final fake = FakeAppleAuthService(
      credential: const AppleCredential(
        identityToken: 'apple-token',
        fullName: 'Magd Kamal',
      ),
    );
    await pumpSocialLogin(tester, fake);
    final s = S.of(tester.element(find.byType(SocialLogin)));

    await tester.tap(find.text(s.continueWithApple));
    await tester.pumpAndSettle();

    expect(fake.signInCount, 1);
    verify(mockLoginRepo.loginWithApple('apple-token', fullName: 'Magd Kamal'))
        .called(1);
  });

  testWidgets('a cancelled sheet signs nobody in and shows no error',
      (tester) async {
    // signIn() returning null covers cancel as well as failure; an error
    // toast for a deliberate cancel would just be noise.
    final fake = FakeAppleAuthService(credential: null);
    await pumpSocialLogin(tester, fake);
    final s = S.of(tester.element(find.byType(SocialLogin)));

    await tester.tap(find.text(s.continueWithApple));
    await tester.pumpAndSettle();

    expect(fake.signInCount, 1);
    verifyNever(
      mockLoginRepo.loginWithApple(any, fullName: anyNamed('fullName')),
    );
    expect(find.byType(SnackBar), findsNothing);
  });

  testWidgets('passes a null name through on a returning sign-in',
      (tester) async {
    // Apple only ever sends the name on the first authorization.
    when(mockLoginRepo.loginWithApple(any, fullName: anyNamed('fullName')))
        .thenAnswer((_) async => ApiResult.success(
              LoginResponse(user: _user(), isNewUser: false),
            ));

    await pumpSocialLogin(
      tester,
      FakeAppleAuthService(
        credential: const AppleCredential(identityToken: 't2'),
      ),
    );
    final s = S.of(tester.element(find.byType(SocialLogin)));

    await tester.tap(find.text(s.continueWithApple));
    await tester.pumpAndSettle();

    verify(mockLoginRepo.loginWithApple('t2', fullName: null)).called(1);
  });
}
