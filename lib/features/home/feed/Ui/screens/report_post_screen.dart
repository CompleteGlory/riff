import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:riff/core/networks/api_constants.dart';
import 'package:riff/core/networks/dio_factory.dart';
import 'package:riff/core/themes/colors/color_manager.dart';

class ReportPostScreen extends StatefulWidget {
  final String postId;
  const ReportPostScreen({super.key, required this.postId});

  @override
  State<ReportPostScreen> createState() => _ReportPostScreenState();
}

class _ReportPostScreenState extends State<ReportPostScreen> {
  String? _selectedReason;
  final _detailsController = TextEditingController();
  bool _isSubmitting = false;

  static const _reasons = [
    'Spam or misleading',
    'Hate speech or discrimination',
    'Violence or dangerous content',
    'Nudity or sexual content',
    'Harassment or bullying',
    'False information',
    'Intellectual property violation',
    'Other',
  ];

  @override
  void dispose() {
    _detailsController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (_selectedReason == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select a reason')),
      );
      return;
    }
    setState(() => _isSubmitting = true);
    try {
      final dio = await DioFactory.getDio();
      await dio.post(
        ApiConstants.reportPost(widget.postId),
        data: {
          'reason': _selectedReason,
          if (_detailsController.text.trim().isNotEmpty)
            'details': _detailsController.text.trim(),
        },
      );
      if (mounted) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            backgroundColor: ColorManager.accent,
            content: const Text(
              'Report submitted. Thank you.',
              style: TextStyle(
                fontFamily: 'GeneralSans',
                fontWeight: FontWeight.w600,
                color: Colors.black,
              ),
            ),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Failed to submit report. Try again.')),
        );
      }
    } finally {
      if (mounted) setState(() => _isSubmitting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bg = isDark ? const Color(0xFF1A1A1A) : const Color(0xFFF6F4F0);
    final cardBg = isDark ? const Color(0xFF252525) : Colors.white;
    final onSurface = Theme.of(context).colorScheme.onSurface;

    return Scaffold(
      backgroundColor: bg,
      appBar: AppBar(
        backgroundColor: bg,
        elevation: 0,
        surfaceTintColor: Colors.transparent,
        leading: IconButton(
          icon: Icon(Icons.arrow_back_ios_new_rounded, size: 18.r, color: onSurface),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          'Report Post',
          style: TextStyle(
            fontFamily: 'GeneralSans',
            fontSize: 17.sp,
            fontWeight: FontWeight.w700,
            color: onSurface,
          ),
        ),
        centerTitle: true,
      ),
      body: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: SingleChildScrollView(
                padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 8.h),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Padding(
                      padding: EdgeInsets.only(left: 4.w, bottom: 12.h),
                      child: Text(
                        'Why are you reporting this post?',
                        style: TextStyle(
                          fontFamily: 'GeneralSans',
                          fontSize: 14.sp,
                          fontWeight: FontWeight.w500,
                          color: isDark ? const Color(0xFF888888) : const Color(0xFF666666),
                        ),
                      ),
                    ),
                    Container(
                      decoration: BoxDecoration(
                        color: cardBg,
                        borderRadius: BorderRadius.circular(16.r),
                      ),
                      child: Column(
                        children: _reasons.asMap().entries.map((e) {
                          final idx = e.key;
                          final reason = e.value;
                          final isLast = idx == _reasons.length - 1;
                          final isSelected = _selectedReason == reason;
                          return Column(
                            children: [
                              InkWell(
                                onTap: () => setState(() => _selectedReason = reason),
                                borderRadius: BorderRadius.vertical(
                                  top: idx == 0 ? Radius.circular(16.r) : Radius.zero,
                                  bottom: isLast ? Radius.circular(16.r) : Radius.zero,
                                ),
                                child: Padding(
                                  padding: EdgeInsets.symmetric(
                                    horizontal: 16.w, vertical: 14.h),
                                  child: Row(
                                    children: [
                                      Expanded(
                                        child: Text(
                                          reason,
                                          style: TextStyle(
                                            fontFamily: 'GeneralSans',
                                            fontSize: 15.sp,
                                            fontWeight: isSelected
                                                ? FontWeight.w600
                                                : FontWeight.w400,
                                            color: isSelected
                                                ? ColorManager.accent
                                                : onSurface,
                                          ),
                                        ),
                                      ),
                                      AnimatedContainer(
                                        duration: const Duration(milliseconds: 200),
                                        width: 20.r,
                                        height: 20.r,
                                        decoration: BoxDecoration(
                                          shape: BoxShape.circle,
                                          color: isSelected
                                              ? ColorManager.accent
                                              : Colors.transparent,
                                          border: Border.all(
                                            color: isSelected
                                                ? ColorManager.accent
                                                : (isDark
                                                    ? const Color(0xFF444444)
                                                    : const Color(0xFFCCCCCC)),
                                            width: 1.5,
                                          ),
                                        ),
                                        child: isSelected
                                            ? Icon(Icons.check_rounded,
                                                size: 13.r, color: Colors.black)
                                            : null,
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                              if (!isLast)
                                Divider(
                                  height: 1,
                                  indent: 16.w,
                                  endIndent: 16.w,
                                  color: isDark
                                      ? const Color(0xFF333333)
                                      : const Color(0xFFEEEEEE),
                                ),
                            ],
                          );
                        }).toList(),
                      ),
                    ),
                    SizedBox(height: 20.h),
                    Text(
                      'Additional details (optional)',
                      style: TextStyle(
                        fontFamily: 'GeneralSans',
                        fontSize: 14.sp,
                        fontWeight: FontWeight.w500,
                        color: isDark ? const Color(0xFF888888) : const Color(0xFF666666),
                      ),
                    ),
                    SizedBox(height: 8.h),
                    Container(
                      decoration: BoxDecoration(
                        color: cardBg,
                        borderRadius: BorderRadius.circular(16.r),
                      ),
                      child: TextField(
                        controller: _detailsController,
                        maxLines: 4,
                        maxLength: 500,
                        style: TextStyle(
                          fontFamily: 'GeneralSans',
                          fontSize: 14.sp,
                          color: onSurface,
                        ),
                        decoration: InputDecoration(
                          hintText: 'Tell us more about the issue...',
                          hintStyle: TextStyle(
                            fontFamily: 'GeneralSans',
                            fontSize: 14.sp,
                            color: isDark
                                ? const Color(0xFF555555)
                                : const Color(0xFFAAAAAA),
                          ),
                          border: InputBorder.none,
                          contentPadding: EdgeInsets.all(16.r),
                          counterStyle: TextStyle(
                            fontFamily: 'GeneralSans',
                            fontSize: 11.sp,
                            color: isDark
                                ? const Color(0xFF555555)
                                : const Color(0xFFAAAAAA),
                          ),
                        ),
                      ),
                    ),
                    SizedBox(height: 8.h),
                    Text(
                      'Your report is anonymous. We review all reports carefully.',
                      style: TextStyle(
                        fontFamily: 'GeneralSans',
                        fontSize: 12.sp,
                        color: isDark
                            ? const Color(0xFF666666)
                            : const Color(0xFF999999),
                      ),
                    ),
                  ],
                ),
              ),
            ),

            // Submit button
            Padding(
              padding: EdgeInsets.fromLTRB(16.w, 8.h, 16.w, 24.h),
              child: SizedBox(
                width: double.infinity,
                height: 52.h,
                child: AnimatedSwitcher(
                  duration: const Duration(milliseconds: 200),
                  child: _isSubmitting
                      ? Container(
                          key: const ValueKey('loading'),
                          decoration: BoxDecoration(
                            color: ColorManager.accent.withValues(alpha: 0.7),
                            borderRadius: BorderRadius.circular(14.r),
                          ),
                          child: const Center(
                            child: SizedBox(
                              width: 22,
                              height: 22,
                              child: CircularProgressIndicator(
                                strokeWidth: 2.5,
                                valueColor:
                                    AlwaysStoppedAnimation<Color>(Colors.black),
                              ),
                            ),
                          ),
                        )
                      : GestureDetector(
                          key: const ValueKey('submit'),
                          onTap: _submit,
                          child: Container(
                            decoration: BoxDecoration(
                              color: _selectedReason != null
                                  ? Colors.red
                                  : (isDark
                                      ? const Color(0xFF333333)
                                      : const Color(0xFFDDDDDD)),
                              borderRadius: BorderRadius.circular(14.r),
                            ),
                            child: Center(
                              child: Text(
                                'Submit Report',
                                style: TextStyle(
                                  fontFamily: 'GeneralSans',
                                  fontSize: 15.sp,
                                  fontWeight: FontWeight.w700,
                                  color: _selectedReason != null
                                      ? Colors.white
                                      : (isDark
                                          ? const Color(0xFF555555)
                                          : const Color(0xFFAAAAAA)),
                                ),
                              ),
                            ),
                          ),
                        ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
