// ignore_for_file: unused_field, deprecated_member_use
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:riff/core/di/dependency_injection.dart';
import 'package:riff/core/helpers/constants.dart';
import 'package:riff/core/helpers/shared_pref_helper.dart';
import 'package:riff/core/helpers/spacing.dart';
import 'package:riff/core/helpers/time_ago.dart';
import 'package:riff/core/networks/api_result.dart';
import 'package:riff/core/themes/colors/color_manager.dart';
import 'package:riff/core/themes/text_styles/text_styles.dart';
import 'package:riff/core/widgets/button.dart';
import 'package:riff/core/widgets/tff.dart';
import 'package:riff/core/networks/api_constants.dart';
import 'package:riff/core/routing/animated_page_route.dart';
import 'package:riff/features/home/core/logic/cubit/home_cubit.dart';
import 'package:riff/features/home/feed/Ui/screens/report_comment_screen.dart';
import 'package:riff/features/home/feed/data/repos/report_repo.dart';
import 'package:riff/features/home/feed/logic/cubit/report/report_cubit.dart';
import 'package:riff/features/home/feed/data/models/author.dart';
import 'package:riff/features/home/feed/data/models/comment.dart';
import 'package:riff/features/home/feed/logic/cubit/comments/comment_cubit.dart';
import 'package:riff/features/home/user_profile/ui/user_profile_screen.dart';
import 'package:riff/generated/l10n.dart';

// ─────────────────────────────────────────────────────────────────────────────
// CommentsSheet — redesigned with animations and full dark-mode support
// ─────────────────────────────────────────────────────────────────────────────

class CommentsSheet extends StatefulWidget {
  final List<Comment> comments;
  final String postId;
  final int initialCommentsCount;
  final Function(Comment) onCommentCreated;

  const CommentsSheet({
    super.key,
    required this.comments,
    required this.postId,
    required this.initialCommentsCount,
    required this.onCommentCreated,
  });

  @override
  State<CommentsSheet> createState() => _CommentsSheetState();
}

class _CommentsSheetState extends State<CommentsSheet> {
  late List<Comment> _comments;
  final TextEditingController _controller = TextEditingController();
  final TextEditingController _editController = TextEditingController();
  final Set<dynamic> _pendingIds = {};
  final Map<dynamic, bool> _commentLikes = {};
  bool _isSending = false;
  String? _errorMessage;
  String? _currentUserId;
  String? _currentUserImageUrl;
  dynamic _editingCommentId;
  dynamic _heartCommentId; // tracks which comment is showing the double-tap heart

  @override
  void initState() {
    super.initState();
    _comments = List.from(widget.comments);
    _initializeCommentLikes();
    _loadCurrentUserId();
  }

  void _initializeCommentLikes() {
    for (var comment in _comments) {
      _commentLikes[comment.id] = comment.isLiked ?? false;
    }
  }

  Future<void> _loadCurrentUserId() async {
    _currentUserId = await SharedPrefHelper.getString(SharedPrefKeys.userId);
    _currentUserImageUrl =
        await SharedPrefHelper.getString(SharedPrefKeys.userProfileImage);
    if (mounted) setState(() {});
  }

  @override
  void dispose() {
    _controller.dispose();
    _editController.dispose();
    super.dispose();
  }

  bool _isCommentMine(Comment comment) =>
      _currentUserId != null && comment.author?.id == _currentUserId;

  Future<void> _sendComment() async {
    final text = _controller.text.trim();
    if (text.isEmpty) return;

    setState(() {
      _isSending = true;
      _errorMessage = null;
    });

    final tempId = -DateTime.now().millisecondsSinceEpoch;
    final tempAuthor = Author(
      id: _currentUserId?.isNotEmpty == true ? _currentUserId! : 'me',
      fullName: S.of(context).youLabel,
      username: '',
      profileImageUrl: _currentUserImageUrl,
    );
    final tempComment = Comment(
      id: tempId,
      content: text,
      author: tempAuthor,
      createdAt: DateTime.now().toIso8601String(),
    );

    setState(() {
      _comments.insert(0, tempComment);
      _pendingIds.add(tempId);
      _commentLikes[tempId] = false;
      _controller.clear();
    });

    final commentCubit = getIt<CommentCubit>();
    final res = await commentCubit.createComment(widget.postId, text);

    setState(() => _isSending = false);

    res.when(
      success: (comment) {
        final index = _comments.indexWhere((c) => c.id == tempId);
        if (index != -1) {
          setState(() {
            _comments[index] = comment;
            _pendingIds.remove(tempId);
            _commentLikes[comment.id] = comment.isLiked ?? false;
          });
        }
        widget.onCommentCreated(comment);
      },
      failure: (_) {
        setState(() {
          _comments.removeWhere((c) => c.id == tempId);
          _pendingIds.remove(tempId);
          _commentLikes.remove(tempId);
          _errorMessage = S.of(context).failedToSendComment;
        });
        Future.delayed(const Duration(seconds: 3), () {
          if (mounted) setState(() => _errorMessage = null);
        });
      },
    );
  }

  Future<void> _likeComment(Comment comment) async {
    final isCurrentlyLiked = _commentLikes[comment.id] ?? false;
    setState(() => _commentLikes[comment.id] = !isCurrentlyLiked);

    final commentCubit = getIt<CommentCubit>();
    final res = isCurrentlyLiked
        ? await commentCubit.unlikeComment(comment.id.toString())
        : await commentCubit.likeComment(comment.id.toString());

    res.when(
      success: (_) {},
      failure: (_) {
        setState(() => _commentLikes[comment.id] = isCurrentlyLiked);
        _showErrorSnackBar(S.of(context).failedToUpdateLike);
      },
    );
  }

  Future<void> _deleteComment(Comment comment) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(S.of(context).deleteCommentTitle, style: TextStyles.font28Bold),
        content: Text(
          S.of(context).areYouSureDeleteComment,
          style: TextStyles.font16Medium,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text(S.of(context).cancelBtn, style: TextStyles.font14regular),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: Text(
              'Delete',
              style: TextStyles.font14regular.copyWith(color: ColorManager.red),
            ),
          ),
        ],
      ),
    );

    if (confirmed != true) return;

    final res = await getIt<CommentCubit>().deleteComment(comment.id.toString());
    res.when(
      success: (_) {
        setState(() {
          _comments.removeWhere((c) => c.id == comment.id);
          _commentLikes.remove(comment.id);
        });
        _showSuccessSnackBar(S.of(context).commentDeleted);
      },
      failure: (_) => _showErrorSnackBar(S.of(context).failedToDeleteComment),
    );
  }

  Future<void> _updateComment(Comment comment) async {
    final text = _editController.text.trim();
    if (text.isEmpty) return;

    final previousContent = comment.content;

    setState(() {
      final index = _comments.indexWhere((c) => c.id == comment.id);
      if (index != -1) {
        _comments[index] = Comment(
          id: comment.id,
          content: text,
          author: comment.author,
          createdAt: comment.createdAt,
          isLiked: comment.isLiked,
        );
      }
      _editingCommentId = null;
      _editController.clear();
    });

    final res = await getIt<CommentCubit>().updateComment(comment.id.toString(), text);
    res.when(
      success: (_) => _showSuccessSnackBar(S.of(context).commentUpdated),
      failure: (_) {
        setState(() {
          final index = _comments.indexWhere((c) => c.id == comment.id);
          if (index != -1) {
            _comments[index] = Comment(
              id: comment.id,
              content: previousContent,
              author: comment.author,
              createdAt: comment.createdAt,
              isLiked: comment.isLiked,
            );
          }
        });
        _showErrorSnackBar(S.of(context).failedToUpdateComment);
      },
    );
  }

  void _onDoubleTapComment(Comment comment) {
    final isPending = _pendingIds.contains(comment.id) || (comment.id ?? 0) < 0;
    if (isPending) return;
    // Like if not already liked (always show the heart burst regardless)
    if (!(_commentLikes[comment.id] ?? false)) {
      _likeComment(comment);
    }
    setState(() => _heartCommentId = comment.id);
    Future.delayed(const Duration(milliseconds: 750), () {
      if (mounted && _heartCommentId == comment.id) {
        setState(() => _heartCommentId = null);
      }
    });
  }

  void _navigateToProfile(String? userId) {
    if (userId == null || userId.isEmpty) return;
    HomeCubit? homeCubit;
    try {
      homeCubit = context.read<HomeCubit>();
    } catch (_) {}
    Navigator.push(
      context,
      FadeSlidePageRoute(
        page: homeCubit != null
            ? BlocProvider.value(
                value: homeCubit,
                child: UserProfileScreen(userId: userId),
              )
            : UserProfileScreen(userId: userId),
      ),
    );
  }

  void _showCommentOptions(Comment comment) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    showModalBottomSheet(
      context: context,
      backgroundColor: isDark ? const Color(0xFF1E1E1E) : Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            verticalSpace(10),
            Container(
              width: 40.w,
              height: 4.h,
              decoration: BoxDecoration(
                color: ColorManager.lighterGrey,
                borderRadius: BorderRadius.circular(10.r),
              ),
            ),
            verticalSpace(16),
            if (_isCommentMine(comment)) ...[
              _OptionTile(
                icon: Icons.edit_outlined,
                label: S.of(context).editLabel,
                onTap: () {
                  Navigator.pop(context);
                  _showEditDialog(comment);
                },
              ),
              _OptionTile(
                icon: Icons.delete_outline,
                label: S.of(context).deleteBtn,
                color: ColorManager.red,
                onTap: () {
                  Navigator.pop(context);
                  _deleteComment(comment);
                },
              ),
            ] else
              _OptionTile(
                icon: Icons.flag_outlined,
                label: S.of(context).reportLabel,
                onTap: () {
                  Navigator.pop(context);
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => BlocProvider(
                        create: (_) => ReportCubit(getIt<ReportRepo>()),
                        child: ReportCommentScreen(
                          commentId: comment.id.toString(),
                          commentPreview: comment.content ?? '',
                        ),
                      ),
                    ),
                  );
                },
              ),
            verticalSpace(8),
          ],
        ),
      ),
    );
  }

  void _showEditDialog(Comment comment) {
    _editController.text = comment.content!;
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(S.of(context).editCommentTitle, style: TextStyles.font28Bold),
        content: SizedBox(
          width: 300.w,
          child: TextField(
            controller: _editController,
            maxLines: 4,
            decoration: InputDecoration(
              hintText: S.of(context).editYourComment,
              hintStyle: TextStyles.font14regular.copyWith(
                color: ColorManager.normalGrey,
              ),
              enabledBorder: const OutlineInputBorder(
                borderRadius: BorderRadius.all(Radius.circular(8)),
                borderSide: BorderSide(color: ColorManager.normalGrey),
              ),
              focusedBorder: const OutlineInputBorder(
                borderRadius: BorderRadius.all(Radius.circular(8)),
                borderSide: BorderSide(color: ColorManager.normalGrey),
              ),
              border: OutlineInputBorder(
                borderRadius: const BorderRadius.all(Radius.circular(8)),
                borderSide: BorderSide(color: ColorManager.primaryBlack),
              ),
            ),
          ),
        ),
        actions: [
          SizedBox(
            width: 120.w,
            child: AppButton(
              onPressed: () => Navigator.pop(context),
              text: S.of(context).cancelBtn,
              isWhite: false,
            ),
          ),
          SizedBox(
            width: 120.w,
            child: AppButton(
              onPressed: () {
                Navigator.pop(context);
                _updateComment(comment);
              },
              text: S.of(context).updateBtn,
              isWhite: true,
            ),
          ),
        ],
      ),
    );
  }

  void _showErrorSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        backgroundColor: ColorManager.primaryBlack,
        content: Text(
          message,
          style: TextStyles.font12Medium.copyWith(color: ColorManager.white),
        ),
      ),
    );
  }

  void _showSuccessSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        backgroundColor: ColorManager.primaryBlack,
        content: Text(
          message,
          style: TextStyles.font12Medium.copyWith(color: ColorManager.white),
        ),
      ),
    );
  }

  // ─────────────────────────────────────────────────────────────────────────
  // Build
  // ─────────────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    final onSurface = Theme.of(context).colorScheme.onSurface;
    final keyboardInset = MediaQuery.of(context).viewInsets.bottom;

    return AnimatedPadding(
      padding: EdgeInsets.only(bottom: keyboardInset),
      duration: const Duration(milliseconds: 250),
      curve: Curves.easeOut,
      child: Container(
        constraints: BoxConstraints(maxHeight: 540.h),
        padding: EdgeInsets.only(top: 10.h),
        child: Column(
          children: [
            // ── Drag handle ────────────────────────────────────────────────
            _DragHandle(),
            verticalSpace(14),

            // ── Header ─────────────────────────────────────────────────────
            Padding(
              padding: EdgeInsets.symmetric(horizontal: 20.w),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  Text(S.of(context).commentsLabel, style: TextStyles.font18Semibold),
                  SizedBox(width: 8.w),
                  _CountBadge(count: _comments.length),
                ],
              ),
            ),
            verticalSpace(12),
            Divider(height: 1, color: Theme.of(context).dividerColor),

            // ── Error banner ───────────────────────────────────────────────
            AnimatedSwitcher(
              duration: const Duration(milliseconds: 280),
              transitionBuilder: (child, animation) => SlideTransition(
                position: Tween<Offset>(
                  begin: const Offset(0, -1),
                  end: Offset.zero,
                ).animate(CurvedAnimation(
                  parent: animation,
                  curve: Curves.easeOutCubic,
                )),
                child: FadeTransition(opacity: animation, child: child),
              ),
              child: _errorMessage != null
                  ? _ErrorBanner(
                      key: const ValueKey('error'),
                      message: _errorMessage!,
                      onDismiss: () => setState(() => _errorMessage = null),
                    )
                  : const SizedBox.shrink(key: ValueKey('no-error')),
            ),

            // ── Comment list / empty state ─────────────────────────────────
            Expanded(
              child: _comments.isEmpty
                  ? _EmptyCommentsState()
                  : ListView.separated(
                      padding: EdgeInsets.fromLTRB(16.w, 8.h, 16.w, 8.h),
                      itemCount: _comments.length,
                      separatorBuilder: (_, __) => Divider(
                        height: 1,
                        color: Theme.of(context).dividerColor.withOpacity(0.5),
                      ),
                      itemBuilder: (context, index) {
                        final c = _comments[index];
                        final isPending =
                            _pendingIds.contains(c.id) || (c.id ?? 0) < 0;
                        final isLiked = _commentLikes[c.id] ?? false;

                        return TweenAnimationBuilder<double>(
                          key: ValueKey(c.id),
                          tween: Tween(begin: 0.0, end: 1.0),
                          duration: const Duration(milliseconds: 350),
                          curve: Curves.easeOutCubic,
                          builder: (_, value, child) => Opacity(
                            opacity: value,
                            child: Transform.translate(
                              offset: Offset(0, 16 * (1 - value)),
                              child: child,
                            ),
                          ),
                          child: GestureDetector(
                            onDoubleTap: () => _onDoubleTapComment(c),
                            behavior: HitTestBehavior.opaque,
                            child: Stack(
                              alignment: Alignment.center,
                              children: [
                                Opacity(
                                  opacity: isPending ? 0.55 : 1.0,
                                  child: Padding(
                                    padding: EdgeInsets.symmetric(vertical: 12.h),
                                    child: Row(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        // Avatar — tappable → navigate to profile
                                        GestureDetector(
                                          onTap: () => _navigateToProfile(c.author?.id),
                                          child: _CommentAvatar(author: c.author),
                                        ),
                                        horizontalSpace(10),

                                        // Content column
                                        Expanded(
                                          child: Column(
                                            crossAxisAlignment:
                                                CrossAxisAlignment.start,
                                            children: [
                                              // Name + options
                                              Row(
                                                crossAxisAlignment:
                                                    CrossAxisAlignment.center,
                                                children: [
                                                  // Name — tappable → navigate to profile
                                                  Expanded(
                                                    child: GestureDetector(
                                                      onTap: () => _navigateToProfile(c.author?.id),
                                                      behavior: HitTestBehavior.opaque,
                                                      child: Text(
                                                        c.author?.fullName ?? '',
                                                        style: TextStyles.font14semiBold
                                                            .copyWith(color: onSurface),
                                                        maxLines: 1,
                                                        overflow: TextOverflow.ellipsis,
                                                      ),
                                                    ),
                                                  ),
                                                  GestureDetector(
                                                    onTap: () =>
                                                        _showCommentOptions(c),
                                                    behavior:
                                                        HitTestBehavior.opaque,
                                                    child: Padding(
                                                      padding: EdgeInsets.only(
                                                          left: 8.w),
                                                      child: Icon(
                                                        Icons.more_horiz,
                                                        color:
                                                            ColorManager.normalGrey,
                                                        size: 18.r,
                                                      ),
                                                    ),
                                                  ),
                                                ],
                                              ),
                                              verticalSpace(4),

                                              // Comment text
                                              Text(
                                                c.content ?? '',
                                                style: TextStyles.font14regular
                                                    .copyWith(
                                                  color: onSurface.withOpacity(0.78),
                                                ),
                                              ),
                                              verticalSpace(6),

                                              // Time + like
                                              Row(
                                                children: [
                                                  Text(
                                                    timeAgo(c.createdAt),
                                                    style: TextStyles.font12regular
                                                        .copyWith(
                                                      color: ColorManager.normalGrey,
                                                    ),
                                                  ),
                                                  if (!isPending) ...[
                                                    horizontalSpace(14),
                                                    _LikeButton(
                                                      isLiked: isLiked,
                                                      onTap: () => _likeComment(c),
                                                    ),
                                                  ],
                                                ],
                                              ),
                                            ],
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ),

                                // ── Double-tap heart burst overlay ──────────
                                if (_heartCommentId == c.id)
                                  IgnorePointer(
                                    child: _CommentHeartFlash(key: ValueKey('heart_${c.id}')),
                                  ),
                              ],
                            ),
                          ),
                        );
                      },
                    ),
            ),

            // ── Input area ─────────────────────────────────────────────────
            Container(
              padding: EdgeInsets.fromLTRB(16.w, 10.h, 16.w, 14.h),
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.surface,
                border: Border(
                  top: BorderSide(
                    color: Theme.of(context).dividerColor,
                  ),
                ),
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Expanded(
                    child: AppTextField(
                      controller: _controller,
                      keyboardType: TextInputType.text,
                      isPassword: false,
                      hintText: S.of(context).addAComment,
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return S.of(context).commentCannotBeEmpty;
                        }
                        return null;
                      },
                    ),
                  ),
                  horizontalSpace(10),
                  AnimatedSwitcher(
                    duration: const Duration(milliseconds: 220),
                    transitionBuilder: (child, anim) => ScaleTransition(
                      scale: CurvedAnimation(
                          parent: anim, curve: Curves.easeOutBack),
                      child: FadeTransition(opacity: anim, child: child),
                    ),
                    child: _isSending
                        ? Container(
                            key: const ValueKey('loading'),
                            width: 40.r,
                            height: 40.r,
                            padding: EdgeInsets.all(10.r),
                            decoration: BoxDecoration(
                              color: ColorManager.accent.withOpacity(0.15),
                              shape: BoxShape.circle,
                            ),
                            child: CircularProgressIndicator(
                              strokeWidth: 2.5,
                              color: ColorManager.accent,
                            ),
                          )
                        : GestureDetector(
                            key: const ValueKey('send'),
                            onTap: _sendComment,
                            child: Container(
                              width: 40.r,
                              height: 40.r,
                              padding: EdgeInsets.all(9.r),
                              decoration: const BoxDecoration(
                                color: ColorManager.accent,
                                shape: BoxShape.circle,
                              ),
                              child: SvgPicture.asset(
                                'assets/svgs/send.svg',
                                colorFilter: const ColorFilter.mode(
                                  Colors.black,
                                  BlendMode.srcIn,
                                ),
                              ),
                            ),
                          ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Helper widgets
// ─────────────────────────────────────────────────────────────────────────────

class _DragHandle extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Center(
      child: Container(
        width: 40.w,
        height: 4.h,
        decoration: BoxDecoration(
          color: Theme.of(context).dividerColor,
          borderRadius: BorderRadius.circular(10.r),
        ),
      ),
    );
  }
}

class _CountBadge extends StatelessWidget {
  final int count;
  const _CountBadge({required this.count});

  @override
  Widget build(BuildContext context) {
    return AnimatedSwitcher(
      duration: const Duration(milliseconds: 220),
      transitionBuilder: (child, anim) =>
          ScaleTransition(scale: anim, child: child),
      child: Container(
        key: ValueKey(count),
        padding: EdgeInsets.symmetric(horizontal: 8.w, vertical: 2.h),
        decoration: BoxDecoration(
          color: ColorManager.accent.withOpacity(0.18),
          borderRadius: BorderRadius.circular(20.r),
        ),
        child: Text(
          '$count',
          style: TextStyles.font12semiBold.copyWith(color: ColorManager.accent),
        ),
      ),
    );
  }
}

class _ErrorBanner extends StatelessWidget {
  final String message;
  final VoidCallback onDismiss;
  const _ErrorBanner(
      {super.key, required this.message, required this.onDismiss});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.fromLTRB(16.w, 6.h, 16.w, 0),
      child: Container(
        padding: EdgeInsets.symmetric(horizontal: 14.w, vertical: 10.h),
        decoration: BoxDecoration(
          color: ColorManager.red.withOpacity(0.08),
          borderRadius: BorderRadius.circular(10.r),
          border: Border.all(color: ColorManager.red.withOpacity(0.28)),
        ),
        child: Row(
          children: [
            Icon(Icons.error_outline, color: ColorManager.red, size: 18.r),
            SizedBox(width: 8.w),
            Expanded(
              child: Text(
                message,
                style:
                    TextStyles.font12Medium.copyWith(color: ColorManager.red),
              ),
            ),
            GestureDetector(
              onTap: onDismiss,
              child:
                  Icon(Icons.close, color: ColorManager.red, size: 16.r),
            ),
          ],
        ),
      ),
    );
  }
}

class _EmptyCommentsState extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Center(
      child: TweenAnimationBuilder<double>(
        tween: Tween(begin: 0.0, end: 1.0),
        duration: const Duration(milliseconds: 700),
        curve: Curves.elasticOut,
        builder: (_, value, child) => Transform.scale(
          scale: value.clamp(0.0, 1.2),
          child: Opacity(
            opacity: value.clamp(0.0, 1.0),
            child: child,
          ),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.chat_bubble_outline_rounded,
              size: 52.r,
              color: ColorManager.accent,
            ),
            SizedBox(height: 14.h),
            Text(
              S.of(context).noCommentsYet,
              style: TextStyles.font16Medium.copyWith(
                color: Theme.of(context).colorScheme.onSurface,
              ),
            ),
            SizedBox(height: 4.h),
            Text(
              S.of(context).beFirstToSaySomething,
              style: TextStyles.font14regular.copyWith(
                color: ColorManager.normalGrey,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Animated like/unlike button with icon swap animation
class _LikeButton extends StatelessWidget {
  final bool isLiked;
  final VoidCallback onTap;
  const _LikeButton({required this.isLiked, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          AnimatedSwitcher(
            duration: const Duration(milliseconds: 220),
            transitionBuilder: (child, anim) => ScaleTransition(
              scale: CurvedAnimation(parent: anim, curve: Curves.easeOutBack),
              child: child,
            ),
            child: SvgPicture.asset(
              isLiked
                  ? 'assets/svgs/Heart-filled.svg'
                  : 'assets/svgs/Heart.svg',
              key: ValueKey(isLiked),
              width: 14.w,
              height: 14.h,
              colorFilter: ColorFilter.mode(
                isLiked ? ColorManager.red : ColorManager.normalGrey,
                BlendMode.srcIn,
              ),
            ),
          ),
          SizedBox(width: 4.w),
          AnimatedSwitcher(
            duration: const Duration(milliseconds: 180),
            transitionBuilder: (child, anim) => FadeTransition(
              opacity: anim,
              child: child,
            ),
            child: Text(
              isLiked ? S.of(context).unlike : S.of(context).likeBtn,
              key: ValueKey(isLiked),
              style: TextStyles.font12regular.copyWith(
                color: isLiked ? ColorManager.red : ColorManager.normalGrey,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// Option row inside the comment options sheet
class _OptionTile extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color? color;
  final VoidCallback onTap;

  const _OptionTile({
    required this.icon,
    required this.label,
    required this.onTap,
    this.color,
  });

  @override
  Widget build(BuildContext context) {
    final c = color ?? Theme.of(context).colorScheme.onSurface;
    return ListTile(
      leading: Icon(icon, color: c, size: 22.r),
      title: Text(
        label,
        style: TextStyles.font14regular.copyWith(color: c),
      ),
      onTap: onTap,
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Heart burst shown on double-tap — scale up then fade out
// ─────────────────────────────────────────────────────────────────────────────

class _CommentHeartFlash extends StatefulWidget {
  const _CommentHeartFlash({super.key});

  @override
  State<_CommentHeartFlash> createState() => _CommentHeartFlashState();
}

class _CommentHeartFlashState extends State<_CommentHeartFlash>
    with SingleTickerProviderStateMixin {
  late final AnimationController _ctrl;
  late final Animation<double> _scale;
  late final Animation<double> _opacity;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 700),
    );

    // Scale: pops in then settles
    _scale = TweenSequence<double>([
      TweenSequenceItem(tween: Tween(begin: 0.2, end: 1.25), weight: 35),
      TweenSequenceItem(tween: Tween(begin: 1.25, end: 1.0), weight: 20),
      TweenSequenceItem(tween: ConstantTween(1.0), weight: 45),
    ]).animate(CurvedAnimation(parent: _ctrl, curve: Curves.easeOut));

    // Opacity: fade in quickly, hold, then fade out
    _opacity = TweenSequence<double>([
      TweenSequenceItem(tween: Tween(begin: 0.0, end: 1.0), weight: 15),
      TweenSequenceItem(tween: ConstantTween(1.0), weight: 45),
      TweenSequenceItem(tween: Tween(begin: 1.0, end: 0.0), weight: 40),
    ]).animate(_ctrl);

    _ctrl.forward();
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _ctrl,
      builder: (_, __) => Opacity(
        opacity: _opacity.value,
        child: Transform.scale(
          scale: _scale.value,
          child: Icon(
            Icons.favorite,
            color: ColorManager.red,
            size: 64.r,
          ),
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Comment avatar — profile image or initials fallback
// ─────────────────────────────────────────────────────────────────────────────

class _CommentAvatar extends StatelessWidget {
  const _CommentAvatar({this.author});
  final Author? author;

  @override
  Widget build(BuildContext context) {
    final rawUrl = author?.profileImageUrl;
    final imageUrl = rawUrl == null || rawUrl.isEmpty
        ? null
        : rawUrl.startsWith('http')
            ? rawUrl
            : '${ApiConstants.apiBASEURL}$rawUrl';

    final initials = (author?.fullName ?? '')
        .trim()
        .split(RegExp(r'\s+'))
        .where((w) => w.isNotEmpty)
        .take(2)
        .map((w) => w[0].toUpperCase())
        .join();

    return CircleAvatar(
      radius: 18.r,
      backgroundColor: ColorManager.lighterGrey,
      backgroundImage: imageUrl != null ? NetworkImage(imageUrl) : null,
      child: imageUrl == null
          ? Text(
              initials.isEmpty ? '?' : initials,
              style: TextStyle(
                fontSize: 11.sp,
                fontWeight: FontWeight.w600,
                color: ColorManager.normalGrey,
              ),
            )
          : null,
    );
  }
}
