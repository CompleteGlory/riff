import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:riff/features/auth/login/UI/widgets/login_form_fields.dart';
import 'package:riff/features/auth/login/logic/cubit/login_cubit.dart';
import 'package:riff/generated/l10n.dart';

import '../../../../../helpers/pump_app.dart';
import '../../logic/cubit/login_cubit_test.mocks.dart';

void main() {
  late MockLoginRepo mockLoginRepo;
  late LoginCubit loginCubit;

  setUp(() {
    mockLoginRepo = MockLoginRepo();
    loginCubit = LoginCubit(mockLoginRepo);
  });

  tearDown(() => loginCubit.close());

  Future<void> pumpFormFields(WidgetTester tester) async {
    await pumpApp(
      tester,
      BlocProvider<LoginCubit>.value(
        value: loginCubit,
        child: const Scaffold(body: LoginFormFields()),
      ),
    );
  }

  testWidgets('renders email and password fields with hint text',
      (tester) async {
    await pumpFormFields(tester);

    final s = S.current;
    expect(find.text(s.emailOrUsername), findsOneWidget);
    expect(find.text(s.passwordLabel), findsOneWidget);
    expect(find.widgetWithText(TextFormField, s.enterEmailOrUsername),
        findsOneWidget);
    expect(find.widgetWithText(TextFormField, s.enterYourPassword),
        findsOneWidget);
    expect(find.byType(TextFormField), findsNWidgets(2));
  });

  testWidgets('obscures the password field by default and can be revealed',
      (tester) async {
    await pumpFormFields(tester);

    final passwordField = tester.widget<TextField>(find.byType(TextField).last);
    expect(passwordField.obscureText, isTrue);

    await tester.tap(find.byIcon(Icons.visibility));
    await tester.pumpAndSettle();

    final revealedField =
        tester.widget<TextField>(find.byType(TextField).last);
    expect(revealedField.obscureText, isFalse);
  });

  testWidgets('shows validation errors when submitted empty', (tester) async {
    await pumpFormFields(tester);

    final isValid = loginCubit.formKey.currentState!.validate();
    await tester.pumpAndSettle();

    expect(isValid, isFalse);
    final s = S.current;
    expect(find.text(s.thisFieldIsRequired), findsOneWidget);
    expect(find.text(s.passwordIsRequired), findsOneWidget);
  });

  testWidgets('clears validation errors once valid text is entered',
      (tester) async {
    await pumpFormFields(tester);

    loginCubit.formKey.currentState!.validate();
    await tester.pumpAndSettle();

    await tester.enterText(
        find.byType(TextFormField).first, 'user@example.com');
    await tester.enterText(find.byType(TextFormField).last, 'Password123');
    loginCubit.formKey.currentState!.validate();
    await tester.pumpAndSettle();

    final s = S.current;
    expect(find.text(s.thisFieldIsRequired), findsNothing);
    expect(find.text(s.passwordIsRequired), findsNothing);
    expect(loginCubit.mailController.text, 'user@example.com');
    expect(loginCubit.passwordController.text, 'Password123');
  });
}
