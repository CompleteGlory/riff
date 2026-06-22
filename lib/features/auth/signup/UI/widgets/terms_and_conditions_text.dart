import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:riff/core/routing/routes.dart';
import 'package:riff/core/themes/colors/color_manager.dart';
import 'package:riff/core/themes/text_styles/text_styles.dart';
import 'package:riff/features/auth/signup/logic/cubit/signup_cubit.dart';
import 'package:riff/generated/l10n.dart';

/// Checkbox + "I have read and agree to the Privacy Policy" text.
/// Stores acceptance in [SignupCubit.privacyAccepted] so [SignupScreen]
/// can gate the submit button without extra state management.
class TermsAndConditionsText extends StatefulWidget {
  const TermsAndConditionsText({super.key});

  @override
  State<TermsAndConditionsText> createState() => _TermsAndConditionsTextState();
}

class _TermsAndConditionsTextState extends State<TermsAndConditionsText> {
  bool _accepted = false;

  void _toggle(bool? value) {
    setState(() => _accepted = value ?? false);
    // Write to cubit so validateAndSignup() can read it without context threading.
    context.read<SignupCubit>().privacyAccepted = _accepted;
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(
          width: 24,
          height: 24,
          child: Checkbox(
            value: _accepted,
            onChanged: _toggle,
            activeColor: ColorManager.accent,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(4),
            ),
          ),
        ),
        const SizedBox(width: 8),
        Flexible(
          child: Wrap(
            crossAxisAlignment: WrapCrossAlignment.center,
            children: [
              Text(
                S.of(context).privacyPolicyConsentPrefix,
                style: TextStyles.font14regular.copyWith(
                  color: isDark
                      ? const Color(0xFFAAAAAA)
                      : ColorManager.lightGrey,
                ),
              ),
              GestureDetector(
                onTap: () => Navigator.pushNamed(context, Routes.privacyPolicy),
                child: Text(
                  S.of(context).privacyPolicyLinkText,
                  style: TextStyles.font14regular.copyWith(
                    color: ColorManager.accent,
                    decoration: TextDecoration.underline,
                    decorationColor: ColorManager.accent,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
