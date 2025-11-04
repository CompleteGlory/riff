import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:riff/core/helpers/constants.dart';
import 'package:riff/core/helpers/extenstions.dart';
import 'package:riff/core/helpers/shared_pref_helper.dart';
import 'package:riff/core/routing/routes.dart';
import 'package:riff/core/themes/text_styles/text_styles.dart';
import 'package:riff/core/widgets/button.dart';
import 'package:riff/features/home/core/UI/widgets/post_item.dart';

class FeedScreen extends StatelessWidget {
  const FeedScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
        child: SafeArea(
          child: Padding(
            padding: EdgeInsets.symmetric(horizontal: 24.w),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text("Discover", style: TextStyles.font28Bold),
                PostItem(),
                PostItem(),
                AppButton(onPressed: ()async{
                  await SharedPrefHelper.removeData(SharedPrefKeys.userToken);
                  context.pushReplacementNamed(Routes.login);
                  }, text: "Log Out", isWhite:false),
              ],
            ),
          ),
        ),
      );
  }
}