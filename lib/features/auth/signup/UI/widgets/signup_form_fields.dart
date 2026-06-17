import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:riff/core/helpers/app_regex.dart';
import 'package:riff/core/themes/text_styles/text_styles.dart';
import 'package:riff/core/widgets/tff.dart';
import 'package:riff/features/auth/signup/logic/cubit/signup_cubit.dart';
import 'package:riff/generated/l10n.dart';

// ── Password strength model ───────────────────────────────────────────────────

class _PasswordStrength {
  final bool hasLength;
  final bool hasUpper;
  final bool hasLower;
  final bool hasNumber;
  final bool hasSpecial;

  const _PasswordStrength({
    required this.hasLength,
    required this.hasUpper,
    required this.hasLower,
    required this.hasNumber,
    required this.hasSpecial,
  });

  factory _PasswordStrength.of(String pw) => _PasswordStrength(
        hasLength: pw.length >= 8,
        hasUpper: pw.contains(RegExp(r'[A-Z]')),
        hasLower: pw.contains(RegExp(r'[a-z]')),
        hasNumber: pw.contains(RegExp(r'[0-9]')),
        hasSpecial: pw.contains(RegExp(r'[!@#$%^&*(),.?":{}|<>_\-+=\[\]\\;~/`]')),
      );

  int get score =>
      (hasLength ? 1 : 0) +
      (hasUpper ? 1 : 0) +
      (hasLower ? 1 : 0) +
      (hasNumber ? 1 : 0) +
      (hasSpecial ? 1 : 0);

  bool get isValid => score == 5;

  Color get barColor {
    if (score <= 1) return const Color(0xFFE53935);
    if (score == 2) return const Color(0xFFFF7043);
    if (score == 3) return const Color(0xFFFFB300);
    if (score == 4) return const Color(0xFF66BB6A);
    return const Color(0xFF43A047);
  }

  String label(S s) {
    if (score <= 1) return s.passwordStrengthWeak;
    if (score == 2) return s.passwordStrengthFair;
    if (score == 3) return s.passwordStrengthGood;
    return s.passwordStrengthStrong;
  }
}

// ── Main form ─────────────────────────────────────────────────────────────────

class SignUpFormFields extends StatefulWidget {
  const SignUpFormFields({super.key});

  @override
  State<SignUpFormFields> createState() => _SignUpFormFieldsState();
}

class _SignUpFormFieldsState extends State<SignUpFormFields> {
  _PasswordStrength _strength = _PasswordStrength.of('');
  late final SignupCubit _cubit;

  @override
  void initState() {
    super.initState();
    _cubit = context.read<SignupCubit>();
    _cubit.passwordController.addListener(_onPasswordChanged);
  }

  void _onPasswordChanged() {
    setState(() => _strength = _PasswordStrength.of(_cubit.passwordController.text));
  }

  @override
  void dispose() {
    _cubit.passwordController.removeListener(_onPasswordChanged);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final cubit = _cubit;
    final s = S.of(context);

    return Form(
      key: cubit.formKey,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Full Name
          Text(s.fullName, style: TextStyles.font15semiBold),
          const SizedBox(height: 4),
          AppTextField(
            controller: cubit.fullNameController,
            keyboardType: TextInputType.name,
            isPassword: false,
            validator: (v) => (v == null || v.isEmpty) ? s.thisFieldIsRequired : null,
            hintText: s.enterYourFullName,
          ),
          const SizedBox(height: 10),

          // Username
          Text(s.userName, style: TextStyles.font15semiBold),
          const SizedBox(height: 4),
          AppTextField(
            controller: cubit.usernameController,
            keyboardType: TextInputType.name,
            isPassword: false,
            validator: (v) {
              if (v == null || v.isEmpty) return s.thisFieldIsRequired;
              if (!RegExp(r'^[a-zA-Z0-9_.]+$').hasMatch(v)) return s.usernameEnglishOnly;
              return null;
            },
            hintText: s.enterYourUserName,
          ),
          const SizedBox(height: 10),

          // Email
          Text(s.emailLabel, style: TextStyles.font15semiBold),
          const SizedBox(height: 4),
          AppTextField(
            controller: cubit.mailController,
            keyboardType: TextInputType.emailAddress,
            isPassword: false,
            validator: (v) {
              if (v == null || v.isEmpty || !AppRegex.isEmailValid(v)) {
                return s.pleaseEnterValidEmail;
              }
              return null;
            },
            hintText: s.enterYourEmailAddress,
          ),
          const SizedBox(height: 10),

          // Password
          Text(s.passwordLabel, style: TextStyles.font15semiBold),
          const SizedBox(height: 4),
          AppTextField(
            controller: cubit.passwordController,
            keyboardType: TextInputType.visiblePassword,
            isPassword: true,
            validator: (v) {
              if (v == null || v.isEmpty) return s.passwordIsRequired;
              if (!_PasswordStrength.of(v).isValid) {
                return s.passwordMinLength;
              }
              return null;
            },
            hintText: s.enterYourPassword,
          ),

          // Strength bar (only shown when typing)
          if (cubit.passwordController.text.isNotEmpty) ...[
            const SizedBox(height: 10),
            _StrengthBar(strength: _strength),
          ],

          // Requirements checklist
          const SizedBox(height: 12),
          _RequirementsCard(strength: _strength),
          const SizedBox(height: 10),

          // Confirm Password
          Text(s.confirmPassword, style: TextStyles.font15semiBold),
          const SizedBox(height: 4),
          AppTextField(
            controller: cubit.confirmPasswordController,
            keyboardType: TextInputType.visiblePassword,
            isPassword: true,
            validator: (v) {
              if (v == null || v.isEmpty) return s.thisFieldIsRequired;
              if (v != cubit.passwordController.text) return s.passwordsDoNotMatch;
              return null;
            },
            hintText: s.enterConfirmPassword,
          ),
        ],
      ),
    );
  }
}

// ── Strength bar ──────────────────────────────────────────────────────────────

class _StrengthBar extends StatelessWidget {
  final _PasswordStrength strength;
  const _StrengthBar({required this.strength});

  @override
  Widget build(BuildContext context) {
    final s = S.of(context);
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final emptyColor = isDark ? const Color(0xFF3A3A3A) : const Color(0xFFE0E0E0);
    final score = strength.score;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: List.generate(5, (i) {
            return Expanded(
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 250),
                height: 4,
                margin: EdgeInsets.only(right: i < 4 ? 4 : 0),
                decoration: BoxDecoration(
                  color: i < score ? strength.barColor : emptyColor,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            );
          }),
        ),
        const SizedBox(height: 5),
        Text(
          strength.label(s),
          overflow: TextOverflow.ellipsis,
          style: TextStyle(
            fontFamily: 'GeneralSans',
            fontSize: 12,
            fontWeight: FontWeight.w600,
            color: strength.barColor,
          ),
        ),
      ],
    );
  }
}

// ── Requirements card ─────────────────────────────────────────────────────────

class _RequirementsCard extends StatelessWidget {
  final _PasswordStrength strength;
  const _RequirementsCard({required this.strength});

  @override
  Widget build(BuildContext context) {
    final s = S.of(context);
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1E1E1E) : const Color(0xFFF7F7F7),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: isDark ? const Color(0xFF3A3A3A) : const Color(0xFFE8E8E8),
        ),
      ),
      child: Column(
        children: [
          _Req(met: strength.hasLength,  label: s.passwordReqLength),
          _Req(met: strength.hasUpper,   label: s.passwordReqUppercase),
          _Req(met: strength.hasLower,   label: s.passwordReqLowercase),
          _Req(met: strength.hasNumber,  label: s.passwordReqNumber),
          _Req(met: strength.hasSpecial, label: s.passwordReqSpecial),
        ],
      ),
    );
  }
}

class _Req extends StatelessWidget {
  final bool met;
  final String label;
  const _Req({required this.met, required this.label});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final color = met
        ? const Color(0xFF43A047)
        : (isDark ? const Color(0xFF666666) : const Color(0xFFAAAAAA));

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 3),
      child: Row(
        children: [
          AnimatedSwitcher(
            duration: const Duration(milliseconds: 200),
            child: Icon(
              met
                  ? Icons.check_circle_rounded
                  : Icons.radio_button_unchecked_rounded,
              key: ValueKey(met),
              size: 16,
              color: color,
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              label,
              style: TextStyle(
                fontFamily: 'GeneralSans',
                fontSize: 12,
                color: color,
                fontWeight: met ? FontWeight.w600 : FontWeight.w400,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
