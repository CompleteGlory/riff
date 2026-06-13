// ignore_for_file: deprecated_member_use
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:riff/features/home/core/UI/app_bottom_nav.dart';
import 'package:riff/features/home/core/UI/drawer/app_drawer.dart';
import 'package:riff/features/home/core/logic/cubit/home_cubit.dart';
import 'package:riff/features/home/core/logic/cubit/home_state.dart';

class HomeLayout extends StatelessWidget {
  const HomeLayout({super.key});

  Future<bool> _onWillPop(BuildContext context) async {
    final shouldExit = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Exit App'),
        content: const Text('Do you want to exit the app?'),
        actions: [
          TextButton(onPressed: () => Navigator.of(ctx).pop(false),
              child: const Text('Cancel')),
          TextButton(onPressed: () => Navigator.of(ctx).pop(true),
              child: const Text('Exit')),
        ],
      ),
    );
    if (shouldExit == true) { SystemNavigator.pop(); return false; }
    return false;
  }

  @override
  Widget build(BuildContext context) {
    return WillPopScope(
      onWillPop: () => _onWillPop(context),
      child: BlocBuilder<HomeCubit, HomeState>(
        builder: (context, state) => Scaffold(
          extendBody: true,
          appBar: context.read<HomeCubit>().currentIndex == 3
              ? null
              : AppBar(
                  title: Text(
                    context.read<HomeCubit>().titles[
                        context.read<HomeCubit>().currentIndex],
                  ),
                ),
          drawer: const AppDrawer(),
          body: context.read<HomeCubit>()
              .screens[context.read<HomeCubit>().currentIndex],
          bottomNavigationBar: AppBottomNav(
              cubit: context.read<HomeCubit>()),
        ),
      ),
    );
  }
}

// ── Drawer ────────────────────────────────────────────────────────────────────

