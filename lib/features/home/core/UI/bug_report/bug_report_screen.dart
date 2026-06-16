import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:riff/core/networks/api_constants.dart';
import 'package:riff/core/networks/dio_factory.dart';
import 'package:riff/core/themes/colors/color_manager.dart';
import 'package:riff/features/home/core/UI/shared/report_widgets.dart';

class BugReportScreen extends StatefulWidget {
  const BugReportScreen({super.key});

  @override
  State<BugReportScreen> createState() => _BugReportScreenState();
}

class _BugReportScreenState extends State<BugReportScreen> {
  final _titleController = TextEditingController();
  final _descController = TextEditingController();
  final _stepsController = TextEditingController();
  bool _isSubmitting = false;
  String _severity = 'Medium';

  @override
  void dispose() {
    _titleController.dispose();
    _descController.dispose();
    _stepsController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (_titleController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please add a title')),
      );
      return;
    }
    if (_descController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please describe the bug')),
      );
      return;
    }
    setState(() => _isSubmitting = true);
    try {
      final dio = await DioFactory.getDio();
      await dio.post(ApiConstants.reportBug, data: {
        'title': _titleController.text.trim(),
        'description': _descController.text.trim(),
        if (_stepsController.text.trim().isNotEmpty)
          'stepsToReproduce': _stepsController.text.trim(),
        'severity': _severity,
      });
      if (mounted) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            backgroundColor: ColorManager.accent,
            content: const Text(
              'Bug report submitted. Thank you!',
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
          const SnackBar(content: Text('Failed to submit. Please try again.')),
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
    final hintColor = isDark ? const Color(0xFF555555) : const Color(0xFFAAAAAA);
    final labelColor = isDark ? const Color(0xFF888888) : const Color(0xFF666666);

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
          'Report a Bug',
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
                    ReportSectionLabel(text: 'Title', color: labelColor),
                    SizedBox(height: 6.h),
                    ReportInputCard(
                      cardBg: cardBg,
                      child: TextField(
                        controller: _titleController,
                        maxLines: 1,
                        style: TextStyle(fontFamily: 'GeneralSans', fontSize: 14.sp, color: onSurface),
                        decoration: InputDecoration(
                          hintText: 'Short summary of the bug',
                          hintStyle: TextStyle(fontFamily: 'GeneralSans', fontSize: 14.sp, color: hintColor),
                          border: InputBorder.none,
                          contentPadding: EdgeInsets.all(16.r),
                        ),
                      ),
                    ),
                    SizedBox(height: 16.h),
                    ReportSectionLabel(text: 'What happened?', color: labelColor),
                    SizedBox(height: 6.h),
                    ReportInputCard(
                      cardBg: cardBg,
                      child: TextField(
                        controller: _descController,
                        maxLines: 4,
                        maxLength: 1000,
                        style: TextStyle(fontFamily: 'GeneralSans', fontSize: 14.sp, color: onSurface),
                        decoration: InputDecoration(
                          hintText: 'Describe the bug in detail...',
                          hintStyle: TextStyle(fontFamily: 'GeneralSans', fontSize: 14.sp, color: hintColor),
                          border: InputBorder.none,
                          contentPadding: EdgeInsets.all(16.r),
                          counterStyle: TextStyle(fontFamily: 'GeneralSans', fontSize: 11.sp, color: hintColor),
                        ),
                      ),
                    ),
                    SizedBox(height: 16.h),
                    ReportSectionLabel(text: 'Steps to reproduce (optional)', color: labelColor),
                    SizedBox(height: 6.h),
                    ReportInputCard(
                      cardBg: cardBg,
                      child: TextField(
                        controller: _stepsController,
                        maxLines: 3,
                        style: TextStyle(fontFamily: 'GeneralSans', fontSize: 14.sp, color: onSurface),
                        decoration: InputDecoration(
                          hintText: '1. Open app\n2. Tap on...',
                          hintStyle: TextStyle(fontFamily: 'GeneralSans', fontSize: 14.sp, color: hintColor),
                          border: InputBorder.none,
                          contentPadding: EdgeInsets.all(16.r),
                        ),
                      ),
                    ),
                    SizedBox(height: 16.h),
                    ReportSectionLabel(text: 'Severity', color: labelColor),
                    SizedBox(height: 8.h),
                    Row(
                      children: ['Low', 'Medium', 'High', 'Critical'].map((s) {
                        final isSelected = _severity == s;
                        final color = s == 'Critical'
                            ? Colors.red
                            : s == 'High'
                                ? Colors.orange
                                : s == 'Medium'
                                    ? Colors.amber
                                    : Colors.green;
                        return Expanded(
                          child: Padding(
                            padding: EdgeInsets.only(right: s != 'Critical' ? 6.w : 0),
                            child: GestureDetector(
                              onTap: () => setState(() => _severity = s),
                              child: AnimatedContainer(
                                duration: const Duration(milliseconds: 180),
                                padding: EdgeInsets.symmetric(vertical: 10.h),
                                decoration: BoxDecoration(
                                  color: isSelected ? color.withValues(alpha: 0.15) : cardBg,
                                  borderRadius: BorderRadius.circular(10.r),
                                  border: Border.all(
                                    color: isSelected
                                        ? color
                                        : (isDark ? const Color(0xFF333333) : const Color(0xFFE0E0E0)),
                                    width: isSelected ? 1.5 : 1,
                                  ),
                                ),
                                child: Center(
                                  child: Text(
                                    s,
                                    style: TextStyle(
                                      fontFamily: 'GeneralSans',
                                      fontSize: 12.sp,
                                      fontWeight: isSelected ? FontWeight.w700 : FontWeight.w400,
                                      color: isSelected ? color : onSurface,
                                    ),
                                  ),
                                ),
                              ),
                            ),
                          ),
                        );
                      }).toList(),
                    ),
                    SizedBox(height: 20.h),
                  ],
                ),
              ),
            ),
            Padding(
              padding: EdgeInsets.fromLTRB(16.w, 8.h, 16.w, 24.h),
              child: ReportSubmitButton(
                isSubmitting: _isSubmitting,
                label: 'Submit Bug Report',
                onTap: _submit,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
