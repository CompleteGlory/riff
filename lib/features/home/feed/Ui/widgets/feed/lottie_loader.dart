import 'package:flutter/material.dart';
import 'package:lottie/lottie.dart';

class LottieLoader extends StatelessWidget {
  const LottieLoader({super.key});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 56,
      child: Center(
        child: Lottie.asset(
          'assets/animations/loading.json',
          width: 100,
          height: 100,
          fit: BoxFit.contain,
          animate: true,
        ),
      ),
    );
  }
}