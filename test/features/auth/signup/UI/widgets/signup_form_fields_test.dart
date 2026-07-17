import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:riff/features/auth/signup/UI/widgets/signup_form_fields.dart';
import 'package:riff/features/auth/signup/logic/cubit/signup_cubit.dart';
import 'package:riff/generated/l10n.dart';

import '../../../../../helpers/pump_app.dart';
import '../../logic/cubit/signup_cubit_test.mocks.dart';

void main() {
  late MockSignupRepo mockSignupRepo;
  late MockLoginRepo mockLoginRepo;
  late SignupCubit cubit;

  setUp(() {
    mockSignupRepo = MockSignupRepo();
    mockLoginRepo = MockLoginRepo();
    cubit = SignupCubit(mockSignupRepo, mockLoginRepo);
  });

  tearDown(() => cubit.close());

  Future<void> pumpForm(WidgetTester tester) async {
    await pumpApp(
      tester,
      BlocProvider<SignupCubit>.value(
        value: cubit,
        // Matches SignupScreen's own SingleChildScrollView — the form's
        // full content (5 fields + strength bar + requirements card)
        // overflows the default test viewport otherwise.
        child: const Scaffold(
          body: SingleChildScrollView(child: SignUpFormFields()),
        ),
      ),
    );
  }

  testWidgets('renders all five fields', (tester) async {
    await pumpForm(tester);
    expect(find.byType(TextFormField), findsNWidgets(5));
  });

  testWidgets('requires every field when submitted empty', (tester) async {
    await pumpForm(tester);

    expect(cubit.formKey.currentState!.validate(), isFalse);
    await tester.pumpAndSettle();

    final s = S.current;
    expect(find.text(s.thisFieldIsRequired), findsWidgets);
    expect(find.text(s.pleaseEnterValidEmail), findsOneWidget);
    expect(find.text(s.passwordIsRequired), findsOneWidget);
  });

  testWidgets('rejects a username with disallowed characters', (tester) async {
    await pumpForm(tester);

    final fields = find.byType(TextFormField);
    await tester.enterText(fields.at(1), 'bad username!');
    expect(cubit.formKey.currentState!.validate(), isFalse);
    await tester.pumpAndSettle();
    expect(find.text(S.current.usernameEnglishOnly), findsOneWidget);
  });

  testWidgets('rejects a weak password', (tester) async {
    await pumpForm(tester);

    final fields = find.byType(TextFormField);
    await tester.enterText(fields.at(3), 'weak');
    expect(cubit.formKey.currentState!.validate(), isFalse);
    await tester.pumpAndSettle();
    expect(find.text(S.current.passwordMinLength), findsOneWidget);
  });

  testWidgets('rejects a confirm password that does not match', (tester) async {
    await pumpForm(tester);

    final fields = find.byType(TextFormField);
    await tester.enterText(fields.at(3), 'StrongPass1!');
    await tester.enterText(fields.at(4), 'Different1!');
    expect(cubit.formKey.currentState!.validate(), isFalse);
    await tester.pumpAndSettle();
    expect(find.text(S.current.passwordsDoNotMatch), findsOneWidget);
  });

  testWidgets('validates successfully with all fields filled correctly',
      (tester) async {
    await pumpForm(tester);

    final fields = find.byType(TextFormField);
    await tester.enterText(fields.at(0), 'Test User');
    await tester.enterText(fields.at(1), 'test_user.1');
    await tester.enterText(fields.at(2), 'user@example.com');
    await tester.enterText(fields.at(3), 'StrongPass1!');
    await tester.enterText(fields.at(4), 'StrongPass1!');

    expect(cubit.formKey.currentState!.validate(), isTrue);
  });
}
