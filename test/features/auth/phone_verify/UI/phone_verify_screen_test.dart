import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/mockito.dart';
import 'package:riff/core/networks/api_error_model.dart';
import 'package:riff/core/networks/api_result.dart';
import 'package:riff/features/auth/phone_verify/UI/phone_verify_screen.dart';
import 'package:riff/features/auth/phone_verify/logic/cubit/phone_verify_cubit.dart';
import 'package:riff/generated/l10n.dart';

import '../../../../helpers/pump_app.dart';
import '../logic/cubit/phone_verify_cubit_test.mocks.dart';

/// [PhoneVerifyScreen] wires its `BlocConsumer` reactions directly (no
/// standalone `BlocListener` widget to target), so these tests drive the
/// cubit's real methods against a mocked repo and assert on the resulting
/// snackbar/navigation, rather than simulating input into the third-party
/// `IntlPhoneField` (covering that widget's own validation is out of scope
/// here — see phone_verify_screen_test.md).
void main() {
  late MockPhoneVerifyRepo mockRepo;
  late PhoneVerifyCubit cubit;

  setUp(() {
    mockRepo = MockPhoneVerifyRepo();
    cubit = PhoneVerifyCubit(mockRepo);
  });

  tearDown(() => cubit.close());

  Future<void> pumpScreen(WidgetTester tester) async {
    await pumpApp(
      tester,
      BlocProvider<PhoneVerifyCubit>.value(
        value: cubit,
        child: const PhoneVerifyScreen(),
      ),
    );
  }

  testWidgets('renders the initial send-OTP button', (tester) async {
    await pumpScreen(tester);
    expect(find.text(S.current.sendOTPViaWhatsApp), findsOneWidget);
  });

  testWidgets('shows the sending-OTP label while the cubit is loading',
      (tester) async {
    when(mockRepo.sendOtp(any)).thenAnswer((_) async {
      await Future.delayed(const Duration(milliseconds: 300));
      return const ApiResult.success(null);
    });
    await pumpScreen(tester);

    cubit.sendOtp('01001234567');
    await tester.pump(); // deliver the Loading state to BlocConsumer
    await tester.pump(); // rebuild triggered by that state's setState

    expect(find.text(S.current.sendingOTP), findsOneWidget);
    // Bounded pump past the mocked delay — pumpAndSettle() would hang here
    // once the success response navigates to PhoneOtpScreen, whose blinking
    // cursor animation and 60s resend countdown never let frames settle.
    await tester.pump(const Duration(milliseconds: 350));
  });

  testWidgets(
      'shows the localized "already taken" snackbar for a 409 conflict',
      (tester) async {
    when(mockRepo.sendOtp(any)).thenAnswer(
      (_) async => ApiResult.failure(ApiErrorModel(statusCode: 409)),
    );
    await pumpScreen(tester);

    await cubit.sendOtp('01001234567');
    await tester.pump(); // build the snackbar
    await tester.pump(const Duration(milliseconds: 100));

    expect(find.text(S.current.phoneNumberAlreadyTaken), findsOneWidget);
  });

  testWidgets('shows the raw server message for other failures',
      (tester) async {
    when(mockRepo.sendOtp(any)).thenAnswer(
      (_) async => ApiResult.failure(ApiErrorModel(message: 'Server error')),
    );
    await pumpScreen(tester);

    await cubit.sendOtp('01001234567');
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 100));

    expect(find.text('Server error'), findsOneWidget);
  });

  testWidgets('navigates to the OTP entry step once an OTP is sent',
      (tester) async {
    when(mockRepo.sendOtp(any))
        .thenAnswer((_) async => const ApiResult.success(null));
    await pumpScreen(tester);

    await cubit.sendOtp('01001234567');
    await tester.pump();
    // Let the push transition finish without pumpAndSettle(), which would
    // spin for the full real-time duration of PhoneOtpScreen's 60s resend
    // countdown Timer.periodic (it keeps scheduling frames every second).
    await tester.pump(const Duration(milliseconds: 300));

    expect(find.byType(PhoneOtpScreen), findsOneWidget);
    expect(find.text(S.current.weSentWhatsAppTo('01001234567')), findsOneWidget);
  });
}
