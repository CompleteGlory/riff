import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:riff/core/themes/colors/color_manager.dart';
import 'package:riff/core/themes/text_styles/text_styles.dart';
import 'package:riff/generated/l10n.dart';
import 'package:url_launcher/url_launcher.dart';

class AboutUsScreen extends StatelessWidget {
  const AboutUsScreen({super.key});
  
  static const _green  = Color(0xFF30D158);

  @override
  Widget build(BuildContext context) {
    final s      = S.of(context);
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bg     = isDark ? const Color(0xFF111111) : const Color(0xFFF5F5F5);

    return Scaffold(
      backgroundColor: bg,
      body: CustomScrollView(
        slivers: [
          _HeroSliver(isDark: isDark, s: s),
          SliverPadding(
            padding: EdgeInsets.fromLTRB(20.w, 28.h, 20.w, 40.h),
            sliver: SliverList(
              delegate: SliverChildListDelegate([
                // ── About ──────────────────────────────────────────────
                _Card(
                  isDark: isDark,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Theme-aware logo inline with the section label
                      Row(children: [
                        Image.asset(
                          isDark
                              ? 'assets/images/riff logo.png'
                              : 'assets/images/riff logo dark.png',
                          height: 28.h,
                          fit: BoxFit.contain,
                        ),
                      ]),
                      SizedBox(height: 12.h),
                      Text(
                        s.aboutUsDescription,
                        style: TextStyles.font14Medium.copyWith(
                          color: isDark
                              ? const Color(0xFFCCCCCC)
                              : const Color(0xFF444444),
                          height: 1.6,
                        ),
                      ),
                    ],
                  ),
                ),

                SizedBox(height: 16.h),

                // ── Mission ─────────────────────────────────────────────
                _Card(
                  isDark: isDark,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _SectionLabel(
                        icon: Icons.flag_rounded,
                        color: _green,
                        text: s.aboutUsMission,
                      ),
                      SizedBox(height: 12.h),
                      Text(
                        s.aboutUsMissionBody,
                        style: TextStyles.font14Medium.copyWith(
                          color: isDark
                              ? const Color(0xFFCCCCCC)
                              : const Color(0xFF444444),
                          height: 1.6,
                        ),
                      ),
                    ],
                  ),
                ),

                SizedBox(height: 16.h),

                // ── Developer ────────────────────────────────────────────
                _Card(
                  isDark: isDark,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _SectionLabel(
                        icon: Icons.code_rounded,
                        color: const Color(0xFF5E5CE6),
                        text: s.aboutUsDeveloperTitle,
                      ),
                      SizedBox(height: 16.h),
                      Row(children: [
                        // Avatar
                        Container(
                          width: 56.r,
                          height: 56.r,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            gradient: const LinearGradient(
                              colors: [Color(0xFF5E5CE6), Color(0xFF30B0C7)],
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight,
                            ),
                          ),
                          child: Center(
                            child: Text(
                              'M',
                              style: TextStyle(
                                fontFamily: 'GeneralSans',
                                fontSize: 24.sp,
                                fontWeight: FontWeight.w800,
                                color: Colors.white,
                              ),
                            ),
                          ),
                        ),
                        SizedBox(width: 14.w),
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              s.aboutUsDeveloperName,
                              style: TextStyle(
                                fontFamily: 'GeneralSans',
                                fontSize: 17.sp,
                                fontWeight: FontWeight.w700,
                                color: isDark ? Colors.white : ColorManager.primaryBlack,
                              ),
                            ),
                            SizedBox(height: 2.h),
                            Text(
                              s.aboutUsDeveloperRole,
                              style: TextStyles.font12Medium.copyWith(
                                color: const Color(0xFF5E5CE6),
                              ),
                            ),
                          ],
                        ),
                      ]),
                      SizedBox(height: 14.h),
                      Text(
                        s.aboutUsDeveloperBio,
                        style: TextStyles.font14Medium.copyWith(
                          color: isDark
                              ? const Color(0xFFCCCCCC)
                              : const Color(0xFF444444),
                          height: 1.6,
                        ),
                      ),
                      SizedBox(height: 16.h),
                      // Email chip
                      GestureDetector(
                        onTap: () => launchUrl(
                          Uri.parse('mailto:${s.aboutUsContactEmail}'),
                        ),
                        child: Container(
                          padding: EdgeInsets.symmetric(
                              horizontal: 14.w, vertical: 10.h),
                          decoration: BoxDecoration(
                            color: const Color(0xFF5E5CE6).withValues(alpha: 0.12),
                            borderRadius: BorderRadius.circular(10.r),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              const Icon(Icons.mail_outline_rounded,
                                  size: 16, color: Color(0xFF5E5CE6)),
                              SizedBox(width: 8.w),
                              Text(
                                s.aboutUsContactEmail,
                                style: TextStyles.font13SemiBold.copyWith(
                                  color: const Color(0xFF5E5CE6),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),

                SizedBox(height: 32.h),

                // ── Footer ───────────────────────────────────────────────
                Center(
                  child: Column(children: [
                    Image.asset(
                      isDark
                          ? 'assets/images/riff logo.png'
                          : 'assets/images/riff logo dark.png',
                      height: 36.h,
                      fit: BoxFit.contain,
                    ),
                    SizedBox(height: 8.h),
                    Text(
                      '${s.aboutUsVersion} 1.0.10',
                      style: TextStyles.font12Medium.copyWith(
                        color: const Color(0xFF666666),
                      ),
                    ),
                    SizedBox(height: 6.h),
                    Text(
                      s.aboutUsMadeWith,
                      style: TextStyles.font12Medium.copyWith(
                        color: const Color(0xFF888888),
                      ),
                    ),
                  ]),
                ),
              ]),
            ),
          ),
        ],
      ),
    );
  }
}

// ── Hero sliver with Riff logo ────────────────────────────────────────────────

class _HeroSliver extends StatelessWidget {
  final bool isDark;
  final S s;
  const _HeroSliver({required this.isDark, required this.s});

  @override
  Widget build(BuildContext context) {
    return SliverAppBar(
      expandedHeight: 220.h,
      pinned: true,
      backgroundColor: isDark ? const Color(0xFF141414) : Colors.black,
      leading: IconButton(
        icon: const Icon(Icons.arrow_back_ios_new, color: Colors.white, size: 20),
        onPressed: () => Navigator.pop(context),
      ),
      title: Text(
        s.aboutUsTitle,
        style: const TextStyle(
          fontFamily: 'GeneralSans',
          fontWeight: FontWeight.w700,
          color: Colors.white,
        ),
      ),
      flexibleSpace: FlexibleSpaceBar(
        collapseMode: CollapseMode.pin,
        background: Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              colors: [Color(0xFF1A1A2E), Color(0xFF16213E), Color(0xFF0F3460)],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
          ),
          child: Stack(
            children: [
              // Background music-wave decoration
              Positioned(
                right: -30,
                top: -20,
                child: Opacity(
                  opacity: 0.06,
                  child: Icon(Icons.graphic_eq_rounded,
                      size: 200, color: Colors.white),
                ),
              ),
              // Centred logo
              Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    SizedBox(height: 24.h),
                    // Actual Riff logo (light version — hero is always dark)
                    Image.asset(
                      'assets/images/riff logo.png',
                      width: 140.w,
                      fit: BoxFit.contain,
                    ),
                    SizedBox(height: 10.h),
                    Text(
                      s.aboutUsTagline,
                      style: TextStyle(
                        fontFamily: 'GeneralSans',
                        fontSize: 13.sp,
                        color: Colors.white.withValues(alpha: 0.6),
                        letterSpacing: 0.5,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ── Reusable card ─────────────────────────────────────────────────────────────

class _Card extends StatelessWidget {
  final bool isDark;
  final Widget child;
  const _Card({required this.isDark, required this.child});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: EdgeInsets.all(18.r),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1E1E1E) : Colors.white,
        borderRadius: BorderRadius.circular(16.r),
        boxShadow: isDark
            ? []
            : [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.05),
                  blurRadius: 10,
                  offset: const Offset(0, 3),
                ),
              ],
      ),
      child: child,
    );
  }
}

// ── Section label ─────────────────────────────────────────────────────────────

class _SectionLabel extends StatelessWidget {
  final IconData icon;
  final Color color;
  final String text;
  const _SectionLabel(
      {required this.icon, required this.color, required this.text});

  @override
  Widget build(BuildContext context) {
    return Row(children: [
      Container(
        width: 30,
        height: 30,
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.15),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Icon(icon, size: 16, color: color),
      ),
      const SizedBox(width: 10),
      Text(
        text,
        style: TextStyle(
          fontFamily: 'GeneralSans',
          fontSize: 15,
          fontWeight: FontWeight.w700,
          color: color,
        ),
      ),
    ]);
  }
}
