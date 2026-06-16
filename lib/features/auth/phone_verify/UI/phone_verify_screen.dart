// ignore_for_file: use_build_context_synchronously
import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:intl_phone_field/intl_phone_field.dart';
import 'package:riff/core/helpers/spacing.dart';
import 'package:riff/core/routing/routes.dart';
import 'package:riff/core/themes/colors/color_manager.dart';
import 'package:riff/core/themes/text_styles/text_styles.dart';
import 'package:riff/core/widgets/button.dart';
import 'package:riff/features/auth/phone_verify/logic/cubit/phone_verify_cubit.dart';
import 'package:riff/features/auth/phone_verify/logic/cubit/phone_verify_state.dart';

/// Step 1 — enter phone number and receive WhatsApp OTP
class PhoneVerifyScreen extends StatefulWidget {
  const PhoneVerifyScreen({super.key});

  @override
  State<PhoneVerifyScreen> createState() => _PhoneVerifyScreenState();
}

class _PhoneVerifyScreenState extends State<PhoneVerifyScreen> {
  String _completePhone = '';
  bool _valid = false;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      body: SafeArea(
        child: BlocConsumer<PhoneVerifyCubit, PhoneVerifyState>(
          listener: (context, state) {
            if (state is PhoneVerifyOtpSent) {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => BlocProvider.value(
                    value: context.read<PhoneVerifyCubit>(),
                    child: PhoneOtpScreen(phoneNumber: state.phoneNumber),
                  ),
                ),
              );
            } else if (state is PhoneVerifyError) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text(state.message),
                  backgroundColor: Colors.red,
                  behavior: SnackBarBehavior.floating,
                ),
              );
            }
          },
          builder: (context, state) {
            final loading = state is PhoneVerifyLoading;
            return SingleChildScrollView(
              padding: EdgeInsets.symmetric(horizontal: 24.w),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  verticalSpace(32),
                  // Back / skip row
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      IconButton(
                        icon: const Icon(Icons.arrow_back_ios_new_rounded),
                        onPressed: () => Navigator.pop(context),
                        padding: EdgeInsets.zero,
                        constraints: const BoxConstraints(),
                      ),
                      TextButton(
                        onPressed: () => Navigator.pushNamedAndRemoveUntil(
                          context,
                          Routes.newUserOnboarding,
                          (r) => false,
                        ),
                        child: Text(
                          'Skip',
                          style: TextStyles.font14Medium.copyWith(
                            color: ColorManager.normalGrey,
                          ),
                        ),
                      ),
                    ],
                  ),
                  verticalSpace(32),
                  Text(
                    'Verify your\nphone number',
                    style: TextStyles.font28Bold,
                  ),
                  verticalSpace(8),
                  Text(
                    "We'll send a WhatsApp message with a 6-digit code.",
                    style: TextStyles.font16Medium.copyWith(
                      color: ColorManager.lightGrey,
                    ),
                  ),
                  verticalSpace(36),
                  // Phone field
                  IntlPhoneField(
                    decoration: InputDecoration(
                      labelText: 'Phone Number',
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(14.r),
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(14.r),
                        borderSide: BorderSide(
                          color: isDark
                              ? const Color(0xFF3A3A3A)
                              : const Color(0xFFE0E0E0),
                        ),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(14.r),
                        borderSide: BorderSide(
                          color: ColorManager.accent,
                          width: 1.5,
                        ),
                      ),
                      filled: true,
                      fillColor: isDark
                          ? const Color(0xFF1E1E1E)
                          : Colors.white,
                    ),
                    style: TextStyles.font16Medium,
                    initialCountryCode: 'EG',
                    onChanged: (phone) {
                      setState(() {
                        _completePhone = phone.completeNumber;
                        _valid = phone.isValidNumber();
                      });
                    },
                    onCountryChanged: (_) {
                      setState(() => _valid = false);
                    },
                    keyboardType: TextInputType.phone,
                    inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                  ),
                  verticalSpace(32),
                  AppButton(
                    text: loading ? 'Sending…' : 'Send OTP via WhatsApp',
                    isWhite: false,
                    onPressed: () {
                      if (_valid && !loading) {
                        context.read<PhoneVerifyCubit>().sendOtp(
                          _completePhone,
                        );
                      }
                    },
                  ),
                  verticalSpace(16),
                  Center(
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        WhatsAppIcon(size: 18.r),
                        SizedBox(width: 6.w),
                        Text(
                          'Code will be sent via WhatsApp',
                          style: TextStyles.font14Medium.copyWith(
                            color: ColorManager.normalGrey,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            );
          },
        ),
      ),
    );
  }
}

// ── WhatsApp SVG icon ───────────────────────────────────────────────────────

class WhatsAppIcon extends StatelessWidget {
  final double size;
  const WhatsAppIcon({super.key, this.size = 24});

  static const String _svg = '''
<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 48 48">
  <circle cx="24" cy="24" r="24" fill="#25D366"/>
  <path fill="#FFFFFF" d="M24 10.4C16.5 10.4 10.4 16.5 10.4 24c0 2.4.6 4.7 1.8 6.7L10 38l7.5-2.2c1.9 1.1 4.1 1.7 6.5 1.7 7.5 0 13.6-6.1 13.6-13.6C37.6 16.5 31.5 10.4 24 10.4zM30.9 29.3c-.3.8-1.6 1.5-2.2 1.6-.6.1-1.3.1-4.2-1.1-3.5-1.4-5.7-5-5.9-5.2-.2-.2-1.5-2-.9-4.1.5-1.5 1.7-2.2 2.3-2.4.5-.2 1-.2 1.4-.1l.5.1c.4.1.6.3.9 1l1 2.4c.1.2.1.4 0 .7-.1.2-.2.4-.4.6l-.6.6c-.2.2-.4.4-.2.7.5.8 1.2 1.7 2.1 2.4.9.7 1.9 1.2 2.7 1.5.3.1.6.1.8-.1l.7-.8c.2-.3.5-.3.8-.2l2.3 1.1c.4.2.7.4.8.6.1.7-.1 1.8-.4 2.5z"/>
</svg>''';

  @override
  Widget build(BuildContext context) {
    return SvgPicture.string(_svg, width: size, height: size);
  }
}

// ────────────────────────────────────────────────────────────────────────────
// Step 2 — enter 6-digit OTP
// ────────────────────────────────────────────────────────────────────────────

class PhoneOtpScreen extends StatefulWidget {
  final String phoneNumber;
  const PhoneOtpScreen({super.key, required this.phoneNumber});

  @override
  State<PhoneOtpScreen> createState() => _PhoneOtpScreenState();
}

class _PhoneOtpScreenState extends State<PhoneOtpScreen> {
  // Single hidden controller that captures all input including paste
  final TextEditingController _hiddenCtl = TextEditingController();
  final FocusNode _hiddenFocus = FocusNode();

  // Visual display list derived from _hiddenCtl.text
  List<String> get _digits {
    final t = _hiddenCtl.text.replaceAll(RegExp(r'\D'), '');
    return List.generate(6, (i) => i < t.length ? t[i] : '');
  }

  // Resend cooldown
  int _resendSeconds = 60;
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    _startTimer();
    _hiddenCtl.addListener(_onTextChanged);
    WidgetsBinding.instance.addPostFrameCallback(
      (_) => _hiddenFocus.requestFocus(),
    );
  }

  void _onTextChanged() {
    final clean = _hiddenCtl.text.replaceAll(RegExp(r'\D'), '');
    // Clamp to 6 digits
    if (clean.length > 6) {
      _hiddenCtl.text = clean.substring(0, 6);
      _hiddenCtl.selection = TextSelection.collapsed(offset: 6);
      return;
    }
    setState(() {});
    if (clean.length == 6) {
      context.read<PhoneVerifyCubit>().verifyOtp(clean);
    }
  }

  void _startTimer() {
    _timer?.cancel();
    setState(() => _resendSeconds = 60);
    _timer = Timer.periodic(const Duration(seconds: 1), (_) {
      if (_resendSeconds <= 0) {
        _timer?.cancel();
      } else {
        setState(() => _resendSeconds--);
      }
    });
  }

  @override
  void dispose() {
    _hiddenCtl.removeListener(_onTextChanged);
    _hiddenCtl.dispose();
    _hiddenFocus.dispose();
    _timer?.cancel();
    super.dispose();
  }

  String get _otp => _hiddenCtl.text.replaceAll(RegExp(r'\D'), '');

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      body: SafeArea(
        child: BlocConsumer<PhoneVerifyCubit, PhoneVerifyState>(
          listener: (context, state) {
            if (state is PhoneVerifySuccess) {
              Navigator.pushNamedAndRemoveUntil(
                context,
                Routes.newUserOnboarding,
                (r) => false,
              );
            } else if (state is PhoneVerifyError) {
              _hiddenCtl.clear();
              WidgetsBinding.instance.addPostFrameCallback((_) {
                if (mounted) _hiddenFocus.requestFocus();
              });
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text(state.message),
                  backgroundColor: Colors.red,
                  behavior: SnackBarBehavior.floating,
                ),
              );
            }
          },
          builder: (context, state) {
            final loading = state is PhoneVerifyLoading;

            return SingleChildScrollView(
              padding: EdgeInsets.symmetric(horizontal: 24.w),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  verticalSpace(32),
                  IconButton(
                    icon: const Icon(Icons.arrow_back_ios_new_rounded),
                    onPressed: () => Navigator.pop(context),
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints(),
                  ),
                  verticalSpace(32),
                  Text('Enter the code', style: TextStyles.font28Bold),
                  verticalSpace(8),
                  Text(
                    'We sent a WhatsApp message to\n${widget.phoneNumber}',
                    style: TextStyles.font16Medium.copyWith(
                      color: ColorManager.lightGrey,
                    ),
                  ),
                  verticalSpace(40),

                  // Hidden real TextField (captures typing + paste)
                  SizedBox(
                    width: 1,
                    height: 1,
                    child: TextField(
                      controller: _hiddenCtl,
                      focusNode: _hiddenFocus,
                      keyboardType: TextInputType.number,
                      maxLength: 6,
                      enabled: !loading,
                      cursorHeight: 1,
                      decoration: const InputDecoration(
                        counterText: '',
                        border: InputBorder.none,
                        isCollapsed: true,
                      ),
                      inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                      style: const TextStyle(
                        fontSize: 1,
                        height: 1,
                        color: Colors.transparent,
                      ),
                    ),
                  ),

                  // 6 visual boxes — tapping any of them focuses the hidden field
                  GestureDetector(
                    onTap: () {
                      _hiddenFocus.requestFocus();
                      // Force keyboard on Android if focus was lost while disabled
                      SystemChannels.textInput.invokeMethod('TextInput.show');
                    },
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: List.generate(6, (i) {
                        final digits = _digits;
                        final isCursor =
                            digits[i].isEmpty &&
                            (i == 0 || digits[i - 1].isNotEmpty);
                        final hasFocus = _hiddenFocus.hasFocus;
                        return AnimatedContainer(
                          duration: const Duration(milliseconds: 150),
                          width: 46.r,
                          height: 56.r,
                          margin: EdgeInsets.symmetric(horizontal: 4.w),
                          decoration: BoxDecoration(
                            color: isDark
                                ? const Color(0xFF1E1E1E)
                                : Colors.white,
                            borderRadius: BorderRadius.circular(12.r),
                            border: Border.all(
                              color: (hasFocus && isCursor)
                                  ? ColorManager.accent
                                  : digits[i].isNotEmpty
                                  ? ColorManager.accent.withValues(alpha: 0.5)
                                  : (isDark
                                        ? const Color(0xFF3A3A3A)
                                        : const Color(0xFFE0E0E0)),
                              width: (hasFocus && isCursor) ? 2 : 1,
                            ),
                          ),
                          alignment: Alignment.center,
                          child: digits[i].isNotEmpty
                              ? Text(
                                  digits[i],
                                  style: TextStyles.font20SemiBold,
                                )
                              : (hasFocus && isCursor
                                    ? _BlinkingCursor(isDark: isDark)
                                    : const SizedBox.shrink()),
                        );
                      }),
                    ),
                  ),
                  verticalSpace(40),

                  if (loading)
                    const Center(child: CircularProgressIndicator())
                  else
                    AppButton(
                      text: 'Verify',
                      isWhite: false,
                      onPressed: () {
                        if (_otp.length == 6) {
                          context.read<PhoneVerifyCubit>().verifyOtp(_otp);
                        }
                      },
                    ),

                  verticalSpace(24),

                  // Resend
                  Center(
                    child: _resendSeconds > 0
                        ? Text(
                            'Resend code in ${_resendSeconds}s',
                            style: TextStyles.font14Medium.copyWith(
                              color: ColorManager.normalGrey,
                            ),
                          )
                        : GestureDetector(
                            onTap: () {
                              _startTimer();
                              context.read<PhoneVerifyCubit>().sendOtp(
                                widget.phoneNumber,
                              );
                            },
                            child: Text(
                              'Resend via WhatsApp',
                              style: TextStyles.font14Medium.copyWith(
                                color: ColorManager.accent,
                                decoration: TextDecoration.underline,
                              ),
                            ),
                          ),
                  ),
                  verticalSpace(16),
                  Center(
                    child: TextButton(
                      onPressed: () => Navigator.pushNamedAndRemoveUntil(
                        context,
                        Routes.newUserOnboarding,
                        (r) => false,
                      ),
                      child: Text(
                        'Skip for now',
                        style: TextStyles.font14Medium.copyWith(
                          color: ColorManager.normalGrey,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            );
          },
        ),
      ),
    );
  }
}

// ── Blinking cursor shown in the active empty box ───────────────────────────

class _BlinkingCursor extends StatefulWidget {
  final bool isDark;
  const _BlinkingCursor({required this.isDark});

  @override
  State<_BlinkingCursor> createState() => _BlinkingCursorState();
}

class _BlinkingCursorState extends State<_BlinkingCursor>
    with SingleTickerProviderStateMixin {
  late final AnimationController _ctrl = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 500),
  )..repeat(reverse: true);

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return FadeTransition(
      opacity: _ctrl,
      child: Container(
        width: 2,
        height: 24,
        decoration: BoxDecoration(
          color: ColorManager.accent,
          borderRadius: BorderRadius.circular(2),
        ),
      ),
    );
  }
}
