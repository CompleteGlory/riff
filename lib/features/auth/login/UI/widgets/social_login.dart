// ignore_for_file: duplicate_ignore, use_build_context_synchronously

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:riff/core/themes/colors/color_manager.dart';
import 'package:riff/features/auth/login/logic/cubit/login_cubit.dart';
import 'apple_sign_in_helper.dart';
import 'google_sign_in_helper.dart';
import 'package:riff/generated/l10n.dart';

class SocialLogin extends StatefulWidget {
  const SocialLogin({
    super.key,
    this.googleAuthService,
    this.appleAuthService,
  });

  /// Injectable seam for the Google sign-in call — defaults to the real
  /// plugin-backed implementation; tests can supply a fake instead.
  final GoogleAuthService? googleAuthService;

  /// Same seam for Sign in with Apple.
  final AppleAuthService? appleAuthService;

  @override
  State<SocialLogin> createState() => _SocialLoginState();
}

class _SocialLoginState extends State<SocialLogin>
    with SingleTickerProviderStateMixin {
  bool _isLoading = false;
  bool _appleLoading = false;

  /// Sign in with Apple exists on iOS only here, and the check is async, so
  /// the button is absent until it answers rather than flashing in and out.
  bool _appleAvailable = false;

  late final GoogleAuthService _authService;
  late final AppleAuthService _appleService;
  late AnimationController _pulseController;
  late Animation<double> _pulseAnimation;

  @override
  void initState() {
    super.initState();
    _authService = widget.googleAuthService ?? GoogleSignInAuthService();
    _appleService = widget.appleAuthService ?? SignInWithAppleService();
    _checkAppleAvailability();
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 900),
    );
    _pulseAnimation = Tween<double>(begin: 0.92, end: 1.0).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _pulseController.dispose();
    super.dispose();
  }

  Future<void> _checkAppleAvailability() async {
    final available = await _appleService.isAvailable();
    if (mounted) setState(() => _appleAvailable = available);
  }

  Future<void> _handleAppleSignIn(BuildContext context) async {
    if (_appleLoading || _isLoading) return;
    setState(() => _appleLoading = true);

    try {
      final result = await _appleService.signIn();
      if (result.isSuccess) {
        final credential = result.credential!;
        if (mounted) {
          context.read<LoginCubit>().loginWithApple(
                credential.identityToken,
                fullName: credential.fullName,
              );
        }
        return;
      }
      // Cancelling is deliberate and needs no message; a real failure does.
      if (mounted && result.status == AppleSignInStatus.failed) {
        final l10n = S.of(context);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(result.detail == null
                ? l10n.appleSignInFailed
                : l10n.signInFailedWithReason(result.detail!)),
            backgroundColor: Colors.red,
            behavior: SnackBarBehavior.floating,
            duration: const Duration(seconds: 8),
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _appleLoading = false);
    }
  }

  Future<void> _handleGoogleSignIn(BuildContext context) async {
    if (_isLoading) return;
    setState(() => _isLoading = true);
    _pulseController.repeat(reverse: true);

    try {
      final result = await _authService.signIn();
      if (result.isSuccess) {
        if (mounted) {
          context.read<LoginCubit>().loginWithGoogle(result.idToken!);
        }
        return;
      }
      if (mounted) _reportGoogleFailure(result);
    } finally {
      _pulseController.stop();
      _pulseController.reset();
      if (mounted) setState(() => _isLoading = false);
    }
  }

  /// Says what actually went wrong.
  ///
  /// These three used to collapse into one "cancelled or failed" message, so a
  /// configuration outage affecting every user looked exactly like a single
  /// person tapping Cancel — which is precisely how one went unnoticed.
  void _reportGoogleFailure(GoogleSignInResult result) {
    final l10n = S.of(context);
    final String message;
    switch (result.status) {
      case GoogleSignInStatus.success:
      case GoogleSignInStatus.cancelled:
        return; // Nothing to say.
      case GoogleSignInStatus.noIdToken:
        message = l10n.googleSignInNoToken;
      case GoogleSignInStatus.failed:
        message = result.detail == null
            ? l10n.googleSignInFailed
            : l10n.signInFailedWithReason(result.detail!);
    }

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.red,
        behavior: SnackBarBehavior.floating,
        duration: const Duration(seconds: 8),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final s = S.of(context);
    final bg = isDark ? const Color(0xFF252525) : Colors.white;
    final border = isDark ? const Color(0xFF3A3A3A) : const Color(0xFFDDDDDD);
    final textColor = isDark ? Colors.white : const Color(0xFF1A1A1A);

    final googleButton = AnimatedBuilder(
      animation: _pulseAnimation,
      builder: (_, child) => Transform.scale(
        scale: _isLoading ? _pulseAnimation.value : 1.0,
        child: child,
      ),
      child: SizedBox(
        width: double.infinity,
        height: 52,
        child: Material(
          color: bg,
          borderRadius: BorderRadius.circular(12),
          child: InkWell(
            borderRadius: BorderRadius.circular(12),
            onTap: _isLoading ? null : () => _handleGoogleSignIn(context),
            splashColor: ColorManager.accent.withValues(alpha: 0.12),
            highlightColor: ColorManager.accent.withValues(alpha: 0.06),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: _isLoading
                      ? ColorManager.accent.withValues(alpha: 0.4)
                      : border,
                  width: 1.5,
                ),
              ),
              child: AnimatedSwitcher(
                duration: const Duration(milliseconds: 250),
                transitionBuilder: (child, animation) => FadeTransition(
                  opacity: CurvedAnimation(
                      parent: animation, curve: Curves.easeInOut),
                  child: ScaleTransition(
                    scale: CurvedAnimation(
                        parent: animation, curve: Curves.easeOutBack),
                    child: child,
                  ),
                ),
                child: _isLoading
                    ? Row(
                        key: const ValueKey('loading'),
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(
                              strokeWidth: 2.2,
                              valueColor: AlwaysStoppedAnimation<Color>(
                                ColorManager.accent,
                              ),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Text(
                            s.signingIn,
                            style: TextStyle(
                              fontFamily: 'GeneralSans',
                              fontSize: 15,
                              fontWeight: FontWeight.w600,
                              color: textColor,
                            ),
                          ),
                        ],
                      )
                    : Row(
                        key: const ValueKey('idle'),
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          SvgPicture.string(_googleGSvg, width: 20, height: 20),
                          const SizedBox(width: 10),
                          Text(
                            s.continueWithGoogle,
                            style: TextStyle(
                              fontFamily: 'GeneralSans',
                              fontSize: 15,
                              fontWeight: FontWeight.w600,
                              color: textColor,
                            ),
                          ),
                        ],
                      ),
              ),
            ),
          ),
        ),
      ),
    );

    // Sign in with Apple sits above Google: App Store guideline 4.8 requires
    // an equivalent privacy-preserving option, and Apple's Human Interface
    // Guidelines ask for it to be at least as prominent as the alternatives.
    if (!_appleAvailable) return googleButton;

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        _AppleSignInButton(
          label: s.continueWithApple,
          isLoading: _appleLoading,
          isDark: isDark,
          onTap: _appleLoading ? null : () => _handleAppleSignIn(context),
        ),
        const SizedBox(height: 12),
        googleButton,
      ],
    );
  }
}

/// The Sign in with Apple button.
///
/// Apple's guidelines allow black, white, or white-with-outline; the fill is
/// flipped by theme so the button keeps its contrast either way.
class _AppleSignInButton extends StatelessWidget {
  const _AppleSignInButton({
    required this.label,
    required this.isLoading,
    required this.isDark,
    required this.onTap,
  });

  final String label;
  final bool isLoading;
  final bool isDark;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final fg = isDark ? Colors.black : Colors.white;
    final bg = isDark ? Colors.white : Colors.black;

    return SizedBox(
      width: double.infinity,
      height: 52,
      child: Material(
        color: bg,
        borderRadius: BorderRadius.circular(12),
        child: InkWell(
          borderRadius: BorderRadius.circular(12),
          onTap: onTap,
          child: Center(
            child: isLoading
                ? SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(
                      strokeWidth: 2.2,
                      valueColor: AlwaysStoppedAnimation<Color>(fg),
                    ),
                  )
                : Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.apple, color: fg, size: 22),
                      const SizedBox(width: 8),
                      Text(
                        label,
                        style: TextStyle(
                          fontFamily: 'GeneralSans',
                          fontSize: 15,
                          fontWeight: FontWeight.w600,
                          color: fg,
                        ),
                      ),
                    ],
                  ),
          ),
        ),
      ),
    );
  }
}

// Official Google "G" mark — four-color SVG
const String _googleGSvg = '''
<svg viewBox="0 0 24 24" xmlns="http://www.w3.org/2000/svg">
  <path d="M23.745 12.27c0-.79-.07-1.54-.19-2.27H12v4.51h6.59c-.29 1.48-1.14 2.73-2.44 3.57v2.97h3.96c2.31-2.13 3.64-5.28 3.64-8.78z" fill="#4285F4"/>
  <path d="M12 24c3.24 0 5.95-1.07 7.93-2.91l-3.96-2.97c-1.08.72-2.45 1.14-3.97 1.14-3.06 0-5.65-2.06-6.57-4.83H1.39v3.07C3.36 21.44 7.39 24 12 24z" fill="#34A853"/>
  <path d="M5.43 14.43A7.19 7.19 0 0 1 5 12c0-.84.15-1.66.43-2.43V6.5H1.39A11.97 11.97 0 0 0 0 12c0 1.93.46 3.76 1.39 5.5l4.04-3.07z" fill="#FBBC05"/>
  <path d="M12 4.75c1.73 0 3.29.6 4.51 1.77l3.38-3.38C17.94 1.19 15.23 0 12 0 7.39 0 3.36 2.56 1.39 6.5L5.43 9.57C6.35 6.8 8.94 4.75 12 4.75z" fill="#EA4335"/>
</svg>
''';
