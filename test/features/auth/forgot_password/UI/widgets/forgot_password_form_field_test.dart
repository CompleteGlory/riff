import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:riff/features/auth/forgot_password/UI/widgets/forgot_password_form_field.dart';
import 'package:riff/features/auth/forgot_password/logic/cubit/forgot_password_cubit.dart';
import 'package:riff/generated/l10n.dart';

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

  Future<void> pumpField(WidgetTester tester) async {
    await pumpApp(
      tester,
      BlocProvider<ForgotPasswordCubit>.value(
        value: cubit,
        child: const Scaffold(body: ForgotPasswordFormField()),
      ),
    );
  }

  testWidgets('renders the email field with hint text', (tester) async {
    await pumpField(tester);

    expect(
      find.widgetWithText(TextFormField, S.current.enterYourEmailAddress),
      findsOneWidget,
    );
  });

  testWidgets('rejects an empty or malformed email', (tester) async {
    await pumpField(tester);

    expect(cubit.formKey.currentState!.validate(), isFalse);
    await tester.pumpAndSettle();
    expect(find.text(S.current.pleaseEnterValidEmail), findsOneWidget);

    await tester.enterText(find.byType(TextFormField), 'not-an-email');
    expect(cubit.formKey.currentState!.validate(), isFalse);
    await tester.pumpAndSettle();
    expect(find.text(S.current.pleaseEnterValidEmail), findsOneWidget);
  });

  testWidgets('accepts a valid email', (tester) async {
    await pumpField(tester);

    await tester.enterText(find.byType(TextFormField), 'user@example.com');
    expect(cubit.formKey.currentState!.validate(), isTrue);
    await tester.pumpAndSettle();
    expect(find.text(S.current.pleaseEnterValidEmail), findsNothing);
  });
}
