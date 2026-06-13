// ignore_for_file: deprecated_member_use
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:riff/core/di/dependency_injection.dart';
import 'package:riff/core/networks/api_constants.dart';
import 'package:riff/core/themes/colors/color_manager.dart';
import 'package:riff/core/themes/text_styles/text_styles.dart';
import 'package:riff/core/helpers/spacing.dart';
import 'package:riff/features/home/feed/data/models/post.dart';
import 'package:riff/features/home/feed/Ui/post_detail_screen.dart';
import 'package:riff/features/home/core/logic/cubit/home_cubit.dart';
import 'package:riff/features/home/user_profile/data/models/user_profile_model.dart';
import 'package:riff/features/home/user_profile/logic/cubit/user_profile_cubit.dart';

class UserProfileScreen extends StatefulWidget {
  final String userId;

  const UserProfileScreen({super.key, required this.userId});

  @override
  State<UserProfileScreen> createState() => _UserProfileScreenState();
}

class _UserProfileScreenState extends State<UserProfileScreen> {
  late final UserProfileCubit _cubit;

  @override
  void initState() {
    super.initState();
    _cubit = getIt<UserProfileCubit>();
    _cubit.loadProfile(widget.userId);
  }

  @override
  void dispose() {
    _cubit.close();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return BlocProvider.value(
      value: _cubit,
      child: Scaffold(
        backgroundColor: const Color(0xFFF5F5F5),
        appBar: AppBar(
          backgroundColor: ColorManager.white,
          elevation: 0.5,
          shadowColor: ColorManager.lighterGrey,
          leading: IconButton(
            onPressed: () => Navigator.pop(context),
            icon: const Icon(Icons.arrow_back_ios_new, size: 20),
            color: ColorManager.primaryBlack,
          ),
          title: Text(
            'Profile',
            style: TextStyles.font16Medium.copyWith(
              color: ColorManager.primaryBlack,
            ),
          ),
          centerTitle: false,
        ),
        body: BlocBuilder<UserProfileCubit, UserProfileState>(
          builder: (context, state) {
            if (state is UserProfileInitial || state is UserProfileLoading) {
              return const Center(child: CircularProgressIndicator());
            }

            if (state is UserProfileFailure) {
              return Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.error_outline,
                        size: 48.r, color: ColorManager.normalGrey),
                    verticalSpace(12),
                    Text(
                      state.message,
                      style: TextStyles.font14Medium.copyWith(
                          color: ColorManager.normalGrey),
                      textAlign: TextAlign.center,
                    ),
                    verticalSpace(16),
                    TextButton(
                      onPressed: () => _cubit.loadProfile(widget.userId),
                      child: Text('Retry',
                          style: TextStyles.font14semiBold.copyWith(
                              color: ColorManager.primaryBlack)),
                    ),
                  ],
                ),
              );
            }

            final loaded = state as UserProfileLoaded;
            return _ProfileBody(
              profile: loaded.profile,
              posts: loaded.posts,
            );
          },
        ),
      ),
    );
  }
}

// ── Profile body ──────────────────────────────────────────────────────────────

class _ProfileBody extends StatelessWidget {
  final UserProfileModel profile;
  final List<Post> posts;

  const _ProfileBody({required this.profile, required this.posts});

  String? get _avatarUrl {
    final raw = profile.profileImageUrl;
    if (raw == null || raw.isEmpty) return null;
    return raw.startsWith('http') ? raw : '${ApiConstants.apiBASEURL}$raw';
  }

  String get _initials {
    return profile.fullName
        .trim()
        .split(RegExp(r'\s+'))
        .take(2)
        .map((w) => w.isEmpty ? '' : w[0].toUpperCase())
        .join();
  }

  @override
  Widget build(BuildContext context) {
    return CustomScrollView(
      physics: const BouncingScrollPhysics(),
      slivers: [
        SliverToBoxAdapter(child: _buildHeader(context)),
        if (posts.isNotEmpty) ...[
          SliverToBoxAdapter(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(height: 8.h, color: const Color(0xFFF5F5F5)),
                Padding(
                  padding: EdgeInsets.fromLTRB(16.w, 16.h, 16.w, 8.h),
                  child: Text('Posts', style: TextStyles.font18Semibold),
                ),
              ],
            ),
          ),
          SliverPadding(
            padding: EdgeInsets.fromLTRB(2.w, 0, 2.w, 32.h),
            sliver: SliverGrid(
              gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 3,
                crossAxisSpacing: 2.w,
                mainAxisSpacing: 2.h,
              ),
              delegate: SliverChildBuilderDelegate(
                (ctx, i) => _PostThumbnail(
                  post: posts[i],
                  onTap: () => Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => BlocProvider.value(
                        value: context.read<HomeCubit>(),
                        child: PostDetailScreen(post: posts[i]),
                      ),
                    ),
                  ),
                ),
                childCount: posts.length,
              ),
            ),
          ),
        ] else
          SliverFillRemaining(
            child: Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.music_note_outlined,
                      size: 48.r, color: ColorManager.lighterGrey),
                  verticalSpace(12),
                  Text(
                    'No posts yet',
                    style: TextStyles.font16Medium.copyWith(
                        color: ColorManager.normalGrey),
                  ),
                ],
              ),
            ),
          ),
      ],
    );
  }

  Widget _buildHeader(BuildContext context) {
    final avatarUrl = _avatarUrl;
    final initials = _initials.isEmpty ? '?' : _initials;

    return Container(
      color: ColorManager.white,
      padding: EdgeInsets.fromLTRB(20.w, 28.h, 20.w, 24.h),
      child: Column(
        children: [
          // Avatar
          Container(
            width: 96.r,
            height: 96.r,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: ColorManager.lighterGrey,
              border: Border.all(color: ColorManager.lighterGrey, width: 3),
            ),
            child: ClipOval(
              child: avatarUrl != null
                  ? Image.network(
                      avatarUrl,
                      fit: BoxFit.cover,
                      errorBuilder: (_, __, ___) =>
                          _InitialsWidget(initials: initials),
                    )
                  : _InitialsWidget(initials: initials),
            ),
          ),

          verticalSpace(14),

          // Full name
          Text(
            profile.fullName,
            style: TextStyles.font20SemiBold,
            textAlign: TextAlign.center,
          ),
          verticalSpace(4),

          // Username
          Text(
            '@${profile.username}',
            style: TextStyles.font14Medium.copyWith(
                color: ColorManager.normalGrey),
          ),

          // Bio
          if (profile.bio != null && profile.bio!.isNotEmpty) ...[
            verticalSpace(10),
            Text(
              profile.bio!,
              style: TextStyles.font14regular.copyWith(
                  color: ColorManager.darkGrey),
              textAlign: TextAlign.center,
              maxLines: 3,
              overflow: TextOverflow.ellipsis,
            ),
          ],

          verticalSpace(20),

          // Counts row
          IntrinsicHeight(
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                _CountCell(
                    count: profile.postsCount,
                    label: profile.postsCount == 1 ? 'Post' : 'Posts'),
                _Divider(),
                _CountCell(count: profile.followersCount, label: 'Followers'),
                _Divider(),
                _CountCell(count: profile.followingCount, label: 'Following'),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ── Sub-widgets ───────────────────────────────────────────────────────────────

class _InitialsWidget extends StatelessWidget {
  final String initials;
  const _InitialsWidget({required this.initials});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Text(
        initials,
        style: TextStyles.font28Bold.copyWith(color: ColorManager.normalGrey),
      ),
    );
  }
}

class _CountCell extends StatelessWidget {
  final int count;
  final String label;
  const _CountCell({required this.count, required this.label});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.symmetric(horizontal: 20.w),
      child: Column(
        children: [
          Text(
            _fmt(count),
            style: TextStyles.font20SemiBold,
          ),
          verticalSpace(2),
          Text(
            label,
            style: TextStyles.font12Medium.copyWith(
                color: ColorManager.normalGrey),
          ),
        ],
      ),
    );
  }

  String _fmt(int n) {
    if (n >= 1000000) return '${(n / 1000000).toStringAsFixed(1)}M';
    if (n >= 1000) return '${(n / 1000).toStringAsFixed(1)}K';
    return '$n';
  }
}

class _Divider extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      width: 1,
      color: ColorManager.lighterGrey,
      margin: EdgeInsets.symmetric(vertical: 4.h),
    );
  }
}

class _PostThumbnail extends StatelessWidget {
  final Post post;
  final VoidCallback onTap;
  const _PostThumbnail({required this.post, required this.onTap});

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
  Widget build(BuildContext context) {
    final media = (post.media ?? []).where((m) => m.isNotEmpty).toList();

    // Shared posts have no own media — fall back to the original post's media
    // so the thumbnail is never blank.
    final isShared = post.originalPost != null && media.isEmpty;
    final effectiveMedia = media.isNotEmpty
        ? media
        : (post.originalPost?.media ?? []).where((m) => m.isNotEmpty).toList();
    final firstMedia = effectiveMedia.isNotEmpty ? effectiveMedia.first : null;

    // Text to show when there is no media at all.
    final displayText = post.content?.isNotEmpty == true
        ? post.content!
        : (post.originalPost?.content ?? '');

    Widget thumbnail;
    if (firstMedia == null) {
      thumbnail = Container(
        color: isShared ? const Color(0xFFE8E8F0) : const Color(0xFFEEEEEE),
        padding: EdgeInsets.all(8.r),
        child: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (isShared) ...[
                Icon(Icons.repeat, size: 16.r, color: ColorManager.normalGrey),
                SizedBox(height: 4.h),
              ],
              Text(
                displayText,
                style: TextStyles.font12Medium.copyWith(color: ColorManager.darkGrey),
                maxLines: 4,
                overflow: TextOverflow.ellipsis,
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      );
    } else if (_isVideo(firstMedia)) {
      thumbnail = Stack(
        fit: StackFit.expand,
        children: [
          Container(color: const Color(0xFF1A1A1A)),
          Center(
            child: Icon(Icons.play_circle_outline, color: Colors.white70, size: 32.r),
          ),
        ],
      );
    } else {
      thumbnail = Image.network(
        _resolve(firstMedia),
        fit: BoxFit.cover,
        loadingBuilder: (_, child, progress) =>
            progress == null ? child : Container(color: ColorManager.lighterGrey),
        errorBuilder: (_, __, ___) => Container(
          color: ColorManager.lighterGrey,
          child: Icon(Icons.broken_image_outlined,
              color: ColorManager.normalGrey, size: 24.r),
        ),
      );
    }

    return GestureDetector(
      onTap: onTap,
      child: Container(
        color: ColorManager.lighterGrey,
        child: Stack(
          fit: StackFit.expand,
          children: [
            thumbnail,
            // Small share badge in the top-right corner.
            if (isShared)
              Positioned(
                top: 4.r,
                right: 4.r,
                child: Container(
                  padding: EdgeInsets.all(3.r),
                  decoration: BoxDecoration(
                    color: Colors.black54,
                    borderRadius: BorderRadius.circular(4.r),
                  ),
                  child: Icon(Icons.repeat, size: 11.r, color: Colors.white),
                ),
              ),
          ],
        ),
      ),
    );
  }
}
