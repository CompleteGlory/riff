import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:riff/features/home/core/UI/widgets/bottom_nav_item.dart';
import 'package:riff/features/home/core/logic/cubit/home_cubit.dart';

class AppBottomNav extends StatelessWidget {
  final HomeCubit cubit;
  const AppBottomNav({super.key, required this.cubit});

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Padding(
        padding: EdgeInsets.symmetric(vertical: 15.h,horizontal: 35.w),
        child: Row(children: [
            BottomNavItem(index: 0, cubit: cubit, image: cubit.currentIndex == 0 ? "assets/svgs/home_filled.svg" : "assets/svgs/home.svg"),
            const Spacer(),
            BottomNavItem(index: 1, cubit: cubit, image: cubit.currentIndex == 1 ? "assets/svgs/search_filled.svg" : "assets/svgs/search.svg"),
            const Spacer(),
            BottomNavItem(index: 2, cubit: cubit, image: cubit.currentIndex == 2 ? "assets/svgs/notifications_filled.svg" : "assets/svgs/notifications.svg"),
            const Spacer(),
            BottomNavItem(index: 3, cubit: cubit, image: cubit.currentIndex == 3 ? "assets/svgs/profile_filled.svg" : "assets/svgs/profile.svg"),
            ],),
      ));
  }
}