import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/mockito.dart';
import 'package:riff/core/networks/api_result.dart';
import 'package:riff/features/auth/login/UI/widgets/google_sign_in_helper.dart';
import 'package:riff/features/auth/login/UI/widgets/social_login.dart';
import 'package:riff/features/auth/login/data/models/login_response.dart';
import 'package:riff/features/auth/login/data/models/user.dart';
import 'package:riff/features/auth/login/logic/cubit/login_cubit.dart';
import 'package:riff/generated/l10n.dart';

import '../../../../../helpers/pump_app.dart';
import '../../logic/cubit/login_cubit_test.mocks.dart';

/// Fake Google auth seam — lets the test control what the "native" Google
/// sign-in flow returns without touching the real plugin/platform channel.
class FakeGoogleAuthService implements GoogleAuthService {
  FakeGoogleAuthService({
    this.tokenToReturn,
    this.status,
    this.detail,
    this.delay = Duration.zero,
  });

  final String? tokenToReturn;

  /// Overrides the status when there is no token — lets a test pick between
  /// "cancelled" (silent) and a real failure (which must say something).
  final GoogleSignInStatus? status;
  final String? detail;
  final Duration delay;
  int callCount = 0;

  @override
  Future<GoogleSignInResult> signIn() async {
    callCount++;
    if (delay > Duration.zero) await Future.delayed(delay);
    if (tokenToReturn != null) {
      return GoogleSignInResult(
        GoogleSignInStatus.success,
        idToken: tokenToReturn,
      );
    }
    return GoogleSignInResult(
      status ?? GoogleSignInStatus.cancelled,
      detail: detail,
    );
  }
}

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
    GoogleAuthService fakeService,
  ) async {
    await pumpApp(
      tester,
      BlocProvider<LoginCubit>.value(
        value: loginCubit,
        child: Scaffold(body: SocialLogin(googleAuthService: fakeService)),
      ),
    );
  }

  testWidgets('renders the continue-with-Google idle state', (tester) async {
    final fake = FakeGoogleAuthService(tokenToReturn: null);
    await pumpSocialLogin(tester, fake);

    expect(find.text(S.current.continueWithGoogle), findsOneWidget);
  });

  testWidgets(
      'triggers LoginCubit.loginWithGoogle with the token when sign-in succeeds',
      (tester) async {
    when(mockLoginRepo.loginWithGoogle(any)).thenAnswer(
      (_) async => ApiResult.success(
        LoginResponse(
          user: User(
            id: 'g1',
            email: 'g@example.com',
            fullName: 'Google User',
            username: 'googleuser',
          ),
        ),
      ),
    );
    final fake = FakeGoogleAuthService(tokenToReturn: 'fake-id-token');
    await pumpSocialLogin(tester, fake);

    await tester.tap(find.text(S.current.continueWithGoogle));
    await tester.pumpAndSettle();

    expect(fake.callCount, 1);
    verify(mockLoginRepo.loginWithGoogle('fake-id-token')).called(1);
  });

  testWidgets('says nothing when the user cancels the account picker',
      (tester) async {
    // Cancelling is a deliberate act, not an error to apologise for.
    final fake = FakeGoogleAuthService(status: GoogleSignInStatus.cancelled);
    await pumpSocialLogin(tester, fake);

    await tester.tap(find.text(S.current.continueWithGoogle));
    await tester.pumpAndSettle();

    expect(find.byType(SnackBar), findsNothing);
    verifyNever(mockLoginRepo.loginWithGoogle(any));
  });

  testWidgets('surfaces the underlying reason when Google throws',
      (tester) async {
    // The reason is the whole point: a plugin or platform failure affecting
    // every user must not read like one person tapping Cancel.
    final fake = FakeGoogleAuthService(
      status: GoogleSignInStatus.failed,
      detail: 'PlatformException(sign_in_failed, ...)',
    );
    await pumpSocialLogin(tester, fake);

    await tester.tap(find.text(S.current.continueWithGoogle));
    await tester.pumpAndSettle();

    expect(
      find.text(S.current
          .signInFailedWithReason('PlatformException(sign_in_failed, ...)')),
      findsOneWidget,
    );
    verifyNever(mockLoginRepo.loginWithGoogle(any));
  });

  testWidgets('names the configuration fault when no ID token comes back',
      (tester) async {
    // Signed in, but no token — on Android that means the server client id is
    // missing, and it is not the user's fault or a cancellation.
    final fake = FakeGoogleAuthService(status: GoogleSignInStatus.noIdToken);
    await pumpSocialLogin(tester, fake);

    await tester.tap(find.text(S.current.continueWithGoogle));
    await tester.pumpAndSettle();

    expect(find.text(S.current.googleSignInNoToken), findsOneWidget);
    verifyNever(mockLoginRepo.loginWithGoogle(any));
  });

  testWidgets('shows a loading indicator while awaiting the Google sign-in',
      (tester) async {
    final fake = FakeGoogleAuthService(
      tokenToReturn: 'token',
      delay: const Duration(milliseconds: 300),
    );
    when(mockLoginRepo.loginWithGoogle(any)).thenAnswer(
      (_) async => ApiResult.success(
        LoginResponse(
          user: User(
            id: 'g1',
            email: 'g@example.com',
            fullName: 'Google User',
            username: 'googleuser',
          ),
        ),
      ),
    );
    await pumpSocialLogin(tester, fake);

    await tester.tap(find.text(S.current.continueWithGoogle));
    await tester.pump(const Duration(milliseconds: 50));

    expect(find.text(S.current.signingIn), findsOneWidget);
    expect(find.byType(CircularProgressIndicator), findsOneWidget);

    await tester.pumpAndSettle();
  });
}
