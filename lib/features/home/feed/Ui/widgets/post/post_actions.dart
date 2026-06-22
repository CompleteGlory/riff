import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_svg/svg.dart';
import 'package:riff/core/themes/colors/color_manager.dart';
import 'package:riff/core/themes/text_styles/text_styles.dart';

class PostActions extends StatelessWidget {
  final bool isLiked;
  final int likeCount;
  final int commentCount;
  final int shareCount;
  final int viewsCount;
  final VoidCallback onLikeTap;
  final VoidCallback onCommentTap;
  final VoidCallback onShareTap;

  const PostActions({
    super.key,
    required this.isLiked,
    required this.likeCount,
    required this.commentCount,
    required this.shareCount,
    this.viewsCount = 0,
    required this.onLikeTap,
    required this.onCommentTap,
    required this.onShareTap,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final mutedColor = isDark ? const Color(0xFF666666) : ColorManager.normalGrey;

    return Row(
      children: [
        _ActionButton(
          svgAsset: isLiked
              ? 'assets/svgs/Heart-filled.svg'
              : 'assets/svgs/Heart.svg',
          color: isLiked ? ColorManager.red : mutedColor,
          label: _formatCount(likeCount),
          onTap: onLikeTap,
        ),
        SizedBox(width: 20.w),
        _ActionButton(
          svgAsset: 'assets/svgs/Chat.svg',
          color: mutedColor,
          label: _formatCount(commentCount),
          onTap: onCommentTap,
        ),
        const Spacer(),
        // Views — eye icon, non-interactive
        Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            SvgPicture.asset(
              'assets/svgs/eye.svg',
              width: 16.w,
              height: 16.w,
              colorFilter: ColorFilter.mode(mutedColor, BlendMode.srcIn),
            ),
            SizedBox(width: 4.w),
            Text(
              _formatCount(viewsCount),
              style: TextStyles.font12semiBold.copyWith(color: mutedColor),
            ),
            SizedBox(width: 16.w),
          ],
        ),
        _ActionButton(
          svgAsset: 'assets/svgs/share.svg',
          color: mutedColor,
          label: _formatCount(shareCount),
          onTap: onShareTap,
        ),
      ],
    );
  }

  String _formatCount(int count) {
    if (count >= 1000000) return '${(count / 1000000).toStringAsFixed(1)}M';
    if (count >= 1000) return '${(count / 1000).toStringAsFixed(1)}K';
    return '$count';
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// _ActionButton — animated icon + count with press-scale feedback
// ─────────────────────────────────────────────────────────────────────────────

class _ActionButton extends StatefulWidget {
  const _ActionButton({
    required this.svgAsset,
    required this.color,
    required this.label,
    required this.onTap,
  });

  final String svgAsset;
  final Color color;
  final String label;
  final VoidCallback onTap;

  @override
  State<_ActionButton> createState() => _ActionButtonState();
}

class _ActionButtonState extends State<_ActionButton>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final Animation<double> _scale;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 110),
    );
    _scale = Tween<double>(begin: 1.0, end: 0.82).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _onTapDown(TapDownDetails _) => _controller.forward();
  void _onTapUp(TapUpDetails _) {
    _controller.reverse();
    widget.onTap();
  }
  void _onTapCancel() => _controller.reverse();

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTapDown: _onTapDown,
      onTapUp: _onTapUp,
      onTapCancel: _onTapCancel,
      behavior: HitTestBehavior.opaque,
      child: ScaleTransition(
        scale: _scale,
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Icon — AnimatedSwitcher handles liked ↔ unliked swap
            AnimatedSwitcher(
              duration: const Duration(milliseconds: 220),
              transitionBuilder: (child, anim) => ScaleTransition(
                scale: CurvedAnimation(
                    parent: anim, curve: Curves.easeOutBack),
                child: FadeTransition(opacity: anim, child: child),
              ),
              child: SvgPicture.asset(
                widget.svgAsset,
                key: ValueKey(widget.svgAsset),
                width: 22.w,
                height: 22.h,
                colorFilter:
                    ColorFilter.mode(widget.color, BlendMode.srcIn),
              ),
            ),
            SizedBox(width: 5.w),

            // Count — slides up when value changes
            AnimatedSwitcher(
              duration: const Duration(milliseconds: 200),
              transitionBuilder: (child, anim) => FadeTransition(
                opacity: anim,
                child: SlideTransition(
                  position: Tween<Offset>(
                    begin: const Offset(0, -0.35),
                    end: Offset.zero,
                  ).animate(
                    CurvedAnimation(parent: anim, curve: Curves.easeOutCubic),
                  ),
                  child: child,
                ),
              ),
              child: Text(
                widget.label,
                key: ValueKey(widget.label),
                style: TextStyles.font12semiBold.copyWith(color: widget.color),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
