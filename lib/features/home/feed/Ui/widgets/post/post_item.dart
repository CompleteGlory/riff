// ignore_for_file: use_build_context_synchronously, deprecated_member_use
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:riff/core/networks/api_result.dart';
import 'package:riff/core/themes/colors/color_manager.dart';
import 'package:riff/core/themes/text_styles/text_styles.dart';
import 'package:riff/core/helpers/spacing.dart';
import 'package:riff/core/di/dependency_injection.dart';
import 'package:riff/features/home/feed/data/models/post.dart';
import 'package:riff/features/home/feed/data/models/comment.dart';
import 'package:riff/features/home/feed/Ui/widgets/comments/comment_sheet.dart';
import 'package:riff/features/home/feed/Ui/widgets/post/post_header.dart';
import 'package:riff/features/home/feed/Ui/widgets/post/post_content.dart';
import 'package:riff/features/home/feed/Ui/widgets/post/post_actions.dart';
import 'package:riff/features/home/feed/logic/cubit/posts/post_cubit.dart';
import 'package:riff/features/home/feed/logic/cubit/comments/comment_cubit.dart';

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
  late int commentCount;
  bool showHeart = false;
  late AnimationController _heartController;
  late Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();
    isLiked = widget.post.isLiked ?? false;
    likeCount = int.tryParse(widget.post.likesCount ?? '0') ?? 0;
    commentCount = int.tryParse(widget.post.commentsCount ?? '0') ?? 0;
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

    final postCubit = getIt<PostCubit>();

    if (!isLiked) {
      setState(() => showHeart = true);
      await _heartController.forward();
      await Future.delayed(const Duration(milliseconds: 200));
      await _heartController.reverse();
      setState(() => showHeart = false);
    }

    await postCubit.toggleLike(
      widget.post,
      onOptimisticUpdate: (newIsLiked, newLikeCount) {
        setState(() {
          isLiked = newIsLiked;
          likeCount = newLikeCount;
        });
      },
      onRevert: () {
        setState(() {
          isLiked = !isLiked;
          likeCount += isLiked ? 1 : -1;
        });
      },
      onError: (error) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            backgroundColor: ColorManager.primaryBlack,
            content: Text(
              error,
              style: TextStyles.font12Medium.copyWith(
                color: ColorManager.lighterGrey,
              ),
            ),
          ),
        );
      },
    );
  }

  void _openComments(String postId) async {
    final commentCubit = getIt<CommentCubit>();

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: ColorManager.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (_) => const Center(
        child: Padding(
          padding: EdgeInsets.all(24),
          child: CircularProgressIndicator(),
        ),
      ),
    );

    final result = await commentCubit.getPostComments(postId);
    Navigator.pop(context);

    result.when(
      success: (comments) {
        // Sync comment count with actual loaded comments
        setState(() => commentCount = comments.length);

        showModalBottomSheet(
          context: context,
          isScrollControlled: true,
          backgroundColor: ColorManager.white,
          shape: const RoundedRectangleBorder(
            borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
          ),
          builder: (_) => Padding(
            padding: EdgeInsets.all(16.w),
            child: CommentsSheet(
              comments: comments,
              postId: postId,
              initialCommentsCount: comments.length,
              onCommentCreated: (Comment newComment) {
                setState(() => commentCount++);
              },
            ),
          ),
        );
      },
      failure: (_) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Failed to load comments')),
        );
      },
    );
  }

  void _sharePost() {
    final postCubit = getIt<PostCubit>();
    postCubit.sharePost(widget.post);
  }

  @override
  Widget build(BuildContext context) {
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
            PostHeader(post: widget.post, onMoreTapped: () {}),
            verticalSpace(12),

            PostContent(
              post: widget.post,
              onImageDoubleTap: _toggleLike,
              showHeartAnimation: showHeart,
              heartAnimation: _scaleAnimation,
            ),
            verticalSpace(10),

            PostActions(
              isLiked: isLiked,
              likeCount: likeCount,
              commentCount: commentCount,
              onLikeTap: _toggleLike,
              onCommentTap: () => _openComments(widget.post.id.toString()),
              onShareTap: _sharePost,
            ),
          ],
        ),
      ),
    );
  }
}
