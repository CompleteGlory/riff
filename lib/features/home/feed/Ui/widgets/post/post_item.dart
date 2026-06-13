// ignore_for_file: use_build_context_synchronously, deprecated_member_use
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
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
import 'package:riff/features/home/feed/Ui/widgets/post/shared_post_card.dart';
import 'package:riff/features/home/feed/Ui/widgets/post/share_sheet.dart';
import 'package:riff/features/home/feed/Ui/post_detail_screen.dart';
import 'package:riff/features/home/core/logic/cubit/home_cubit.dart';
import 'package:riff/features/home/reels/ui/reels_screen.dart';
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
  late int shareCount;
  bool showHeart = false;
  late AnimationController _heartController;
  late Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();
    isLiked = widget.post.isLiked ?? false;
    likeCount = int.tryParse(widget.post.likesCount ?? '0') ?? 0;
    commentCount = int.tryParse(widget.post.commentsCount ?? '0') ?? 0;
    shareCount = widget.post.sharesCount ?? 0;
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
                color: Theme.of(context).dividerColor,
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
      backgroundColor: Theme.of(context).colorScheme.surface,
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
        setState(() => commentCount = comments.length);
        showModalBottomSheet(
          context: context,
          isScrollControlled: true,
          backgroundColor: Theme.of(context).colorScheme.surface,
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
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => ShareSheet(
        post: widget.post,
        onShare: (caption) async {
          await getIt<PostCubit>().sharePost(widget.post, caption: caption);
          if (mounted) {
            Navigator.pop(context);
            setState(() => shareCount++);
          }
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final cardColor = isDark ? const Color(0xFF1E1E1E) : Colors.white;
    final shadowColor = isDark ? Colors.transparent : Colors.black.withOpacity(0.05);

    return GestureDetector(
      // Single tap → open full post detail (like tapping a shared post card)
      onTap: () {
        HomeCubit? homeCubit;
        try { homeCubit = context.read<HomeCubit>(); } catch (_) {}
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => homeCubit != null
                ? BlocProvider.value(
                    value: homeCubit,
                    child: PostDetailScreen(post: widget.post),
                  )
                : PostDetailScreen(post: widget.post),
          ),
        );
      },
      child: Container(
      margin: EdgeInsets.symmetric(vertical: 6.h),
      decoration: BoxDecoration(
        color: cardColor,
        borderRadius: BorderRadius.circular(18.r),
        boxShadow: [
          BoxShadow(
            color: shadowColor,
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          Padding(
            padding: EdgeInsets.fromLTRB(14.w, 14.h, 8.w, 10.h),
            child: PostHeader(post: widget.post, onMoreTapped: () {}),
          ),

          // Shared original post card (only when this post is a share)
          if (widget.post.originalPost != null)
            SharedPostCard(
              originalPost: widget.post.originalPost!,
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
                            child: PostDetailScreen(post: widget.post.originalPost!),
                          )
                        : PostDetailScreen(post: widget.post.originalPost!),
                  ),
                );
              },
            ),

          // Content + images (no horizontal padding on images so they go edge to edge)
          Padding(
            padding: EdgeInsets.symmetric(horizontal: 14.w),
            child: PostContent(
              post: widget.post,
              onImageDoubleTap: _toggleLike,
              showHeartAnimation: showHeart,
              heartAnimation: _scaleAnimation,
              onVideoTap: (_) => Navigator.push(
                context,
                MaterialPageRoute(
                  fullscreenDialog: true,
                  builder: (_) => ReelsScreen(initialPost: widget.post),
                ),
              ),
            ),
          ),

          // Divider
          Padding(
            padding: EdgeInsets.symmetric(horizontal: 14.w),
            child: Column(
              children: [
                verticalSpace(12),
                Divider(
                  height: 1,
                  color: Theme.of(context).dividerColor,
                ),
                verticalSpace(10),
              ],
            ),
          ),

          // Actions
          Padding(
            padding: EdgeInsets.fromLTRB(14.w, 0, 14.w, 14.h),
            child: PostActions(
              isLiked: isLiked,
              likeCount: likeCount,
              commentCount: commentCount,
              shareCount: shareCount,
              onLikeTap: _toggleLike,
              onCommentTap: () => _openComments(widget.post.id.toString()),
              onShareTap: _sharePost,
            ),
          ),
        ],
      ),
      ),
    );
  }
}
