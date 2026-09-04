import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:riff/core/themes/colors/color_manager.dart';
import 'package:riff/core/themes/text_styles/text_styles.dart';
import 'package:riff/features/auth/forgot_password/logic/cubit/forgot_password_cubit.dart';
import 'package:riff/generated/l10n.dart';

/// "Didn't get the email? Resend code" under the code entry.
///
/// It used to navigate back to the email screen instead of asking for another
/// code, so the one control a user reaches for when the email has not arrived
/// did not resend anything. It now calls the cubit, and holds a short cooldown
/// afterwards: the API allows three requests a minute and each one sends real
/// mail, so an eager tap would otherwise earn a rejection the user cannot
/// interpret.
class EmailNotRecievedText extends StatefulWidget {
  const EmailNotRecievedText({super.key});

  /// Seconds to wait before another code can be requested.
  static const cooldown = 30;

  @override
  State<EmailNotRecievedText> createState() => _EmailNotRecievedTextState();
}

class _EmailNotRecievedTextState extends State<EmailNotRecievedText> {
  Timer? _timer;
  int _secondsLeft = 0;

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  void _startCooldown() {
    _timer?.cancel();
    setState(() => _secondsLeft = EmailNotRecievedText.cooldown);
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (!mounted) return timer.cancel();
      setState(() => _secondsLeft--);
      if (_secondsLeft <= 0) timer.cancel();
    });
  }

  Future<void> _resend() async {
    final s = S.of(context);
    final messenger = ScaffoldMessenger.of(context);
    _startCooldown();
    await context.read<ForgotPasswordCubit>().emitForgotPasswordStates();
    if (!mounted) return;
    messenger.showSnackBar(SnackBar(content: Text(s.resendCodeSent)));
  }

  @override
  Widget build(BuildContext context) {
    final s = S.of(context);
    final waiting = _secondsLeft > 0;
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Text(
          s.emailNotReceived,
          style: TextStyles.font14regular.copyWith(
            color: ColorManager.lightGrey,
          ),
        ),
        TextButton(
          onPressed: waiting ? null : _resend,
          child: Text(
            waiting ? s.resendCodeWait('$_secondsLeft') : s.resendCode,
            style: TextStyles.font16Medium.copyWith(
              decoration: waiting ? null : TextDecoration.underline,
            ),
          ),
        ),
      ],
    );
  }
}
