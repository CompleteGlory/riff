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
import 'package:riff/features/home/feed/Ui/widgets/post/fullscsreen_image.dart';
import 'package:riff/features/home/feed/Ui/widgets/post/post_item.dart';
import 'package:riff/features/home/profile/logic/cubit/profile_cubit.dart';

// ---------------------------------------------------------------------------
// Genre → asset image map
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

// ---------------------------------------------------------------------------
// UserProfile model
// ---------------------------------------------------------------------------

class UserProfile {
  final String id;
  final String fullName;
  final String username;
  final String email;
  final String? provider;
  final List<String>? instruments;
  final List<String>? genres;
  final String? profileImageUrl;

  const UserProfile({
    required this.id,
    required this.fullName,
    required this.username,
    required this.email,
    this.provider,
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
                  style: TextStyles.font14Medium.copyWith(
                    color: ColorManager.white,
                  ),
                ),
              ),
            );
          } else if (state is ProfileImageUploadFailure) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                behavior: SnackBarBehavior.floating,
                backgroundColor: ColorManager.red,
                content: Text(state.message,
                    style: TextStyles.font14Medium.copyWith(
                        color: ColorManager.white)),
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

  // ── Header ────────────────────────────────────────────────────────────────

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
            // Avatar + edit badge
            BlocBuilder<ProfileCubit, ProfileState>(
              buildWhen: (_, s) =>
                  s is ProfileImageUploading || s is ProfileImageUploadSuccess || s is ProfileImageUploadFailure,
              builder: (context, state) {
                final isUploading = state is ProfileImageUploading;
                return Stack(
                  children: [
                    // Avatar — tap opens fullscreen (if image exists)
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
                            color: ColorManager.lighterGrey,
                            width: 3,
                          ),
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
                    // Camera badge — tap opens upload sheet
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
                            border: Border.all(
                              color: ColorManager.white,
                              width: 2,
                            ),
                          ),
                          child: isUploading
                              ? Padding(
                                  padding: const EdgeInsets.all(6),
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                    color: ColorManager.white,
                                  ),
                                )
                              : Icon(
                                  Icons.camera_alt_rounded,
                                  size: 14.r,
                                  color: ColorManager.white,
                                ),
                        ),
                      ),
                    ),
                  ],
                );
              },
            ),

            verticalSpace(16),

            // Name
            Text(
              widget.profile.fullName,
              style: TextStyles.font20SemiBold,
              textAlign: TextAlign.center,
            ),
            verticalSpace(4),

            // Username
            Text(
              '@${widget.profile.username}',
              style: TextStyles.font14Medium.copyWith(
                color: ColorManager.normalGrey,
              ),
            ),

            verticalSpace(16),

            // Posts count pill
            BlocBuilder<ProfileCubit, ProfileState>(
              buildWhen: (_, s) => s is ProfileSuccess,
              builder: (context, state) {
                final count =
                    state is ProfileSuccess ? state.posts.length : 0;
                return Container(
                  padding: EdgeInsets.symmetric(horizontal: 20.w, vertical: 8.h),
                  decoration: BoxDecoration(
                    color: const Color(0xFFF5F5F5),
                    borderRadius: BorderRadius.circular(99),
                  ),
                  child: Text(
                    '$count ${count == 1 ? 'Post' : 'Posts'}',
                    style: TextStyles.font14semiBold.copyWith(
                      color: ColorManager.darkGrey,
                    ),
                  ),
                );
              },
            ),
          ],
        ),
      ),
    );
  }

  // ── Genres ────────────────────────────────────────────────────────────────

  Widget _buildGenresSection(List<String> genres) {
    return SliverToBoxAdapter(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _SectionDivider(),
          Padding(
            padding: EdgeInsets.fromLTRB(20.w, 20.h, 20.w, 14.h),
            child: Text('Genres', style: TextStyles.font18Semibold),
          ),
          SizedBox(
            height: 110.h,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              physics: const BouncingScrollPhysics(),
              padding: EdgeInsets.symmetric(horizontal: 20.w),
              itemCount: genres.length,
              separatorBuilder: (_, __) => SizedBox(width: 12.w),
              itemBuilder: (_, i) => _GenreCard(name: genres[i]),
            ),
          ),
          verticalSpace(20),
        ],
      ),
    );
  }

  // ── Posts ─────────────────────────────────────────────────────────────────

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
            child: Center(child: CircularProgressIndicator()),
          );
        }

        if (state is ProfileFailure) {
          return SliverFillRemaining(
            child: Center(
              child: Text(
                state.message,
                style: TextStyles.font14Medium.copyWith(
                    color: ColorManager.normalGrey),
                textAlign: TextAlign.center,
              ),
            ),
          );
        }

        final posts =
            state is ProfileSuccess ? state.posts : _cubit.posts;

        if (posts.isEmpty) {
          return SliverFillRemaining(
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
          );
        }

        return SliverMainAxisGroup(slivers: [
          SliverToBoxAdapter(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _SectionDivider(),
                Padding(
                  padding: EdgeInsets.fromLTRB(20.w, 20.h, 20.w, 4.h),
                  child: Text('Posts', style: TextStyles.font18Semibold),
                ),
              ],
            ),
          ),
          SliverPadding(
            padding: EdgeInsets.fromLTRB(16.w, 8.h, 16.w, 32.h),
            sliver: SliverList.separated(
              itemCount: posts.length,
              separatorBuilder: (_, __) => SizedBox(height: 2.h),
              itemBuilder: (_, i) => PostItem(post: posts[i]),
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
    return Container(
      width: 80.w,
      decoration: BoxDecoration(
        color: ColorManager.white,
        borderRadius: BorderRadius.circular(16.r),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.07),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          if (imagePath != null)
            Image.asset(imagePath,
                width: 46.r, height: 46.r, fit: BoxFit.contain)
          else
            Icon(Icons.music_note_rounded,
                size: 40.r, color: ColorManager.normalGrey),
          verticalSpace(8),
          Padding(
            padding: EdgeInsets.symmetric(horizontal: 6.w),
            child: Text(
              name,
              style: TextStyles.font12semiBold.copyWith(
                color: ColorManager.primaryBlack,
              ),
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
// Section divider
// ---------------------------------------------------------------------------

class _SectionDivider extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      height: 8.h,
      color: const Color(0xFFF5F5F5),
    );
  }
}

// ---------------------------------------------------------------------------
// Bottom sheet tile
// ---------------------------------------------------------------------------

class _SheetTile extends StatelessWidget {
  const _SheetTile({
    required this.icon,
    required this.label,
    required this.onTap,
  });

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
