import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:riff/core/themes/colors/color_manager.dart';
import 'package:riff/core/themes/text_styles/text_styles.dart';

/// A polished, animated error state widget.
///
/// Detects connection vs server errors from [message] automatically,
/// or override with [isConnectionError].
class AppErrorWidget extends StatefulWidget {
  final String? message;
  final VoidCallback? onRetry;
  final bool? isConnectionError; // null = auto-detect from message

  const AppErrorWidget({
    super.key,
    this.message,
    this.onRetry,
    this.isConnectionError,
  });

  @override
  State<AppErrorWidget> createState() => _AppErrorWidgetState();
}

class _AppErrorWidgetState extends State<AppErrorWidget>
    with TickerProviderStateMixin {
  late final AnimationController _bobController;
  late final Animation<double> _bob;

  late final AnimationController _rotateController;
  late final Animation<double> _rotate;

  late final AnimationController _fadeController;
  late final Animation<double> _fade;
  late final Animation<Offset> _slide;

  bool get _isConnErr {
    if (widget.isConnectionError != null) return widget.isConnectionError!;
    final msg = (widget.message ?? '').toLowerCase();
    return msg.contains('connection') ||
        msg.contains('network') ||
        msg.contains('socket') ||
        msg.contains('host') ||
        msg.contains('timeout') ||
        msg.contains('unreachable');
  }

  @override
  void initState() {
    super.initState();

    _bobController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2800),
    )..repeat(reverse: true);
    _bob = Tween<double>(begin: -6, end: 6).animate(
      CurvedAnimation(parent: _bobController, curve: Curves.easeInOut),
    );

    _rotateController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 12),
    )..repeat();
    _rotate = Tween<double>(begin: 0, end: 2 * math.pi).animate(
      CurvedAnimation(parent: _rotateController, curve: Curves.linear),
    );

    _fadeController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
    )..forward();
    _fade = CurvedAnimation(parent: _fadeController, curve: Curves.easeOut);
    _slide = Tween<Offset>(
      begin: const Offset(0, 0.06),
      end: Offset.zero,
    ).animate(CurvedAnimation(parent: _fadeController, curve: Curves.easeOutCubic));
  }

  @override
  void dispose() {
    _bobController.dispose();
    _rotateController.dispose();
    _fadeController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final accentColor =
        isDark ? const Color(0xFFC6FF00) : ColorManager.primaryBlack;
    final subtleColor =
        isDark ? const Color(0xFF3A3A3A) : const Color(0xFFF0F0F0);
    final iconBg =
        isDark ? const Color(0xFF2A2A2A) : const Color(0xFFF5F5F5);
    final greyText =
        isDark ? const Color(0xFF888888) : const Color(0xFF999999);

    final title = _isConnErr ? 'No Connection' : 'Something Went Wrong';
    final subtitle = _isConnErr
        ? 'Check your internet and try again.'
        : 'The server ran into a problem.\nTap retry to try again.';

    return FadeTransition(
      opacity: _fade,
      child: SlideTransition(
        position: _slide,
        child: Center(
          child: Padding(
            padding: EdgeInsets.symmetric(horizontal: 40.w),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              mainAxisSize: MainAxisSize.min,
              children: [
                // ── Animated icon ──────────────────────────────────────
                AnimatedBuilder(
                  animation: Listenable.merge([_bob, _rotate]),
                  builder: (_, __) {
                    return Transform.translate(
                      offset: Offset(0, _bob.value),
                      child: Stack(
                        alignment: Alignment.center,
                        children: [
                          Transform.rotate(
                            angle: _rotate.value,
                            child: CustomPaint(
                              size: Size(96.r, 96.r),
                              painter: _DashedCirclePainter(
                                color: subtleColor,
                                dashCount: 12,
                                strokeWidth: 2,
                              ),
                            ),
                          ),
                          Container(
                            width: 72.r,
                            height: 72.r,
                            decoration: BoxDecoration(
                              color: iconBg,
                              shape: BoxShape.circle,
                            ),
                            child: Icon(
                              _isConnErr
                                  ? Icons.wifi_off_rounded
                                  : Icons.cloud_off_rounded,
                              size: 32.r,
                              color: isDark
                                  ? const Color(0xFF888888)
                                  : const Color(0xFFAAAAAA),
                            ),
                          ),
                        ],
                      ),
                    );
                  },
                ),

                SizedBox(height: 28.h),

                // ── Title ──────────────────────────────────────────────
                Text(
                  title,
                  style: TextStyles.font18Semibold,
                  textAlign: TextAlign.center,
                ),

                SizedBox(height: 8.h),

                // ── Subtitle ───────────────────────────────────────────
                Text(
                  subtitle,
                  style: TextStyles.font14Medium.copyWith(
                    color: greyText,
                    height: 1.5,
                  ),
                  textAlign: TextAlign.center,
                ),

                if (widget.onRetry != null) ...[
                  SizedBox(height: 32.h),

                  // ── Retry button ───────────────────────────────────────
                  GestureDetector(
                    onTap: widget.onRetry,
                    child: Container(
                      padding: EdgeInsets.symmetric(
                          horizontal: 28.w, vertical: 13.h),
                      decoration: BoxDecoration(
                        color: accentColor,
                        borderRadius: BorderRadius.circular(24.r),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            Icons.refresh_rounded,
                            size: 18.r,
                            color: isDark
                                ? ColorManager.primaryBlack
                                : ColorManager.white,
                          ),
                          SizedBox(width: 8.w),
                          Text(
                            'Try Again',
                            style: TextStyles.font14Medium.copyWith(
                              color: isDark
                                  ? ColorManager.primaryBlack
                                  : ColorManager.white,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),

                  SizedBox(height: 16.h),

                  // ── Pull hint ──────────────────────────────────────────
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.keyboard_arrow_down_rounded,
                        size: 16.r,
                        color: isDark
                            ? const Color(0xFF555555)
                            : const Color(0xFFCCCCCC),
                      ),
                      SizedBox(width: 4.w),
                      Text(
                        'or pull down to refresh',
                        style: TextStyles.font12Medium.copyWith(
                          color: isDark
                              ? const Color(0xFF555555)
                              : const Color(0xFFCCCCCC),
                        ),
                      ),
                    ],
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _DashedCirclePainter extends CustomPainter {
  final Color color;
  final int dashCount;
  final double strokeWidth;

  const _DashedCirclePainter({
    required this.color,
    required this.dashCount,
    required this.strokeWidth,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..strokeWidth = strokeWidth
      ..strokeCap = StrokeCap.round
      ..style = PaintingStyle.stroke;

    final center = Offset(size.width / 2, size.height / 2);
    final radius = (size.width / 2) - strokeWidth;
    final angleStep = (2 * math.pi) / dashCount;
    const dashAngle = 0.18;

    for (int i = 0; i < dashCount; i++) {
      final startAngle = i * angleStep;
      canvas.drawArc(
        Rect.fromCircle(center: center, radius: radius),
        startAngle,
        dashAngle,
        false,
        paint,
      );
    }
  }

  @override
  bool shouldRepaint(_DashedCirclePainter old) =>
      old.color != color || old.dashCount != dashCount;
}
