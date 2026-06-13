import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:shimmer/shimmer.dart';

// ── Tiny helper ───────────────────────────────────────────────────────────────

class _Box extends StatelessWidget {
  const _Box({this.width, required this.height, this.radius = 8, this.circle = false});
  final double? width;
  final double height;
  final double radius;
  final bool circle;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Container(
      width: width,
      height: height,
      decoration: BoxDecoration(
        // In dark mode use a visible dark surface; light mode use white
        color: isDark ? const Color(0xFF2A2A2A) : Colors.white,
        borderRadius: circle ? null : BorderRadius.circular(radius.r),
        shape: circle ? BoxShape.circle : BoxShape.rectangle,
      ),
    );
  }
}

Color _shimmerBase(BuildContext context) =>
    Theme.of(context).brightness == Brightness.dark
        ? const Color(0xFF222222)
        : const Color(0xFFE8E8E8);

Color _shimmerHighlight(BuildContext context) =>
    Theme.of(context).brightness == Brightness.dark
        ? const Color(0xFF303030)
        : const Color(0xFFF6F6F6);

// ─────────────────────────────────────────────────────────────────────────────
// FEED SHIMMER
// ─────────────────────────────────────────────────────────────────────────────

class FeedShimmer extends StatelessWidget {
  const FeedShimmer({super.key});

  @override
  Widget build(BuildContext context) {
    return Shimmer.fromColors(
      baseColor: _shimmerBase(context),
      highlightColor: _shimmerHighlight(context),
      child: ListView.builder(
        physics: const NeverScrollableScrollPhysics(),
        padding: EdgeInsets.symmetric(vertical: 8.h),
        itemCount: 3,
        itemBuilder: (_, __) => _PostCardSkeleton(),
      ),
    );
  }
}

class _PostCardSkeleton extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Container(
      margin: EdgeInsets.symmetric(horizontal: 16.w, vertical: 8.h),
      padding: EdgeInsets.all(14.w),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1E1E1E) : Colors.white,
        borderRadius: BorderRadius.circular(18.r),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(children: [
            _Box(width: 42.r, height: 42.r, circle: true),
            SizedBox(width: 10.w),
            Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              _Box(width: 130.w, height: 12.h),
              SizedBox(height: 6.h),
              _Box(width: 80.w, height: 10.h),
            ]),
          ]),
          SizedBox(height: 14.h),
          _Box(width: double.infinity, height: 11.h),
          SizedBox(height: 6.h),
          _Box(width: 180.w, height: 11.h),
          SizedBox(height: 14.h),
          _Box(width: double.infinity, height: 200.h, radius: 12),
          SizedBox(height: 14.h),
          Row(children: [
            _Box(width: 56.w, height: 18.h, radius: 6),
            SizedBox(width: 16.w),
            _Box(width: 56.w, height: 18.h, radius: 6),
            SizedBox(width: 16.w),
            _Box(width: 56.w, height: 18.h, radius: 6),
          ]),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// PROFILE PAGE SHIMMER
// ─────────────────────────────────────────────────────────────────────────────

class ProfilePageShimmer extends StatelessWidget {
  const ProfilePageShimmer({super.key});

  @override
  Widget build(BuildContext context) {
    return Shimmer.fromColors(
      baseColor: _shimmerBase(context),
      highlightColor: _shimmerHighlight(context),
      child: SingleChildScrollView(
        physics: const NeverScrollableScrollPhysics(),
        child: Column(children: [
          _ProfileHeaderSkeleton(),
          const _ProfileGridSkeleton(),
        ]),
      ),
    );
  }
}

class _ProfileHeaderSkeleton extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Container(
      color: isDark ? const Color(0xFF1E1E1E) : Colors.white,
      padding: EdgeInsets.fromLTRB(20.w, 32.h, 20.w, 28.h),
      child: Column(children: [
        _Box(width: 96.r, height: 96.r, circle: true),
        SizedBox(height: 16.h),
        _Box(width: 150.w, height: 14.h),
        SizedBox(height: 8.h),
        _Box(width: 100.w, height: 12.h),
        SizedBox(height: 8.h),
        _Box(width: 230.w, height: 11.h),
        SizedBox(height: 4.h),
        _Box(width: 180.w, height: 11.h),
        SizedBox(height: 24.h),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceAround,
          children: List.generate(3, (_) => Column(children: [
            _Box(width: 44.w, height: 18.h),
            SizedBox(height: 5.h),
            _Box(width: 60.w, height: 11.h),
          ])),
        ),
      ]),
    );
  }
}

class _ProfileGridSkeleton extends StatelessWidget {
  const _ProfileGridSkeleton();

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      padding: EdgeInsets.only(top: 2.h),
      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 3,
        crossAxisSpacing: 2.w,
        mainAxisSpacing: 2.h,
      ),
      itemCount: 9,
      itemBuilder: (_, __) => Container(
        color: isDark ? const Color(0xFF252525) : Colors.white),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// PROFILE GRID SHIMMER (sliver)
// ─────────────────────────────────────────────────────────────────────────────

class ProfileGridShimmer extends StatelessWidget {
  const ProfileGridShimmer({super.key});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return SliverToBoxAdapter(
      child: Shimmer.fromColors(
        baseColor: _shimmerBase(context),
        highlightColor: _shimmerHighlight(context),
        child: GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          padding: EdgeInsets.fromLTRB(2.w, 2.h, 2.w, 32.h),
          gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 3,
            crossAxisSpacing: 2.w,
            mainAxisSpacing: 2.h,
          ),
          itemCount: 9,
          itemBuilder: (_, __) => Container(
            color: isDark ? const Color(0xFF252525) : Colors.white),
        ),
      ),
    );
  }
}
