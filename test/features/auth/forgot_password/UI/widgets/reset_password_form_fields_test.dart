import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:riff/features/auth/forgot_password/UI/widgets/reset_password_form_fields.dart';
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

  Future<void> pumpFields(WidgetTester tester) async {
    await pumpApp(
      tester,
      BlocProvider<ForgotPasswordCubit>.value(
        value: cubit,
        child: const Scaffold(body: ResetPasswordFormFields()),
      ),
    );
  }

  testWidgets('renders both password fields', (tester) async {
    await pumpFields(tester);
    expect(find.byType(TextFormField), findsNWidgets(2));
  });

  testWidgets('requires a minimum length new password', (tester) async {
    await pumpFields(tester);

    await tester.enterText(find.byType(TextFormField).first, 'short');
    await tester.enterText(find.byType(TextFormField).last, 'short');
    expect(cubit.resetFormKey.currentState!.validate(), isFalse);
    await tester.pumpAndSettle();
    expect(find.text(S.current.passwordMinLength), findsOneWidget);
  });

  testWidgets('rejects a confirm password that does not match', (tester) async {
    await pumpFields(tester);

    await tester.enterText(find.byType(TextFormField).first, 'NewPassword1');
    await tester.enterText(find.byType(TextFormField).last, 'Different1');
    expect(cubit.resetFormKey.currentState!.validate(), isFalse);
    await tester.pumpAndSettle();
    expect(find.text(S.current.passwordsDoNotMatch), findsOneWidget);
  });

  testWidgets('accepts matching, long-enough passwords', (tester) async {
    await pumpFields(tester);

    await tester.enterText(find.byType(TextFormField).first, 'NewPassword1');
    await tester.enterText(find.byType(TextFormField).last, 'NewPassword1');
    expect(cubit.resetFormKey.currentState!.validate(), isTrue);
  });
}
