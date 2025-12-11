import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:riff/core/themes/text_styles/text_styles.dart';
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
          appBar: AppBar(
            leading: IconButton(
              icon: const Icon(Icons.menu),
              onPressed: () {
               // Scaffold.of(context).openDrawer();
              },
            ),
            title: Text(
              context.read<HomeCubit>().titles[
                  context.read<HomeCubit>().currentIndex],
                  style: TextStyles.font28Bold,
            ),
          ),
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