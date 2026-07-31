import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/mockito.dart';
import 'package:riff/core/networks/api_error_model.dart';
import 'package:riff/core/networks/api_result.dart';
import 'package:riff/features/auth/login/data/models/login_response.dart';
import 'package:riff/features/auth/login/data/models/user.dart';
import 'package:riff/features/auth/signup/UI/widgets/signup_bloc_listener.dart';
import 'package:riff/features/auth/signup/logic/cubit/signup_cubit.dart';
import 'package:riff/generated/l10n.dart';

import '../../../../../helpers/pump_app.dart';
import '../../logic/cubit/signup_cubit_test.mocks.dart';

void main() {
  late MockSignupRepo mockSignupRepo;
  late MockLoginRepo mockLoginRepo;
  late SignupCubit cubit;

  final user = User(
    id: 'u1',
    email: 'user@example.com',
    fullName: 'Test User',
    username: 'testuser',
  );

  setUp(() {
    mockSignupRepo = MockSignupRepo();
    mockLoginRepo = MockLoginRepo();
    cubit = SignupCubit(mockSignupRepo, mockLoginRepo);
  });

  tearDown(() => cubit.close());

  Future<void> pumpListener(WidgetTester tester) async {
    await pumpApp(
      tester,
      BlocProvider<SignupCubit>.value(
        value: cubit,
        child: const Scaffold(body: SignupBlocListener()),
      ),
      routes: {
        '/newUserOnboarding': (_) => const Scaffold(body: Text('ONBOARDING')),
      },
    );
  }

  testWidgets('shows a loading dialog while signing up', (tester) async {
    when(mockSignupRepo.signUp(any)).thenAnswer((_) async {
      await Future.delayed(const Duration(milliseconds: 300));
      return const ApiResult.success(null);
    });
    // The cubit auto-logs in after a successful signup — stub it too, or the
    // unstubbed mock call throws inside emitSignupStates() and the loading
    // state (and its indeterminate spinner) is never replaced, hanging
    // pumpAndSettle() below.
    when(mockLoginRepo.login(any))
        .thenAnswer((_) async => ApiResult.success(LoginResponse(user: user)));
    await pumpListener(tester);

    cubit.emitSignupStates();
    await tester.pump();
    await tester.pump();
    await tester.pump();

    expect(find.byType(CircularProgressIndicator), findsOneWidget);
    await tester.pumpAndSettle();
  });

  testWidgets('navigates straight to onboarding on success', (tester) async {
    when(mockSignupRepo.signUp(any))
        .thenAnswer((_) async => const ApiResult.success(null));
    when(mockLoginRepo.login(any))
        .thenAnswer((_) async => ApiResult.success(LoginResponse(user: user)));
    await pumpListener(tester);

    await cubit.emitSignupStates();
    await tester.pumpAndSettle();

    expect(find.byType(CircularProgressIndicator), findsNothing);
    // Phone verification used to sit between signup and onboarding; it was
    // removed, so signup must land the user directly on onboarding.
    expect(find.text('ONBOARDING'), findsOneWidget);
  });

  testWidgets('shows an error dialog when signup is rejected', (tester) async {
    when(mockSignupRepo.signUp(any)).thenAnswer(
      (_) async =>
          ApiResult.failure(ApiErrorModel(message: 'Username already taken')),
    );
    await pumpListener(tester);

    await cubit.emitSignupStates();
    await tester.pumpAndSettle();

    expect(find.text('Username already taken'), findsOneWidget);
    expect(find.text('PHONE_VERIFY'), findsNothing);

    await tester.tap(find.text(S.current.gotItBtn));
    await tester.pumpAndSettle();
    expect(find.text('Username already taken'), findsNothing);
  });
}
