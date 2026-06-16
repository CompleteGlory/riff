import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:riff/core/helpers/extenstions.dart';
import 'package:riff/core/routing/routes.dart';
import 'package:riff/core/themes/text_styles/text_styles.dart';
import 'package:riff/core/widgets/button.dart';

class OnBoardingScreen extends StatelessWidget {
  const OnBoardingScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      body: Stack(
        fit: StackFit.expand,
        children: [
          // Background image — fills the whole screen
          Image.asset(
            'assets/images/onboarding_background.png',
            fit: BoxFit.cover,
          ),
          // Dark scrim so text is always readable
          Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  Colors.black.withValues(alpha: 0.25),
                  Colors.black.withValues(alpha: 0.55),
                ],
              ),
            ),
          ),
          // Text — anchored to top-left with safe area padding
          SafeArea(
            child: Padding(
              padding: EdgeInsets.symmetric(horizontal: 24.w, vertical: 32.h),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  Text(
                    'Define Yourself\nin Your Unique Way.',
                    style: TextStyles.font45SemiBold.copyWith(
                      color: Colors.white,
                      height: 1.15,
                      shadows: [
                        Shadow(
                          color: Colors.black.withValues(alpha: 0.4),
                          blurRadius: 12,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                  ),
                  SizedBox(height: 12.h),
                  Text(
                    'Share your sound. Find your people.',
                    style: TextStyles.font16Medium.copyWith(
                      color: Colors.white.withValues(alpha: 0.85),
                      shadows: [
                        Shadow(
                          color: Colors.black.withValues(alpha: 0.4),
                          blurRadius: 8,
                        ),
                      ],
                    ),
                  ),
                  SizedBox(height: 120.h),
                ],
              ),
            ),
          ),
        ],
      ),
      bottomNavigationBar: Container(
        height: 100.h,
        color: isDark ? const Color(0xFF141414) : Colors.white,
        padding: const EdgeInsets.all(25.0),
        child: AppButton(
          onPressed: () => context.pushNamed(Routes.instruments),
          text: 'Get Started',
          isWhite: false,
          icon: Icons.arrow_forward,
        ),
      ),
    );
  }
}
