// ignore_for_file: use_build_context_synchronously, deprecated_member_use
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_svg/svg.dart';
import 'package:riff/core/helpers/constants.dart';
import 'package:riff/core/helpers/shared_pref_helper.dart';
import 'package:riff/core/helpers/spacing.dart';
import 'package:riff/core/helpers/time_ago.dart';
import 'package:riff/core/networks/api_result.dart';
import 'package:riff/core/themes/colors/color_manager.dart';
import 'package:riff/core/themes/text_styles/text_styles.dart';
import 'package:riff/features/home/feed/Ui/widgets/comment_sheet.dart';
import 'package:riff/features/home/feed/Ui/widgets/fullscsreen_image.dart';
import 'package:riff/features/home/feed/Ui/widgets/post_options.dart';
import 'package:riff/features/home/feed/data/models/post.dart';
import 'package:share_plus/share_plus.dart';
import 'package:riff/core/di/dependency_injection.dart';
import 'package:riff/features/home/feed/data/models/comment.dart';
import 'package:riff/features/home/feed/logic/cubit/feed_cubit.dart';
import 'package:riff/features/home/feed/logic/cubit/like_post_cubit.dart';

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
  late String currentUserId;

  @override
  void initState() {
    super.initState();
    isLiked = widget.post.isLiked ?? false;
    // The likesCount is a String, parse it safely
    likeCount = int.tryParse(widget.post.likesCount ?? '0') ?? 0;

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
    // Optimistic UI update
    final previousLiked = isLiked;
    final previousLikeCount = likeCount;

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

    // Call cubit to like/unlike the post and reconcile
    final likeCubit = getIt<LikePostCubit>();
    final postId = (widget.post.id).toString();

    try {
      final feedCubit = getIt<FeedCubit>();
      if (isLiked) {
        // we just liked the post
        final result = await likeCubit.likePost(postId);
        result.when(
          success: (liked) {
            if (liked) {
              try {
                feedCubit.updatePostLikeLocally(postId, isLiked, likeCount);
              } catch (_) {}
            } else {
              setState(() {
                isLiked = previousLiked;
                likeCount = previousLikeCount;
              });
            }
          },
          failure: (_) {
            setState(() {
              isLiked = previousLiked;
              likeCount = previousLikeCount;
            });
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                backgroundColor: ColorManager.primaryBlack,
                content: Text(
                  'Failed to update like. Please try again.',
                  style: TextStyles.font12Medium.copyWith(
                    color: ColorManager.lighterGrey,
                  ),
                ),
              ),
            );
          },
        );
      } else {
        // we just unliked the post
        final result = await likeCubit.unlikePost(postId);
        result.when(
          success: (ok) {
            if (ok) {
              try {
                feedCubit.updatePostLikeLocally(postId, isLiked, likeCount);
              } catch (_) {}
            } else {
              setState(() {
                isLiked = previousLiked;
                likeCount = previousLikeCount;
              });
            }
          },
          failure: (_) {
            setState(() {
              isLiked = previousLiked;
              likeCount = previousLikeCount;
            });
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                backgroundColor: ColorManager.primaryBlack,
                content: Text(
                  'Failed to update like. Please try again.',
                  style: TextStyles.font12Medium.copyWith(
                    color: ColorManager.lighterGrey,
                  ),
                ),
              ),
            );
          },
        );
      }
    } catch (e) {
      // revert on unexpected error
      setState(() {
        isLiked = previousLiked;
        likeCount = previousLikeCount;
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          backgroundColor: ColorManager.primaryBlack,
          content: Text(
            'Failed to update like. Please try again.',
            style: TextStyles.font12Medium.copyWith(
              color: ColorManager.lighterGrey,
            ),
          ),
        ),
      );
    }
  }

  void _openComments(String postId) async {
  final feedCubit = getIt<FeedCubit>();

  // show loading first
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

  final result = await feedCubit.getPostComments(postId);

  Navigator.pop(context); // close loading sheet

  result.when(
    success: (comments) {
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
              // optional: local update
            },
          ),
        ),
      );
    },
    failure: (_) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Failed to load comments'),
        ),
      );
    },
  );
}


  void _sharePost() {
    final textToShare =
        '${widget.post.author?.fullName ?? "Unknown"} on Riff 🎸:\n${widget.post.content ?? ""}\n\n#RiffApp #MusicCommunity';
    Share.share(textToShare);
  }

  void _openImage(String imageUrl) {
    if (imageUrl.isEmpty) return;
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => FullScreenImage(imageUrl: imageUrl)),
    );
  }

  @override
  Widget build(BuildContext context) {
    // FIX: Safely access the media list. Use the null-aware operator `?`
    // If widget.post.media is null or empty, mediaUrl will be an empty string.
    final mediaUrl =
        widget.post.media?.firstWhere(
          (e) => e.isNotEmpty,
          orElse: () =>
              '', // If media is not null but empty, or no item is not empty
        ) ??
        '';

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
                    Text(
                      widget.post.author?.fullName ?? "Unknown",
                      style: TextStyles.font15semiBold,
                    ),
                    Text(
                      timeAgo(widget.post.createdAt),
                      style: TextStyles.font12regular.copyWith(
                        color: ColorManager.normalGrey,
                      ),
                    ),
                  ],
                ),
                const Spacer(),
                IconButton(
                  icon: const Icon(Icons.more_horiz),
                  onPressed: () async {
                    currentUserId =
                        await SharedPrefHelper.getString(
                          SharedPrefKeys.userId,
                        ) ??
                        "";
                    final isMine = widget.post.author?.id == currentUserId;

                    showPostOptions(
                      isMine: isMine,
                      context: context,
                      post: widget.post,
                    );
                  },
                ),
              ],
            ),
            verticalSpace(12),

            // Post Content
            Text(widget.post.content ?? "", style: TextStyles.font16Medium),
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
                        child: const Icon(
                          Icons.favorite,
                          color: ColorManager.red,
                          size: 100,
                        ),
                      ),
                  ],
                ),
              ),
            verticalSpace(10),
            // Action Buttons
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                GestureDetector(
                  onTap: _toggleLike,
                  child: SvgPicture.asset(
                    isLiked
                        ? "assets/svgs/Heart-filled.svg"
                        : "assets/svgs/Heart.svg",
                    width: 24.w,
                    height: 24.h,
                    color: isLiked
                        ? ColorManager.red
                        : ColorManager.primaryBlack,
                  ),
                ),
                GestureDetector(
                  onTap: () => _openComments((widget.post.id).toString()),
                  child: SvgPicture.asset(
                    "assets/svgs/Chat.svg",
                    width: 24.w,
                    height: 24.h,
                    color: ColorManager.primaryBlack,
                  ),
                ),
                GestureDetector(
                  onTap: _sharePost,
                  child: SvgPicture.asset(
                    "assets/svgs/share.svg",
                    width: 32.w,
                    height: 32.h,
                    color: ColorManager.primaryBlack,
                  ),
                ),
              ],
            ),
            verticalSpace(4),
            Padding(
              padding:  EdgeInsets.symmetric(horizontal: 33.w,),
              child: Text(
                '$likeCount likes',
                style: TextStyles.font14semiBold.copyWith(
                  color: ColorManager.darkGrey,
                ),
              ),
            ),   
            verticalSpace(4),
          ],
        ),
      ),
    );
  }
}

