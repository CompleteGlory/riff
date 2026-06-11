// ignore_for_file: deprecated_member_use

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:riff/core/helpers/extenstions.dart';
import 'package:riff/core/helpers/shared_pref_helper.dart';
import 'package:riff/core/routing/routes.dart';
import 'package:riff/core/themes/text_styles/text_styles.dart';
import 'package:riff/core/widgets/button.dart';
import 'package:riff/features/home/core/UI/app_bottom_nav.dart';
import 'package:riff/features/home/core/logic/cubit/home_cubit.dart';
import 'package:riff/features/home/core/logic/cubit/home_state.dart';

class HomeLayout extends StatelessWidget {
  const HomeLayout({super.key});

  Future<bool> _onWillPop(BuildContext context) async {
    // Prevent navigating back to auth/onboarding. Instead ask user to exit the app.
    final shouldExit = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Exit App'),
        content: const Text('Do you want to exit the app?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('Exit'),
          ),
        ],
      ),
    );

    if (shouldExit == true) {
      // Close the app instead of popping back to auth screens.
      SystemNavigator.pop();
      return false; // we've handled exit
    }

    return false; // don't pop the Home route
  }

  @override
  Widget build(BuildContext context) {
    return WillPopScope(
      onWillPop: () => _onWillPop(context),
      child: BlocBuilder<HomeCubit, HomeState>(
        builder: (context, state) => Scaffold(
          backgroundColor: const Color(0xFFF7F7F7),
          appBar: AppBar(
            backgroundColor: const Color(0xFFF7F7F7),
            title: Text(
              context.read<HomeCubit>().titles[
                  context.read<HomeCubit>().currentIndex],
                  style: TextStyles.font28Bold,
            ),
          ),
          drawer: Drawer(
            child: Padding(
              padding: const EdgeInsets.all(15.0),
              child: Column(
                children: [
                  DrawerHeader(
                    child: Text(
                      'Riff',
                      style: TextStyles.font28Bold,
                    ),
                  ),
                  AppButton(onPressed: (){
                      context.pushReplacementNamed(Routes.login);
                      SharedPrefHelper.clearAllData();
                  }, text:"Logout", isWhite: false,image: "assets/svgs/Logout.svg")
                ],
              ),
            ),
          ), // Add your drawer widget here
          body: context
              .read<HomeCubit>()
              .screens[context.read<HomeCubit>().currentIndex],
          bottomNavigationBar: AppBottomNav(cubit: context
              .read<HomeCubit>()),
        ),
      ),
    );
  }
}