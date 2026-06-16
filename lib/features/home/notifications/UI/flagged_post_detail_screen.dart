import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:riff/core/di/dependency_injection.dart';
import 'package:riff/core/themes/colors/color_manager.dart';
import 'package:riff/core/themes/text_styles/text_styles.dart';
import 'package:riff/features/home/feed/data/models/post.dart';
import 'package:riff/features/home/feed/Ui/widgets/post/post_item.dart';
import 'package:riff/features/home/core/logic/cubit/home_cubit.dart';

/// Shown when the user taps a [post_flagged] notification.
/// Fetches the reported post by ID and displays it with a warning banner.
/// [postId] may be null for notifications sent before post-ID tracking was added.
class FlaggedPostDetailScreen extends StatefulWidget {
  final int? postId;
  final String? flagTitle;
  final String? flagBody;

  const FlaggedPostDetailScreen({
    super.key,
    required this.postId,
    this.flagTitle,
    this.flagBody,
  });

  @override
  State<FlaggedPostDetailScreen> createState() =>
      _FlaggedPostDetailScreenState();
}

class _FlaggedPostDetailScreenState extends State<FlaggedPostDetailScreen> {
  Post? _post;
  String? _error;
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    if (widget.postId != null) {
      _fetchPost();
    } else {
      // No post ID — notification was sent without one
      setState(() => _loading = false);
    }
  }

  Future<void> _fetchPost() async {
    setState(() { _loading = true; _error = null; });
    try {
      final dio = getIt<Dio>();
      final resp = await dio.get('/api/posts/${widget.postId}');
      final data = resp.data;
      if (data is Map<String, dynamic>) {
        setState(() {
          _post = Post.fromJson(data);
          _loading = false;
        });
      } else {
        setState(() { _error = 'Unexpected response format'; _loading = false; });
      }
    } on DioException catch (e) {
      final msg = (e.response?.data?['message'] as String?) ??
          e.message ??
          'Failed to load post';
      setState(() { _error = msg; _loading = false; });
    } catch (e) {
      setState(() { _error = e.toString(); _loading = false; });
    }
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
        title: const Text('Flagged Post'),
        centerTitle: false,
      ),
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ── Orange flag banner ─────────────────────────────────────────
          _FlagBanner(
            title: widget.flagTitle ?? 'Your post was flagged',
            body: widget.flagBody,
          ),

          // ── Post content ───────────────────────────────────────────────
          Expanded(
            child: _loading
                ? const Center(
                    child: CircularProgressIndicator(color: Colors.orange))
                : _error != null
                    ? _ErrorView(message: _error!, onRetry: _fetchPost)
                    : widget.postId == null
                        ? _NoPostView(
                            title: widget.flagTitle,
                            body: widget.flagBody,
                          )
                        : _post == null
                        ? Center(
                            child: Text('Post not found or was deleted.',
                                style: TextStyles.font14Medium.copyWith(
                                    color: ColorManager.normalGrey)))
                        : RefreshIndicator(
                            onRefresh: _fetchPost,
                            color: Colors.orange,
                            backgroundColor: isDark
                                ? const Color(0xFF252525)
                                : Colors.white,
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
                                  final item = PostItem(
                                      post: _post!, disableTap: true);
                                  return homeCubit != null
                                      ? BlocProvider.value(
                                          value: homeCubit, child: item)
                                      : item;
                                },
                              ),
                            ),
                          ),
          ),
        ],
      ),
    );
  }
}

// ── Orange flagged banner ──────────────────────────────────────────────────────

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
                      child: Icon(Icons.flag_rounded,
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

// ── No post ID (old notification) ─────────────────────────────────────────────

class _NoPostView extends StatelessWidget {
  final String? title;
  final String? body;
  const _NoPostView({this.title, this.body});

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
              child: Icon(Icons.flag_rounded,
                  color: Colors.orange, size: 40.r),
            ),
            SizedBox(height: 20.h),
            Text(
              title ?? 'Post flagged by admin',
              style: TextStyles.font16Medium.copyWith(
                fontWeight: FontWeight.w600,
              ),
              textAlign: TextAlign.center,
            ),
            if (body != null && body!.isNotEmpty) ...[
              SizedBox(height: 10.h),
              Text(
                body!,
                style: TextStyles.font14Medium.copyWith(
                    color: ColorManager.normalGrey),
                textAlign: TextAlign.center,
              ),
            ],
            SizedBox(height: 20.h),
            Text(
              'The specific post is no longer available or has already been removed.',
              style: TextStyles.font12Medium.copyWith(
                  color: ColorManager.normalGrey),
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
          Icon(Icons.error_outline,
              size: 48.r, color: ColorManager.normalGrey),
          SizedBox(height: 12.h),
          Text(message,
              style: TextStyles.font14Medium.copyWith(
                  color: ColorManager.normalGrey),
              textAlign: TextAlign.center),
          SizedBox(height: 16.h),
          TextButton(onPressed: onRetry, child: const Text('Retry')),
        ],
      ),
    );
  }
}
