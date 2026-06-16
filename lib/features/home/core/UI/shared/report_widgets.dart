import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:riff/core/themes/colors/color_manager.dart';

class ReportSectionLabel extends StatelessWidget {
  final String text;
  final Color color;
  const ReportSectionLabel({super.key, required this.text, required this.color});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(left: 4),
      child: Text(
        text,
        style: TextStyle(
          fontFamily: 'GeneralSans',
          fontSize: 13,
          fontWeight: FontWeight.w500,
          color: color,
        ),
      ),
    );
  }
}

class ReportInputCard extends StatelessWidget {
  final Widget child;
  final Color cardBg;
  const ReportInputCard({super.key, required this.child, required this.cardBg});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: cardBg,
        borderRadius: BorderRadius.circular(16),
      ),
      child: child,
    );
  }
}

class ReportSubmitButton extends StatelessWidget {
  final bool isSubmitting;
  final String label;
  final VoidCallback onTap;
  const ReportSubmitButton({
    super.key,
    required this.isSubmitting,
    required this.label,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      height: 52.h,
      child: GestureDetector(
        onTap: isSubmitting ? null : onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          decoration: BoxDecoration(
            color: isSubmitting
                ? ColorManager.accent.withValues(alpha: 0.7)
                : ColorManager.accent,
            borderRadius: BorderRadius.circular(14),
          ),
          child: Center(
            child: isSubmitting
                ? const SizedBox(
                    width: 22,
                    height: 22,
                    child: CircularProgressIndicator(
                      strokeWidth: 2.5,
                      valueColor: AlwaysStoppedAnimation<Color>(Colors.black),
                    ),
                  )
                : Text(
                    label,
                    style: const TextStyle(
                      fontFamily: 'GeneralSans',
                      fontSize: 15,
                      fontWeight: FontWeight.w700,
                      color: Colors.black,
                    ),
                  ),
          ),
        ),
      ),
    );
  }
}
