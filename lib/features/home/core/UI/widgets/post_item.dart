// ignore_for_file: deprecated_member_use

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:riff/core/themes/colors/color_manager.dart';
import 'package:riff/core/themes/text_styles/text_styles.dart';
import 'package:share_plus/share_plus.dart';

SizedBox verticalSpace(double height) => SizedBox(height: height.h);
SizedBox horizontalSpace(double width) => SizedBox(width: width.w);

class PostItem extends StatefulWidget {
  final String username;
  final String content;
  final String imageUrl;
  final String timeAgo;
  final int likes;
  final int comments;

  const PostItem({
    super.key,
    this.username = 'Magd Zaky',
    this.content =
        'Just jammed over a Dorian groove with my new Strat — tone heaven 🎶🔥',
    this.imageUrl = 'assets/images/logo_android.png',
    this.timeAgo = '2h ago',
    this.likes = 240,
    this.comments = 56,
  });

  @override
  State<PostItem> createState() => _PostItemState();
}

class _PostItemState extends State<PostItem>
    with SingleTickerProviderStateMixin {
  bool isLiked = false;
  int likeCount = 0;
  bool showHeart = false;
  late AnimationController _heartController;
  late Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();
    likeCount = widget.likes;

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
    HapticFeedback.mediumImpact(); // 🎯 Haptic feedback

    setState(() {
      isLiked = !isLiked;
      likeCount += isLiked ? 1 : -1;
    });

    // ❤️ Animate heart pop
    if (isLiked) {
      setState(() => showHeart = true);
      await _heartController.forward();
      await Future.delayed(const Duration(milliseconds: 200));
      await _heartController.reverse();
      setState(() => showHeart = false);
    }
  }

  void _openComments() {
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
              '💬 No comments yet. Be the first to say something!',
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
        '${widget.username} on Riff 🎸:\n${widget.content}\n\n#RiffApp #MusicCommunity';
    Share.share(textToShare);
  }

  void _openImage() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => FullScreenImage(imageUrl: widget.imageUrl),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 180),
      margin: EdgeInsets.symmetric( vertical: 10.h),
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
            /// 🧍 User Info
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
                    Text(widget.username, style: TextStyles.font15semiBold),
                    Text(widget.timeAgo,
                        style: TextStyles.font12regular.copyWith(
                          color: ColorManager.normalGrey,
                        )),
                  ],
                ),
              ],
            ),

            verticalSpace(12),

            /// 📝 Post Text
            Text(widget.content, style: TextStyles.font16Medium),
            verticalSpace(16),

            /// 🖼️ Post Image with Heart Animation
            GestureDetector(
              onDoubleTap: _toggleLike,
              onTap: _openImage,
              child: Stack(
                alignment: Alignment.center,
                children: [
                  ClipRRect(
                    borderRadius: BorderRadius.circular(12.r),
                    child: Image.asset(
                      widget.imageUrl,
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

            /// ❤️ 💬 🔗 Action Buttons
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
            Text('${widget.comments} comments',
                style: TextStyles.font14regular
                    .copyWith(color: ColorManager.normalGrey)),
          ],
        ),
      ),
    );
  }
}

/// 📸 Fullscreen Image Viewer
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
