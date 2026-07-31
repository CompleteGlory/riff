import 'package:flutter/material.dart';
import 'package:riff/core/di/dependency_injection.dart';
import 'package:riff/core/helpers/extenstions.dart';
import 'package:riff/core/helpers/constants.dart';
import 'package:riff/core/helpers/shared_pref_helper.dart';
import 'package:riff/core/routing/routes.dart';
import 'package:riff/core/themes/colors/color_manager.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:riff/features/home/notifications/logic/cubit/notifications_cubit.dart';
import 'package:riff/features/home/chat/logic/cubit/chats_list_cubit.dart';
import 'package:riff/features/home/chat/data/services/chat_socket_service.dart';
import 'package:riff/features/home/settings/UI/settings_screen.dart';
import 'package:riff/features/home/core/UI/bug_report/bug_report_screen.dart';
import 'package:riff/features/home/core/UI/feature_request/feature_request_screen.dart';
import 'package:riff/features/home/core/logic/bug_report/bug_report_cubit.dart';
import 'package:riff/features/home/core/logic/feature_request/feature_request_cubit.dart';
import 'package:riff/features/home/core/data/repos/feedback_repo.dart';
import 'package:riff/features/home/block/UI/blocked_users_screen.dart';
import 'package:riff/features/home/block/logic/cubit/block_cubit.dart';
import 'package:riff/features/home/block/data/repos/block_repo.dart';
import 'package:riff/features/home/core/logic/cubit/home_cubit.dart';
import 'package:riff/features/home/core/logic/cubit/home_state.dart';
import 'package:riff/features/home/profile/UI/profile_screen.dart';
import 'package:riff/generated/l10n.dart';

class AppDrawer extends StatelessWidget {
  final bool isPrivate;
  const AppDrawer({super.key, this.isPrivate = false});

  @override
  Widget build(BuildContext context) {
    final s = S.of(context);
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bg = isDark ? const Color(0xFF1A1A1A) : ColorManager.white;
    final divider = isDark ? const Color(0xFF2A2A2A) : ColorManager.lighterGrey;

    return Drawer(
      backgroundColor: bg,
      surfaceTintColor: Colors.transparent,
      child: SafeArea(
        child: Column(children: [
          _DrawerHeader(isDark: isDark),
          Divider(height: 1, color: divider),

          // Scrollable items — wrapped so adding more entries never overflows
          Expanded(
            child: SingleChildScrollView(
              child: Column(children: [
          const SizedBox(height: 8),

          // Profile Settings
          BlocBuilder<HomeCubit, HomeState>(
            builder: (context, homeState) {
              // Extract the loaded profile from HomeCubit's screens list.
              // screens[4] is a ProfileScreen once the user is loaded.
              final cubit = context.read<HomeCubit>();
              final screen = cubit.screens[4];
              final UserProfile? profile =
                  screen is ProfileScreen ? screen.profile : null;

              return _DrawerItem(
                isDark: isDark,
                icon: Icons.manage_accounts_outlined,
                iconColor: const Color(0xFF30D158),
                title: s.profileSettingsDrawer,
                subtitle: s.editYourProfile,
                onTap: profile == null
                    ? () {} // profile not loaded yet — no-op
                    : () {
                        // Capture references before closing the drawer so
                        // they stay valid after Navigator.pop.
                        final homeCubit = context.read<HomeCubit>();
                        final nav = Navigator.of(context);
                        nav.pop(); // close drawer
                        nav.pushNamed(
                          Routes.profileSettings,
                          arguments: (profile, homeCubit),
                        );
                      },
              );
            },
          ),

          const SizedBox(height: 4),

          // App Settings
          _DrawerItem(
            isDark: isDark,
            icon: Icons.settings_outlined,
            iconColor: const Color(0xFF5E5CE6),
            title: s.settingsDrawer,
            subtitle: s.privacyAppearance,
            onTap: () {
              Navigator.pop(context);
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const SettingsScreen()),
              );
            },
          ),

          const SizedBox(height: 4),

          // Account Settings
          _DrawerItem(
            isDark: isDark,
            icon: Icons.manage_accounts_outlined,
            iconColor: const Color(0xFF30B0C7),
            title: s.accountSettingsDrawer,
            subtitle: s.accountSettingsSub,
            onTap: () {
              Navigator.pop(context);
              Navigator.pushNamed(
                context,
                Routes.accountSettings,
                arguments: isPrivate,
              );
            },
          ),

          Divider(height: 1, color: divider, indent: 16, endIndent: 16),
          const SizedBox(height: 8),

          // Bug Report
          _DrawerItem(
            isDark: isDark,
            icon: Icons.bug_report_outlined,
            iconColor: const Color(0xFFFF6B35),
            title: s.reportABugDrawer,
            subtitle: s.helpUsFixIssues,
            onTap: () {
              Navigator.pop(context);
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => BlocProvider(
                    create: (_) => BugReportCubit(getIt<FeedbackRepo>()),
                    child: const BugReportScreen(),
                  ),
                ),
              );
            },
          ),

          // Feature Request
          _DrawerItem(
            isDark: isDark,
            icon: Icons.lightbulb_outline_rounded,
            iconColor: ColorManager.accent,
            title: s.requestAFeatureDrawer,
            subtitle: s.shareYourIdeas,
            onTap: () {
              Navigator.pop(context);
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => BlocProvider(
                    create: (_) => FeatureRequestCubit(getIt<FeedbackRepo>()),
                    child: const FeatureRequestScreen(),
                  ),
                ),
              );
            },
          ),

          Divider(height: 1, color: divider, indent: 16, endIndent: 16),
          const SizedBox(height: 8),

          // Blocked Users
          _DrawerItem(
            isDark: isDark,
            icon: Icons.block_rounded,
            iconColor: const Color(0xFFFF3B30),
            title: s.blockedUsersDrawer,
            subtitle: s.manageBlockedUsers,
            onTap: () {
              Navigator.pop(context);
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => BlocProvider(
                    create: (_) => BlockCubit(getIt<BlockRepo>()),
                    child: const BlockedUsersScreen(),
                  ),
                ),
              );
            },
          ),

          // Privacy Policy
          _DrawerItem(
            isDark: isDark,
            icon: Icons.shield_outlined,
            iconColor: const Color(0xFF5E5CE6),
            title: s.privacyPolicyDrawer,
            subtitle: s.howWeHandleData,
            onTap: () {
              Navigator.pop(context);
              Navigator.pushNamed(context, Routes.privacyPolicy);
            },
          ),

          // About Us
          _DrawerItem(
            isDark: isDark,
            icon: Icons.info_outline_rounded,
            iconColor: const Color(0xFFFFD60A),
            title: s.aboutUsDrawer,
            subtitle: s.aboutUsDrawerSubtitle,
            onTap: () {
              Navigator.pop(context);
              Navigator.pushNamed(context, Routes.aboutUs);
            },
          ),

          Divider(height: 1, color: divider, indent: 16, endIndent: 16),
          const SizedBox(height: 8),
              ]),  // Column (scrollable)
            ),    // SingleChildScrollView
          ),      // Expanded

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
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        const Text('Riff',
          style: TextStyle(fontFamily: 'GeneralSans', fontSize: 22,
              fontWeight: FontWeight.w800, color: ColorManager.white)),
        const SizedBox(height: 2),
        Text(S.of(context).yourMusicSocialFeed,
          style: const TextStyle(fontFamily: 'GeneralSans', fontSize: 13,
              color: Color(0xFFAAAAAA))),
      ]),
    );
  }
}

class _DrawerItem extends StatelessWidget {
  final bool isDark;
  final IconData icon;
  final Color iconColor;
  final String title;
  final String subtitle;
  final VoidCallback onTap;

  const _DrawerItem({
    required this.isDark,
    required this.icon,
    required this.iconColor,
    required this.title,
    required this.subtitle,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      child: GestureDetector(
        onTap: onTap,
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
                color: iconColor.withValues(alpha: 0.15),
                shape: BoxShape.circle,
              ),
              child: Icon(icon, size: 18, color: iconColor),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text(title,
                  style: TextStyle(fontFamily: 'GeneralSans', fontSize: 15,
                      fontWeight: FontWeight.w600,
                      color: isDark ? ColorManager.white : ColorManager.black)),
                Text(subtitle,
                  style: const TextStyle(fontFamily: 'GeneralSans',
                      fontSize: 12, color: Color(0xFF888888))),
              ]),
            ),
            Icon(Icons.arrow_forward_ios_rounded, size: 14,
                color: isDark ? const Color(0xFF555555) : const Color(0xFFBBBBBB)),
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
      onTap: () async {
        Navigator.pop(context);
        // Reset all singletons that hold per-user state so the next login
        // starts with a clean slate.
        getIt<NotificationsCubit>().reset();
        getIt<ChatsListCubit>().reset();
        getIt<ChatSocketService>().disconnect();
        context.pushReplacementNamed(Routes.login);
        // Clear user session data but preserve theme preference so the
        // user's chosen light/dark mode survives logout.
        await SharedPrefHelper.removeData(SharedPrefKeys.userToken);
        await SharedPrefHelper.removeData(SharedPrefKeys.refreshToken);
        await SharedPrefHelper.removeData(SharedPrefKeys.userId);
        await SharedPrefHelper.removeData(SharedPrefKeys.userProfileImage);
        await SharedPrefHelper.removeData(SharedPrefKeys.firstName);
        await SharedPrefHelper.removeData(SharedPrefKeys.lastName);
      },
      behavior: HitTestBehavior.opaque,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        decoration: BoxDecoration(
          color: isDark ? const Color(0xFF2A1515) : const Color(0xFFFFF0F0),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: ColorManager.red.withValues(alpha: 0.25)),
        ),
        child: Row(children: [
          Container(
            width: 36, height: 36,
            decoration: BoxDecoration(
                color: ColorManager.red.withValues(alpha: 0.12),
                shape: BoxShape.circle),
            child: const Icon(Icons.logout_rounded,
                size: 18, color: ColorManager.red),
          ),
          const SizedBox(width: 14),
          Text(S.of(context).logOut,
            style: const TextStyle(fontFamily: 'GeneralSans', fontSize: 15,
                fontWeight: FontWeight.w600, color: ColorManager.red)),
          const Spacer(),
          Icon(Icons.arrow_forward_ios_rounded,
              size: 14, color: ColorManager.red.withValues(alpha: 0.6)),
        ]),
      ),
    );
  }
}
