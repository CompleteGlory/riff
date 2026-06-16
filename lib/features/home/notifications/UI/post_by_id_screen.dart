import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:riff/core/di/dependency_injection.dart';
import 'package:riff/core/networks/api_result.dart';
import 'package:riff/core/themes/colors/color_manager.dart';
import 'package:riff/core/themes/text_styles/text_styles.dart';
import 'package:riff/features/home/core/logic/cubit/home_cubit.dart';
import 'package:riff/features/home/feed/data/models/comment.dart';
import 'package:riff/features/home/feed/data/models/post.dart';
import 'package:riff/features/home/feed/logic/cubit/comments/comment_cubit.dart';
import 'package:riff/features/home/feed/Ui/widgets/comments/comment_sheet.dart';
import 'package:riff/features/home/feed/Ui/widgets/post/post_item.dart';

/// Navigates to a post by its numeric ID. Used by like / comment notifications.
/// When [openComments] is true the comment sheet is automatically shown after
/// the post loads.
class PostByIdScreen extends StatefulWidget {
  final int postId;
  final bool openComments;

  const PostByIdScreen({
    super.key,
    required this.postId,
    this.openComments = false,
  });

  @override
  State<PostByIdScreen> createState() => _PostByIdScreenState();
}

class _PostByIdScreenState extends State<PostByIdScreen> {
  Post? _post;
  String? _error;
  bool _loading = true;
  bool _commentsOpened = false;

  @override
  void initState() {
    super.initState();
    _fetchPost();
  }

  Future<void> _fetchPost() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final dio = getIt<Dio>();
      final resp = await dio.get('/api/posts/${widget.postId}');
      final data = resp.data;
      if (data is Map<String, dynamic>) {
        setState(() {
          _post = Post.fromJson(data);
          _loading = false;
        });
        if (widget.openComments && !_commentsOpened) {
          _commentsOpened = true;
          WidgetsBinding.instance.addPostFrameCallback((_) {
            if (mounted) _openComments();
          });
        }
      } else {
        setState(() {
          _error = 'Unexpected response format';
          _loading = false;
        });
      }
    } on DioException catch (e) {
      final msg = (e.response?.data?['message'] as String?) ??
          e.message ??
          'Failed to load post';
      setState(() {
        _error = msg;
        _loading = false;
      });
    } catch (e) {
      setState(() {
        _error = e.toString();
        _loading = false;
      });
    }
  }

  Future<void> _openComments() async {
    if (_post == null || !mounted) return;
    final postId = _post!.id.toString();
    final commentCubit = getIt<CommentCubit>();

    // Show loading sheet while fetching
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Theme.of(context).colorScheme.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (_) => SizedBox(
        height: 220,
        child: Column(
          children: [
            const SizedBox(height: 12),
            Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: Theme.of(context).dividerColor,
                borderRadius: BorderRadius.circular(10),
              ),
            ),
            const SizedBox(height: 14),
            Text('Comments', style: TextStyles.font18Semibold),
            const Expanded(child: Center(child: CircularProgressIndicator())),
          ],
        ),
      ),
    );

    final result = await commentCubit.getPostComments(postId);
    if (!mounted) return;
    Navigator.pop(context);

    result.when(
      success: (comments) {
        showModalBottomSheet(
          context: context,
          isScrollControlled: true,
          backgroundColor: Theme.of(context).colorScheme.surface,
          shape: const RoundedRectangleBorder(
            borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
          ),
          builder: (_) => CommentsSheet(
            comments: comments,
            postId: postId,
            initialCommentsCount: comments.length,
            onCommentCreated: (Comment _) {},
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

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new, size: 20),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text('Post'),
        centerTitle: false,
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _error != null
              ? Center(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.error_outline,
                          size: 48.r, color: ColorManager.normalGrey),
                      SizedBox(height: 12.h),
                      Text(_error!,
                          style: TextStyles.font14Medium.copyWith(
                              color: ColorManager.normalGrey),
                          textAlign: TextAlign.center),
                      SizedBox(height: 16.h),
                      TextButton(
                          onPressed: _fetchPost, child: const Text('Retry')),
                    ],
                  ),
                )
              : _post == null
                  ? Center(
                      child: Text('Post not found or was deleted.',
                          style: TextStyles.font14Medium.copyWith(
                              color: ColorManager.normalGrey)))
                  : RefreshIndicator(
                      onRefresh: _fetchPost,
                      color: isDark
                          ? const Color(0xFFC6FF00)
                          : ColorManager.primaryBlack,
                      backgroundColor:
                          isDark ? const Color(0xFF252525) : Colors.white,
                      child: SingleChildScrollView(
                        physics: const AlwaysScrollableScrollPhysics(),
                        padding: EdgeInsets.symmetric(
                            horizontal: 12.w, vertical: 10.h),
                        child: Builder(
                          builder: (ctx) {
                            HomeCubit? homeCubit;
                            try {
                              homeCubit = ctx.read<HomeCubit>();
                            } catch (_) {}
                            final item = PostItem(post: _post!, disableTap: true);
                            return homeCubit != null
                                ? BlocProvider.value(
                                    value: homeCubit, child: item)
                                : item;
                          },
                        ),
                      ),
                    ),
    );
  }
}
