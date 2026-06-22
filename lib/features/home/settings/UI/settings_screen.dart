// ignore_for_file: deprecated_member_use

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:riff/core/logic/cubit/theme_cubit.dart';
import 'package:riff/core/themes/colors/color_manager.dart';
import 'package:riff/core/themes/text_styles/text_styles.dart';
import 'package:riff/features/home/settings/logic/cubit/language_cubit.dart';
import 'package:riff/generated/l10n.dart';

class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final s = S.of(context);
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bg = isDark ? const Color(0xFF111111) : const Color(0xFFF5F5F5);
    final cardBg = isDark ? const Color(0xFF1E1E1E) : Colors.white;

    return Scaffold(
      backgroundColor: bg,
      appBar: AppBar(
        backgroundColor: isDark ? const Color(0xFF141414) : Colors.white,
        title: Text(s.appSettingsTitle),
        centerTitle: false,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new, size: 20),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: ListView(
        padding: EdgeInsets.all(16.w),
        children: [
          // ── Appearance ──────────────────────────────────────────────────
          _SectionHeader(s.appearanceSection),
          SizedBox(height: 8.h),
          Container(
            decoration: BoxDecoration(
              color: cardBg,
              borderRadius: BorderRadius.circular(14.r),
              boxShadow: isDark ? [] : [
                BoxShadow(color: Colors.black.withValues(alpha: 0.04),
                    blurRadius: 8, offset: const Offset(0, 2))
              ],
            ),
            child: BlocBuilder<ThemeCubit, ThemeMode>(
              builder: (ctx, themeMode) {
                final effectiveIsDark =
                    Theme.of(ctx).brightness == Brightness.dark;
                final s2 = S.of(ctx);
                return _SettingsTile(
                  icon: effectiveIsDark
                      ? Icons.dark_mode_rounded
                      : Icons.light_mode_rounded,
                  iconColor: effectiveIsDark
                      ? const Color(0xFFFFD60A)
                      : const Color(0xFFFF9500),
                  title: s2.darkMode,
                  subtitle: effectiveIsDark ? s2.darkModeOn : s2.darkModeOff,
                  trailing: Switch.adaptive(
                    value: effectiveIsDark,
                    activeColor: ColorManager.accent,
                    onChanged: (_) => ctx
                        .read<ThemeCubit>()
                        .toggleTheme(effectiveIsDark),
                  ),
                );
              },
            ),
          ),

          SizedBox(height: 24.h),

          // ── Language ────────────────────────────────────────────────────
          _SectionHeader(s.languageSection),
          SizedBox(height: 8.h),
          Container(
            decoration: BoxDecoration(
              color: cardBg,
              borderRadius: BorderRadius.circular(14.r),
              boxShadow: isDark ? [] : [
                BoxShadow(color: Colors.black.withValues(alpha: 0.04),
                    blurRadius: 8, offset: const Offset(0, 2))
              ],
            ),
            child: BlocBuilder<LanguageCubit, Locale>(
              builder: (ctx, locale) {
                final isAr = locale.languageCode == 'ar';
                final s2 = S.of(ctx);
                return _SettingsTile(
                  icon: Icons.language_rounded,
                  iconColor: const Color(0xFF30B0C7),
                  title: s2.appLanguage,
                  subtitle: isAr ? 'العربية' : 'English',
                  trailing: Switch.adaptive(
                    value: isAr,
                    activeColor: ColorManager.accent,
                    onChanged: (val) {
                      ctx.read<LanguageCubit>().setLocale(
                        Locale(val ? 'ar' : 'en'),
                      );
                    },
                  ),
                  isFirst: true,
                  isLast: true,
                );
              },
            ),
          ),

          SizedBox(height: 32.h),
        ],
      ),
    );
  }
}

class _SectionHeader extends StatelessWidget {
  final String title;
  const _SectionHeader(this.title);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(left: 4.w, bottom: 4.h),
      child: Text(
        title.toUpperCase(),
        style: TextStyles.font12Medium.copyWith(
            color: ColorManager.normalGrey, letterSpacing: 0.8),
      ),
    );
  }
}

class _SettingsTile extends StatelessWidget {
  final IconData icon;
  final Color iconColor;
  final String title;
  final String subtitle;
  final Widget trailing;
  final bool isFirst;
  final bool isLast;

  const _SettingsTile({
    required this.icon,
    required this.iconColor,
    required this.title,
    required this.subtitle,
    required this.trailing,
    this.isFirst = false,
    this.isLast = false,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Padding(
      padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 14.h),
      child: Row(children: [
        Container(
          width: 36.r,
          height: 36.r,
          decoration: BoxDecoration(
            color: iconColor.withValues(alpha: 0.15),
            borderRadius: BorderRadius.circular(9.r),
          ),
          child: Icon(icon, color: iconColor, size: 20),
        ),
        SizedBox(width: 14.w),
        Expanded(
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(title,
                style: TextStyles.font14semiBold.copyWith(
                    color: isDark ? Colors.white : ColorManager.primaryBlack)),
            SizedBox(height: 2.h),
            Text(subtitle,
                style: TextStyles.font12Medium.copyWith(
                    color: ColorManager.normalGrey)),
          ]),
        ),
        trailing,
      ]),
    );
  }
}
