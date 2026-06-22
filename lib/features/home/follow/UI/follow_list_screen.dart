// ignore_for_file: use_build_context_synchronously
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get_it/get_it.dart';
import 'package:riff/core/helpers/constants.dart';
import 'package:riff/core/helpers/shared_pref_helper.dart';
import 'package:riff/core/utils/media_url.dart';
import 'package:riff/core/themes/colors/color_manager.dart';
import 'package:riff/features/home/follow/data/models/follow_user.dart';
import 'package:riff/features/home/follow/data/repos/follow_repo.dart';
import 'package:riff/features/home/chat/data/repos/chat_repo.dart';
import 'package:riff/features/home/chat/UI/chat_detail_screen.dart';
import 'package:riff/features/home/follow/logic/cubit/follow_cubit.dart';
import 'package:riff/features/home/user_profile/ui/user_profile_screen.dart';
import 'package:riff/generated/l10n.dart';

enum FollowListType { followers, following }

class FollowListScreen extends StatefulWidget {
  final String userId;
  final FollowListType type;
  final String profileName;

  const FollowListScreen({
    super.key,
    required this.userId,
    required this.type,
    required this.profileName,
  });

  @override
  State<FollowListScreen> createState() => _FollowListScreenState();
}

class _FollowListScreenState extends State<FollowListScreen> {
  late final FollowRepo _repo;
  late Future<List<FollowUser>> _future;

  List<FollowUser> _allUsers = [];
  String _currentUserId = '';
  String _query = '';
  final _searchController = TextEditingController();
  final Map<String, String> _statusOverrides = {};

  @override
  void initState() {
    super.initState();
    _repo = GetIt.I<FollowRepo>();
    _loadCurrentUser();
    _load();
  }

  Future<void> _loadCurrentUser() async {
    final id =
        await SharedPrefHelper.getString(SharedPrefKeys.userId) as String;
    if (mounted) setState(() => _currentUserId = id);
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _load() {
    _future = (widget.type == FollowListType.followers
            ? _repo.getFollowers(widget.userId)
            : _repo.getFollowing(widget.userId))
        .then((list) {
      _allUsers = list;
      return list;
    });
  }

  List<FollowUser> get _filtered {
    final q = _query.trim().toLowerCase();
    if (q.isEmpty) return _allUsers;
    return _allUsers.where((u) {
      return u.username.toLowerCase().contains(q) ||
          u.fullName.toLowerCase().contains(q);
    }).toList();
  }

  String _statusFor(FollowUser u) =>
      _statusOverrides[u.id] ?? u.followStatus;

  Future<void> _toggleFollow(FollowUser u) async {
    final followCubit = GetIt.I<FollowCubit>();
    final current = _statusFor(u);
    if (current == 'following' || current == 'pending') {
      setState(() => _statusOverrides[u.id] = 'not_following');
      try {
        await followCubit.unfollow(u.id);
      } catch (_) {
        if (mounted) setState(() => _statusOverrides[u.id] = current);
      }
    } else {
      final next = u.isPrivate ? 'pending' : 'following';
      setState(() => _statusOverrides[u.id] = next);
      try {
        await followCubit.follow(u.id);
      } catch (_) {
        if (mounted) setState(() => _statusOverrides[u.id] = 'not_following');
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bg = isDark ? const Color(0xFF0F0F0F) : const Color(0xFFF8F8F8);
    final title = widget.type == FollowListType.followers
        ? S.of(context).followersTitle
        : S.of(context).followingTitle;

    return Scaffold(
      backgroundColor: bg,
      appBar: AppBar(
        backgroundColor: isDark ? const Color(0xFF0F0F0F) : Colors.white,
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
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              title,
              style: TextStyle(
                fontFamily: 'GeneralSans',
                fontSize: 17,
                fontWeight: FontWeight.w700,
                color: isDark ? Colors.white : ColorManager.black,
              ),
            ),
            Text(
              '@${widget.profileName}',
              style: const TextStyle(
                fontFamily: 'GeneralSans',
                fontSize: 12,
                color: Color(0xFF888888),
              ),
            ),
          ],
        ),
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(1),
          child: Divider(
            height: 1,
            color: isDark ? const Color(0xFF2A2A2A) : const Color(0xFFEEEEEE),
          ),
        ),
      ),
      body: FutureBuilder<List<FollowUser>>(
        future: _future,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return _Shimmer(isDark: isDark);
          }
          if (snapshot.hasError) {
            return Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.wifi_off_rounded,
                      size: 40.r, color: const Color(0xFF444444)),
                  SizedBox(height: 14.h),
                  Text(S.of(context).failedToLoad,
                      style: TextStyle(
                        fontFamily: 'GeneralSans',
                        fontSize: 15,
                        color: isDark ? Colors.white : ColorManager.black,
                      )),
                  SizedBox(height: 10.h),
                  TextButton(
                    onPressed: () => setState(_load),
                    child: Text(S.of(context).retryBtn,
                        style: TextStyle(
                            color: ColorManager.accent,
                            fontFamily: 'GeneralSans',
                            fontWeight: FontWeight.w600)),
                  ),
                ],
              ),
            );
          }

          if (_allUsers.isEmpty) {
            return _EmptyState(type: widget.type, isDark: isDark);
          }

          final visible = _filtered;

          return Column(
            children: [
              // ── Search bar ──────────────────────────────────────
              Padding(
                padding: EdgeInsets.fromLTRB(16.w, 12.h, 16.w, 8.h),
                child: Container(
                  height: 40.h,
                  decoration: BoxDecoration(
                    color: isDark
                        ? const Color(0xFF1E1E1E)
                        : const Color(0xFFF0F0F0),
                    borderRadius: BorderRadius.circular(20.r),
                  ),
                  child: Row(children: [
                    SizedBox(width: 12.w),
                    Icon(Icons.search_rounded,
                        size: 18.r,
                        color: isDark
                            ? const Color(0xFF666666)
                            : const Color(0xFFAAAAAA)),
                    SizedBox(width: 8.w),
                    Expanded(
                      child: TextField(
                        controller: _searchController,
                        onChanged: (v) => setState(() => _query = v),
                        style: TextStyle(
                          fontFamily: 'GeneralSans',
                          fontSize: 14,
                          color: isDark ? Colors.white : ColorManager.black,
                        ),
                        decoration: InputDecoration(
                          hintText: S.of(context).searchHintFollow,
                          hintStyle: TextStyle(
                            fontFamily: 'GeneralSans',
                            fontSize: 14,
                            color: isDark
                                ? const Color(0xFF555555)
                                : const Color(0xFFAAAAAA),
                          ),
                          border: InputBorder.none,
                          enabledBorder: InputBorder.none,
                          focusedBorder: InputBorder.none,
                          disabledBorder: InputBorder.none,
                          isDense: true,
                          contentPadding: EdgeInsets.zero,
                        ),
                      ),
                    ),
                    if (_query.isNotEmpty)
                      GestureDetector(
                        onTap: () {
                          _searchController.clear();
                          setState(() => _query = '');
                        },
                        child: Padding(
                          padding: EdgeInsets.only(right: 10.w),
                          child: Icon(Icons.close_rounded,
                              size: 16.r,
                              color: isDark
                                  ? const Color(0xFF666666)
                                  : const Color(0xFFAAAAAA)),
                        ),
                      ),
                  ]),
                ),
              ),

              // ── List ────────────────────────────────────────────
              Expanded(
                child: visible.isEmpty
                    ? Center(
                        child: Text(
                          S.of(context).noResultsForQueryShort(_query),
                          style: TextStyle(
                            fontFamily: 'GeneralSans',
                            fontSize: 14,
                            color: isDark
                                ? const Color(0xFF555555)
                                : ColorManager.normalGrey,
                          ),
                        ),
                      )
                    : ListView.separated(
                        padding: EdgeInsets.symmetric(vertical: 4.h),
                        itemCount: visible.length,
                        separatorBuilder: (_, __) => Divider(
                          height: 1,
                          indent: 76.w,
                          color: isDark
                              ? const Color(0xFF2A2A2A)
                              : const Color(0xFFF0F0F0),
                        ),
                        itemBuilder: (_, i) {
                          final u = visible[i];
                          final isMe = _currentUserId.isNotEmpty &&
                              u.id == _currentUserId;
                          final status = _statusFor(u);
                          return _UserRow(
                            user: u,
                            followStatus: status,
                            isDark: isDark,
                            isCurrentUser: isMe,
                            onTap: () => Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (_) =>
                                    UserProfileScreen(userId: u.id),
                              ),
                            ),
                            onFollow: () => _toggleFollow(u),
                            onMessage: () async {
                              try {
                                final conversation = await GetIt.I<ChatRepo>()
                                    .startDirectConversation(u.id);
                                if (!mounted) return;
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (_) => ChatDetailScreen(
                                        conversation: conversation),
                                  ),
                                );
                              } catch (_) {}
                            },
                          );
                        },
                      ),
              ),
            ],
          );
        },
      ),
    );
  }
}

// ─── Row ──────────────────────────────────────────────────────────────────────

class _UserRow extends StatelessWidget {
  final FollowUser user;
  final String followStatus;
  final bool isDark;
  final bool isCurrentUser;
  final VoidCallback onTap;
  final VoidCallback onFollow;
  final VoidCallback onMessage;

  const _UserRow({
    required this.user,
    required this.followStatus,
    required this.isDark,
    required this.isCurrentUser,
    required this.onTap,
    required this.onFollow,
    required this.onMessage,
  });


  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: Padding(
        padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 10.h),
        child: Row(
          children: [
            // Avatar
            Container(
              width: 46.r,
              height: 46.r,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: isDark
                    ? const Color(0xFF2A2A2A)
                    : const Color(0xFFEEEEEE),
              ),
              child: user.profileImageUrl != null
                  ? ClipOval(
                      child: Image.network(
                        MediaUrl.resolveOrEmpty(user.profileImageUrl!),
                        fit: BoxFit.cover,
                        errorBuilder: (_, __, ___) => _Initials(
                            name: user.fullName, isDark: isDark),
                      ),
                    )
                  : _Initials(name: user.fullName, isDark: isDark),
            ),
            SizedBox(width: 12.w),

            // Name + username
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(children: [
                    Flexible(
                      child: Text(
                        user.username,
                        style: TextStyle(
                          fontFamily: 'GeneralSans',
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          color: isDark ? Colors.white : ColorManager.black,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    if (user.isPrivate) ...[
                      SizedBox(width: 4.w),
                      Icon(Icons.lock_outline_rounded,
                          size: 12.r, color: const Color(0xFF888888)),
                    ],
                  ]),
                  SizedBox(height: 2.h),
                  Text(
                    user.fullName,
                    style: const TextStyle(
                      fontFamily: 'GeneralSans',
                      fontSize: 12,
                      color: Color(0xFF888888),
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),

            // Buttons — hidden for the current user
            if (!isCurrentUser) ...[
              SizedBox(width: 10.w),
              GestureDetector(
                onTap: onMessage,
                child: Container(
                  width: 36.r,
                  height: 36.r,
                  margin: EdgeInsets.only(right: 8.w),
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: isDark
                        ? const Color(0xFF252525)
                        : const Color(0xFFF0F0F0),
                    border: Border.all(
                      color: isDark
                          ? const Color(0xFF3A3A3A)
                          : const Color(0xFFE0E0E0),
                    ),
                  ),
                  child: Icon(
                    Icons.chat_bubble_outline_rounded,
                    size: 16.r,
                    color: isDark
                        ? const Color(0xFFAAAAAA)
                        : const Color(0xFF666666),
                  ),
                ),
              ),
              _FollowChip(
                status: followStatus,
                isDark: isDark,
                onTap: onFollow,
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _FollowChip extends StatelessWidget {
  final String status;
  final bool isDark;
  final VoidCallback onTap;

  const _FollowChip({
    required this.status,
    required this.isDark,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final isFollowing = status == 'following';
    final isPending = status == 'pending';

    final bg = isFollowing || isPending
        ? (isDark ? const Color(0xFF2A2A2A) : const Color(0xFFF0F0F0))
        : ColorManager.accent;

    final borderColor = isFollowing || isPending
        ? (isDark ? const Color(0xFF3A3A3A) : const Color(0xFFDDDDDD))
        : ColorManager.accent;

    final textColor = isFollowing || isPending
        ? (isDark ? Colors.white : ColorManager.black)
        : ColorManager.black;

    final label = isFollowing
        ? S.of(context).followingStatus
        : isPending
            ? 'Requested'
            : S.of(context).followBtn;

    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        padding: EdgeInsets.symmetric(horizontal: 14.w, vertical: 7.h),
        decoration: BoxDecoration(
          color: bg,
          borderRadius: BorderRadius.circular(20.r),
          border: Border.all(color: borderColor),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontFamily: 'GeneralSans',
            fontSize: 13,
            fontWeight: FontWeight.w600,
            color: textColor,
          ),
        ),
      ),
    );
  }
}

class _Initials extends StatelessWidget {
  final String name;
  final bool isDark;
  const _Initials({required this.name, required this.isDark});

  @override
  Widget build(BuildContext context) {
    final initials = name
        .trim()
        .split(RegExp(r'\s+'))
        .take(2)
        .map((w) => w.isEmpty ? '' : w[0].toUpperCase())
        .join();
    return Center(
      child: Text(
        initials.isEmpty ? '?' : initials,
        style: TextStyle(
          fontFamily: 'GeneralSans',
          fontSize: 16,
          fontWeight: FontWeight.w700,
          color: isDark ? const Color(0xFF666666) : const Color(0xFFAAAAAA),
        ),
      ),
    );
  }
}

// ─── Empty state ──────────────────────────────────────────────────────────────

class _EmptyState extends StatelessWidget {
  final FollowListType type;
  final bool isDark;
  const _EmptyState({required this.type, required this.isDark});

  @override
  Widget build(BuildContext context) {
    final isFollowers = type == FollowListType.followers;
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 72.r,
            height: 72.r,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: isDark
                  ? const Color(0xFF252525)
                  : const Color(0xFFF0F0F0),
            ),
            child: Icon(
              isFollowers
                  ? Icons.people_outline_rounded
                  : Icons.person_add_alt_1_outlined,
              size: 32.r,
              color:
                  isDark ? const Color(0xFF444444) : const Color(0xFFCCCCCC),
            ),
          ),
          SizedBox(height: 18.h),
          Text(
            isFollowers ? S.of(context).noFollowersYet : S.of(context).notFollowingAnyone,
            style: TextStyle(
              fontFamily: 'GeneralSans',
              fontSize: 17,
              fontWeight: FontWeight.w700,
              color: isDark ? Colors.white : ColorManager.black,
            ),
          ),
          SizedBox(height: 6.h),
          Text(
            isFollowers
                ? S.of(context).whenSomeonFollows
                : S.of(context).accountsFollowed,
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

// ─── Shimmer ──────────────────────────────────────────────────────────────────

class _Shimmer extends StatelessWidget {
  final bool isDark;
  const _Shimmer({required this.isDark});

  @override
  Widget build(BuildContext context) {
    final c = isDark ? const Color(0xFF252525) : const Color(0xFFE8E8E8);
    return Column(
      children: [
        // Placeholder search bar
        Padding(
          padding: EdgeInsets.fromLTRB(16.w, 12.h, 16.w, 8.h),
          child: Container(
            height: 40.h,
            decoration: BoxDecoration(
              color: c,
              borderRadius: BorderRadius.circular(20.r),
            ),
          ),
        ),
        Expanded(
          child: ListView.separated(
            padding: EdgeInsets.symmetric(vertical: 4.h),
            itemCount: 8,
            separatorBuilder: (_, __) => SizedBox(height: 2.h),
            itemBuilder: (_, __) => Padding(
              padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 10.h),
              child: Row(children: [
                Container(
                    width: 46.r,
                    height: 46.r,
                    decoration:
                        BoxDecoration(shape: BoxShape.circle, color: c)),
                SizedBox(width: 12.w),
                Expanded(
                  child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Container(
                            height: 13.h,
                            width: 120.w,
                            decoration: BoxDecoration(
                                color: c,
                                borderRadius: BorderRadius.circular(4))),
                        SizedBox(height: 6.h),
                        Container(
                            height: 11.h,
                            width: 80.w,
                            decoration: BoxDecoration(
                                color: c,
                                borderRadius: BorderRadius.circular(4))),
                      ]),
                ),
                Container(
                    width: 72.w,
                    height: 32.h,
                    decoration: BoxDecoration(
                        color: c,
                        borderRadius: BorderRadius.circular(20.r))),
              ]),
            ),
          ),
        ),
      ],
    );
  }
}
