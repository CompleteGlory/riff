// ignore_for_file: deprecated_member_use
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:image_picker/image_picker.dart';
import 'package:riff/core/helpers/spacing.dart';
import 'package:riff/core/networks/api_constants.dart';
import 'package:riff/core/themes/colors/color_manager.dart';
import 'package:riff/core/themes/text_styles/text_styles.dart';
import 'package:riff/core/widgets/button.dart';
import 'package:riff/features/home/add_post/logic/cubit/update_post_cubit.dart';
import 'package:riff/features/home/feed/Ui/widgets/post/shared_post_card.dart';
import 'package:riff/features/home/feed/data/models/post.dart';

const _maxMedia = 10;

class UpdatePostScreen extends StatefulWidget {
  final Post post;

  const UpdatePostScreen({super.key, required this.post});

  @override
  State<UpdatePostScreen> createState() => _UpdatePostScreenState();
}

class _UpdatePostScreenState extends State<UpdatePostScreen> {
  late TextEditingController _contentController;
  final ImagePicker _picker = ImagePicker();

  /// Existing media URLs the user wants to keep.
  late List<String> _keepUrls;

  /// Newly picked files to upload.
  final List<File> _newFiles = [];

  /// True when this post is a share (quotes another post). For shares the user
  /// can only edit the caption they wrote above the shared post.
  late bool _isShare;

  int get _totalCount => _keepUrls.length + _newFiles.length;

  /// Whether the media picker should be shown. Shares don't carry their own
  /// media, so we only show it for normal posts.
  bool get _showMedia => !_isShare;

  @override
  void initState() {
    super.initState();
    _isShare = widget.post.originalPost != null;
    _contentController = TextEditingController(text: widget.post.content ?? '');
    _keepUrls = List<String>.from(widget.post.media ?? []);
  }

  @override
  void dispose() {
    _contentController.dispose();
    super.dispose();
  }

  // ── Media helpers ──────────────────────────────────────────────────────────

  Future<void> _pickImages(ImageSource source) async {
    Navigator.pop(context);
    if (source == ImageSource.gallery) {
      final remaining = _maxMedia - _totalCount;
      final picked = await _picker.pickMultiImage(
        maxWidth: 1280, imageQuality: 85, limit: remaining,
      );
      if (picked.isNotEmpty) {
        setState(() {
          for (final xf in picked) {
            if (_totalCount < _maxMedia) _newFiles.add(File(xf.path));
          }
        });
      }
    } else {
      final picked = await _picker.pickImage(
        source: ImageSource.camera, maxWidth: 1280, imageQuality: 85,
      );
      if (picked != null && _totalCount < _maxMedia) {
        setState(() => _newFiles.add(File(picked.path)));
      }
    }
  }

  Future<void> _pickVideo(ImageSource source) async {
    Navigator.pop(context);
    if (_totalCount >= _maxMedia) return;
    final picked = await _picker.pickVideo(
      source: source, maxDuration: const Duration(minutes: 5),
    );
    if (picked != null) setState(() => _newFiles.add(File(picked.path)));
  }

  void _showMediaSheet() {
    if (_totalCount >= _maxMedia) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        backgroundColor: ColorManager.primaryBlack,
        content: Text('Maximum $_maxMedia files allowed.',
            style: TextStyles.font14Medium.copyWith(color: ColorManager.white)),
      ));
      return;
    }
    final isDark = Theme.of(context).brightness == Brightness.dark;
    showModalBottomSheet(
      context: context,
      backgroundColor: Theme.of(context).colorScheme.surface,
      shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(24.r))),
      builder: (ctx) => SafeArea(
        child: Padding(
          padding: EdgeInsets.fromLTRB(20.w, 12.h, 20.w, 20.h),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 40.w, height: 4.h,
                decoration: BoxDecoration(
                    color: isDark
                        ? const Color(0xFF3A3A3A)
                        : ColorManager.lighterGrey,
                    borderRadius: BorderRadius.circular(99)),
              ),
              verticalSpace(16),
              _SheetTile(
                  icon: Icons.photo_library_outlined,
                  label: 'Choose Photos',
                  onTap: () => _pickImages(ImageSource.gallery)),
              _SheetTile(
                  icon: Icons.photo_camera_outlined,
                  label: 'Take a Photo',
                  onTap: () => _pickImages(ImageSource.camera)),
              _SheetTile(
                  icon: Icons.video_library_outlined,
                  label: 'Choose Video',
                  onTap: () => _pickVideo(ImageSource.gallery)),
              _SheetTile(
                  icon: Icons.videocam_outlined,
                  label: 'Record Video',
                  onTap: () => _pickVideo(ImageSource.camera)),
            ],
          ),
        ),
      ),
    );
  }

  void _removeExisting(int index) =>
      setState(() => _keepUrls.removeAt(index));

  void _removeNew(int index) =>
      setState(() => _newFiles.removeAt(index));

  // ── Submit ─────────────────────────────────────────────────────────────────

  void _handleUpdate() {
    final content = _contentController.text.trim();
    if (content.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        backgroundColor: ColorManager.primaryBlack,
        content: Text('Please enter content before updating.',
            style: TextStyles.font14Medium
                .copyWith(color: ColorManager.lighterGrey)),
      ));
      return;
    }

    context.read<UpdatePostCubit>().updatePost(
          postId: widget.post.id.toString(),
          content: content,
          keepMedia: List<String>.from(_keepUrls),
          newFiles: _newFiles.isEmpty ? null : List<File>.from(_newFiles),
        );
  }

  // ── Build ──────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final cardColor = isDark ? const Color(0xFF252525) : ColorManager.white;

    return Scaffold(
      appBar: AppBar(
        title: Text('Edit Post', style: TextStyles.font28Bold),
        elevation: 0,
      ),
      body: SingleChildScrollView(
        padding: EdgeInsets.symmetric(vertical: 24.h, horizontal: 20.w),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Caption / content label for shared posts
            if (_isShare) ...[
              Text('Your caption', style: TextStyles.font15semiBold),
              verticalSpace(8),
            ],

            // Content field
            Container(
              decoration: BoxDecoration(
                color: cardColor,
                borderRadius: BorderRadius.circular(16.r),
                boxShadow: [
                  BoxShadow(
                    color: isDark
                        ? Colors.black.withOpacity(0.3)
                        : ColorManager.lighterGrey.withOpacity(0.5),
                    blurRadius: 10,
                    offset: const Offset(0, 5),
                  ),
                ],
              ),
              child: TextField(
                controller: _contentController,
                maxLines: 10,
                minLines: _isShare ? 3 : 5,
                keyboardType: TextInputType.multiline,
                style: TextStyles.font16Medium,
                decoration: InputDecoration(
                  hintText: _isShare
                      ? 'Add a caption to your share…'
                      : 'Share your latest music riff, thoughts, or gear...',
                  hintStyle: TextStyles.font16Medium
                      .copyWith(color: ColorManager.normalGrey),
                  border: InputBorder.none,
                  contentPadding: EdgeInsets.all(16.w),
                ),
              ),
            ),

            // Shared-post preview (read-only)
            if (_isShare) ...[
              verticalSpace(16),
              Text('Shared post', style: TextStyles.font15semiBold),
              verticalSpace(4),
              // SharedPostCard adds its own horizontal margin; cancel it so it
              // lines up with the rest of the form.
              Transform.translate(
                offset: Offset(-14.w, 0),
                child: SharedPostCard(originalPost: widget.post.originalPost!),
              ),
            ],

            // Media section (normal posts only)
            if (_showMedia) ...[
              verticalSpace(20),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text('Media', style: TextStyles.font15semiBold),
                  if (_totalCount > 0)
                    Text('$_totalCount/$_maxMedia',
                        style: TextStyles.font14Medium
                            .copyWith(color: ColorManager.normalGrey)),
                ],
              ),
              verticalSpace(10),
              if (_totalCount == 0)
                _MediaPickerPlaceholder(onTap: _showMediaSheet)
              else
                _MediaGrid(
                  keepUrls: _keepUrls,
                  newFiles: _newFiles,
                  onRemoveExisting: _removeExisting,
                  onRemoveNew: _removeNew,
                  onAddMore: _totalCount < _maxMedia ? _showMediaSheet : null,
                ),
            ],

            verticalSpace(50),

            AppButton(
              onPressed: _handleUpdate,
              text: 'Save Changes',
              isWhite: false,
            ),
          ],
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Grid: existing URL cells + new File cells + optional add-more cell
// ─────────────────────────────────────────────────────────────────────────────

class _MediaGrid extends StatelessWidget {
  const _MediaGrid({
    required this.keepUrls,
    required this.newFiles,
    required this.onRemoveExisting,
    required this.onRemoveNew,
    this.onAddMore,
  });

  final List<String> keepUrls;
  final List<File> newFiles;
  final void Function(int) onRemoveExisting;
  final void Function(int) onRemoveNew;
  final VoidCallback? onAddMore;

  bool _isVideo(String path) {
    final ext = path.split('.').last.toLowerCase();
    return ['mp4', 'mov', 'webm', 'avi', 'mkv'].contains(ext);
  }

  String _fullUrl(String url) =>
      url.startsWith('/') ? '${ApiConstants.apiBASEURL}$url' : url;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final totalSlots = keepUrls.length + newFiles.length + (onAddMore != null ? 1 : 0);

    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 3,
        crossAxisSpacing: 8.w,
        mainAxisSpacing: 8.h,
        childAspectRatio: 1,
      ),
      itemCount: totalSlots,
      itemBuilder: (_, i) {
        // Existing URL cells
        if (i < keepUrls.length) {
          final url = keepUrls[i];
          return _UrlCell(
            url: _fullUrl(url),
            isVideo: _isVideo(url),
            onRemove: () => onRemoveExisting(i),
          );
        }

        // New file cells
        final newIndex = i - keepUrls.length;
        if (newIndex < newFiles.length) {
          final f = newFiles[newIndex];
          final isVid = _isVideo(f.path);
          return _FileCell(
            file: f,
            isVideo: isVid,
            onRemove: () => onRemoveNew(newIndex),
          );
        }

        // Add-more cell
        return GestureDetector(
          onTap: onAddMore,
          child: Container(
            decoration: BoxDecoration(
              color: isDark ? const Color(0xFF252525) : const Color(0xFFF5F5F5),
              borderRadius: BorderRadius.circular(12.r),
              border: Border.all(
                color: isDark
                    ? const Color(0xFF2A2A2A)
                    : ColorManager.lighterGrey,
              ),
            ),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.add_photo_alternate_outlined,
                    size: 28.r, color: ColorManager.normalGrey),
                verticalSpace(4),
                Text('Add more',
                    style: TextStyles.font12semiBold
                        .copyWith(color: ColorManager.normalGrey)),
              ],
            ),
          ),
        );
      },
    );
  }
}

// ── Existing URL cell ─────────────────────────────────────────────────────────

class _UrlCell extends StatelessWidget {
  const _UrlCell(
      {required this.url, required this.isVideo, required this.onRemove});
  final String url;
  final bool isVideo;
  final VoidCallback onRemove;

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
                    child: Icon(Icons.play_circle_outline,
                        color: Colors.white, size: 40),
                  ),
                )
              : Image.network(url, fit: BoxFit.cover,
                  errorBuilder: (_, __, ___) => Container(
                    color: ColorManager.lighterGrey,
                    child: Icon(Icons.broken_image_outlined,
                        color: ColorManager.normalGrey),
                  )),
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
                  shape: BoxShape.circle),
              child:
                  const Icon(Icons.close, color: Colors.white, size: 14),
            ),
          ),
        ),
      ],
    );
  }
}

// ── New File cell ─────────────────────────────────────────────────────────────

class _FileCell extends StatelessWidget {
  const _FileCell(
      {required this.file, required this.isVideo, required this.onRemove});
  final File file;
  final bool isVideo;
  final VoidCallback onRemove;

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
                    child: Icon(Icons.play_circle_outline,
                        color: Colors.white, size: 40),
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
                  shape: BoxShape.circle),
              child:
                  const Icon(Icons.close, color: Colors.white, size: 14),
            ),
          ),
        ),
      ],
    );
  }
}

// ── Empty placeholder ─────────────────────────────────────────────────────────

class _MediaPickerPlaceholder extends StatelessWidget {
  const _MediaPickerPlaceholder({required this.onTap});
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final fg = Theme.of(context).colorScheme.onSurface;
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
            Icon(Icons.add_a_photo_outlined, color: fg, size: 28.r),
            verticalSpace(4),
            Text('Tap to add photos or videos',
                style: TextStyles.font14regular.copyWith(color: fg)),
          ],
        ),
      ),
    );
  }
}

// ── Bottom sheet tile ─────────────────────────────────────────────────────────

class _SheetTile extends StatelessWidget {
  const _SheetTile(
      {required this.icon, required this.label, required this.onTap});
  final IconData icon;
  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final fg = Theme.of(context).colorScheme.onSurface;
    return ListTile(
      onTap: onTap,
      contentPadding: EdgeInsets.symmetric(horizontal: 4.w),
      leading: Container(
        width: 40.r,
        height: 40.r,
        decoration: BoxDecoration(
          color: isDark ? const Color(0xFF2A2A2A) : const Color(0xFFF5F5F5),
          borderRadius: BorderRadius.circular(12.r),
        ),
        child: Icon(icon, color: fg, size: 20.r),
      ),
      title: Text(label, style: TextStyles.font15semiBold),
    );
  }
}
