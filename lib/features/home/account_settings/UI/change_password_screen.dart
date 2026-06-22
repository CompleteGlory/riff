import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:riff/core/themes/colors/color_manager.dart';
import 'package:riff/core/themes/text_styles/text_styles.dart';
import 'package:riff/core/widgets/tff.dart';
import 'package:riff/features/home/account_settings/logic/change_password_cubit.dart';
import 'package:riff/generated/l10n.dart';

// ── Password strength model (same logic as signup) ────────────────────────────

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
        hasSpecial:
            pw.contains(RegExp(r'[!@#$%^&*(),.?":{}|<>_\-+=\[\]\\;~/`]')),
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

// ── Screen ────────────────────────────────────────────────────────────────────

class ChangePasswordScreen extends StatefulWidget {
  const ChangePasswordScreen({super.key});

  @override
  State<ChangePasswordScreen> createState() => _ChangePasswordScreenState();
}

class _ChangePasswordScreenState extends State<ChangePasswordScreen> {
  final _formKey = GlobalKey<FormState>();
  final _oldPassCtrl = TextEditingController();
  final _newPassCtrl = TextEditingController();
  final _confirmPassCtrl = TextEditingController();

  _PasswordStrength _strength = _PasswordStrength.of('');

  @override
  void initState() {
    super.initState();
    _newPassCtrl.addListener(() {
      setState(() => _strength = _PasswordStrength.of(_newPassCtrl.text));
    });
  }

  @override
  void dispose() {
    _oldPassCtrl.dispose();
    _newPassCtrl.dispose();
    _confirmPassCtrl.dispose();
    super.dispose();
  }

  void _submit() {
    if (!(_formKey.currentState?.validate() ?? false)) return;
    context.read<ChangePasswordCubit>().changePassword(
          oldPassword: _oldPassCtrl.text.trim(),
          newPassword: _newPassCtrl.text,
        );
  }

  @override
  Widget build(BuildContext context) {
    final s = S.of(context);
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bg = isDark ? const Color(0xFF111111) : const Color(0xFFF5F5F5);

    return BlocListener<ChangePasswordCubit, ChangePasswordState>(
      listener: (context, state) {
        if (state.status == ChangePasswordStatus.success) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(s.passwordChangedSuccess),
              backgroundColor: Colors.green,
            ),
          );
          Navigator.pop(context);
        } else if (state.status == ChangePasswordStatus.failure) {
          final msg = (state.errorMessage?.toLowerCase().contains('incorrect') ?? false)
              ? s.wrongCurrentPassword
              : (state.errorMessage ?? s.passwordChangedFailure);
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(msg),
              backgroundColor: ColorManager.red,
            ),
          );
          context.read<ChangePasswordCubit>().reset();
        }
      },
      child: Scaffold(
        backgroundColor: bg,
        appBar: AppBar(
          backgroundColor: isDark ? const Color(0xFF141414) : Colors.white,
          title: Text(s.changePasswordTitle),
          centerTitle: false,
          leading: IconButton(
            icon: const Icon(Icons.arrow_back_ios_new, size: 20),
            onPressed: () => Navigator.pop(context),
          ),
        ),
        body: SingleChildScrollView(
          padding: EdgeInsets.all(20.w),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Current password
                Text(s.currentPasswordLabel, style: TextStyles.font15semiBold),
                SizedBox(height: 6.h),
                AppTextField(
                  controller: _oldPassCtrl,
                  keyboardType: TextInputType.visiblePassword,
                  isPassword: true,
                  hintText: s.currentPasswordHint,
                  validator: (v) =>
                      (v == null || v.isEmpty) ? s.thisFieldIsRequired : null,
                ),

                SizedBox(height: 20.h),

                // New password
                Text(s.newPasswordLabel, style: TextStyles.font15semiBold),
                SizedBox(height: 6.h),
                AppTextField(
                  controller: _newPassCtrl,
                  keyboardType: TextInputType.visiblePassword,
                  isPassword: true,
                  hintText: s.newPasswordHint,
                  validator: (v) {
                    if (v == null || v.isEmpty) return s.thisFieldIsRequired;
                    if (!_PasswordStrength.of(v).isValid) {
                      return s.passwordMinLength;
                    }
                    return null;
                  },
                ),

                // Strength bar
                if (_newPassCtrl.text.isNotEmpty) ...[
                  SizedBox(height: 10.h),
                  _StrengthBar(strength: _strength),
                ],

                SizedBox(height: 12.h),
                _RequirementsCard(strength: _strength),

                SizedBox(height: 20.h),

                // Confirm new password
                Text(s.confirmNewPasswordLabel,
                    style: TextStyles.font15semiBold),
                SizedBox(height: 6.h),
                AppTextField(
                  controller: _confirmPassCtrl,
                  keyboardType: TextInputType.visiblePassword,
                  isPassword: true,
                  hintText: s.confirmNewPasswordHint,
                  validator: (v) {
                    if (v == null || v.isEmpty) return s.thisFieldIsRequired;
                    if (v != _newPassCtrl.text) return s.passwordsDoNotMatch;
                    return null;
                  },
                ),

                SizedBox(height: 32.h),

                // Submit button
                BlocBuilder<ChangePasswordCubit, ChangePasswordState>(
                  builder: (context, state) {
                    final isLoading =
                        state.status == ChangePasswordStatus.loading;
                    return SizedBox(
                      width: double.infinity,
                      height: 52.h,
                      child: ElevatedButton(
                        onPressed: isLoading ? null : _submit,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: ColorManager.accent,
                          foregroundColor: Colors.white,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(14.r),
                          ),
                          elevation: 0,
                        ),
                        child: isLoading
                            ? const SizedBox(
                                width: 22,
                                height: 22,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2.5,
                                  color: Colors.white,
                                ),
                              )
                            : Text(s.changePasswordBtn,
                                style: TextStyles.font15semiBold
                                    .copyWith(color: Colors.white)),
                      ),
                    );
                  },
                ),
              ],
            ),
          ),
        ),
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
    final emptyColor =
        isDark ? const Color(0xFF3A3A3A) : const Color(0xFFE0E0E0);
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
          _Req(met: strength.hasLength, label: s.passwordReqLength),
          _Req(met: strength.hasUpper, label: s.passwordReqUppercase),
          _Req(met: strength.hasLower, label: s.passwordReqLowercase),
          _Req(met: strength.hasNumber, label: s.passwordReqNumber),
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
