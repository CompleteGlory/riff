// ignore_for_file: deprecated_member_use

import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:riff/core/di/dependency_injection.dart';
import 'package:riff/core/routing/routes.dart';
import 'package:riff/core/themes/colors/color_manager.dart';
import 'package:riff/core/themes/text_styles/text_styles.dart';
import 'package:riff/features/home/follow/logic/cubit/follow_cubit.dart';
import 'package:riff/generated/l10n.dart';

class AccountSettingsScreen extends StatefulWidget {
  final bool initialIsPrivate;
  const AccountSettingsScreen({super.key, this.initialIsPrivate = false});

  @override
  State<AccountSettingsScreen> createState() => _AccountSettingsScreenState();
}

class _AccountSettingsScreenState extends State<AccountSettingsScreen> {
  late bool _isPrivate;
  bool _privacyLoading = false;

  @override
  void initState() {
    super.initState();
    _isPrivate = widget.initialIsPrivate;
  }

  Future<void> _togglePrivacy() async {
    setState(() => _privacyLoading = true);
    final ok = await getIt<FollowCubit>().updatePrivacy(!_isPrivate);
    if (mounted) {
      setState(() {
        _privacyLoading = false;
        if (ok) _isPrivate = !_isPrivate;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final s = S.of(context);
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bg = isDark ? const Color(0xFF111111) : const Color(0xFFF5F5F5);
    final cardBg = isDark ? const Color(0xFF1E1E1E) : Colors.white;
    final shadow = isDark
        ? <BoxShadow>[]
        : [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.04),
              blurRadius: 8,
              offset: const Offset(0, 2),
            )
          ];

    return Scaffold(
      backgroundColor: bg,
      appBar: AppBar(
        backgroundColor: isDark ? const Color(0xFF141414) : Colors.white,
        title: Text(s.accountSettingsTitle),
        centerTitle: false,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new, size: 20),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: ListView(
        padding: EdgeInsets.all(16.w),
        children: [
          // ── Privacy ──────────────────────────────────────────────────────
          _SectionHeader(s.privacySection),
          SizedBox(height: 8.h),
          Container(
            decoration: BoxDecoration(
              color: cardBg,
              borderRadius: BorderRadius.circular(14.r),
              boxShadow: shadow,
            ),
            child: Padding(
              padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 14.h),
              child: Row(children: [
                Container(
                  width: 36.r,
                  height: 36.r,
                  decoration: BoxDecoration(
                    color: const Color(0xFF5E5CE6).withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(9.r),
                  ),
                  child: const Icon(Icons.lock_outline_rounded,
                      color: Color(0xFF5E5CE6), size: 20),
                ),
                SizedBox(width: 14.w),
                Expanded(
                  child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(s.privateAccount,
                            style: TextStyles.font14semiBold.copyWith(
                                color: isDark
                                    ? Colors.white
                                    : ColorManager.primaryBlack)),
                        SizedBox(height: 2.h),
                        Text(
                          _isPrivate
                              ? s.onlyApprovedFollowers
                              : s.anyoneCanFollow,
                          style: TextStyles.font12Medium
                              .copyWith(color: ColorManager.normalGrey),
                        ),
                      ]),
                ),
                _privacyLoading
                    ? SizedBox(
                        width: 32.r,
                        height: 20.h,
                        child: const Center(
                          child: SizedBox(
                            width: 16,
                            height: 16,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          ),
                        ),
                      )
                    : Switch.adaptive(
                        value: _isPrivate,
                        activeColor: ColorManager.accent,
                        onChanged: (_) => _togglePrivacy(),
                      ),
              ]),
            ),
          ),
          if (_isPrivate) ...[
            SizedBox(height: 6.h),
            Padding(
              padding: EdgeInsets.symmetric(horizontal: 4.w),
              child: Text(
                s.privateAccountDisclaimer,
                style: TextStyles.font12Medium
                    .copyWith(color: ColorManager.normalGrey),
              ),
            ),
          ],

          SizedBox(height: 24.h),

          // ── Security ──────────────────────────────────────────────────────
          _SectionHeader(s.changePasswordTitle),
          SizedBox(height: 8.h),
          Container(
            decoration: BoxDecoration(
              color: cardBg,
              borderRadius: BorderRadius.circular(14.r),
              boxShadow: shadow,
            ),
            child: InkWell(
              borderRadius: BorderRadius.circular(14.r),
              onTap: () => Navigator.pushNamed(context, Routes.changePassword),
              child: Padding(
                padding:
                    EdgeInsets.symmetric(horizontal: 16.w, vertical: 14.h),
                child: Row(children: [
                  Container(
                    width: 36.r,
                    height: 36.r,
                    decoration: BoxDecoration(
                      color: const Color(0xFFFF9500).withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(9.r),
                    ),
                    child: const Icon(Icons.key_rounded,
                        color: Color(0xFFFF9500), size: 20),
                  ),
                  SizedBox(width: 14.w),
                  Expanded(
                    child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(s.changePasswordTile,
                              style: TextStyles.font14semiBold.copyWith(
                                  color: isDark
                                      ? Colors.white
                                      : ColorManager.primaryBlack)),
                          SizedBox(height: 2.h),
                          Text(s.changePasswordSub,
                              style: TextStyles.font12Medium
                                  .copyWith(color: ColorManager.normalGrey)),
                        ]),
                  ),
                  Icon(Icons.arrow_forward_ios_rounded,
                      size: 14,
                      color: isDark
                          ? const Color(0xFF555555)
                          : const Color(0xFFBBBBBB)),
                ]),
              ),
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
