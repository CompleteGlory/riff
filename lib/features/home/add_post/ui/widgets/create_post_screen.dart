// ignore_for_file: unused_element, deprecated_member_use

import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:image_picker/image_picker.dart';
import 'package:riff/core/helpers/spacing.dart';
import 'package:riff/core/themes/colors/color_manager.dart';
import 'package:riff/core/themes/text_styles/text_styles.dart';
import 'package:riff/core/widgets/button.dart';
import 'package:riff/features/home/add_post/data/models/create_post_request_model.dart';
import 'package:riff/features/home/add_post/logic/cubit/create_post_cubit.dart';
import 'package:riff/generated/l10n.dart';

// Platform colours used in the social-share banner.
const _igGradient = [Color(0xFFF58529), Color(0xFFDD2A7B), Color(0xFF8134AF)];
const _ttColor = Color(0xFF010101);

const _maxImages = 10;

class CreatePostScreen extends StatefulWidget {
  /// Optional pre-fill when opened via the share sheet (Instagram / TikTok).
  final String? initialCaption;
  final String? sourceUrl;
  final String? sourcePlatform;

  /// Optional media files shared from another app.
  final List<String>? initialMediaPaths;

  const CreatePostScreen({
    super.key,
    this.initialCaption,
    this.sourceUrl,
    this.sourcePlatform,
    this.initialMediaPaths,
  });

  @override
  State<CreatePostScreen> createState() => _CreatePostScreenState();
}

class _CreatePostScreenState extends State<CreatePostScreen> {
  final TextEditingController _contentController = TextEditingController();
  final ImagePicker _picker = ImagePicker();
  final List<File> _selectedFiles = [];

  /// For Spotify shares: the song/artist extracted from the shared text.
  /// Spotify share text looks like "Song – Artist" (already cleaned by captionText).
  /// We show this in the banner subtitle but do NOT pre-fill it into the caption
  /// field so the user writes their own commentary.
  String? get _spotifyTitle {
    final t = widget.initialCaption?.trim();
    if (t == null || t.isEmpty) return null;
    // Truncate to first 80 chars to avoid huge subtitle
    return t.length > 80 ? '${t.substring(0, 77)}…' : t;
  }

  @override
  void initState() {
    super.initState();

    // For IG/TikTok, pre-fill with the caption text from the share.
    // For Spotify we show the song title in the banner but leave caption blank
    // so the user writes their own post text.
    if (widget.sourcePlatform != 'spotify' &&
        widget.initialCaption != null &&
        widget.initialCaption!.isNotEmpty) {
      _contentController.text = widget.initialCaption!;
    }

    if (widget.initialMediaPaths != null && widget.initialMediaPaths!.isNotEmpty) {
      setState(() {
        _selectedFiles.addAll(widget.initialMediaPaths!.map((path) {
          if (path.startsWith('content://')) {
            return File.fromUri(Uri.parse(path));
          }
          return File(path);
        }));
      });
    }
  }

  @override
  void dispose() {
    _contentController.dispose();
    super.dispose();
  }

  bool _isVideoFile(File f) {
    final ext = f.path.split('.').last.toLowerCase();
    return ['mp4', 'mov', 'webm', 'avi', 'mkv'].contains(ext);
  }

  Future<void> _pickImages(ImageSource source) async {
    Navigator.pop(context);
    if (source == ImageSource.gallery) {
      final remaining = _maxImages - _selectedFiles.length;
      final picked = await _picker.pickMultiImage(
        maxWidth: 1280, imageQuality: 85, limit: remaining,
      );
      if (picked.isNotEmpty) {
        setState(() {
          for (final xf in picked) {
            if (_selectedFiles.length < _maxImages) _selectedFiles.add(File(xf.path));
          }
        });
      }
    } else {
      final picked = await _picker.pickImage(
        source: ImageSource.camera, maxWidth: 1280, imageQuality: 85,
      );
      if (picked != null) setState(() => _selectedFiles.add(File(picked.path)));
    }
  }

  Future<void> _pickVideo(ImageSource source) async {
    Navigator.pop(context);
    final picked = await _picker.pickVideo(source: source, maxDuration: const Duration(minutes: 5));
    if (picked != null) setState(() => _selectedFiles.add(File(picked.path)));
  }

  void _showMediaSheet() {
    if (_selectedFiles.length >= _maxImages) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          backgroundColor: ColorManager.primaryBlack,
          content: Text(S.of(context).maximumFilesAllowed(_maxImages),
              style: TextStyles.font14Medium.copyWith(color: ColorManager.white)),
        ),
      );
      return;
    }

    showModalBottomSheet(
      context: context,
      backgroundColor: Theme.of(context).colorScheme.surface,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(24.r))),
      builder: (ctx) => SafeArea(
        child: Padding(
          padding: EdgeInsets.fromLTRB(20.w, 12.h, 20.w, 20.h),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 40.w, height: 4.h,
                decoration: BoxDecoration(color: ColorManager.lighterGrey, borderRadius: BorderRadius.circular(99)),
              ),
              verticalSpace(16),
              _SheetTile(icon: Icons.photo_library_outlined, label: S.of(context).choosePhotos, onTap: () => _pickImages(ImageSource.gallery)),
              _SheetTile(icon: Icons.photo_camera_outlined, label: S.of(context).takeAPhoto, onTap: () => _pickImages(ImageSource.camera)),
              _SheetTile(icon: Icons.video_library_outlined, label: S.of(context).chooseVideo, onTap: () => _pickVideo(ImageSource.gallery)),
              _SheetTile(icon: Icons.videocam_outlined, label: S.of(context).recordVideo, onTap: () => _pickVideo(ImageSource.camera)),
            ],
          ),
        ),
      ),
    );
  }

  void _removeImage(int index) {
    setState(() => _selectedFiles.removeAt(index));
  }

  void _handlePost() {
    final content = _contentController.text.trim();
    if (content.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          backgroundColor: ColorManager.primaryBlack,
          content: Text(
            S.of(context).pleaseEnterContentBeforePosting,
            style: TextStyles.font14Medium.copyWith(
              color: ColorManager.lighterGrey,
            ),
          ),
        ),
      );
      return;
    }

    context.read<CreatePostCubit>().createPost(
          CreatePostRequestModel(
            content: content,
            sourceUrl: widget.sourceUrl,
            sourcePlatform: widget.sourcePlatform,
          ),
          mediaFiles: _selectedFiles.isEmpty ? null : List.of(_selectedFiles),
        );

    // Navigate back to home immediately — upload continues in the background
    // and the progress bar in HomeLayout keeps displaying.
    Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final isShare = widget.sourcePlatform != null;
    return Scaffold(
      body: SingleChildScrollView(
        padding: EdgeInsets.symmetric(vertical: 35.h, horizontal: 20.w),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              S.of(context).whatsOnYourMind,
              style: TextStyles.font28Bold,
            ),
            verticalSpace(20),

            // Social-share origin banner (shown when opened via share sheet)
            if (isShare) ...[
              _SocialShareBanner(
                platform: widget.sourcePlatform!,
                // For Spotify: extracted song title shown as subtitle in the banner.
                // For IG/TT: displayTitle is null (caption is already pre-filled above).
                displayTitle: widget.sourcePlatform == 'spotify'
                    ? _spotifyTitle
                    : null,
              ),
              verticalSpace(16),
            ],

            // Content input
            Container(
              decoration: BoxDecoration(
                color: isDark ? const Color(0xFF252525) : ColorManager.white,
                borderRadius: BorderRadius.circular(16.r),
                boxShadow: isDark ? [] : [
                  BoxShadow(
                    color: ColorManager.lighterGrey.withOpacity(0.5),
                    blurRadius: 10,
                    offset: const Offset(0, 5),
                  ),
                ],
              ),
              child: TextField(
                controller: _contentController,
                maxLines: 10,
                minLines: 5,
                keyboardType: TextInputType.multiline,
                style: TextStyles.font16Medium,
                decoration: InputDecoration(
                  hintText: isShare
                      ? S.of(context).addCaptionToShare
                      : S.of(context).shareYourMusicRiff,
                  hintStyle: TextStyles.font16Medium
                      .copyWith(color: ColorManager.normalGrey),
                  border: InputBorder.none,
                  contentPadding: EdgeInsets.all(16.w),
                ),
              ),
            ),

            verticalSpace(20),

            // Media section header
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(S.of(context).attachMedia, style: TextStyles.font15semiBold),
                if (_selectedFiles.isNotEmpty)
                  Text(
                    '${_selectedFiles.length}/$_maxImages',
                    style: TextStyles.font14Medium.copyWith(
                      color: ColorManager.normalGrey,
                    ),
                  ),
              ],
            ),
            verticalSpace(10),

            // Image grid or placeholder
            if (_selectedFiles.isEmpty)
              _MediaPickerPlaceholder(onTap: _showMediaSheet)
            else
              _ImageGrid(
                files: _selectedFiles,
                onRemove: _removeImage,
                onAddMore: _selectedFiles.length < _maxImages
                    ? _showMediaSheet
                    : null,
              ),

            verticalSpace(50),

            AppButton(
              onPressed: _handlePost,
              text: S.of(context).postBtn,
              isWhite: false,
            ),
          ],
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Image grid (existing picks + optional add-more cell)
// ---------------------------------------------------------------------------

class _ImageGrid extends StatelessWidget {
  const _ImageGrid({
    required this.files,
    required this.onRemove,
    this.onAddMore,
  });

  final List<File> files;
  final void Function(int index) onRemove;
  final VoidCallback? onAddMore;

  @override
  Widget build(BuildContext context) {
    final itemCount = files.length + (onAddMore != null ? 1 : 0);
    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 3,
        crossAxisSpacing: 8.w,
        mainAxisSpacing: 8.h,
        childAspectRatio: 1,
      ),
      itemCount: itemCount,
      itemBuilder: (_, i) {
        if (i < files.length) {
          final ext = files[i].path.split('.').last.toLowerCase();
          final isVid = ['mp4', 'mov', 'webm', 'avi', 'mkv'].contains(ext);
          return _ImageCell(file: files[i], onRemove: () => onRemove(i), isVideo: isVid);
        }
        // Add-more cell
        return GestureDetector(
          onTap: onAddMore,
          child: Container(
            decoration: BoxDecoration(
              color: const Color(0xFFF5F5F5),
              borderRadius: BorderRadius.circular(12.r),
              border: Border.all(color: ColorManager.lighterGrey),
            ),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.add_photo_alternate_outlined,
                    size: 28.r, color: ColorManager.normalGrey),
                verticalSpace(4),
                Text(
                  S.of(context).addMore,
                  style: TextStyles.font12semiBold.copyWith(
                    color: ColorManager.normalGrey,
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}

class _ImageCell extends StatelessWidget {
  const _ImageCell({required this.file, required this.onRemove, this.isVideo = false});
  final File file;
  final VoidCallback onRemove;
  final bool isVideo;

  @override
  Widget build(BuildContext context) {
    return Stack(
      fit: StackFit.expand,
      children: [
        ClipRRect(
          borderRadius: BorderRadius.circular(12.r),
          child: isVideo
              ? Container(
                  color: Colors.black87,
                  child: const Center(
                    child: Icon(Icons.play_circle_outline, color: Colors.white, size: 40),
                  ),
                )
              : Image.file(file, fit: BoxFit.cover),
        ),
        Positioned(
          top: 4.h,
          right: 4.w,
          child: GestureDetector(
            onTap: onRemove,
            child: Container(
              padding: const EdgeInsets.all(3),
              decoration: BoxDecoration(
                color: Colors.black.withOpacity(0.6),
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.close, color: Colors.white, size: 14),
            ),
          ),
        ),
      ],
    );
  }
}

// ---------------------------------------------------------------------------
// Empty placeholder
// ---------------------------------------------------------------------------

class _MediaPickerPlaceholder extends StatelessWidget {
  const _MediaPickerPlaceholder({required this.onTap});
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: double.infinity,
        height: 80.h,
        decoration: BoxDecoration(
          color: isDark ? const Color(0xFF252525) : ColorManager.white,
          borderRadius: BorderRadius.circular(16.r),
          border: Border.all(
            color: isDark ? const Color(0xFF2A2A2A) : ColorManager.lighterGrey,
          ),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.add_a_photo_outlined,
                color: isDark ? const Color(0xFFC6FF00) : ColorManager.primaryBlack,
                size: 28.r),
            verticalSpace(4),
            Text(
              S.of(context).tapToAddPhotosOrVideos,
              style: TextStyles.font14regular,
            ),
          ],
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Social-share origin banner
// ---------------------------------------------------------------------------

class _SocialShareBanner extends StatelessWidget {
  const _SocialShareBanner({required this.platform, this.displayTitle});
  final String platform;
  /// For Spotify: extracted song name / artist, shown as a subtitle.
  final String? displayTitle;

  bool get _isInstagram => platform == 'instagram';
  bool get _isTikTok    => platform == 'tiktok';
  bool get _isSpotify   => platform == 'spotify';

  String get _label {
    if (_isInstagram) return 'Instagram';
    if (_isTikTok)    return 'TikTok';
    return 'Spotify';
  }

  String get _logoUrl {
    if (_isInstagram) return 'https://logo.clearbit.com/instagram.com';
    if (_isTikTok)    return 'https://logo.clearbit.com/tiktok.com';
    return 'https://logo.clearbit.com/spotify.com';
  }

  Color get _color {
    if (_isInstagram) return const Color(0xFFDD2A7B);
    if (_isTikTok)    return const Color(0xFF010101);
    return const Color(0xFF1DB954);
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 14.w, vertical: 10.h),
      decoration: BoxDecoration(
        color: _color.withOpacity(0.10),
        borderRadius: BorderRadius.circular(12.r),
        border: Border.all(color: _color.withOpacity(0.5), width: 1),
      ),
      child: Row(
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(6.r),
            child: Image.network(
              _logoUrl,
              width: 24.r,
              height: 24.r,
              fit: BoxFit.contain,
              errorBuilder: (_, __, ___) => Icon(Icons.link_rounded, size: 24.r, color: _color),
            ),
          ),
          horizontalSpace(10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  'Sharing from $_label',
                  style: TextStyles.font14Medium.copyWith(color: _color),
                ),
                if (displayTitle != null && displayTitle!.isNotEmpty) ...[
                  SizedBox(height: 2.h),
                  Text(
                    displayTitle!,
                    style: TextStyles.font12Medium.copyWith(
                      color: _color.withOpacity(0.75),
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
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
