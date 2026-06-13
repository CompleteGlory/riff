import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:riff/core/helpers/extenstions.dart';
import 'package:riff/core/helpers/shared_pref_helper.dart';
import 'package:riff/core/logic/cubit/theme_cubit.dart';
import 'package:riff/core/routing/routes.dart';
import 'package:riff/core/themes/colors/color_manager.dart';

class AppDrawer extends StatelessWidget {
  const AppDrawer({super.key});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bg   = isDark ? const Color(0xFF1A1A1A) : ColorManager.white;
    final divider = isDark ? const Color(0xFF2A2A2A) : ColorManager.lighterGrey;

    return Drawer(
      backgroundColor: bg,
      surfaceTintColor: Colors.transparent,
      child: SafeArea(
        child: Column(children: [
          // ── Brand header ──────────────────────────────────────────────────
          _DrawerHeader(isDark: isDark),
          Divider(height: 1, color: divider),

          const SizedBox(height: 8),

          // ── Theme toggle ─────────────────────────────────────────────────
          BlocBuilder<ThemeCubit, ThemeMode>(
            builder: (ctx, themeMode) {
              final cubit = ctx.read<ThemeCubit>();
              // Resolve the effective brightness so the toggle reflects (and
              // flips) correctly even while on system mode.
              final effectiveIsDark =
                  Theme.of(ctx).brightness == Brightness.dark;
              return _DrawerToggle(
                isDark: effectiveIsDark,
                onToggle: () => cubit.toggleTheme(effectiveIsDark),
              );
            },
          ),

          Divider(height: 1, color: divider),
          const Spacer(),

          // ── Logout ────────────────────────────────────────────────────────
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 24),
            child: _LogoutButton(),
          ),
        ]),
      ),
    );
  }
}

class _DrawerHeader extends StatelessWidget {
  final bool isDark;
  const _DrawerHeader({required this.isDark});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(24, 24, 24, 20),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF141414) : ColorManager.black,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Riff wordmark
          Container(
            width: 48, height: 48,
            decoration: BoxDecoration(
              color: ColorManager.accent,
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Center(
              child: Text('R',
                style: TextStyle(
                  fontFamily: 'GeneralSans',
                  fontSize: 24,
                  fontWeight: FontWeight.w800,
                  color: ColorManager.black,
                ),
              ),
            ),
          ),
          const SizedBox(height: 16),
          const Text('Riff',
            style: TextStyle(
              fontFamily: 'GeneralSans',
              fontSize: 22,
              fontWeight: FontWeight.w800,
              color: ColorManager.white,
            ),
          ),
          const SizedBox(height: 2),
          const Text('Your music social feed',
            style: TextStyle(
              fontFamily: 'GeneralSans',
              fontSize: 13,
              color: Color(0xFFAAAAAA),
            ),
          ),
        ],
      ),
    );
  }
}

class _DrawerToggle extends StatelessWidget {
  final bool isDark;
  final VoidCallback onToggle;
  const _DrawerToggle({required this.isDark, required this.onToggle});

  @override
  Widget build(BuildContext context) {
    final textColor = isDark ? ColorManager.white : ColorManager.black;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      child: GestureDetector(
        onTap: onToggle,
        behavior: HitTestBehavior.opaque,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          decoration: BoxDecoration(
            color: isDark ? const Color(0xFF252525) : const Color(0xFFF0F0F0),
            borderRadius: BorderRadius.circular(14),
          ),
          child: Row(children: [
            Container(
              width: 36, height: 36,
              decoration: BoxDecoration(
                color: isDark ? const Color(0xFF333333) : ColorManager.lighterGrey,
                shape: BoxShape.circle,
              ),
              child: Icon(
                isDark ? Icons.dark_mode_rounded : Icons.light_mode_rounded,
                size: 18,
                color: isDark ? ColorManager.accent : const Color(0xFF666666),
              ),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(isDark ? 'Dark Mode' : 'Light Mode',
                    style: TextStyle(
                      fontFamily: 'GeneralSans',
                      fontSize: 15,
                      fontWeight: FontWeight.w600,
                      color: textColor,
                    ),
                  ),
                  Text(isDark ? 'Tap to switch to light' : 'Tap to switch to dark',
                    style: const TextStyle(
                      fontFamily: 'GeneralSans',
                      fontSize: 12,
                      color: Color(0xFF888888),
                    ),
                  ),
                ],
              ),
            ),
            // Toggle pill
            AnimatedContainer(
              duration: const Duration(milliseconds: 250),
              curve: Curves.easeInOut,
              width: 48, height: 28,
              padding: const EdgeInsets.all(3),
              decoration: BoxDecoration(
                color: isDark ? ColorManager.accent : const Color(0xFFCCCCCC),
                borderRadius: BorderRadius.circular(14),
              ),
              child: AnimatedAlign(
                duration: const Duration(milliseconds: 250),
                curve: Curves.easeInOut,
                alignment: isDark ? Alignment.centerRight : Alignment.centerLeft,
                child: Container(
                  width: 22, height: 22,
                  decoration: BoxDecoration(
                    color: isDark ? ColorManager.black : ColorManager.white,
                    shape: BoxShape.circle,
                    boxShadow: [
                      BoxShadow(color: Colors.black.withValues(alpha: 0.15),
                          blurRadius: 4, offset: const Offset(0, 1)),
                    ],
                  ),
                ),
              ),
            ),
          ]),
        ),
      ),
    );
  }
}

class _LogoutButton extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return GestureDetector(
      onTap: () {
        Navigator.pop(context); // close drawer first
        context.pushReplacementNamed(Routes.login);
        SharedPrefHelper.clearAllData();
      },
      behavior: HitTestBehavior.opaque,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        decoration: BoxDecoration(
          color: isDark
              ? const Color(0xFF2A1515)
              : const Color(0xFFFFF0F0),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: ColorManager.red.withValues(alpha: 0.25),
          ),
        ),
        child: Row(children: [
          Container(
            width: 36, height: 36,
            decoration: BoxDecoration(
              color: ColorManager.red.withValues(alpha: 0.12),
              shape: BoxShape.circle,
            ),
            child: const Icon(Icons.logout_rounded,
                size: 18, color: ColorManager.red),
          ),
          const SizedBox(width: 14),
          const Text('Log out',
            style: TextStyle(
              fontFamily: 'GeneralSans',
              fontSize: 15,
              fontWeight: FontWeight.w600,
              color: ColorManager.red,
            ),
          ),
          const Spacer(),
          Icon(Icons.arrow_forward_ios_rounded,
              size: 14, color: ColorManager.red.withValues(alpha: 0.6)),
        ]),
      ),
    );
  }
}
