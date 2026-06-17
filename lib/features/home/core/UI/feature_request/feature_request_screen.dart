import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:riff/core/themes/colors/color_manager.dart';
import 'package:riff/features/home/core/logic/feature_request/feature_request_cubit.dart';
import 'package:riff/features/home/core/logic/feature_request/feature_request_state.dart';
import 'package:riff/features/home/core/UI/shared/report_widgets.dart';
import 'package:riff/generated/l10n.dart';

class FeatureRequestScreen extends StatefulWidget {
  const FeatureRequestScreen({super.key});

  @override
  State<FeatureRequestScreen> createState() => _FeatureRequestScreenState();
}

class _FeatureRequestScreenState extends State<FeatureRequestScreen> {
  final _titleController = TextEditingController();
  final _descController = TextEditingController();
  final _whyController = TextEditingController();

  @override
  void dispose() {
    _titleController.dispose();
    _descController.dispose();
    _whyController.dispose();
    super.dispose();
  }

  void _submit(FeatureRequestCubit cubit) {
    if (_titleController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(S.of(context).pleaseAddTitle)),
      );
      return;
    }
    if (_descController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(S.of(context).pleaseDescribeFeature)),
      );
      return;
    }
    cubit.submit(
      title: _titleController.text.trim(),
      description: _descController.text.trim(),
      motivation: _whyController.text.trim(),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bg = isDark ? const Color(0xFF1A1A1A) : const Color(0xFFF6F4F0);
    final cardBg = isDark ? const Color(0xFF252525) : Colors.white;
    final onSurface = Theme.of(context).colorScheme.onSurface;
    final hintColor = isDark ? const Color(0xFF555555) : const Color(0xFFAAAAAA);
    final labelColor = isDark ? const Color(0xFF888888) : const Color(0xFF666666);

    return BlocConsumer<FeatureRequestCubit, FeatureRequestState>(
      listener: (context, state) {
        if (state is FeatureRequestSuccess) {
          Navigator.pop(context);
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              backgroundColor: ColorManager.accent,
              content: Text(
                S.of(context).featureRequestSubmitted,
                style: TextStyle(
                  fontFamily: 'GeneralSans',
                  fontWeight: FontWeight.w600,
                  color: Colors.black,
                ),
              ),
            ),
          );
        } else if (state is FeatureRequestFailure) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(S.of(context).failedToSubmit)),
          );
        }
      },
      builder: (context, state) {
        final isLoading = state is FeatureRequestLoading;
        final cubit = context.read<FeatureRequestCubit>();

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
              S.of(context).featureRequestTitle,
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
                        Center(
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                            decoration: BoxDecoration(
                              color: ColorManager.accent.withValues(alpha: 0.12),
                              borderRadius: BorderRadius.circular(100),
                              border: Border.all(color: ColorManager.accent.withValues(alpha: 0.3)),
                            ),
                            child: const Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(Icons.lightbulb_outline_rounded, size: 16, color: ColorManager.accent),
                                SizedBox(width: 6),
                                Text(
                                  'Share your idea with the Riff team',
                                  style: TextStyle(
                                    fontFamily: 'GeneralSans',
                                    fontSize: 13,
                                    fontWeight: FontWeight.w500,
                                    color: ColorManager.accent,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                        SizedBox(height: 20.h),
                        ReportSectionLabel(text: S.of(context).featureTitleLabel, color: labelColor),
                        SizedBox(height: 6.h),
                        ReportInputCard(
                          cardBg: cardBg,
                          child: TextField(
                            controller: _titleController,
                            maxLines: 1,
                            style: TextStyle(fontFamily: 'GeneralSans', fontSize: 14.sp, color: onSurface),
                            decoration: InputDecoration(
                              hintText: 'e.g. Dark mode for comments',
                              hintStyle: TextStyle(fontFamily: 'GeneralSans', fontSize: 14.sp, color: hintColor),
                              border: InputBorder.none,
                              contentPadding: EdgeInsets.all(16.r),
                            ),
                          ),
                        ),
                        SizedBox(height: 16.h),
                        ReportSectionLabel(text: S.of(context).describeTheFeature, color: labelColor),
                        SizedBox(height: 6.h),
                        ReportInputCard(
                          cardBg: cardBg,
                          child: TextField(
                            controller: _descController,
                            maxLines: 5,
                            maxLength: 1000,
                            style: TextStyle(fontFamily: 'GeneralSans', fontSize: 14.sp, color: onSurface),
                            decoration: InputDecoration(
                              hintText: S.of(context).whatShouldItDo,
                              hintStyle: TextStyle(fontFamily: 'GeneralSans', fontSize: 14.sp, color: hintColor),
                              border: InputBorder.none,
                              contentPadding: EdgeInsets.all(16.r),
                              counterStyle: TextStyle(fontFamily: 'GeneralSans', fontSize: 11.sp, color: hintColor),
                            ),
                          ),
                        ),
                        SizedBox(height: 16.h),
                        ReportSectionLabel(text: S.of(context).whyWouldBeUseful, color: labelColor),
                        SizedBox(height: 6.h),
                        ReportInputCard(
                          cardBg: cardBg,
                          child: TextField(
                            controller: _whyController,
                            maxLines: 3,
                            style: TextStyle(fontFamily: 'GeneralSans', fontSize: 14.sp, color: onSurface),
                            decoration: InputDecoration(
                              hintText: S.of(context).whoBenefitAndHow,
                              hintStyle: TextStyle(fontFamily: 'GeneralSans', fontSize: 14.sp, color: hintColor),
                              border: InputBorder.none,
                              contentPadding: EdgeInsets.all(16.r),
                            ),
                          ),
                        ),
                        SizedBox(height: 20.h),
                      ],
                    ),
                  ),
                ),
                Padding(
                  padding: EdgeInsets.fromLTRB(16.w, 8.h, 16.w, 24.h),
                  child: ReportSubmitButton(
                    isSubmitting: isLoading,
                    label: S.of(context).submitRequestBtn,
                    onTap: () => _submit(cubit),
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
