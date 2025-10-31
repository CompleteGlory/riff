import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:riff/core/themes/text_styles/text_styles.dart';
import 'package:riff/core/widgets/button.dart';

class OnBoardingScreen extends StatelessWidget {
  const OnBoardingScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Stack(
        children: [
          Image.asset("assets/images/onboarding_background.png",width: double.infinity,fit: BoxFit.cover,),
          // Column(
          //   children: [
              
          //    // Image.asset("assets/images/onboarding_image.png",width: double.infinity,fit: BoxFit.cover,alignment: AlignmentDirectional.topCenter,height: 685.h,),
          //   ],
          // ),
          Padding(
            padding: EdgeInsets.symmetric(horizontal: 24.w),
            child: Column(children: [
              Center(child: Text("Define Yourself in your unique way.",style: TextStyles.font50SemiBold,)), 
              ],),
          ),
          
        ],
      )
      ),
      bottomNavigationBar: Container(
        padding: EdgeInsets.all(1),
      color: Colors.white,
      height: 100.h,
      child: Padding(
        padding: const EdgeInsets.all(25.0),
        child: AppButton(onPressed: (){}, text: "Get started", isWhite: false,icon: Icons.arrow_forward,),
      )
      ),
    );
  }
}