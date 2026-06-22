import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:riff/core/themes/colors/color_manager.dart';
import 'package:riff/features/home/feed/logic/cubit/report/report_cubit.dart';
import 'package:riff/features/home/feed/logic/cubit/report/report_state.dart';
import 'package:riff/generated/l10n.dart';

class ReportCommentScreen extends StatefulWidget {
  final String commentId;
  final String commentPreview;

  const ReportCommentScreen({
    super.key,
    required this.commentId,
    required this.commentPreview,
  });

  @override
  State<ReportCommentScreen> createState() => _ReportCommentScreenState();
}

class _ReportCommentScreenState extends State<ReportCommentScreen> {
  String? _selectedReason;
  final _detailsController = TextEditingController();




  List<String> _buildReasons(BuildContext context) {
    final s = S.of(context);
    return [
      s.spamOrMisleading,
      s.hateSpeechOrDiscrimination,
      s.violenceOrDangerous,
      s.nudityOrSexual,
      s.harassmentOrBullying,
      s.falseInformation,
      s.intellectualPropertyViolation,
      s.otherReason,
    ];
  }
  @override
  void dispose() {
    _detailsController.dispose();
    super.dispose();
  }

  void _submit(ReportCubit cubit) {
    if (_selectedReason == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(S.of(context).pleaseSelectAReason)),
      );
      return;
    }
    cubit.reportComment(
      commentId: widget.commentId,
      reason: _selectedReason!,
      details: _detailsController.text.trim(),
    );
  }

  @override
  Widget build(BuildContext context) {
    final s = S.of(context);
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bg = isDark ? const Color(0xFF1A1A1A) : const Color(0xFFF6F4F0);
    final cardBg = isDark ? const Color(0xFF252525) : Colors.white;
    final onSurface = Theme.of(context).colorScheme.onSurface;

    return BlocConsumer<ReportCubit, ReportState>(
      listener: (context, state) {
        if (state is ReportSuccess) {
          Navigator.pop(context);
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              backgroundColor: ColorManager.accent,
              content: Text(
                s.reportSubmittedThankYou,
                style: TextStyle(
                  fontFamily: 'GeneralSans',
                  fontWeight: FontWeight.w600,
                  color: Colors.black,
                ),
              ),
            ),
          );
        } else if (state is ReportFailure) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(s.failedToSubmitReport)),
          );
        }
      },
      builder: (context, state) {
        final isSubmitting = state is ReportLoading;
        final cubit = context.read<ReportCubit>();

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
              s.reportCommentTitle,
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
                        if (widget.commentPreview.isNotEmpty) ...[
                          Container(
                            width: double.infinity,
                            padding: EdgeInsets.symmetric(horizontal: 14.w, vertical: 10.h),
                            decoration: BoxDecoration(
                              color: isDark ? const Color(0xFF2A2A2A) : const Color(0xFFEEEEEE),
                              borderRadius: BorderRadius.circular(10.r),
                              border: Border.all(
                                color: isDark ? const Color(0xFF3A3A3A) : const Color(0xFFDDDDDD),
                              ),
                            ),
                            child: Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                SvgPicture.asset(
                                  'assets/svgs/Chat.svg',
                                  width: 14.r,
                                  height: 14.r,
                                  colorFilter: ColorFilter.mode(
                                    isDark ? const Color(0xFF666666) : const Color(0xFF999999),
                                    BlendMode.srcIn,
                                  ),
                                ),
                                SizedBox(width: 8.w),
                                Expanded(
                                  child: Text(
                                    widget.commentPreview,
                                    maxLines: 2,
                                    overflow: TextOverflow.ellipsis,
                                    style: TextStyle(
                                      fontFamily: 'GeneralSans',
                                      fontSize: 13.sp,
                                      color: isDark ? const Color(0xFF888888) : const Color(0xFF666666),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                          SizedBox(height: 16.h),
                        ],
                        Padding(
                          padding: EdgeInsets.only(left: 4.w, bottom: 12.h),
                          child: Text(
                            s.whyReportingComment,
                            style: TextStyle(
                              fontFamily: 'GeneralSans',
                              fontSize: 14.sp,
                              fontWeight: FontWeight.w500,
                              color: isDark ? const Color(0xFF888888) : const Color(0xFF666666),
                            ),
                          ),
                        ),
                        Container(
                          decoration: BoxDecoration(color: cardBg, borderRadius: BorderRadius.circular(16.r)),
                          child: Column(
                            children: _buildReasons(context).asMap().entries.map((e) {
                              final idx = e.key;
                              final reason = e.value;
                              final isLast = idx == _buildReasons(context).length - 1;
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
                                      padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 14.h),
                                      child: Row(
                                        children: [
                                          Expanded(
                                            child: Text(
                                              reason,
                                              style: TextStyle(
                                                fontFamily: 'GeneralSans',
                                                fontSize: 15.sp,
                                                fontWeight: isSelected ? FontWeight.w600 : FontWeight.w400,
                                                color: isSelected ? ColorManager.accent : onSurface,
                                              ),
                                            ),
                                          ),
                                          AnimatedContainer(
                                            duration: const Duration(milliseconds: 200),
                                            width: 20.r,
                                            height: 20.r,
                                            decoration: BoxDecoration(
                                              shape: BoxShape.circle,
                                              color: isSelected ? ColorManager.accent : Colors.transparent,
                                              border: Border.all(
                                                color: isSelected
                                                    ? ColorManager.accent
                                                    : (isDark ? const Color(0xFF444444) : const Color(0xFFCCCCCC)),
                                                width: 1.5,
                                              ),
                                            ),
                                            child: isSelected
                                                ? Icon(Icons.check_rounded, size: 13.r, color: Colors.black)
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
                                      color: isDark ? const Color(0xFF333333) : const Color(0xFFEEEEEE),
                                    ),
                                ],
                              );
                            }).toList(),
                          ),
                        ),
                        SizedBox(height: 20.h),
                        Text(
                          s.additionalDetails,
                          style: TextStyle(
                            fontFamily: 'GeneralSans',
                            fontSize: 14.sp,
                            fontWeight: FontWeight.w500,
                            color: isDark ? const Color(0xFF888888) : const Color(0xFF666666),
                          ),
                        ),
                        SizedBox(height: 8.h),
                        Container(
                          decoration: BoxDecoration(color: cardBg, borderRadius: BorderRadius.circular(16.r)),
                          child: TextField(
                            controller: _detailsController,
                            maxLines: 4,
                            maxLength: 500,
                            style: TextStyle(fontFamily: 'GeneralSans', fontSize: 14.sp, color: onSurface),
                            decoration: InputDecoration(
                              hintText: s.tellUsMoreAboutIssue,
                              hintStyle: TextStyle(
                                fontFamily: 'GeneralSans',
                                fontSize: 14.sp,
                                color: isDark ? const Color(0xFF555555) : const Color(0xFFAAAAAA),
                              ),
                              border: InputBorder.none,
                              contentPadding: EdgeInsets.all(16.r),
                              counterStyle: TextStyle(
                                fontFamily: 'GeneralSans',
                                fontSize: 11.sp,
                                color: isDark ? const Color(0xFF555555) : const Color(0xFFAAAAAA),
                              ),
                            ),
                          ),
                        ),
                        SizedBox(height: 8.h),
                        Text(
                          s.yourReportIsAnonymous,
                          style: TextStyle(
                            fontFamily: 'GeneralSans',
                            fontSize: 12.sp,
                            color: isDark ? const Color(0xFF666666) : const Color(0xFF999999),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                Padding(
                  padding: EdgeInsets.fromLTRB(16.w, 8.h, 16.w, 24.h),
                  child: SizedBox(
                    width: double.infinity,
                    height: 52.h,
                    child: AnimatedSwitcher(
                      duration: const Duration(milliseconds: 200),
                      child: isSubmitting
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
                                    valueColor: AlwaysStoppedAnimation<Color>(Colors.black),
                                  ),
                                ),
                              ),
                            )
                          : GestureDetector(
                              key: const ValueKey('submit'),
                              onTap: () => _submit(cubit),
                              child: Container(
                                decoration: BoxDecoration(
                                  color: _selectedReason != null
                                      ? Colors.red
                                      : (isDark ? const Color(0xFF333333) : const Color(0xFFDDDDDD)),
                                  borderRadius: BorderRadius.circular(14.r),
                                ),
                                child: Center(
                                  child: Text(
                                    s.submitReportBtn,
                                    style: TextStyle(
                                      fontFamily: 'GeneralSans',
                                      fontSize: 15.sp,
                                      fontWeight: FontWeight.w700,
                                      color: _selectedReason != null
                                          ? Colors.white
                                          : (isDark ? const Color(0xFF555555) : const Color(0xFFAAAAAA)),
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
      },
    );
  }
}
