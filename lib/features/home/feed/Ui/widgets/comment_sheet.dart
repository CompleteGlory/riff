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
import 'package:riff/core/widgets/tff.dart';
import 'package:riff/features/home/feed/data/models/author.dart';
import 'package:riff/features/home/feed/data/models/comment.dart';
import 'package:riff/features/home/feed/logic/cubit/feed_cubit.dart';

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
  final Set<int> _pendingIds = {};
  bool _isSending = false;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _comments = List<Comment>.from(widget.comments);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> _sendComment() async {
    final text = _controller.text.trim();
    if (text.isEmpty) return;

    setState(() {
      _isSending = true;
      _errorMessage = null;
    });

    final tempId = -DateTime.now().millisecondsSinceEpoch;
    final currentUserId =
        await SharedPrefHelper.getString(SharedPrefKeys.userId);

    final tempAuthor = Author(
      id: currentUserId.isNotEmpty ? currentUserId : 'me',
      fullName: 'You',
      username: '',
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
      _controller.clear();
    });

    final feedCubit = getIt<FeedCubit>();
    final res = await feedCubit.createComment(widget.postId, text);

    setState(() => _isSending = false);

    res.when(
      success: (comment) {
        final index = _comments.indexWhere((c) => c.id == tempId);
        if (index != -1) {
          setState(() {
            _comments[index] = comment;
            _pendingIds.remove(tempId);
          });
        }
        widget.onCommentCreated(comment);
      },
      failure: (_) {
        setState(() {
          _comments.removeWhere((c) => c.id == tempId);
          _pendingIds.remove(tempId);
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
                      onTap: () =>
                          setState(() => _errorMessage = null),
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
                          _pendingIds.contains(c.id) || c.id < 0;

                      return ListTile(
                        leading: const CircleAvatar(
                          radius: 16,
                          backgroundColor: ColorManager.lighterGrey,
                          child: Icon(
                            Icons.person,
                            color: ColorManager.white,
                          ),
                        ),
                        title: Text(
                          c.author!.fullName,
                          style:
                              TextStyles.font14semiBold.copyWith(
                            color: isPending
                                ? ColorManager.normalGrey
                                : ColorManager.primaryBlack,
                          ),
                        ),
                        subtitle: Text(
                          c.content,
                          style:
                              TextStyles.font14regular.copyWith(
                            color: isPending
                                ? ColorManager.normalGrey
                                : ColorManager.darkGrey,
                          ),
                        ),
                        trailing: Text(
                          timeAgo(c.createdAt),
                          style:
                              TextStyles.font12regular.copyWith(
                            color: ColorManager.normalGrey,
                          ),
                        ),
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
