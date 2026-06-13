// ignore_for_file: unused_field, deprecated_member_use
import 'package:flutter/material.dart';
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
import 'package:riff/features/home/feed/data/models/author.dart';
import 'package:riff/features/home/feed/data/models/comment.dart';
import 'package:riff/features/home/feed/logic/cubit/comments/comment_cubit.dart';

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
    setState(() {});
  }

  @override
  void dispose() {
    _controller.dispose();
    _editController.dispose();
    super.dispose();
  }

  bool _isCommentMine(Comment comment) {
    return _currentUserId != null && comment.author?.id == _currentUserId;
  }

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
      fullName: 'You',
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
          _errorMessage = 'Failed to send comment';
        });
        Future.delayed(const Duration(seconds: 3), () {
          if (mounted) {
            setState(() => _errorMessage = null);
          }
        });
      },
    );
  }

  Future<void> _likeComment(Comment comment) async {
    final commentId = comment.id.toString();
    final isCurrentlyLiked = _commentLikes[comment.id] ?? false;

    // Optimistic update
    setState(() {
      _commentLikes[comment.id] = !isCurrentlyLiked;
    });

    final commentCubit = getIt<CommentCubit>();
    final res = isCurrentlyLiked
        ? await commentCubit.unlikeComment(commentId)
        : await commentCubit.likeComment(commentId);

    res.when(
      success: (_) {
        // Like/unlike successful, state already updated optimistically
      },
      failure: (_) {
        // Revert optimistic update
        setState(() {
          _commentLikes[comment.id] = isCurrentlyLiked;
        });
        _showErrorSnackBar('Failed to update like');
      },
    );
  }

  Future<void> _deleteComment(Comment comment) async {
    final commentId = comment.id.toString();

    // Show confirmation dialog
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title:  Text('Delete Comment',style: TextStyles.font28Bold,),
        content: Text('Are you sure you want to delete this comment?',style: TextStyles.font16Medium,),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text('Cancel',style: TextStyles.font14regular,),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child:  Text(
              'Delete',
              style: TextStyles.font14regular.copyWith(color: ColorManager.red),
            ),
          ),
        ],
      ),
    );

    if (confirmed != true) return;

    final commentCubit = getIt<CommentCubit>();
    final res = await commentCubit.deleteComment(commentId);

    res.when(
      success: (_) {
        setState(() {
          _comments.removeWhere((c) => c.id == comment.id);
          _commentLikes.remove(comment.id);
        });
        _showSuccessSnackBar('Comment deleted');
      },
      failure: (_) {
        _showErrorSnackBar('Failed to delete comment');
      },
    );
  }

  Future<void> _updateComment(Comment comment) async {
    final text = _editController.text.trim();
    if (text.isEmpty) return;

    final commentId = comment.id.toString();
    final previousContent = comment.content;

    // Optimistic update
    setState(() {
      final index = _comments.indexWhere((c) => c.id == comment.id);
      if (index != -1) {
        final updatedComment = Comment(
          id: comment.id,
          content: text,
          author: comment.author,
          createdAt: comment.createdAt,
          isLiked: comment.isLiked,
        );
        _comments[index] = updatedComment;
      }
      _editingCommentId = null;
      _editController.clear();
    });

    final commentCubit = getIt<CommentCubit>();
    final res = await commentCubit.updateComment(commentId, text);

    res.when(
      success: (updatedComment) {
        // Update confirmed
        setState(() {
          final index = _comments.indexWhere((c) => c.id == comment.id);
          if (index != -1) {
            _comments[index] = Comment(
              id: comment.id,
              content: text, createdAt: comment.createdAt,
              author: comment.author,
              isLiked: comment.isLiked,
             
            );
          }
        });
        _showSuccessSnackBar('Comment updated');
      },
      failure: (_) {
        // Revert optimistic update
        setState(() {
          final index = _comments.indexWhere((c) => c.id == comment.id);
          if (index != -1) {
            final revertedComment = Comment(
              id: comment.id,
              content: previousContent,
              author: comment.author,
              createdAt: comment.createdAt,
              isLiked: comment.isLiked,
            );
            _comments[index] = revertedComment;
          }
        });
        _showErrorSnackBar('Failed to update comment');
      },
    );
  }

  void _showCommentOptions(Comment comment) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Theme.of(context).colorScheme.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            verticalSpace(8),
            Container(
              width: 50.w,
              height: 5.h,
              decoration: BoxDecoration(
                color: ColorManager.lighterGrey,
                borderRadius: BorderRadius.circular(10.r),
              ),
            ),
            verticalSpace(16),
            if (_isCommentMine(comment)) ...[
              ListTile(
                leading: const Icon(Icons.edit),
                title: const Text('Edit'),
                onTap: () {
                  Navigator.pop(context);
                  _showEditDialog(comment);
                },
              ),
              ListTile(
                leading: const Icon(Icons.delete, color: Colors.red),
                title: const Text(
                  'Delete',
                  style: TextStyle(color: Colors.red),
                ),
                onTap: () {
                  Navigator.pop(context);
                  _deleteComment(comment);
                },
              ),
            ] else
              ListTile(
                leading: const Icon(Icons.flag),
                title: const Text('Report'),
                onTap: () {
                  Navigator.pop(context);
                  _showErrorSnackBar('Comment reported');
                },
              ),
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
        
        title:  Text('Edit Comment',style: TextStyles.font28Bold,),
        content: SizedBox(
          width: 300.w,
        //  width: double.maxFinite,
          child: TextField(
            
            controller: _editController,
            maxLines: 4,
            decoration:  InputDecoration(
              hintText: 'Edit your comment...',
              hintStyle: TextStyles.font14regular.copyWith(
                color: ColorManager.normalGrey,
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.all(Radius.circular(8)),
                borderSide: BorderSide(color: ColorManager.normalGrey),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.all(Radius.circular(8)),
                borderSide: BorderSide(color: ColorManager.normalGrey),
              ),

              border: OutlineInputBorder(
                borderRadius: BorderRadius.all(Radius.circular(8)),
                borderSide: BorderSide(color: ColorManager.primaryBlack),
              ),
            ),
          ),
        ),
        actions: [
          SizedBox(
            width: 120.w,
            child: AppButton(onPressed: (){
              Navigator.pop(context);
            }, text: "Cancel", isWhite: false),
          ),
          SizedBox(
            width: 120.w,
            child: AppButton(onPressed: (){
              Navigator.pop(context);
              _updateComment(comment);
            }, text: "Update", isWhite: true),
          )
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
          style: TextStyles.font12Medium.copyWith(
            color: ColorManager.lighterGrey,
          ),
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
          style: TextStyles.font12Medium.copyWith(
            color: ColorManager.lighterGrey,
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      constraints: BoxConstraints(maxHeight: 480.h),
      padding: EdgeInsets.only(top: 8.h),
      child: Column(
        children: [
          Container(
            width: 50.w,
            height: 5.h,
            decoration: BoxDecoration(
              color: ColorManager.lighterGrey,
              borderRadius: BorderRadius.circular(10.r),
            ),
          ),
          verticalSpace(12),
          Text(
            'Comments (${_comments.length})',
            style: TextStyles.font18Semibold,
          ),
          verticalSpace(8),

          /// ERROR BANNER
          if (_errorMessage != null) ...[
            Padding(
              padding: EdgeInsets.symmetric(horizontal: 16.w),
              child: Container(
                padding: EdgeInsets.all(12.r),
                decoration: BoxDecoration(
                  color: ColorManager.primaryBlack,
                  borderRadius: BorderRadius.circular(8.r),
                  border: Border.all(color: ColorManager.normalGrey),
                ),
                child: Row(
                  children: [
                    Icon(
                      Icons.error_outline,
                      color: ColorManager.white,
                      size: 18.r,
                    ),
                    horizontalSpace(8),
                    Expanded(
                      child: Text(
                        _errorMessage!,
                        style: TextStyles.font12Medium.copyWith(
                          color: ColorManager.white,
                        ),
                      ),
                    ),
                    GestureDetector(
                      onTap: () => setState(() => _errorMessage = null),
                      child: Icon(
                        Icons.close,
                        color: ColorManager.white,
                        size: 16.r,
                      ),
                    ),
                  ],
                ),
              ),
            ),
            verticalSpace(8),
          ],

          Expanded(
            child: _comments.isEmpty
                ? Center(
                    child: Text(
                      '💬 No comments yet. Be the first to say something!',
                      style: TextStyles.font14regular.copyWith(
                        color: ColorManager.normalGrey,
                      ),
                    ),
                  )
                : ListView.separated(
                    itemCount: _comments.length,
                    separatorBuilder: (_, __) => verticalSpace(8),
                    itemBuilder: (context, index) {
                      final c = _comments[index];
                      final isPending =
                          _pendingIds.contains(c.id) || c.id! < 0;
                      final isLiked = _commentLikes[c.id] ?? false;

                      return Column(
                        children: [
                          ListTile(
                            leading: _CommentAvatar(author: c.author),
                            title: Text(
                              c.author!.fullName,
                              style: TextStyles.font14semiBold.copyWith(
                                color: isPending
                                    ? ColorManager.normalGrey
                                    : ColorManager.primaryBlack,
                              ),
                            ),
                            subtitle: Text(
                              c.content!,
                              style: TextStyles.font14regular.copyWith(
                                color: isPending
                                    ? ColorManager.normalGrey
                                    : ColorManager.darkGrey,
                              ),
                            ),
                            trailing: GestureDetector(
                              onTap: () => _showCommentOptions(c),
                              child: Icon(
                                Icons.more_horiz,
                                color: ColorManager.normalGrey,
                              ),
                            ),
                          ),
                          Padding(
                            padding: EdgeInsets.symmetric(horizontal: 56.w),
                            child: Row(
                              children: [
                                Text(
                                  timeAgo(c.createdAt),
                                  style: TextStyles.font12regular.copyWith(
                                    color: ColorManager.normalGrey,
                                  ),
                                ),
                                horizontalSpace(16),
                                if (!isPending)
                                  GestureDetector(
                                    onTap: () => _likeComment(c),
                                    child: Row(
                                      children: [
                                        SvgPicture.asset(
                                          isLiked
                                              ? "assets/svgs/Heart-filled.svg"
                                              : "assets/svgs/Heart.svg",
                                          width: 16.w,
                                          height: 16.h,
                                          color: isLiked
                                              ? ColorManager.red
                                              : ColorManager.normalGrey,
                                        ),
                                        horizontalSpace(4),
                                        Text(
                                          isLiked ? 'Unlike' : 'Like',
                                          style: TextStyles.font12regular
                                              .copyWith(
                                            color: ColorManager.normalGrey,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                              ],
                            ),
                          ),
                        ],
                      );
                    },
                  ),
          ),
          Padding(
            padding: EdgeInsets.fromLTRB(16.w, 8.h, 16.w, 10.h),
            child: Row(
              children: [
                Expanded(
                  child: AppTextField(
                    controller: _controller,
                    keyboardType: TextInputType.text,
                    isPassword: false,
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'Comment cannot be empty';
                      }
                      return null;
                    },
                  ),
                ),
                horizontalSpace(12),
                _isSending
                    ? SizedBox(
                        width: 24.r,
                        height: 24.r,
                        child: const CircularProgressIndicator(
                          strokeWidth: 2,
                        ),
                      )
                    : GestureDetector(
                        onTap: _sendComment,
                        child: SvgPicture.asset(
                          'assets/svgs/send.svg',
                          width: 30.w,
                          colorFilter: ColorFilter.mode(
                            Theme.of(context).brightness == Brightness.dark
                                ? const Color(0xFFC6FF00)
                                : const Color(0xFF1A1A1A),
                            BlendMode.srcIn,
                          ),
                        ),
                      ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Comment avatar — shows profile image or initials fallback
// ---------------------------------------------------------------------------

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
      radius: 18,
      backgroundColor: ColorManager.lighterGrey,
      backgroundImage: imageUrl != null ? NetworkImage(imageUrl) : null,
      child: imageUrl == null
          ? Text(
              initials.isEmpty ? '?' : initials,
              style: const TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w600,
                color: ColorManager.normalGrey,
              ),
            )
          : null,
    );
  }
}