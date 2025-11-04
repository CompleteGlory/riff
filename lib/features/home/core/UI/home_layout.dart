import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:riff/features/home/core/UI/app_bottom_nav.dart';
import 'package:riff/features/home/core/logic/cubit/home_cubit.dart';
import 'package:riff/features/home/core/logic/cubit/home_state.dart';

class HomeLayout extends StatelessWidget {
  const HomeLayout({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<HomeCubit, HomeState>(
      builder: (context, state) => Scaffold(
        body: context
            .read<HomeCubit>()
            .screens[context.read<HomeCubit>().currentIndex],
        bottomNavigationBar: AppBottomNav(cubit: context
            .read<HomeCubit>()),
      ),
    );
  }
}