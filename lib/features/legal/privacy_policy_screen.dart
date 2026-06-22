import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:riff/core/themes/colors/color_manager.dart';
import 'package:riff/core/themes/text_styles/text_styles.dart';
import 'package:riff/generated/l10n.dart';

/// Full Privacy Policy screen.
/// Opened from the signup flow (TermsAndConditionsText) and from the app drawer.
class PrivacyPolicyScreen extends StatelessWidget {
  const PrivacyPolicyScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(S.of(context).privacyPolicyScreenTitle),
        centerTitle: true,
      ),
      body: const PrivacyPolicyBody(),
    );
  }
}

/// Scrollable policy content — shared by [PrivacyPolicyScreen] and
/// [PrivacyPolicyGateScreen].
class PrivacyPolicyBody extends StatelessWidget {
  const PrivacyPolicyBody({super.key});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final s = S.of(context);
    return ListView(
      padding: EdgeInsets.symmetric(horizontal: 20.w, vertical: 20.h),
      children: [
          _Header(isDark: isDark),
          SizedBox(height: 24.h),
          _Section(isDark: isDark, icon: Icons.info_outline_rounded,
            iconColor: const Color(0xFF5E5CE6),
            title: s.ppSection1Title, body: s.ppSection1Body),
          _Section(isDark: isDark, icon: Icons.data_usage_rounded,
            iconColor: const Color(0xFF30D158),
            title: s.ppSection2Title, body: s.ppSection2Body),
          _Section(isDark: isDark, icon: Icons.settings_outlined,
            iconColor: const Color(0xFFFF9500),
            title: s.ppSection3Title, body: s.ppSection3Body),
          _Section(isDark: isDark, icon: Icons.share_outlined,
            iconColor: const Color(0xFFFF6B35),
            title: s.ppSection4Title, body: s.ppSection4Body),
          _Section(isDark: isDark, icon: Icons.lock_outline_rounded,
            iconColor: const Color(0xFF5E5CE6),
            title: s.ppSection5Title, body: s.ppSection5Body),
          _Section(isDark: isDark, icon: Icons.chat_bubble_outline_rounded,
            iconColor: const Color(0xFF64D2FF),
            title: s.ppSection6Title, body: s.ppSection6Body),
          _Section(isDark: isDark, icon: Icons.child_care_rounded,
            iconColor: const Color(0xFFFF375F),
            title: s.ppSection7Title, body: s.ppSection7Body),
          _Section(isDark: isDark, icon: Icons.person_outline_rounded,
            iconColor: const Color(0xFF30D158),
            title: s.ppSection8Title, body: s.ppSection8Body),
          _Section(isDark: isDark, icon: Icons.cookie_outlined,
            iconColor: const Color(0xFFFF9500),
            title: s.ppSection9Title, body: s.ppSection9Body),
          _Section(isDark: isDark, icon: Icons.update_rounded,
            iconColor: const Color(0xFF5E5CE6),
            title: s.ppSection10Title, body: s.ppSection10Body),
          _Section(isDark: isDark, icon: Icons.mail_outline_rounded,
            iconColor: const Color(0xFF64D2FF),
            title: s.ppSection11Title, body: s.ppSection11Body),
          SizedBox(height: 32.h),
        ],
      );
  }
}

// ─── Header ──────────────────────────────────────────────────────────────────

class _Header extends StatelessWidget {
  final bool isDark;
  const _Header({required this.isDark});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.all(20.r),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1A1A2E) : const Color(0xFFF0EEFF),
        borderRadius: BorderRadius.circular(16.r),
      ),
      child: Row(children: [
        Container(
          width: 48.r,
          height: 48.r,
          decoration: BoxDecoration(
            color: const Color(0xFF5E5CE6).withValues(alpha: 0.15),
            shape: BoxShape.circle,
          ),
          child: const Icon(Icons.shield_outlined,
              color: Color(0xFF5E5CE6), size: 26),
        ),
        SizedBox(width: 14.w),
        Flexible(
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(S.of(context).privacyPolicyHeaderTitle,
                style: TextStyles.font16Medium.copyWith(
                    fontWeight: FontWeight.w700)),
            SizedBox(height: 2.h),
            Text(
              S.of(context).privacyPolicyHeaderSubtitle,
              style: TextStyles.font12regular
                  .copyWith(color: ColorManager.normalGrey, height: 1.4),
            ),
          ]),
        ),
      ]),
    );
  }
}

// ─── Section card ─────────────────────────────────────────────────────────────

class _Section extends StatelessWidget {
  final bool isDark;
  final IconData icon;
  final Color iconColor;
  final String title;
  final String body;

  const _Section({
    required this.isDark,
    required this.icon,
    required this.iconColor,
    required this.title,
    required this.body,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(bottom: 16.h),
      child: Container(
        padding: EdgeInsets.all(16.r),
        decoration: BoxDecoration(
          color: isDark ? const Color(0xFF1C1C1C) : const Color(0xFFF8F8F8),
          borderRadius: BorderRadius.circular(14.r),
          border: Border.all(
            color: isDark
                ? Colors.white.withValues(alpha: 0.06)
                : Colors.black.withValues(alpha: 0.05),
          ),
        ),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Row(children: [
            Container(
              width: 32.r,
              height: 32.r,
              decoration: BoxDecoration(
                color: iconColor.withValues(alpha: 0.12),
                shape: BoxShape.circle,
              ),
              child: Icon(icon, size: 16, color: iconColor),
            ),
            SizedBox(width: 10.w),
            Flexible(
              child: Text(title,
                  style: TextStyles.font14Medium.copyWith(
                      fontWeight: FontWeight.w700)),
            ),
          ]),
          SizedBox(height: 10.h),
          Text(
            body,
            style: TextStyles.font12regular.copyWith(
              fontSize: 13,
              color: isDark
                  ? const Color(0xFFBBBBBB)
                  : const Color(0xFF444444),
              height: 1.55,
            ),
          ),
        ]),
      ),
    );
  }
}
