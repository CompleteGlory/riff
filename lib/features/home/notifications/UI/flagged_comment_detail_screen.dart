import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:riff/core/di/dependency_injection.dart';
import 'package:riff/core/helpers/time_ago.dart';
import 'package:riff/core/networks/api_constants.dart';
import 'package:riff/core/networks/api_result.dart';
import 'package:riff/core/themes/colors/color_manager.dart';
import 'package:riff/core/themes/text_styles/text_styles.dart';
import 'package:riff/features/home/feed/data/models/post.dart';
import 'package:riff/features/home/feed/data/repos/feed_repo.dart';
import 'package:riff/features/home/feed/logic/cubit/comments/comment_cubit.dart';
import 'package:riff/features/home/feed/Ui/widgets/post/post_item.dart';
import 'package:riff/features/home/core/logic/cubit/home_cubit.dart';

/// Shown when the user taps a [admin_notice] notification that has a
/// [comment_id] in its metadata. Displays the flagged comment content
/// and the post it belongs to.
class FlaggedCommentDetailScreen extends StatefulWidget {
  final int? commentId;
  final int? postId;
  final String? flagTitle;
  final String? flagBody;

  const FlaggedCommentDetailScreen({
    super.key,
    required this.commentId,
    this.postId,
    this.flagTitle,
    this.flagBody,
  });

  @override
  State<FlaggedCommentDetailScreen> createState() =>
      _FlaggedCommentDetailScreenState();
}

class _FlaggedCommentDetailScreenState
    extends State<FlaggedCommentDetailScreen> {
  Map<String, dynamic>? _comment;
  Post? _post;
  String? _error;
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _fetch();
  }

  Future<void> _fetch() async {
    setState(() { _loading = true; _error = null; });

    try {
      if (widget.commentId != null) {
        // Fetch comment via CommentCubit
        final commentResult = await getIt<CommentCubit>()
            .getComment(widget.commentId!);
        if (!mounted) return;
        commentResult.when(
          success: (data) {
            setState(() => _comment = data);
            // Extract post from comment response if available
            final postData = data['post'] as Map<String, dynamic>?;
            if (postData != null) {
              setState(() => _post = Post.fromJson(postData));
            }
          },
          failure: (err) => setState(() => _error = err.message ?? 'Failed to load comment'),
        );

        // If post still null, fetch it separately via FeedRepo
        if (_post == null && widget.postId != null && _error == null) {
          final postResult =
              await getIt<FeedRepo>().getPostById(widget.postId!);
          if (mounted) {
            postResult.whenOrNull(
                success: (post) => setState(() => _post = post));
          }
        }
      }
    } catch (e) {
      if (mounted) setState(() => _error = e.toString());
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new, size: 20),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text('Flagged Comment'),
        centerTitle: false,
      ),
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ── Orange flag banner ─────────────────────────────────────────
          _FlagBanner(
            title: widget.flagTitle ?? 'Your comment was flagged',
            body: widget.flagBody,
          ),

          // ── Content ────────────────────────────────────────────────────
          Expanded(
            child: _loading
                ? const Center(
                    child: CircularProgressIndicator(color: Colors.orange))
                : _error != null
                    ? _ErrorView(message: _error!, onRetry: _fetch)
                    : widget.commentId == null
                        ? _NoContentView(
                            title: widget.flagTitle,
                            body: widget.flagBody,
                          )
                        : RefreshIndicator(
                            onRefresh: _fetch,
                            color: Colors.orange,
                            child: SingleChildScrollView(
                              physics: const AlwaysScrollableScrollPhysics(),
                              padding: EdgeInsets.fromLTRB(16.w, 12.h, 16.w, 24.h),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  // ── Flagged comment card ───────────
                                  if (_comment != null)
                                    _CommentCard(comment: _comment!),
                                  if (_comment == null)
                                    Center(
                                      child: Padding(
                                        padding: EdgeInsets.only(top: 32.h),
                                        child: Text(
                                          'Comment was deleted or unavailable.',
                                          style: TextStyles.font14Medium
                                              .copyWith(
                                                  color: ColorManager
                                                      .normalGrey),
                                          textAlign: TextAlign.center,
                                        ),
                                      ),
                                    ),

                                  // ── Parent post ────────────────────
                                  if (_post != null) ...[
                                    SizedBox(height: 16.h),
                                    _SectionHeader(label: 'Post this comment was on'),
                                    SizedBox(height: 8.h),
                                    Builder(builder: (ctx) {
                                      HomeCubit? homeCubit;
                                      try {
                                        homeCubit = ctx.read<HomeCubit>();
                                      } catch (_) {}
                                      final item = PostItem(
                                          post: _post!, disableTap: true);
                                      return homeCubit != null
                                          ? BlocProvider.value(
                                              value: homeCubit, child: item)
                                          : item;
                                    }),
                                  ],
                                ],
                              ),
                            ),
                          ),
          ),
        ],
      ),
    );
  }
}

// ── Comment card ──────────────────────────────────────────────────────────────

class _CommentCard extends StatelessWidget {
  final Map<String, dynamic> comment;
  const _CommentCard({required this.comment});

  String _avatarUrl(String? raw) {
    if (raw == null || raw.isEmpty) return '';
    return raw.startsWith('http') ? raw : '${ApiConstants.apiBASEURL}$raw';
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final user = comment['user'] as Map<String, dynamic>?;
    final username = user?['username'] as String? ?? 'Unknown';
    final profilePic = _avatarUrl(user?['profile_image_url'] as String?);
    final content = comment['content'] as String? ?? '';
    final createdAt = comment['created_at'] as String? ?? '';

    return Container(
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1E1E1E) : Colors.white,
        borderRadius: BorderRadius.circular(12.r),
        border: Border.all(
          color: Colors.orange.withValues(alpha: 0.4),
          width: 1,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header with orange left accent
          Container(
            decoration: BoxDecoration(
              color: Colors.orange.withValues(alpha: 0.06),
              borderRadius: BorderRadius.only(
                topLeft: Radius.circular(12.r),
                topRight: Radius.circular(12.r),
              ),
            ),
            padding: EdgeInsets.symmetric(horizontal: 14.w, vertical: 10.h),
            child: Row(
              children: [
                Container(
                  padding: EdgeInsets.symmetric(horizontal: 6.w, vertical: 2.h),
                  decoration: BoxDecoration(
                    color: Colors.orange.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(4.r),
                  ),
                  child: Text(
                    'FLAGGED COMMENT',
                    style: TextStyle(
                      color: Colors.orange,
                      fontSize: 9.sp,
                      fontWeight: FontWeight.w800,
                      letterSpacing: 0.8,
                    ),
                  ),
                ),
                const Spacer(),
                Icon(Icons.chat_bubble_outline_rounded,
                    size: 14.r, color: Colors.orange),
              ],
            ),
          ),

          // Comment author + content
          Padding(
            padding: EdgeInsets.all(14.w),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    CircleAvatar(
                      radius: 18.r,
                      backgroundColor: ColorManager.lighterGrey,
                      backgroundImage: profilePic.isNotEmpty
                          ? NetworkImage(profilePic)
                          : null,
                      child: profilePic.isEmpty
                          ? Text(
                              username.isNotEmpty
                                  ? username[0].toUpperCase()
                                  : '?',
                              style: TextStyles.font12Medium,
                            )
                          : null,
                    ),
                    SizedBox(width: 10.w),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            '@$username',
                            style: TextStyles.font13SemiBold,
                          ),
                          if (createdAt.isNotEmpty)
                            Text(
                              timeAgo(createdAt),
                              style: TextStyles.font12Medium.copyWith(
                                  color: ColorManager.normalGrey),
                            ),
                        ],
                      ),
                    ),
                  ],
                ),
                SizedBox(height: 10.h),
                if (content.isNotEmpty)
                  Container(
                    width: double.infinity,
                    padding: EdgeInsets.all(12.w),
                    decoration: BoxDecoration(
                      color: isDark
                          ? const Color(0xFF2A2A2A)
                          : const Color(0xFFF9F9F9),
                      borderRadius: BorderRadius.circular(8.r),
                    ),
                    child: Text(
                      content,
                      style: TextStyles.font14Medium,
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

// ── Section header ────────────────────────────────────────────────────────────

class _SectionHeader extends StatelessWidget {
  final String label;
  const _SectionHeader({required this.label});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(width: 3, height: 16.h, color: Colors.orange),
        SizedBox(width: 8.w),
        Text(
          label,
          style: TextStyles.font13SemiBold.copyWith(
              color: ColorManager.normalGrey),
        ),
      ],
    );
  }
}

// ── Flag banner ───────────────────────────────────────────────────────────────

class _FlagBanner extends StatelessWidget {
  final String title;
  final String? body;
  const _FlagBanner({required this.title, this.body});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      color: Colors.orange.withValues(alpha: 0.08),
      child: IntrinsicHeight(
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Container(width: 4, color: Colors.orange),
            Expanded(
              child: Padding(
                padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 12.h),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: Colors.orange.withValues(alpha: 0.15),
                        borderRadius: BorderRadius.circular(10.r),
                      ),
                      child: Icon(Icons.chat_bubble_outlined,
                          color: Colors.orange, size: 18.r),
                    ),
                    SizedBox(width: 12.w),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Row(children: [
                            Container(
                              padding: EdgeInsets.symmetric(
                                  horizontal: 6.w, vertical: 2.h),
                              decoration: BoxDecoration(
                                color: Colors.orange.withValues(alpha: 0.15),
                                borderRadius: BorderRadius.circular(4.r),
                              ),
                              child: Text(
                                'FLAGGED',
                                style: TextStyle(
                                  color: Colors.orange,
                                  fontSize: 9.sp,
                                  fontWeight: FontWeight.w800,
                                  letterSpacing: 0.8,
                                ),
                              ),
                            ),
                          ]),
                          SizedBox(height: 4.h),
                          Text(
                            title,
                            style: TextStyles.font13SemiBold.copyWith(
                                color: Colors.orange.shade700),
                          ),
                          if (body != null && body!.isNotEmpty) ...[
                            SizedBox(height: 2.h),
                            Text(
                              body!,
                              style: TextStyles.font12Medium.copyWith(
                                  color: ColorManager.normalGrey),
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ],
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ── No comment ID (old notification) ─────────────────────────────────────────

class _NoContentView extends StatelessWidget {
  final String? title;
  final String? body;
  const _NoContentView({this.title, this.body});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: EdgeInsets.symmetric(horizontal: 32.w),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Colors.orange.withValues(alpha: 0.1),
                shape: BoxShape.circle,
              ),
              child: Icon(Icons.chat_bubble_outline_rounded,
                  color: Colors.orange, size: 40.r),
            ),
            SizedBox(height: 20.h),
            Text(
              title ?? 'Comment flagged by admin',
              style: TextStyles.font16Medium
                  .copyWith(fontWeight: FontWeight.w600),
              textAlign: TextAlign.center,
            ),
            if (body != null && body!.isNotEmpty) ...[
              SizedBox(height: 10.h),
              Text(
                body!,
                style: TextStyles.font14Medium
                    .copyWith(color: ColorManager.normalGrey),
                textAlign: TextAlign.center,
              ),
            ],
            SizedBox(height: 20.h),
            Text(
              'The comment is no longer available or has already been removed.',
              style: TextStyles.font12Medium
                  .copyWith(color: ColorManager.normalGrey),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}

// ── Error view ────────────────────────────────────────────────────────────────

class _ErrorView extends StatelessWidget {
  final String message;
  final VoidCallback onRetry;
  const _ErrorView({required this.message, required this.onRetry});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.error_outline, size: 48.r, color: ColorManager.normalGrey),
          SizedBox(height: 12.h),
          Text(message,
              style: TextStyles.font14Medium
                  .copyWith(color: ColorManager.normalGrey),
              textAlign: TextAlign.center),
          SizedBox(height: 16.h),
          TextButton(onPressed: onRetry, child: const Text('Retry')),
        ],
      ),
    );
  }
}
