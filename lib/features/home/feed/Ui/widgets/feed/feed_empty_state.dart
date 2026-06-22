// ignore_for_file: use_build_context_synchronously, deprecated_member_use
import 'package:flutter/material.dart';
import 'package:flutter_contacts/flutter_contacts.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:riff/core/di/dependency_injection.dart';
import 'package:riff/core/utils/media_url.dart';
import 'package:riff/core/networks/api_result.dart';
import 'package:riff/core/themes/colors/color_manager.dart';
import 'package:riff/core/themes/text_styles/text_styles.dart';
import 'package:riff/features/auth/new_user_onboarding/data/repos/suggested_users_repo.dart';
import 'package:riff/features/home/follow/logic/cubit/follow_cubit.dart';
import 'package:riff/features/home/search/data/models/search_user.dart';
import 'package:riff/features/home/user_profile/ui/user_profile_screen.dart';
import 'package:video_player/video_player.dart';
import 'package:riff/generated/l10n.dart';

class FeedEmptyState extends StatefulWidget {
  const FeedEmptyState({super.key});

  @override
  State<FeedEmptyState> createState() => _FeedEmptyStateState();
}

class _FeedEmptyStateState extends State<FeedEmptyState>
    with TickerProviderStateMixin {
  final SuggestedUsersRepo _suggestedRepo = getIt<SuggestedUsersRepo>();

  List<SearchUser> _suggested = [];
  List<SearchUser> _contacts = [];
  bool _loadingSuggested = true;
  bool _contactsSynced = false;
  bool _syncingContacts = false;
  final Set<String> _followed = {};
  final Map<String, bool> _inProgress = {};

  late AnimationController _pulseController;

  @override
  void initState() {
    super.initState();
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    )..repeat(reverse: true);
    _loadSuggested();
  }

  @override
  void dispose() {
    _pulseController.dispose();
    super.dispose();
  }

  Future<void> _loadSuggested() async {
    final result = await _suggestedRepo.getSuggested();
    result.when(
      success: (users) => setState(() {
        _suggested = users;
        _loadingSuggested = false;
      }),
      failure: (_) => setState(() => _loadingSuggested = false),
    );
  }

  Future<void> _syncContacts() async {
    if (_syncingContacts) return;
    setState(() => _syncingContacts = true);

    // Request permission
    final status = await Permission.contacts.request();
    if (!status.isGranted) {
      setState(() => _syncingContacts = false);
      return;
    }

    // Read contacts
    final contacts = await FlutterContacts.getContacts(withProperties: true);
    final phones = contacts
        .expand((c) => c.phones)
        .map((p) => p.number.replaceAll(RegExp(r'\s|-|\(|\)'), ''))
        .where((p) => p.isNotEmpty)
        .toList();

    if (phones.isEmpty) {
      setState(() {
        _syncingContacts = false;
        _contactsSynced = true;
      });
      return;
    }

    try {
      final result = await _suggestedRepo.findContacts(phones);
      final list = result.when(
        success: (users) => users,
        failure: (_) => <SearchUser>[],
      );
      setState(() {
        _contacts = list;
        _contactsSynced = true;
        _syncingContacts = false;
      });
    } catch (_) {
      setState(() {
        _syncingContacts = false;
        _contactsSynced = true;
      });
    }
  }

  Future<void> _toggleFollow(SearchUser user) async {
    if (_inProgress[user.id] == true) return;
    setState(() => _inProgress[user.id] = true);
    final followCubit = getIt<FollowCubit>();
    if (_followed.contains(user.id)) {
      await followCubit.unfollow(user.id);
      _followed.remove(user.id);
    } else {
      await followCubit.follow(user.id);
      _followed.add(user.id);
    }
    if (mounted) setState(() => _inProgress[user.id] = false);
  }


  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final s = S.of(context);

    return ListView(
      padding: EdgeInsets.symmetric(horizontal: 20.w, vertical: 24.h),
      children: [
        // Header
        Center(
          child: Column(
            children: [
              Icon(
                Icons.queue_music_rounded,
                size: 56.r,
                color: ColorManager.accent,
              ),
              SizedBox(height: 12.h),
              Text(s.noPostsLoaded, style: TextStyles.font20Bold),
              SizedBox(height: 6.h),
              Text(
                s.followArtistsToFillFeed,
                style: TextStyles.font14Medium
                    .copyWith(color: ColorManager.normalGrey),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
        SizedBox(height: 32.h),

        // Suggested users
        _SectionHeader(title: s.followArtistsToFillFeed, isDark: isDark),
        SizedBox(height: 12.h),

        if (_loadingSuggested) ...[
          for (int i = 0; i < 3; i++) _ShimmerCard(isDark: isDark, animation: _pulseController),
        ] else if (_suggested.isEmpty)
          _EmptyHint(
            icon: Icons.people_outline_rounded,
            label: 'No suggestions right now',
            isDark: isDark,
          )
        else
          ..._suggested.take(3).map(
                (u) => _SuggestedUserCard(
                  user: u,
                  isDark: isDark,
                  isFollowed: _followed.contains(u.id),
                  inProgress: _inProgress[u.id] == true,
                  onToggle: () => _toggleFollow(u),
                  resolveUrl: MediaUrl.resolveOrEmpty,
                ),
              ),

        SizedBox(height: 28.h),

        // Contacts section
        _SectionHeader(title: s.seeWhichContactsOnRiff, isDark: isDark),
        SizedBox(height: 12.h),

        if (!_contactsSynced) ...[
          _SyncContactsButton(
            loading: _syncingContacts,
            isDark: isDark,
            onTap: _syncContacts,
          ),
        ] else if (_contacts.isEmpty)
          _EmptyHint(
            icon: Icons.contact_phone_outlined,
            label: 'None of your contacts are on Riff yet',
            isDark: isDark,
          )
        else
          ..._contacts.map(
                (u) => _UserCard(
                  user: u,
                  isDark: isDark,
                  isFollowed: _followed.contains(u.id),
                  inProgress: _inProgress[u.id] == true,
                  onToggle: () => _toggleFollow(u),
                  resolveUrl: MediaUrl.resolveOrEmpty,
                ),
              ),

        SizedBox(height: 45.h),
      ],
    );
  }
}

// ── Sub-widgets ────────────────────────────────────────────────────────────

/// Expanded card for the "Suggested for you" section — shows user header + top posts
class _SuggestedUserCard extends StatelessWidget {
  final SearchUser user;
  final bool isDark;
  final bool isFollowed;
  final bool inProgress;
  final VoidCallback onToggle;
  final String Function(String) resolveUrl;

  const _SuggestedUserCard({
    required this.user,
    required this.isDark,
    required this.isFollowed,
    required this.inProgress,
    required this.onToggle,
    required this.resolveUrl,
  });

  @override
  Widget build(BuildContext context) {
    final cardBg = isDark ? const Color(0xFF1A1A1A) : Colors.white;
    final borderColor =
        isDark ? const Color(0xFF2A2A2A) : const Color(0xFFEEEEEE);

    return Container(
      margin: EdgeInsets.only(bottom: 16.h),
      decoration: BoxDecoration(
        color: cardBg,
        borderRadius: BorderRadius.circular(16.r),
        border: Border.all(color: borderColor),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ── User header row ─────────────────────────────────────────────
          GestureDetector(
            onTap: () => Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) => UserProfileScreen(userId: user.id),
              ),
            ),
            behavior: HitTestBehavior.opaque,
            child: Padding(
            padding: EdgeInsets.symmetric(horizontal: 14.w, vertical: 12.h),
            child: Row(
              children: [
                Container(
                  width: 44.r,
                  height: 44.r,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: isDark
                        ? const Color(0xFF2A2A2A)
                        : const Color(0xFFEEEEEE),
                  ),
                  child: user.profileImageUrl != null
                      ? ClipOval(
                          child: Image.network(
                            resolveUrl(user.profileImageUrl!),
                            fit: BoxFit.cover,
                            errorBuilder: (_, __, ___) => const Icon(
                                Icons.person,
                                size: 22,
                                color: Color(0xFF888888)),
                          ),
                        )
                      : const Icon(Icons.person,
                          size: 22, color: Color(0xFF888888)),
                ),
                SizedBox(width: 12.w),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        user.fullName,
                        style: TextStyle(
                          fontFamily: 'GeneralSans',
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          color: isDark ? Colors.white : ColorManager.black,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      SizedBox(height: 2.h),
                      Row(
                        children: [
                          Flexible(
                            child: Text(
                              '@${user.username}',
                              style: const TextStyle(
                                fontFamily: 'GeneralSans',
                                fontSize: 12,
                                color: Color(0xFF888888),
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          if ((user.followersCount ?? 0) > 0) ...[
                            const Text(
                              '  ·  ',
                              style: TextStyle(
                                  color: Color(0xFF888888), fontSize: 12),
                            ),
                            Text(
                              '${_formatCount(user.followersCount!)} followers',
                              style: const TextStyle(
                                fontFamily: 'GeneralSans',
                                fontSize: 12,
                                color: Color(0xFF888888),
                              ),
                            ),
                          ],
                        ],
                      ),
                    ],
                  ),
                ),
                SizedBox(width: 8.w),
                GestureDetector(
                  onTap: inProgress ? null : onToggle,
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 200),
                    padding:
                        EdgeInsets.symmetric(horizontal: 14.w, vertical: 7.h),
                    decoration: BoxDecoration(
                      color: isFollowed
                          ? Colors.transparent
                          : ColorManager.accent,
                      borderRadius: BorderRadius.circular(20.r),
                      border: isFollowed
                          ? Border.all(
                              color: isDark
                                  ? const Color(0xFF3A3A3A)
                                  : const Color(0xFFDDDDDD),
                            )
                          : null,
                    ),
                    child: inProgress
                        ? SizedBox(
                            width: 13.r,
                            height: 13.r,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: isFollowed
                                  ? ColorManager.normalGrey
                                  : Colors.black,
                            ),
                          )
                        : Text(
                            isFollowed ? S.of(context).followingStatus : S.of(context).followBtn,
                            style: TextStyle(
                              fontFamily: 'GeneralSans',
                              fontSize: 13,
                              fontWeight: FontWeight.w600,
                              color: isFollowed
                                  ? (isDark
                                      ? const Color(0xFF888888)
                                      : const Color(0xFF666666))
                                  : Colors.black,
                            ),
                          ),
                  ),
                ),
              ],
            ),
          ),
          ),  // GestureDetector

          // ── Top posts (2-column grid) ────────────────────────────────
          if (user.topPosts.isNotEmpty) ...[
            Divider(height: 1, color: borderColor),
            Padding(
              padding:
                  EdgeInsets.symmetric(horizontal: 14.w, vertical: 10.h),
              child: Text(
                'Top posts',
                style: TextStyle(
                  fontFamily: 'GeneralSans',
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: const Color(0xFF888888),
                ),
              ),
            ),
            Padding(
              padding: EdgeInsets.only(left: 10.w, right: 10.w, bottom: 12.h),
              child: Column(
                children: [
                  // first row: posts 0 and 1
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(
                        child: _PostPreviewTile(
                          post: user.topPosts[0],
                          
                          isDark: isDark,
                          resolveUrl: resolveUrl,
                        ),
                      ),
                      if (user.topPosts.length > 1) ...[
                        SizedBox(width: 8.w),
                        Expanded(
                          child: _PostPreviewTile(
                            post: user.topPosts[1],
                            isDark: isDark,
                            resolveUrl: resolveUrl,
                          ),
                        ),
                      ] else
                        const Expanded(child: SizedBox()),
                    ],
                  ),
                  // second row: post 2 (if any) + empty
                  if (user.topPosts.length > 2) ...[
                    SizedBox(height: 8.h),
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(
                          child: _PostPreviewTile(
                            post: user.topPosts[2],
                            isDark: isDark,
                            resolveUrl: resolveUrl,
                          ),
                        ),
                        SizedBox(width: 8.w),
                        const Expanded(child: SizedBox()),
                      ],
                    ),
                  ],
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }

  String _formatCount(int count) {
    if (count >= 1000000) return '${(count / 1000000).toStringAsFixed(1)}M';
    if (count >= 1000) return '${(count / 1000).toStringAsFixed(1)}K';
    return count.toString();
  }
}

class _PostPreviewTile extends StatefulWidget {
  final SuggestedPost post;
  final bool isDark;
  final String Function(String) resolveUrl;

  const _PostPreviewTile({
    required this.post,
    required this.isDark,
    required this.resolveUrl,
  });

  @override
  State<_PostPreviewTile> createState() => _PostPreviewTileState();
}

class _PostPreviewTileState extends State<_PostPreviewTile> {
  VideoPlayerController? _videoCtrl;
  bool _videoReady = false;

  bool _isVideo(String url) {
    final lower = url.toLowerCase();
    return lower.endsWith('.mp4') ||
        lower.endsWith('.mov') ||
        lower.endsWith('.webm') ||
        lower.endsWith('.avi') ||
        lower.endsWith('.mkv');
  }

  @override
  void initState() {
    super.initState();
    final media = widget.post.media;
    if (media != null && media.isNotEmpty && _isVideo(media.first)) {
      _loadVideoThumb(widget.resolveUrl(media.first));
    }
  }

  Future<void> _loadVideoThumb(String url) async {
    final c = VideoPlayerController.networkUrl(Uri.parse(url));
    try {
      await c.initialize();
      await c.seekTo(Duration.zero);
      if (mounted) {
        setState(() {
          _videoCtrl = c;
          _videoReady = true;
        });
      } else {
        c.dispose();
      }
    } catch (_) {
      c.dispose();
    }
  }

  @override
  void dispose() {
    _videoCtrl?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final media = widget.post.media;
    final firstMedia = (media != null && media.isNotEmpty) ? media.first : null;
    final isDark = widget.isDark;

    Widget thumbnail;
    if (firstMedia == null) {
      // Text-only post — show a music note placeholder
      thumbnail = Container(
        width: 52.r,
        height: 52.r,
        decoration: BoxDecoration(
          color: isDark ? const Color(0xFF2A2A2A) : const Color(0xFFEEEEEE),
          borderRadius: BorderRadius.circular(8.r),
        ),
        child: Icon(Icons.music_note_rounded,
            size: 22.r, color: const Color(0xFF888888)),
      );
    } else if (_isVideo(firstMedia)) {
      thumbnail = ClipRRect(
        borderRadius: BorderRadius.circular(8.r),
        child: SizedBox(
          width: 52.r,
          height: 52.r,
          child: Stack(
            fit: StackFit.expand,
            children: [
              Container(color: const Color(0xFF1A1A1A)),
              if (_videoReady && _videoCtrl != null)
                FittedBox(
                  fit: BoxFit.cover,
                  clipBehavior: Clip.hardEdge,
                  child: SizedBox(
                    width: _videoCtrl!.value.size.width,
                    height: _videoCtrl!.value.size.height,
                    child: VideoPlayer(_videoCtrl!),
                  ),
                ),
              Center(
                child: Icon(Icons.play_circle_outline,
                    color: Colors.white70, size: 22.r),
              ),
            ],
          ),
        ),
      );
    } else {
      thumbnail = ClipRRect(
        borderRadius: BorderRadius.circular(8.r),
        child: Image.network(
          widget.resolveUrl(firstMedia),
          width: 52.r,
          height: 52.r,
          fit: BoxFit.cover,
          errorBuilder: (_, __, ___) => Container(
            width: 52.r,
            height: 52.r,
            decoration: BoxDecoration(
              color: isDark
                  ? const Color(0xFF2A2A2A)
                  : const Color(0xFFEEEEEE),
              borderRadius: BorderRadius.circular(8.r),
            ),
            child: Icon(Icons.broken_image_outlined,
                size: 22.r, color: const Color(0xFF888888)),
          ),
        ),
      );
    }

    return Padding(
      padding: EdgeInsets.only(left: 14.w, right: 14.w, bottom: 10.h),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          thumbnail,
          SizedBox(width: 10.w),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  widget.post.content,
                  style: TextStyle(
                    fontFamily: 'GeneralSans',
                    fontSize: 13,
                    color: isDark ? Colors.white : ColorManager.black,
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
                SizedBox(height: 4.h),
                Row(
                  children: [
                    Icon(Icons.favorite_rounded,
                        size: 12.r, color: const Color(0xFF888888)),
                    SizedBox(width: 4.w),
                    Text(
                      '${widget.post.likesCount}',
                      style: const TextStyle(
                        fontFamily: 'GeneralSans',
                        fontSize: 12,
                        color: Color(0xFF888888),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _SectionHeader extends StatelessWidget {
  final String title;
  final bool isDark;
  const _SectionHeader({required this.title, required this.isDark});

  @override
  Widget build(BuildContext context) {
    return Text(
      title,
      style: TextStyle(
        fontFamily: 'GeneralSans',
        fontSize: 17,
        fontWeight: FontWeight.w700,
        color: isDark ? Colors.white : ColorManager.black,
      ),
    );
  }
}

class _UserCard extends StatelessWidget {
  final SearchUser user;
  final bool isDark;
  final bool isFollowed;
  final bool inProgress;
  final VoidCallback onToggle;
  final String Function(String) resolveUrl;

  const _UserCard({
    required this.user,
    required this.isDark,
    required this.isFollowed,
    required this.inProgress,
    required this.onToggle,
    required this.resolveUrl,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: EdgeInsets.only(bottom: 10.h),
      padding: EdgeInsets.symmetric(horizontal: 14.w, vertical: 12.h),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1A1A1A) : Colors.white,
        borderRadius: BorderRadius.circular(16.r),
        border: Border.all(
          color: isDark ? const Color(0xFF2A2A2A) : const Color(0xFFEEEEEE),
        ),
      ),
      child: Row(
        children: [
          // Avatar
          Container(
            width: 44.r,
            height: 44.r,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: isDark ? const Color(0xFF2A2A2A) : const Color(0xFFEEEEEE),
            ),
            child: user.profileImageUrl != null
                ? ClipOval(
                    child: Image.network(
                      resolveUrl(user.profileImageUrl!),
                      fit: BoxFit.cover,
                      errorBuilder: (_, __, ___) =>
                          const Icon(Icons.person, size: 22, color: Color(0xFF888888)),
                    ),
                  )
                : const Icon(Icons.person, size: 22, color: Color(0xFF888888)),
          ),
          SizedBox(width: 12.w),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  user.fullName,
                  style: TextStyle(
                    fontFamily: 'GeneralSans',
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: isDark ? Colors.white : ColorManager.black,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                SizedBox(height: 2.h),
                Text(
                  '@${user.username}',
                  style: TextStyle(
                    fontFamily: 'GeneralSans',
                    fontSize: 12,
                    color: const Color(0xFF888888),
                  ),
                ),
              ],
            ),
          ),
          SizedBox(width: 8.w),
          GestureDetector(
            onTap: inProgress ? null : onToggle,
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              padding: EdgeInsets.symmetric(horizontal: 14.w, vertical: 7.h),
              decoration: BoxDecoration(
                color: isFollowed ? Colors.transparent : ColorManager.accent,
                borderRadius: BorderRadius.circular(20.r),
                border: isFollowed
                    ? Border.all(
                        color: isDark ? const Color(0xFF3A3A3A) : const Color(0xFFDDDDDD),
                      )
                    : null,
              ),
              child: inProgress
                  ? SizedBox(
                      width: 13.r,
                      height: 13.r,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: isFollowed ? ColorManager.normalGrey : Colors.black,
                      ),
                    )
                  : Text(
                      isFollowed ? S.of(context).followingStatus : S.of(context).followBtn,
                      style: TextStyle(
                        fontFamily: 'GeneralSans',
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: isFollowed
                            ? (isDark ? const Color(0xFF888888) : const Color(0xFF666666))
                            : Colors.black,
                      ),
                    ),
            ),
          ),
        ],
      ),
    );
  }
}

/// Animated shimmer placeholder card while loading
class _ShimmerCard extends StatelessWidget {
  final bool isDark;
  final AnimationController animation;
  const _ShimmerCard({required this.isDark, required this.animation});

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: animation,
      builder: (_, __) {
        final opacity = 0.3 + 0.5 * animation.value;
        return Container(
          margin: EdgeInsets.only(bottom: 10.h),
          padding: EdgeInsets.symmetric(horizontal: 14.w, vertical: 14.h),
          decoration: BoxDecoration(
            color: isDark ? const Color(0xFF1A1A1A) : Colors.white,
            borderRadius: BorderRadius.circular(16.r),
            border: Border.all(
              color: isDark ? const Color(0xFF2A2A2A) : const Color(0xFFEEEEEE),
            ),
          ),
          child: Row(
            children: [
              Opacity(
                opacity: opacity,
                child: Container(
                  width: 44.r,
                  height: 44.r,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: isDark ? const Color(0xFF2A2A2A) : const Color(0xFFE0E0E0),
                  ),
                ),
              ),
              SizedBox(width: 12.w),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Opacity(
                      opacity: opacity,
                      child: Container(
                        height: 13.h,
                        width: 120.w,
                        decoration: BoxDecoration(
                          color: isDark ? const Color(0xFF2A2A2A) : const Color(0xFFE0E0E0),
                          borderRadius: BorderRadius.circular(6.r),
                        ),
                      ),
                    ),
                    SizedBox(height: 6.h),
                    Opacity(
                      opacity: opacity * 0.6,
                      child: Container(
                        height: 11.h,
                        width: 80.w,
                        decoration: BoxDecoration(
                          color: isDark ? const Color(0xFF2A2A2A) : const Color(0xFFE0E0E0),
                          borderRadius: BorderRadius.circular(6.r),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              SizedBox(width: 8.w),
              Opacity(
                opacity: opacity,
                child: Container(
                  width: 70.w,
                  height: 32.h,
                  decoration: BoxDecoration(
                    color: ColorManager.accent.withOpacity(0.4),
                    borderRadius: BorderRadius.circular(20.r),
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

class _SyncContactsButton extends StatelessWidget {
  final bool loading;
  final bool isDark;
  final VoidCallback onTap;

  const _SyncContactsButton({
    required this.loading,
    required this.isDark,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: loading ? null : onTap,
      child: Container(
        padding: EdgeInsets.symmetric(horizontal: 20.w, vertical: 16.h),
        decoration: BoxDecoration(
          color: isDark ? const Color(0xFF1A1A1A) : Colors.white,
          borderRadius: BorderRadius.circular(16.r),
          border: Border.all(
            color: isDark ? const Color(0xFF2A2A2A) : const Color(0xFFEEEEEE),
          ),
        ),
        child: Row(
          children: [
            Container(
              width: 44.r,
              height: 44.r,
              decoration: BoxDecoration(
                color: ColorManager.accent.withOpacity(0.15),
                shape: BoxShape.circle,
              ),
              child: Icon(
                Icons.contacts_rounded,
                color: ColorManager.accent,
                size: 22.r,
              ),
            ),
            SizedBox(width: 14.w),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    S.of(context).syncContactsBtn,
                    style: TextStyle(
                      fontFamily: 'GeneralSans',
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: isDark ? Colors.white : ColorManager.black,
                    ),
                  ),
                  SizedBox(height: 2.h),
                  Text(
                    S.of(context).seeWhichContactsOnRiff,
                    style: TextStyle(
                      fontFamily: 'GeneralSans',
                      fontSize: 12,
                      color: const Color(0xFF888888),
                    ),
                  ),
                ],
              ),
            ),
            SizedBox(width: 8.w),
            if (loading)
              SizedBox(
                width: 20.r,
                height: 20.r,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  color: ColorManager.accent,
                ),
              )
            else
              Icon(
                Icons.arrow_forward_ios_rounded,
                size: 16.r,
                color: isDark ? const Color(0xFF666666) : const Color(0xFFAAAAAA),
              ),
          ],
        ),
      ),
    );
  }
}

class _EmptyHint extends StatelessWidget {
  final IconData icon;
  final String label;
  final bool isDark;

  const _EmptyHint({required this.icon, required this.label, required this.isDark});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.symmetric(vertical: 16.h),
      child: Row(
        children: [
          Icon(icon, size: 20.r, color: const Color(0xFF888888)),
          SizedBox(width: 10.w),
          Expanded(
            child: Text(
              label,
              style: TextStyle(
                fontFamily: 'GeneralSans',
                fontSize: 13,
                color: const Color(0xFF888888),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
