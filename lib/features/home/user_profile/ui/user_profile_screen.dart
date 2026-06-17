// ignore_for_file: use_build_context_synchronously, deprecated_member_use
// ignore_for_file: unused_import
import 'package:flutter/material.dart';


import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:riff/core/di/dependency_injection.dart';
import 'package:riff/core/helpers/constants.dart';
import 'package:riff/core/helpers/shared_pref_helper.dart';
import 'package:riff/core/networks/api_constants.dart';
import 'package:riff/core/themes/colors/color_manager.dart';
import 'package:riff/core/themes/text_styles/text_styles.dart';
import 'package:riff/core/helpers/spacing.dart';
import 'package:riff/features/home/feed/data/models/post.dart';
import 'package:video_player/video_player.dart';
import 'package:riff/features/home/feed/Ui/post_detail_screen.dart';
import 'package:riff/features/home/core/logic/cubit/home_cubit.dart';
import 'package:riff/features/home/user_profile/data/models/user_profile_model.dart';
import 'package:riff/core/widgets/shimmer_loading.dart';
import 'package:riff/features/home/user_profile/logic/cubit/user_profile_cubit.dart';
import 'package:riff/features/home/notifications/logic/cubit/notifications_cubit.dart';
import 'package:riff/core/widgets/button.dart';
import 'package:riff/features/home/follow/UI/follow_list_screen.dart';
import 'package:riff/features/home/chat/UI/chat_screen.dart';
import 'package:riff/generated/l10n.dart';

// ── Genre assets + accent colors (mirrors profile_screen.dart) ────────────────

const _instrumentImages = <String, String>{
  'Guitar': 'assets/images/electric-guitar.png',
  'Piano': 'assets/images/piano.png',
  'Drums': 'assets/images/drum.png',
  'Oud': 'assets/images/saz.png',
  'Percussions': 'assets/images/dholak.png',
  'Bass': 'assets/images/electric-guitar (1).png',
  'Violin': 'assets/images/violin.png',
  'Harp': 'assets/images/harp.png',
  'Hang': 'assets/images/hang.png',
  'Saxophone': 'assets/images/saxophone.png',
};

const _genreImages = <String, String>{
  'Rock': 'assets/images/rock-and-roll.png',
  'Jazz': 'assets/images/jazz.png',
  'Classical': 'assets/images/conductor.png',
  'Hip-Hop': 'assets/images/poster.png',
  'Electronic': 'assets/images/techno.png',
  'Gospel': 'assets/images/choir.png',
  'Pop': 'assets/images/kpop.png',
  'Metal': 'assets/images/rock.png',
};

const _genreColors = <String, Color>{
  'Rock': Color(0xFFFFE5E5),
  'Jazz': Color(0xFFE5F8F7),
  'Classical': Color(0xFFE8F4F8),
  'Hip-Hop': Color(0xFFFFF8E1),
  'Electronic': Color(0xFFEDE7F6),
  'Gospel': Color(0xFFE8F5E9),
  'Pop': Color(0xFFFCE4EC),
  'Metal': Color(0xFFECEFF1),
};

const _genreAccents = <String, Color>{
  'Rock': Color(0xFFFF6B6B),
  'Jazz': Color(0xFF26A69A),
  'Classical': Color(0xFF42A5F5),
  'Hip-Hop': Color(0xFFFFCA28),
  'Electronic': Color(0xFF7E57C2),
  'Gospel': Color(0xFF66BB6A),
  'Pop': Color(0xFFEC407A),
  'Metal': Color(0xFF78909C),
};

class UserProfileScreen extends StatefulWidget {
  final String userId;
  const UserProfileScreen({super.key, required this.userId});

  @override
  State<UserProfileScreen> createState() => _UserProfileScreenState();
}

class _UserProfileScreenState extends State<UserProfileScreen> {
  late final UserProfileCubit _cubit;
  String _currentUserId = '';

  @override
  void initState() {
    super.initState();
    _cubit = getIt<UserProfileCubit>();
    _cubit.loadProfile(widget.userId);
    _loadCurrentUserId();
  }

  Future<void> _loadCurrentUserId() async {
    final id =
        await SharedPrefHelper.getString(SharedPrefKeys.userId) as String;
    if (mounted) setState(() => _currentUserId = id);
  }

  @override
  void dispose() {
    _cubit.close();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return BlocProvider.value(
      value: _cubit,
      child: BlocBuilder<UserProfileCubit, UserProfileState>(
        builder: (context, state) {
          // Derive username for AppBar title
          String username = '';
          if (state is UserProfileLoaded) {
            username = '@${state.profile.username}';
          }

          return Scaffold(
            backgroundColor:
                isDark ? const Color(0xFF0F0F0F) : const Color(0xFFF8F8F8),
            appBar: AppBar(
              backgroundColor:
                  isDark ? const Color(0xFF0F0F0F) : Colors.white,
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
              title: username.isEmpty
                  ? null
                  : Text(
                      username,
                      style: TextStyle(
                        fontFamily: 'GeneralSans',
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                        color: isDark ? Colors.white : ColorManager.black,
                      ),
                    ),
              centerTitle: false,
              bottom: PreferredSize(
                preferredSize: const Size.fromHeight(1),
                child: Divider(
                  height: 1,
                  color: isDark
                      ? const Color(0xFF2A2A2A)
                      : const Color(0xFFEEEEEE),
                ),
              ),
            ),
            body: _buildBody(context, state, isDark),
          );
        },
      ),
    );
  }

  Widget _buildBody(
      BuildContext context, UserProfileState state, bool isDark) {
    if (state is UserProfileInitial || state is UserProfileLoading) {
      return const ProfilePageShimmer();
    }
    if (state is UserProfileFailure) {
      return Center(
        child: Column(mainAxisSize: MainAxisSize.min, children: [
          Icon(Icons.error_outline,
              size: 48.r, color: ColorManager.normalGrey),
          verticalSpace(12),
          Text(state.message,
              style: TextStyles.font14Medium
                  .copyWith(color: ColorManager.normalGrey),
              textAlign: TextAlign.center),
          verticalSpace(16),
          TextButton(
            onPressed: () => _cubit.loadProfile(widget.userId),
            child: Text(S.of(context).retryBtn,
                style: TextStyles.font14semiBold
                    .copyWith(color: ColorManager.accent)),
          ),
        ]),
      );
    }

    final loaded = state as UserProfileLoaded;
    final isOwnProfile =
        _currentUserId.isNotEmpty && _currentUserId == widget.userId;
    final canAccessList = isOwnProfile ||
        !loaded.profile.isPrivate ||
        loaded.profile.followStatus == 'following';

    return _ProfileBody(
      profile: loaded.profile,
      posts: loaded.posts,
      userId: widget.userId,
      cubit: _cubit,
      isOwnProfile: isOwnProfile,
      canAccessList: canAccessList,
      isDark: isDark,
      onRefresh: () => _cubit.loadProfile(widget.userId),
    );
  }
}

// ── Profile body ──────────────────────────────────────────────────────────────

class _ProfileBody extends StatelessWidget {
  final UserProfileModel profile;
  final List<Post> posts;
  final String userId;
  final UserProfileCubit cubit;
  final bool isOwnProfile;
  final bool canAccessList;
  final bool isDark;
  final Future<void> Function() onRefresh;

  const _ProfileBody({
    required this.profile,
    required this.posts,
    required this.userId,
    required this.cubit,
    required this.isOwnProfile,
    required this.canAccessList,
    required this.isDark,
    required this.onRefresh,
  });

  String? get _avatarUrl {
    final raw = profile.profileImageUrl;
    if (raw == null || raw.isEmpty) return null;
    return raw.startsWith('http') ? raw : '${ApiConstants.apiBASEURL}$raw';
  }

  String get _initials => profile.fullName
      .trim()
      .split(RegExp(r'\s+'))
      .take(2)
      .map((w) => w.isEmpty ? '' : w[0].toUpperCase())
      .join();

  @override
  Widget build(BuildContext context) {
    return RefreshIndicator(
      onRefresh: onRefresh,
      color: isDark ? ColorManager.accent : ColorManager.primaryBlack,
      backgroundColor:
          isDark ? const Color(0xFF252525) : ColorManager.white,
      child: CustomScrollView(
        physics: const BouncingScrollPhysics(
            parent: AlwaysScrollableScrollPhysics()),
        slivers: [
          SliverToBoxAdapter(child: _buildHeader(context)),
          if (posts.isNotEmpty) ...[
            SliverToBoxAdapter(
              child: Padding(
                padding: EdgeInsets.fromLTRB(16.w, 20.h, 16.w, 10.h),
                child: Row(children: [
                  Text(S.of(context).postsLabel,
                      style: TextStyle(
                        fontFamily: 'GeneralSans',
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                        color: isDark ? Colors.white : ColorManager.black,
                      )),
                  SizedBox(width: 8.w),
                  Container(
                    padding: EdgeInsets.symmetric(
                        horizontal: 8.w, vertical: 3.h),
                    decoration: BoxDecoration(
                      color: isDark
                          ? const Color(0xFF252525)
                          : const Color(0xFFEEEEEE),
                      borderRadius: BorderRadius.circular(20.r),
                    ),
                    child: Text(
                      '${posts.length}',
                      style: TextStyle(
                        fontFamily: 'GeneralSans',
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: isDark
                            ? const Color(0xFFAAAAAA)
                            : const Color(0xFF666666),
                      ),
                    ),
                  ),
                ]),
              ),
            ),
            SliverPadding(
              padding: EdgeInsets.fromLTRB(2.w, 0, 2.w, 40.h),
              sliver: SliverGrid(
                gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 3,
                  crossAxisSpacing: 2.w,
                  mainAxisSpacing: 2.h,
                ),
                delegate: SliverChildBuilderDelegate(
                  (ctx, i) => _PostThumbnail(
                    post: posts[i],
                    isDark: isDark,
                    onTap: () {
                      HomeCubit? homeCubit;
                      try {
                        homeCubit = context.read<HomeCubit>();
                      } catch (_) {}
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => homeCubit != null
                              ? BlocProvider.value(
                                  value: homeCubit,
                                  child: PostDetailScreen(post: posts[i]),
                                )
                              : PostDetailScreen(post: posts[i]),
                        ),
                      );
                    },
                  ),
                  childCount: posts.length,
                ),
              ),
            ),
          ] else
            SliverFillRemaining(
              child: Center(
                child: Column(mainAxisSize: MainAxisSize.min, children: [
                  Icon(Icons.music_note_outlined,
                      size: 48.r,
                      color: isDark
                          ? const Color(0xFF333333)
                          : ColorManager.lighterGrey),
                  verticalSpace(12),
                  Text(S.of(context).noPostsYet,
                      style: TextStyle(
                        fontFamily: 'GeneralSans',
                        fontSize: 15,
                        color: isDark
                            ? const Color(0xFF555555)
                            : ColorManager.normalGrey,
                      )),
                ]),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildHeader(BuildContext context) {
    final avatarUrl = _avatarUrl;
    final initials = _initials.isEmpty ? '?' : _initials;
    final canMessage = !isOwnProfile &&
        (profile.followStatus == 'following' || profile.isFollowingMe);

    return Container(
      color: isDark ? const Color(0xFF141414) : Colors.white,
      child: Column(children: [
        // ── Avatar + name block ────────────────────────────────────
        Padding(
          padding: EdgeInsets.fromLTRB(20.w, 28.h, 20.w, 0),
          child: Column(children: [
            // Avatar
            Container(
              width: 88.r,
              height: 88.r,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(
                  color: isDark
                      ? const Color(0xFF3A3A3A)
                      : const Color(0xFFE8E8E8),
                  width: 2.5,
                ),
              ),
              child: ClipOval(
                child: avatarUrl != null
                    ? Image.network(avatarUrl, fit: BoxFit.cover,
                        errorBuilder: (_, __, ___) =>
                            _InitialsWidget(initials: initials, isDark: isDark))
                    : _InitialsWidget(initials: initials, isDark: isDark),
              ),
            ),

            verticalSpace(14),

            // Name + lock
            Row(mainAxisAlignment: MainAxisAlignment.center, children: [
              Flexible(
                child: Text(
                  profile.fullName,
                  style: TextStyle(
                    fontFamily: 'GeneralSans',
                    fontSize: 20,
                    fontWeight: FontWeight.w800,
                    color: isDark ? Colors.white : ColorManager.black,
                  ),
                  textAlign: TextAlign.center,
                ),
              ),
              if (profile.isPrivate) ...[
                SizedBox(width: 6.w),
                Icon(Icons.lock_rounded,
                    size: 15.r, color: const Color(0xFF888888)),
              ],
            ]),

            verticalSpace(3),

            Text(
              '@${profile.username}',
              style: const TextStyle(
                fontFamily: 'GeneralSans',
                fontSize: 14,
                color: Color(0xFF888888),
              ),
            ),

            if (profile.bio != null && profile.bio!.isNotEmpty) ...[
              verticalSpace(10),
              Text(
                profile.bio!,
                style: TextStyle(
                  fontFamily: 'GeneralSans',
                  fontSize: 14,
                  height: 1.45,
                  color: isDark
                      ? const Color(0xFFCCCCCC)
                      : const Color(0xFF444444),
                ),
                textAlign: TextAlign.center,
                maxLines: 3,
                overflow: TextOverflow.ellipsis,
              ),
            ],

            verticalSpace(24),

            // ── Stats row ────────────────────────────────────────
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                _StatCell(
                  count: profile.postsCount,
                  label: profile.postsCount == 1 ? S.of(context).postLabel : S.of(context).postsLabel,
                  onTap: null,
                  isDark: isDark,
                ),
                _StatDivider(isDark: isDark),
                _StatCell(
                  count: profile.followersCount,
                  label: S.of(context).followersLabel,
                  isDark: isDark,
                  onTap: canAccessList
                      ? () => Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => FollowListScreen(
                                userId: userId,
                                type: FollowListType.followers,
                                profileName: profile.username,
                              ),
                            ),
                          )
                      : null,
                ),
                _StatDivider(isDark: isDark),
                _StatCell(
                  count: profile.followingCount,
                  label: S.of(context).followingLabel,
                  isDark: isDark,
                  onTap: canAccessList
                      ? () => Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => FollowListScreen(
                                userId: userId,
                                type: FollowListType.following,
                                profileName: profile.username,
                              ),
                            ),
                          )
                      : null,
                ),
              ],
            ),

            // ── Buttons row ──────────────────────────────────────
            if (!isOwnProfile) ...[
              verticalSpace(20),
              Row(children: [
                Expanded(
                  child: _FollowButton(
                      profile: profile,
                      userId: userId,
                      cubit: cubit,
                      isDark: isDark),
                ),
                if (canMessage) ...[
                  SizedBox(width: 10.w),
                  _MessageButton(
                    profile: profile,
                    isDark: isDark,
                  ),
                ],
              ]),
            ],

            verticalSpace(24),
          ]),
        ),

        // ── Genres section ─────────────────────────────────────────
        if (profile.genres != null && profile.genres!.isNotEmpty)
          _GenresSection(genres: profile.genres!, isDark: isDark),

        // ── Instruments section ─────────────────────────────────────
        if (profile.instruments != null && profile.instruments!.isNotEmpty)
          _InstrumentsSection(instruments: profile.instruments!, isDark: isDark),

        // Bottom border
        Divider(
          height: 1,
          color: isDark ? const Color(0xFF2A2A2A) : const Color(0xFFEEEEEE),
        ),
      ]),
    );
  }
}

// ── Stat cell ─────────────────────────────────────────────────────────────────

class _StatCell extends StatelessWidget {
  final int count;
  final String label;
  final bool isDark;
  final VoidCallback? onTap;

  const _StatCell({
    required this.count,
    required this.label,
    required this.isDark,
    this.onTap,
  });

  String _fmt(int n) {
    if (n >= 1000000) return '${(n / 1000000).toStringAsFixed(1)}M';
    if (n >= 1000) return '${(n / 1000).toStringAsFixed(1)}K';
    return '$n';
  }

  @override
  Widget build(BuildContext context) {
    final content = Padding(
      padding: EdgeInsets.symmetric(horizontal: 20.w),
      child: Column(children: [
        Text(
          _fmt(count),
          style: TextStyle(
            fontFamily: 'GeneralSans',
            fontSize: 20,
            fontWeight: FontWeight.w800,
            color: isDark ? Colors.white : ColorManager.black,
          ),
        ),
        verticalSpace(2),
        Text(
          label,
          style: const TextStyle(
            fontFamily: 'GeneralSans',
            fontSize: 12,
            color: Color(0xFF888888),
          ),
        ),
      ]),
    );

    if (onTap == null) return content;

    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: content,
    );
  }
}

class _StatDivider extends StatelessWidget {
  final bool isDark;
  const _StatDivider({required this.isDark});

  @override
  Widget build(BuildContext context) => Container(
        width: 1,
        height: 32.h,
        color: isDark ? const Color(0xFF2A2A2A) : const Color(0xFFEEEEEE),
      );
}

// ── Message button ────────────────────────────────────────────────────────────

class _MessageButton extends StatelessWidget {
  final UserProfileModel profile;
  final bool isDark;

  const _MessageButton({required this.profile, required this.isDark});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => ChatScreen(
            userId: profile.id,
            username: profile.username,
            fullName: profile.fullName,
            profileImageUrl: profile.profileImageUrl,
          ),
        ),
      ),
      child: Container(
        width: 46.r,
        height: 46.r,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: isDark ? const Color(0xFF252525) : const Color(0xFFF0F0F0),
          border: Border.all(
            color:
                isDark ? const Color(0xFF3A3A3A) : const Color(0xFFDDDDDD),
          ),
        ),
        child: Icon(
          Icons.chat_bubble_outline_rounded,
          size: 20.r,
          color:
              isDark ? const Color(0xFFCCCCCC) : const Color(0xFF444444),
        ),
      ),
    );
  }
}

// ── Follow button ─────────────────────────────────────────────────────────────

class _FollowButton extends StatelessWidget {
  final UserProfileModel profile;
  final String userId;
  final UserProfileCubit cubit;
  final bool isDark;

  const _FollowButton({
    required this.profile,
    required this.userId,
    required this.cubit,
    required this.isDark,
  });

  void _showUnfollowSheet(BuildContext context) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (_) => Container(
        decoration: BoxDecoration(
          color: isDark ? const Color(0xFF1E1E1E) : Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(20.r)),
        ),
        padding: EdgeInsets.fromLTRB(20.w, 16.h, 20.w, 32.h),
        child: Column(mainAxisSize: MainAxisSize.min, children: [
          Container(
            width: 36.w,
            height: 4.h,
            margin: EdgeInsets.only(bottom: 20.h),
            decoration: BoxDecoration(
              color: isDark
                  ? const Color(0xFF3A3A3A)
                  : const Color(0xFFDDDDDD),
              borderRadius: BorderRadius.circular(2.r),
            ),
          ),
          // Unfollow action
          GestureDetector(
            onTap: () async {
              Navigator.pop(context);
              await cubit.unfollow(userId);
              try {
                context.read<NotificationsCubit>().silentRefresh();
              } catch (_) {}
              final st = cubit.state;
              if (st is UserProfileLoaded &&
                  st.profile.isFollowingMe &&
                  context.mounted) {
                final remove = await showDialog<bool>(
                  context: context,
                  builder: (ctx) => AlertDialog(
                    title: Text(S.of(context).removeFollowerTitle),
                    content: Text(
                        '${profile.username} follows you. Remove them too?'),
                    actions: [
                      TextButton(
                          onPressed: () => Navigator.pop(ctx, false),
                          child: Text(S.of(context).keepBtn)),
                      TextButton(
                          onPressed: () => Navigator.pop(ctx, true),
                          child: Text(S.of(context).removeBtn,
                              style: TextStyle(color: ColorManager.red))),
                    ],
                  ),
                );
                if (remove == true) await cubit.removeFollower(userId);
              }
            },
            child: Container(
              width: double.infinity,
              padding: EdgeInsets.symmetric(vertical: 14.h),
              decoration: BoxDecoration(
                color: ColorManager.red.withValues(alpha: 0.08),
                borderRadius: BorderRadius.circular(12.r),
                border: Border.all(
                    color: ColorManager.red.withValues(alpha: 0.2)),
              ),
              child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.person_remove_outlined,
                        color: ColorManager.red, size: 18.r),
                    SizedBox(width: 8.w),
                    Text(S.of(context).unfollowBtn,
                        style: TextStyles.font14semiBold
                            .copyWith(color: ColorManager.red)),
                  ]),
            ),
          ),
          SizedBox(height: 10.h),
          GestureDetector(
            onTap: () => Navigator.pop(context),
            child: Container(
              width: double.infinity,
              padding: EdgeInsets.symmetric(vertical: 14.h),
              decoration: BoxDecoration(
                color: isDark
                    ? const Color(0xFF2A2A2A)
                    : const Color(0xFFF5F5F5),
                borderRadius: BorderRadius.circular(12.r),
              ),
              child: Text(S.of(context).cancelBtn,
                  textAlign: TextAlign.center,
                  style: TextStyles.font14semiBold.copyWith(
                    color: isDark ? Colors.white : ColorManager.black,
                  )),
            ),
          ),
        ]),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final status = profile.followStatus;

    if (status == 'following') {
      return AppButton(
        onPressed: () => _showUnfollowSheet(context),
        text: S.of(context).followingStatus,
        isWhite: true,
        icon: Icons.keyboard_arrow_down_rounded,
      );
    }
    if (status == 'pending') {
      return AppButton(
        onPressed: () async {
          await cubit.unfollow(userId);
          try {
            context.read<NotificationsCubit>().silentRefresh();
          } catch (_) {}
        },
        text: S.of(context).requestedBtn,
        isWhite: true,
      );
    }
    return AppButton(
      onPressed: () => cubit.follow(userId),
      text: profile.isPrivate ? S.of(context).requestBtn : S.of(context).followBtn,
      isWhite: false,
    );
  }
}

// ── Initials widget ───────────────────────────────────────────────────────────

class _InitialsWidget extends StatelessWidget {
  final String initials;
  final bool isDark;
  const _InitialsWidget({required this.initials, required this.isDark});

  @override
  Widget build(BuildContext context) {
    return Container(
      color: isDark ? const Color(0xFF2A2A2A) : const Color(0xFFEEEEEE),
      child: Center(
        child: Text(
          initials,
          style: TextStyle(
            fontFamily: 'GeneralSans',
            fontSize: 28,
            fontWeight: FontWeight.w700,
            color: isDark ? const Color(0xFF666666) : const Color(0xFFAAAAAA),
          ),
        ),
      ),
    );
  }
}

// ── Genres section ────────────────────────────────────────────────────────────

class _GenresSection extends StatelessWidget {
  final List<String> genres;
  final bool isDark;
  const _GenresSection({required this.genres, required this.isDark});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.fromLTRB(20.w, 16.h, 20.w, 4.h),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text(
          S.of(context).genresSection,
          style: TextStyle(
            fontFamily: 'GeneralSans',
            fontSize: 14,
            fontWeight: FontWeight.w700,
            color: isDark ? Colors.white : const Color(0xFF1A1A1A),
          ),
        ),
        SizedBox(height: 10.h),
        Wrap(
          spacing: 8.w,
          runSpacing: 8.h,
          children: genres.map((g) => _GenreChip(genre: g, isDark: isDark)).toList(),
        ),
      ]),
    );
  }
}

class _GenreChip extends StatelessWidget {
  final String genre;
  final bool isDark;
  const _GenreChip({required this.genre, required this.isDark});

  @override
  Widget build(BuildContext context) {
    return _InfoChip(
      label: genre,
      imagePath: _genreImages[genre],
      accentColor: _genreAccents[genre],
      bgColor: _genreColors[genre],
      isDark: isDark,
    );
  }
}

// ── Instruments section ───────────────────────────────────────────────────────

class _InstrumentsSection extends StatelessWidget {
  final List<String> instruments;
  final bool isDark;
  const _InstrumentsSection({required this.instruments, required this.isDark});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.fromLTRB(20.w, 12.h, 20.w, 16.h),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text(
          S.of(context).instrumentsSection,
          style: TextStyle(
            fontFamily: 'GeneralSans',
            fontSize: 13,
            fontWeight: FontWeight.w700,
            color: isDark ? Colors.white : const Color(0xFF1A1A1A),
          ),
        ),
        SizedBox(height: 10.h),
        Wrap(
          spacing: 8.w,
          runSpacing: 8.h,
          children: instruments
              .map((ins) => _InfoChip(
                    label: ins,
                    imagePath: _instrumentImages[ins],
                    isDark: isDark,
                  ))
              .toList(),
        ),
      ]),
    );
  }
}

// ── Unified info chip — white circle icon on left, label on right ─────────────

class _InfoChip extends StatelessWidget {
  final String label;
  final String? imagePath;
  final Color? accentColor;
  final Color? bgColor;
  final bool isDark;

  const _InfoChip({
    required this.label,
    required this.isDark,
    this.imagePath,
    this.accentColor,
    this.bgColor,
  });

  @override
  Widget build(BuildContext context) {
    final accent = accentColor ??
        (isDark ? const Color(0xFF999999) : const Color(0xFF555555));
    final bg = isDark
        ? const Color(0xFF1E1E1E)
        : (bgColor ?? const Color(0xFFF5F5F5));
    final border =
        isDark ? accent.withValues(alpha: 0.2) : accent.withValues(alpha: 0.25);

    return Container(
      padding: EdgeInsets.symmetric(horizontal: 10.w, vertical: 7.h),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(20.r),
        border: Border.all(color: border, width: 1),
      ),
      child: Row(mainAxisSize: MainAxisSize.min, children: [
        Container(
          width: 22.r,
          height: 22.r,
          decoration: const BoxDecoration(
            color: Colors.white,
            shape: BoxShape.circle,
          ),
          child: imagePath != null
              ? Padding(
                  padding: EdgeInsets.all(3.r),
                  child: Image.asset(imagePath!, fit: BoxFit.contain),
                )
              : Icon(Icons.music_note_rounded, size: 13.r, color: accent),
        ),
        SizedBox(width: 7.w),
        Text(
          label,
          style: TextStyle(
            fontFamily: 'GeneralSans',
            fontSize: 12,
            fontWeight: FontWeight.w600,
            color: isDark ? const Color(0xFFCCCCCC) : accent,
          ),
        ),
      ]),
    );
  }
}

// ── Post thumbnail ────────────────────────────────────────────────────────────

class _PostThumbnail extends StatefulWidget {
  final Post post;
  final bool isDark;
  final VoidCallback onTap;
  const _PostThumbnail(
      {required this.post, required this.isDark, required this.onTap});

  @override
  State<_PostThumbnail> createState() => _PostThumbnailState();
}

class _PostThumbnailState extends State<_PostThumbnail> {
  VideoPlayerController? _controller;
  bool _thumbReady = false;

  bool _isVideo(String url) {
    final lower = url.toLowerCase();
    return lower.endsWith('.mp4') ||
        lower.endsWith('.mov') ||
        lower.endsWith('.webm') ||
        lower.endsWith('.avi') ||
        lower.endsWith('.mkv');
  }

  String _resolve(String url) =>
      url.startsWith('http') ? url : '${ApiConstants.apiBASEURL}$url';

  @override
  void initState() {
    super.initState();
    final media = (widget.post.media ?? []).where((m) => m.isNotEmpty).toList();
    final effectiveMedia = media.isNotEmpty
        ? media
        : (widget.post.originalPost?.media ?? []).where((m) => m.isNotEmpty).toList();
    final firstMedia = effectiveMedia.isNotEmpty ? effectiveMedia.first : null;
    if (firstMedia != null && _isVideo(firstMedia)) {
      _loadThumb(_resolve(firstMedia));
    }
  }

  Future<void> _loadThumb(String url) async {
    final c = VideoPlayerController.networkUrl(Uri.parse(url));
    try {
      await c.initialize();
      await c.seekTo(Duration.zero);
      if (mounted) {
        setState(() { _controller = c; _thumbReady = true; });
      } else {
        c.dispose();
      }
    } catch (_) {
      c.dispose();
    }
  }

  @override
  void dispose() {
    _controller?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final media = (widget.post.media ?? []).where((m) => m.isNotEmpty).toList();
    final isShared = widget.post.originalPost != null && media.isEmpty;
    final effectiveMedia = media.isNotEmpty
        ? media
        : (widget.post.originalPost?.media ?? []).where((m) => m.isNotEmpty).toList();
    final firstMedia = effectiveMedia.isNotEmpty ? effectiveMedia.first : null;
    final displayText = widget.post.content?.isNotEmpty == true
        ? widget.post.content!
        : (widget.post.originalPost?.content ?? '');

    Widget thumbnail;
    if (firstMedia == null) {
      thumbnail = Container(
        color: widget.isDark ? const Color(0xFF2A2A2A) : const Color(0xFFEEEEEE),
        padding: EdgeInsets.all(8.r),
        child: Center(
          child: Column(mainAxisSize: MainAxisSize.min, children: [
            if (isShared) ...[
              Icon(Icons.repeat, size: 14.r, color: const Color(0xFF888888)),
              SizedBox(height: 4.h),
            ],
            Text(displayText,
                style: TextStyle(
                  fontFamily: 'GeneralSans',
                  fontSize: 11,
                  color: widget.isDark ? const Color(0xFF888888) : ColorManager.darkGrey,
                ),
                maxLines: 4,
                overflow: TextOverflow.ellipsis,
                textAlign: TextAlign.center),
          ]),
        ),
      );
    } else if (_isVideo(firstMedia)) {
      thumbnail = Stack(fit: StackFit.expand, children: [
        Container(color: const Color(0xFF1A1A1A)),
        if (_thumbReady && _controller != null)
          FittedBox(
            fit: BoxFit.cover,
            clipBehavior: Clip.hardEdge,
            child: SizedBox(
              width: _controller!.value.size.width,
              height: _controller!.value.size.height,
              child: VideoPlayer(_controller!),
            ),
          ),
        Center(child: Icon(Icons.play_circle_outline, color: Colors.white70, size: 28.r)),
      ]);
    } else {
      thumbnail = Image.network(
        _resolve(firstMedia),
        fit: BoxFit.cover,
        loadingBuilder: (_, child, progress) => progress == null
            ? child
            : Container(color: widget.isDark ? const Color(0xFF252525) : const Color(0xFFE8E8E8)),
        errorBuilder: (_, __, ___) => Container(
          color: widget.isDark ? const Color(0xFF252525) : const Color(0xFFE8E8E8),
          child: Icon(Icons.broken_image_outlined, color: const Color(0xFF888888), size: 22.r),
        ),
      );
    }

    final viewsCount = widget.post.viewsCount ?? 0;

    return GestureDetector(
      onTap: widget.onTap,
      child: Stack(fit: StackFit.expand, children: [
        thumbnail,
        if (isShared)
          Positioned(
            top: 4.r,
            right: 4.r,
            child: Container(
              padding: EdgeInsets.all(3.r),
              decoration: BoxDecoration(
                  color: Colors.black54,
                  borderRadius: BorderRadius.circular(4.r)),
              child: Icon(Icons.repeat, size: 10.r, color: Colors.white),
            ),
          ),
        if (viewsCount > 0)
          Positioned(
            left: 4.r,
            bottom: 4.r,
            child: Container(
              padding: EdgeInsets.symmetric(horizontal: 5.w, vertical: 2.h),
              decoration: BoxDecoration(
                color: Colors.black54,
                borderRadius: BorderRadius.circular(4.r),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.visibility_outlined,
                      size: 9.r, color: Colors.white),
                  SizedBox(width: 2.w),
                  Text(
                    _fmtCount(viewsCount),
                    style: const TextStyle(
                      fontSize: 9,
                      fontWeight: FontWeight.w600,
                      color: Colors.white,
                      fontFamily: 'GeneralSans',
                    ),
                  ),
                ],
              ),
            ),
          ),
      ]),
    );
  }

  String _fmtCount(int n) {
    if (n >= 1000000) return '${(n / 1000000).toStringAsFixed(1)}M';
    if (n >= 1000) return '${(n / 1000).toStringAsFixed(1)}K';
    return '$n';
  }
}
