// ignore_for_file: use_build_context_synchronously, deprecated_member_use
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:image_picker/image_picker.dart';
import 'package:riff/core/di/dependency_injection.dart';
import 'package:riff/core/networks/api_constants.dart';
import 'package:riff/core/themes/colors/color_manager.dart';
import 'package:riff/core/themes/text_styles/text_styles.dart';
import 'package:riff/core/helpers/spacing.dart';
import 'package:riff/features/home/feed/Ui/post_detail_screen.dart';
import 'package:riff/features/home/feed/Ui/widgets/post/fullscsreen_image.dart';
import 'package:riff/features/home/feed/data/models/post.dart';
import 'package:riff/features/home/profile/logic/cubit/profile_cubit.dart';

// ---------------------------------------------------------------------------
// Genre assets + accent colors
// ---------------------------------------------------------------------------

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

// ---------------------------------------------------------------------------
// UserProfile model  (imported by HomeRepo + HomeCubit — keep this class here)
// ---------------------------------------------------------------------------

class UserProfile {
  final String id;
  final String fullName;
  final String username;
  final String email;
  final String? provider;
  final String? bio;
  final List<String>? instruments;
  final List<String>? genres;
  final String? profileImageUrl;

  const UserProfile({
    required this.id,
    required this.fullName,
    required this.username,
    required this.email,
    this.provider,
    this.bio,
    this.instruments,
    this.genres,
    this.profileImageUrl,
  });

  factory UserProfile.fromJson(Map<String, dynamic> json) => UserProfile(
        id: json['id'] as String,
        fullName: json['full_name'] ?? '',
        username: json['username'] ?? '',
        email: json['email'] ?? '',
        provider: json['provider'],
        bio: json['bio'] as String?,
        instruments: (json['instruments'] as List?)?.cast<String>(),
        genres: (json['genres'] as List?)?.cast<String>(),
        profileImageUrl: json['profile_image_url'],
      );
}

// ---------------------------------------------------------------------------
// Screen
// ---------------------------------------------------------------------------

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key, required this.profile});
  final UserProfile profile;

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  late final ProfileCubit _cubit;
  final _picker = ImagePicker();
  String? _uploadedImageUrl;

  @override
  void initState() {
    super.initState();
    _cubit = getIt<ProfileCubit>();
    _cubit.loadUserPosts(widget.profile.id);
  }

  @override
  void dispose() {
    _cubit.close();
    super.dispose();
  }

  String? get _effectiveImageUrl {
    final raw = _uploadedImageUrl ?? widget.profile.profileImageUrl;
    if (raw == null || raw.isEmpty) return null;
    return raw.startsWith('http') ? raw : '${ApiConstants.apiBASEURL}$raw';
  }

  Future<void> _pickAndUpload(ImageSource source) async {
    Navigator.pop(context);
    final file = await _picker.pickImage(
      source: source,
      maxWidth: 1024,
      imageQuality: 85,
    );
    if (file == null) return;
    await _cubit.uploadProfileImage(File(file.path));
  }

  void _showPhotoSheet() {
    HapticFeedback.lightImpact();
    showModalBottomSheet(
      context: context,
      backgroundColor: ColorManager.white,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24.r)),
      ),
      builder: (ctx) => SafeArea(
        child: Padding(
          padding: EdgeInsets.fromLTRB(20.w, 12.h, 20.w, 20.h),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 40.w,
                height: 4.h,
                decoration: BoxDecoration(
                  color: ColorManager.lighterGrey,
                  borderRadius: BorderRadius.circular(99),
                ),
              ),
              verticalSpace(16),
              _SheetTile(
                icon: Icons.photo_library_outlined,
                label: 'Choose from Gallery',
                onTap: () => _pickAndUpload(ImageSource.gallery),
              ),
              _SheetTile(
                icon: Icons.photo_camera_outlined,
                label: 'Take a Photo',
                onTap: () => _pickAndUpload(ImageSource.camera),
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return BlocProvider.value(
      value: _cubit,
      child: BlocListener<ProfileCubit, ProfileState>(
        listener: (context, state) {
          if (state is ProfileImageUploadSuccess) {
            setState(() => _uploadedImageUrl = state.imageUrl);
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                behavior: SnackBarBehavior.floating,
                backgroundColor: ColorManager.primaryBlack,
                content: Text(
                  'Profile photo updated',
                  style:
                      TextStyles.font14Medium.copyWith(color: ColorManager.white),
                ),
              ),
            );
          } else if (state is ProfileImageUploadFailure) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                behavior: SnackBarBehavior.floating,
                backgroundColor: ColorManager.red,
                content: Text(state.message,
                    style: TextStyles.font14Medium
                        .copyWith(color: ColorManager.white)),
              ),
            );
          }
        },
        child: CustomScrollView(
          physics: const BouncingScrollPhysics(),
          slivers: [
            _buildHeader(),
            if (widget.profile.genres?.isNotEmpty ?? false)
              _buildGenresSection(widget.profile.genres!),
            _buildPostsSection(),
          ],
        ),
      ),
    );
  }

  // ── Header ──────────────────────────────────────────────────────────────────

  Widget _buildHeader() {
    final imageUrl = _effectiveImageUrl;
    final initials = widget.profile.fullName.trim().isEmpty
        ? '?'
        : widget.profile.fullName
            .trim()
            .split(RegExp(r'\s+'))
            .take(2)
            .map((w) => w[0].toUpperCase())
            .join();

    return SliverToBoxAdapter(
      child: Container(
        color: ColorManager.white,
        padding: EdgeInsets.fromLTRB(20.w, 24.h, 20.w, 28.h),
        child: Column(
          children: [
            // ── Avatar + camera badge ───────────────────────────────────────
            BlocBuilder<ProfileCubit, ProfileState>(
              buildWhen: (_, s) =>
                  s is ProfileImageUploading ||
                  s is ProfileImageUploadSuccess ||
                  s is ProfileImageUploadFailure,
              builder: (context, state) {
                final isUploading = state is ProfileImageUploading;
                return Stack(
                  children: [
                    GestureDetector(
                      onTap: (!isUploading && imageUrl != null)
                          ? () => Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (_) =>
                                      FullScreenImage.single(imageUrl: imageUrl),
                                ),
                              )
                          : null,
                      child: Container(
                        width: 96.r,
                        height: 96.r,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: ColorManager.lighterGrey,
                          border: Border.all(
                              color: ColorManager.lighterGrey, width: 3),
                        ),
                        child: ClipOval(
                          child: imageUrl != null
                              ? Image.network(
                                  imageUrl,
                                  fit: BoxFit.cover,
                                  errorBuilder: (_, __, ___) => Center(
                                    child: Text(initials,
                                        style: TextStyles.font28Bold.copyWith(
                                            color: ColorManager.normalGrey)),
                                  ),
                                )
                              : Center(
                                  child: Text(
                                    initials,
                                    style: TextStyles.font28Bold.copyWith(
                                        color: ColorManager.normalGrey),
                                  ),
                                ),
                        ),
                      ),
                    ),
                    Positioned(
                      right: 0,
                      bottom: 0,
                      child: GestureDetector(
                        onTap: isUploading ? null : _showPhotoSheet,
                        child: Container(
                          width: 30.r,
                          height: 30.r,
                          decoration: BoxDecoration(
                            color: isUploading
                                ? ColorManager.normalGrey
                                : ColorManager.primaryBlack,
                            shape: BoxShape.circle,
                            border:
                                Border.all(color: ColorManager.white, width: 2),
                          ),
                          child: isUploading
                              ? Padding(
                                  padding: const EdgeInsets.all(6),
                                  child: CircularProgressIndicator(
                                      strokeWidth: 2,
                                      color: ColorManager.white),
                                )
                              : Icon(Icons.camera_alt_rounded,
                                  size: 14.r, color: ColorManager.white),
                        ),
                      ),
                    ),
                  ],
                );
              },
            ),

            verticalSpace(16),

            // ── Name ────────────────────────────────────────────────────────
            Text(
              widget.profile.fullName,
              style: TextStyles.font20SemiBold,
              textAlign: TextAlign.center,
            ),
            verticalSpace(4),

            // ── Username ─────────────────────────────────────────────────────
            Text(
              '@${widget.profile.username}',
              style: TextStyles.font14Medium.copyWith(
                  color: ColorManager.normalGrey),
            ),

            // ── Bio ──────────────────────────────────────────────────────────
            if (widget.profile.bio != null && widget.profile.bio!.isNotEmpty) ...[
              verticalSpace(10),
              Text(
                widget.profile.bio!,
                style: TextStyles.font14regular
                    .copyWith(color: ColorManager.darkGrey),
                textAlign: TextAlign.center,
                maxLines: 3,
                overflow: TextOverflow.ellipsis,
              ),
            ],

            verticalSpace(20),

            // ── Counts row ───────────────────────────────────────────────────
            BlocBuilder<ProfileCubit, ProfileState>(
              buildWhen: (_, s) => s is ProfileSuccess,
              builder: (context, state) {
                final postsCount =
                    state is ProfileSuccess ? state.posts.length : 0;
                return IntrinsicHeight(
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      _CountCell(
                          count: postsCount,
                          label: postsCount == 1 ? 'Post' : 'Posts'),
                      _VertDivider(),
                      _CountCell(count: 0, label: 'Followers'),
                      _VertDivider(),
                      _CountCell(count: 0, label: 'Following'),
                    ],
                  ),
                );
              },
            ),
          ],
        ),
      ),
    );
  }

  // ── Genres ──────────────────────────────────────────────────────────────────

  Widget _buildGenresSection(List<String> genres) {
    return SliverToBoxAdapter(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _SectionSpacer(),
          Padding(
            padding: EdgeInsets.fromLTRB(20.w, 20.h, 20.w, 14.h),
            child: Text('Genres', style: TextStyles.font18Semibold),
          ),
          SizedBox(
            height: 130.h,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              physics: const BouncingScrollPhysics(),
              padding: EdgeInsets.symmetric(horizontal: 16.w),
              itemCount: genres.length,
              separatorBuilder: (_, __) => SizedBox(width: 10.w),
              itemBuilder: (_, i) => _GenreCard(name: genres[i]),
            ),
          ),
          verticalSpace(20),
        ],
      ),
    );
  }

  // ── Posts grid ───────────────────────────────────────────────────────────────

  Widget _buildPostsSection() {
    return BlocBuilder<ProfileCubit, ProfileState>(
      buildWhen: (_, s) =>
          s is ProfileLoading ||
          s is ProfileSuccess ||
          s is ProfileFailure ||
          s is ProfileInitial,
      builder: (context, state) {
        if (state is ProfileInitial || state is ProfileLoading) {
          return const SliverFillRemaining(
              child: Center(child: CircularProgressIndicator()));
        }

        if (state is ProfileFailure) {
          return SliverFillRemaining(
            child: Center(
              child: Text(state.message,
                  style: TextStyles.font14Medium
                      .copyWith(color: ColorManager.normalGrey),
                  textAlign: TextAlign.center),
            ),
          );
        }

        final posts = state is ProfileSuccess ? state.posts : _cubit.posts;

        if (posts.isEmpty) {
          return SliverFillRemaining(
            child: Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.music_note_outlined,
                      size: 48.r, color: ColorManager.lighterGrey),
                  verticalSpace(12),
                  Text('No posts yet',
                      style: TextStyles.font16Medium
                          .copyWith(color: ColorManager.normalGrey)),
                ],
              ),
            ),
          );
        }

        return SliverMainAxisGroup(slivers: [
          SliverToBoxAdapter(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _SectionSpacer(),
                Padding(
                  padding: EdgeInsets.fromLTRB(20.w, 20.h, 20.w, 4.h),
                  child: Text('Posts', style: TextStyles.font18Semibold),
                ),
              ],
            ),
          ),
          SliverPadding(
            padding: EdgeInsets.fromLTRB(2.w, 8.h, 2.w, 32.h),
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
                      builder: (_) => PostDetailScreen(post: posts[i]),
                    ),
                  ),
                ),
                childCount: posts.length,
              ),
            ),
          ),
        ]);
      },
    );
  }
}

// ---------------------------------------------------------------------------
// Genre card
// ---------------------------------------------------------------------------

class _GenreCard extends StatelessWidget {
  const _GenreCard({required this.name});
  final String name;

  @override
  Widget build(BuildContext context) {
    final imagePath = _genreImages[name];
    final bg = _genreColors[name] ?? const Color(0xFFF5F5F5);
    final accent = _genreAccents[name] ?? ColorManager.normalGrey;

    return Container(
      width: 100.w,
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(20.r),
        border: Border.all(color: accent.withOpacity(0.25), width: 1.5),
        boxShadow: [
          BoxShadow(
            color: accent.withOpacity(0.12),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            width: 52.r,
            height: 52.r,
            decoration: BoxDecoration(
              color: ColorManager.white.withOpacity(0.7),
              shape: BoxShape.circle,
            ),
            child: imagePath != null
                ? Padding(
                    padding: EdgeInsets.all(8.r),
                    child: Image.asset(imagePath, fit: BoxFit.contain),
                  )
                : Icon(Icons.music_note_rounded, size: 28.r, color: accent),
          ),
          verticalSpace(10),
          Padding(
            padding: EdgeInsets.symmetric(horizontal: 8.w),
            child: Text(
              name,
              style: TextStyles.font12semiBold.copyWith(color: accent),
              textAlign: TextAlign.center,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Post thumbnail
// ---------------------------------------------------------------------------

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

// ---------------------------------------------------------------------------
// Shared small widgets
// ---------------------------------------------------------------------------

class _CountCell extends StatelessWidget {
  final int count;
  final String label;
  const _CountCell({required this.count, required this.label});

  String _fmt(int n) {
    if (n >= 1000000) return '${(n / 1000000).toStringAsFixed(1)}M';
    if (n >= 1000) return '${(n / 1000).toStringAsFixed(1)}K';
    return '$n';
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.symmetric(horizontal: 20.w),
      child: Column(
        children: [
          Text(_fmt(count), style: TextStyles.font20SemiBold),
          verticalSpace(2),
          Text(label,
              style: TextStyles.font12Medium
                  .copyWith(color: ColorManager.normalGrey)),
        ],
      ),
    );
  }
}

class _VertDivider extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      width: 1,
      color: ColorManager.lighterGrey,
      margin: EdgeInsets.symmetric(vertical: 4.h),
    );
  }
}

class _SectionSpacer extends StatelessWidget {
  @override
  Widget build(BuildContext context) =>
      Container(height: 8.h, color: const Color(0xFFF5F5F5));
}

class _SheetTile extends StatelessWidget {
  const _SheetTile(
      {required this.icon, required this.label, required this.onTap});
  final IconData icon;
  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return ListTile(
      onTap: onTap,
      contentPadding: EdgeInsets.symmetric(horizontal: 4.w),
      leading: Container(
        width: 40.r,
        height: 40.r,
        decoration: BoxDecoration(
          color: const Color(0xFFF5F5F5),
          borderRadius: BorderRadius.circular(12.r),
        ),
        child: Icon(icon, color: ColorManager.primaryBlack, size: 20.r),
      ),
      title: Text(label, style: TextStyles.font15semiBold),
    );
  }
}
