// ignore_for_file: deprecated_member_use

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:riff/core/helpers/spacing.dart';
import 'package:riff/core/themes/colors/color_manager.dart';
import 'package:riff/core/themes/text_styles/text_styles.dart';
import 'package:riff/features/home/feed/data/models/post.dart';
import 'package:share_plus/share_plus.dart';


class PostItem extends StatefulWidget {
  final Post post;

  const PostItem({super.key, required this.post});

  @override
  State<PostItem> createState() => _PostItemState();
}

class _PostItemState extends State<PostItem>
    with SingleTickerProviderStateMixin {
  late bool isLiked;
  late int likeCount;
  bool showHeart = false;
  late AnimationController _heartController;
  late Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();
    isLiked = widget.post.isLiked?? false;
    // The likesCount is a String, parse it safely
    likeCount = int.tryParse(widget.post.likesCount) ?? 0; 

    _heartController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 400),
    );

    _scaleAnimation = Tween<double>(begin: 0.5, end: 1.5).animate(
      CurvedAnimation(parent: _heartController, curve: Curves.easeOutBack),
    );
  }

  @override
  void dispose() {
    _heartController.dispose();
    super.dispose();
  }

  void _toggleLike() async {
    HapticFeedback.mediumImpact();

    // NOTE: You'll likely need to call a cubit method here to update the like status on the server.

    setState(() {
      isLiked = !isLiked;
      likeCount += isLiked ? 1 : -1;
    });

    if (isLiked) {
      setState(() => showHeart = true);
      await _heartController.forward();
      await Future.delayed(const Duration(milliseconds: 200));
      await _heartController.reverse();
      setState(() => showHeart = false);
    }
  }

  void _openComments() {
    // FIX: Safely access comments list, use null-aware operator
    final commentsCount = widget.post.comments?.length ?? 0;
    
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      backgroundColor: ColorManager.white,
      builder: (context) => Padding(
        padding: EdgeInsets.all(16.w),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 50.w,
              height: 5.h,
              decoration: BoxDecoration(
                color: ColorManager.lighterGrey,
                borderRadius: BorderRadius.circular(10.r),
              ),
            ),
            verticalSpace(16),
            Text('Comments', style: TextStyles.font18Semibold),
            verticalSpace(16),
            Text(
              // FIX: Use the calculated commentsCount
              commentsCount == 0
                  ? '💬 No comments yet. Be the first to say something!'
                  : '💬 $commentsCount comments',
              style: TextStyles.font14regular.copyWith(
                color: ColorManager.normalGrey,
              ),
            ),
            verticalSpace(20),
          ],
        ),
      ),
    );
  }

  void _sharePost() {
    final textToShare =
        '${widget.post.author.fullName} on Riff 🎸:\n${widget.post.content}\n\n#RiffApp #MusicCommunity';
    Share.share(textToShare);
  }

  void _openImage(String imageUrl) {
    if (imageUrl.isEmpty) return;
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => FullScreenImage(imageUrl: imageUrl),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    // FIX: Safely access the media list. Use the null-aware operator `?`
    // If widget.post.media is null or empty, mediaUrl will be an empty string.
    final mediaUrl = widget.post.media?.firstWhere(
        (e) => e.isNotEmpty, 
        orElse: () => '' // If media is not null but empty, or no item is not empty
    ) ?? ''; 
    
    final commentsCount = widget.post.comments?.length ?? 0;

    return AnimatedContainer(
      duration: const Duration(milliseconds: 180),
      margin: EdgeInsets.symmetric(vertical: 10.h),
      decoration: BoxDecoration(
        color: ColorManager.white,
        borderRadius: BorderRadius.circular(20.r),
        boxShadow: [
          BoxShadow(
            color: ColorManager.lighterGrey.withOpacity(0.5),
            blurRadius: 12,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Padding(
        padding: EdgeInsets.all(16.w),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // User Info
            Row(
              children: [
                const CircleAvatar(
                  radius: 22,
                  backgroundColor: ColorManager.lighterGrey,
                  child: Icon(Icons.person, color: ColorManager.white),
                ),
                horizontalSpace(12),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(widget.post.author.fullName,
                        style: TextStyles.font15semiBold),
                    Text(_formatTimeAgo(widget.post.createdAt),
                        style: TextStyles.font12regular
                            .copyWith(color: ColorManager.normalGrey)),
                  ],
                ),
              ],
            ),
            verticalSpace(12),

            // Post Content
            Text(widget.post.content, style: TextStyles.font16Medium),
            verticalSpace(16),

            // Post Image with Heart Animation
            if (mediaUrl.isNotEmpty)
              GestureDetector(
                onDoubleTap: _toggleLike,
                onTap: () => _openImage(mediaUrl),
                child: Stack(
                  alignment: Alignment.center,
                  children: [
                    ClipRRect(
                      borderRadius: BorderRadius.circular(12.r),
                      // NOTE: If mediaUrl contains a network path, you must use Image.network
                      // If it's a local asset, keep Image.asset
                      child: Image.asset( 
                        mediaUrl,
                        width: double.infinity,
                        height: 220.h,
                        fit: BoxFit.cover,
                      ),
                    ),
                    if (showHeart)
                      ScaleTransition(
                        scale: _scaleAnimation,
                        child: const Icon(Icons.favorite,
                            color: ColorManager.red, size: 100),
                      ),
                  ],
                ),
              ),
            verticalSpace(10),

            // Action Buttons
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                IconButton(
                  icon: Icon(
                    isLiked ? Icons.favorite : Icons.favorite_border,
                    color: isLiked ? ColorManager.red : ColorManager.darkGrey,
                  ),
                  onPressed: _toggleLike,
                ),
                IconButton(
                  icon: const Icon(Icons.comment_outlined),
                  onPressed: _openComments,
                ),
                IconButton(
                  icon: const Icon(Icons.share_outlined),
                  onPressed: _sharePost,
                ),
              ],
            ),
            verticalSpace(4),
            Text('$likeCount likes',
                style: TextStyles.font14semiBold
                    .copyWith(color: ColorManager.darkGrey)),
            verticalSpace(4),
            // FIX: Use the calculated commentsCount
            Text('$commentsCount comments', 
                style: TextStyles.font14regular
                    .copyWith(color: ColorManager.normalGrey)),
          ],
        ),
      ),
    );
  }

  String _formatTimeAgo(String createdAt) {
    try {
      final createdDate = DateTime.parse(createdAt);
      final diff = DateTime.now().difference(createdDate);

      if (diff.inSeconds < 60) return "Just now";
      if (diff.inMinutes < 60) return "${diff.inMinutes}m ago";
      if (diff.inHours < 24) return "${diff.inHours}h ago";
      return "${diff.inDays}d ago";
    } catch (_) {
      return "Just now";
    }
  }
}

// Fullscreen Image Viewer
class FullScreenImage extends StatelessWidget {
  final String imageUrl;
  const FullScreenImage({super.key, required this.imageUrl});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(
        children: [
          Center(
            child: InteractiveViewer(
              // NOTE: If mediaUrl is a network path, this should be Image.network
              child: Image.asset(imageUrl, fit: BoxFit.contain), 
            ),
          ),
          Positioned(
            top: 40.h,
            right: 20.w,
            child: IconButton(
              icon: const Icon(Icons.close, color: Colors.white, size: 30),
              onPressed: () => Navigator.pop(context),
            ),
          ),
        ],
      ),
    );
  }
}