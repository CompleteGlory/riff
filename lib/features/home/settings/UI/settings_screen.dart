// ignore_for_file: deprecated_member_use, use_build_context_synchronously
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:riff/core/di/dependency_injection.dart';
import 'package:riff/core/logic/cubit/theme_cubit.dart';
import 'package:riff/core/themes/colors/color_manager.dart';
import 'package:riff/core/themes/text_styles/text_styles.dart';
import 'package:riff/features/home/follow/logic/cubit/follow_cubit.dart';

class SettingsScreen extends StatefulWidget {
  /// Pass current is_private value from the user's profile
  final bool initialIsPrivate;
  const SettingsScreen({super.key, this.initialIsPrivate = false});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  late bool _isPrivate;
  bool _privacyLoading = false;

  @override
  void initState() {
    super.initState();
    _isPrivate = widget.initialIsPrivate;
  }

  Future<void> _togglePrivacy(bool value) async {
    setState(() { _privacyLoading = true; _isPrivate = value; });
    final cubit = getIt<FollowCubit>();
    final ok = await cubit.updatePrivacy(value);
    cubit.close();
    if (!ok && mounted) {
      setState(() => _isPrivate = !value); // revert on failure
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Failed to update privacy setting')),
      );
    }
    if (mounted) setState(() => _privacyLoading = false);
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bg = isDark ? const Color(0xFF111111) : const Color(0xFFF5F5F5);
    final cardBg = isDark ? const Color(0xFF1E1E1E) : Colors.white;

    return Scaffold(
      backgroundColor: bg,
      appBar: AppBar(
        backgroundColor: isDark ? const Color(0xFF141414) : Colors.white,
        title: const Text('Settings'),
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
          _SectionHeader('Appearance'),
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
                return _SettingsTile(
                  icon: effectiveIsDark
                      ? Icons.dark_mode_rounded
                      : Icons.light_mode_rounded,
                  iconColor: effectiveIsDark
                      ? const Color(0xFFFFD60A)
                      : const Color(0xFFFF9500),
                  title: 'Dark Mode',
                  subtitle: effectiveIsDark ? 'On' : 'Off',
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

          // ── Privacy ─────────────────────────────────────────────────────
          _SectionHeader('Privacy'),
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
            child: Column(children: [
              _SettingsTile(
                icon: Icons.lock_outline_rounded,
                iconColor: const Color(0xFF5E5CE6),
                title: 'Private Account',
                subtitle: _isPrivate
                    ? 'Only approved followers can see your posts'
                    : 'Anyone can follow you and see your posts',
                trailing: _privacyLoading
                    ? const SizedBox(width: 28, height: 28,
                        child: CircularProgressIndicator(strokeWidth: 2))
                    : Switch.adaptive(
                        value: _isPrivate,
                        activeColor: ColorManager.accent,
                        onChanged: _togglePrivacy,
                      ),
                isFirst: true,
                isLast: true,
              ),
            ]),
          ),
          SizedBox(height: 8.h),
          Padding(
            padding: EdgeInsets.symmetric(horizontal: 8.w),
            child: Text(
              'When your account is private, only people you approve can follow you '
              'and see your posts and reels.',
              style: TextStyles.font12Medium.copyWith(
                  color: ColorManager.normalGrey),
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
