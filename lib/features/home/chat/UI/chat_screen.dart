import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:riff/core/networks/api_constants.dart';
import 'package:riff/core/themes/colors/color_manager.dart';
import 'package:riff/generated/l10n.dart';

class ChatScreen extends StatelessWidget {
  final String userId;
  final String username;
  final String fullName;
  final String? profileImageUrl;

  const ChatScreen({
    super.key,
    required this.userId,
    required this.username,
    required this.fullName,
    this.profileImageUrl,
  });

  String? get _avatarUrl {
    final raw = profileImageUrl;
    if (raw == null || raw.isEmpty) return null;
    return raw.startsWith('http') ? raw : '${ApiConstants.apiBASEURL}$raw';
  }

  @override
  Widget build(BuildContext context) {
    S.of(context);
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bg = isDark ? const Color(0xFF0F0F0F) : Colors.white;
    final divider =
        isDark ? const Color(0xFF2A2A2A) : const Color(0xFFEEEEEE);

    return Scaffold(
      backgroundColor: bg,
      appBar: AppBar(
        backgroundColor: bg,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          onPressed: () => Navigator.pop(context),
          icon: Icon(
            Icons.arrow_back_ios_new_rounded,
            size: 18.r,
            color: isDark ? Colors.white : ColorManager.black,
          ),
        ),
        title: Row(children: [
          Container(
            width: 34.r,
            height: 34.r,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: isDark
                  ? const Color(0xFF2A2A2A)
                  : const Color(0xFFEEEEEE),
            ),
            child: _avatarUrl != null
                ? ClipOval(
                    child: Image.network(_avatarUrl!, fit: BoxFit.cover,
                        errorBuilder: (_, __, ___) =>
                            _InitialIcon(name: fullName, isDark: isDark)),
                  )
                : _InitialIcon(name: fullName, isDark: isDark),
          ),
          SizedBox(width: 10.w),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                username,
                style: TextStyle(
                  fontFamily: 'GeneralSans',
                  fontSize: 15,
                  fontWeight: FontWeight.w700,
                  color: isDark ? Colors.white : ColorManager.black,
                ),
              ),
              Text(
                fullName,
                style: const TextStyle(
                  fontFamily: 'GeneralSans',
                  fontSize: 11,
                  color: Color(0xFF888888),
                ),
              ),
            ],
          ),
        ]),
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(1),
          child: Divider(height: 1, color: divider),
        ),
      ),
      body: Column(
        children: [
          const Expanded(child: _ComingSoonBody()),
          _InputBar(isDark: isDark),
        ],
      ),
    );
  }
}

class _ComingSoonBody extends StatelessWidget {
  const _ComingSoonBody();

  @override
  Widget build(BuildContext context) {
    final s = S.of(context);
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 72.r,
            height: 72.r,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: LinearGradient(
                colors: [
                  ColorManager.accent.withValues(alpha: 0.3),
                  ColorManager.accent.withValues(alpha: 0.1),
                ],
              ),
            ),
            child: Icon(
              Icons.chat_bubble_outline_rounded,
              size: 32.r,
              color: ColorManager.accent,
            ),
          ),
          SizedBox(height: 20.h),
          Text(
            s.messagesComingSoon,
            style: TextStyle(
              fontFamily: 'GeneralSans',
              fontSize: 18,
              fontWeight: FontWeight.w700,
              color: isDark ? Colors.white : ColorManager.black,
            ),
          ),
          SizedBox(height: 8.h),
          Text(
            s.directMessagingBeingBuilt,
            textAlign: TextAlign.center,
            style: const TextStyle(
              fontFamily: 'GeneralSans',
              fontSize: 14,
              height: 1.5,
              color: Color(0xFF888888),
            ),
          ),
        ],
      ),
    );
  }
}

class _InputBar extends StatelessWidget {
  final bool isDark;
  const _InputBar({required this.isDark});

  @override
  Widget build(BuildContext context) {
    S.of(context);
    return Container(
      padding: EdgeInsets.fromLTRB(16.w, 10.h, 16.w, 24.h),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF141414) : Colors.white,
        border: Border(
          top: BorderSide(
            color: isDark
                ? const Color(0xFF2A2A2A)
                : const Color(0xFFEEEEEE),
          ),
        ),
      ),
      child: Row(children: [
        Expanded(
          child: Container(
            height: 44.h,
            padding: EdgeInsets.symmetric(horizontal: 16.w),
            decoration: BoxDecoration(
              color: isDark
                  ? const Color(0xFF252525)
                  : const Color(0xFFF5F5F5),
              borderRadius: BorderRadius.circular(22.r),
            ),
            child: Align(
              alignment: Alignment.centerLeft,
              child: Text(
                'Message…',
                style: TextStyle(
                  fontFamily: 'GeneralSans',
                  fontSize: 14,
                  color: isDark
                      ? const Color(0xFF555555)
                      : const Color(0xFFAAAAAA),
                ),
              ),
            ),
          ),
        ),
        SizedBox(width: 10.w),
        Container(
          width: 44.r,
          height: 44.r,
          decoration: BoxDecoration(
            color: ColorManager.accent,
            shape: BoxShape.circle,
          ),
          child: Icon(
            Icons.send_rounded,
            size: 18.r,
            color: ColorManager.black,
          ),
        ),
      ]),
    );
  }
}

class _InitialIcon extends StatelessWidget {
  final String name;
  final bool isDark;
  const _InitialIcon({required this.name, required this.isDark});

  @override
  Widget build(BuildContext context) {
    S.of(context);
    final initials = name.trim().split(RegExp(r'\s+')).take(2)
        .map((w) => w.isEmpty ? '' : w[0].toUpperCase()).join();
    return Center(
      child: Text(
        initials.isEmpty ? '?' : initials,
        style: TextStyle(
          fontFamily: 'GeneralSans',
          fontSize: 13,
          fontWeight: FontWeight.w700,
          color: isDark ? const Color(0xFF666666) : const Color(0xFFAAAAAA),
        ),
      ),
    );
  }
}
