import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:riff/core/helpers/constants.dart';
import 'package:riff/core/helpers/shared_pref_helper.dart';
import 'package:riff/core/routing/routes.dart';
import 'package:riff/core/themes/colors/color_manager.dart';
import 'package:riff/core/themes/text_styles/text_styles.dart';
import 'package:riff/features/legal/privacy_policy_screen.dart';

/// Shown on first launch (or after an app reinstall) before the user can
/// proceed.  Accepts [startAtHome] so it knows where to navigate after
/// the user accepts.
class PrivacyPolicyGateScreen extends StatefulWidget {
  final bool startAtHome;
  const PrivacyPolicyGateScreen({super.key, required this.startAtHome});

  @override
  State<PrivacyPolicyGateScreen> createState() =>
      _PrivacyPolicyGateScreenState();
}

class _PrivacyPolicyGateScreenState extends State<PrivacyPolicyGateScreen> {
  bool _accepting = false;

  Future<void> _accept() async {
    setState(() => _accepting = true);
    await SharedPrefHelper.setData(
        SharedPrefKeys.privacyPolicyAccepted, true);
    if (!mounted) return;
    Navigator.pushNamedAndRemoveUntil(
      context,
      widget.startAtHome ? Routes.home : Routes.onBoarding,
      (_) => false,
    );
  }

  Future<void> _decline() async {
    // Tell the user why we need acceptance and give them a chance to reconsider.
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Cannot Continue'),
        content: const Text(
          'You must accept the Privacy Policy to use Riff. '
          'If you decline, the app will close.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Go Back'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: Text('Close App',
                style: TextStyle(color: ColorManager.red)),
          ),
        ],
      ),
    );
    if (confirmed == true) {
      // Exit the app
      if (mounted) Navigator.maybePop(context);
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      // Reuse the existing full-text policy view as the body
      body: const PrivacyPolicyBody(),
      bottomNavigationBar: SafeArea(
        child: Container(
          padding: EdgeInsets.fromLTRB(20.w, 12.h, 20.w, 16.h),
          decoration: BoxDecoration(
            color: isDark ? const Color(0xFF141414) : Colors.white,
            border: Border(
              top: BorderSide(
                color: isDark
                    ? Colors.white.withValues(alpha: 0.08)
                    : Colors.black.withValues(alpha: 0.08),
              ),
            ),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                'By tapping "Accept & Continue" you agree to our Privacy Policy.',
                textAlign: TextAlign.center,
                style: TextStyles.font12regular.copyWith(
                  color: ColorManager.normalGrey,
                  height: 1.4,
                ),
              ),
              SizedBox(height: 14.h),
              Row(children: [
                // Decline — outlined
                Expanded(
                  child: OutlinedButton(
                    onPressed: _accepting ? null : _decline,
                    style: OutlinedButton.styleFrom(
                      padding: EdgeInsets.symmetric(vertical: 14.h),
                      side: BorderSide(color: ColorManager.normalGrey),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12.r),
                      ),
                    ),
                    child: Text(
                      'Decline',
                      style: TextStyles.font14Medium
                          .copyWith(color: ColorManager.normalGrey),
                    ),
                  ),
                ),
                SizedBox(width: 12.w),
                // Accept — filled accent
                Expanded(
                  flex: 2,
                  child: ElevatedButton(
                    onPressed: _accepting ? null : _accept,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: ColorManager.accent,
                      foregroundColor: ColorManager.black,
                      padding: EdgeInsets.symmetric(vertical: 14.h),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12.r),
                      ),
                      elevation: 0,
                    ),
                    child: _accepting
                        ? SizedBox(
                            width: 20.r,
                            height: 20.r,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: ColorManager.black,
                            ),
                          )
                        : Text(
                            'Accept & Continue',
                            style: TextStyles.font14Medium.copyWith(
                              fontWeight: FontWeight.w700,
                              color: ColorManager.black,
                            ),
                          ),
                  ),
                ),
              ]),
            ],
          ),
        ),
      ),
    );
  }
}
