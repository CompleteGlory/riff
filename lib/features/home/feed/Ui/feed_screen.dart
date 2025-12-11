import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:riff/core/di/dependency_injection.dart';
import 'package:riff/features/home/feed/Ui/widgets/feed_bloc_listener.dart';
import 'package:riff/features/home/feed/Ui/widgets/feed_screen_body.dart';
import 'package:riff/features/home/feed/logic/cubit/feed_cubit.dart';
import 'package:riff/features/home/core/logic/cubit/home_cubit.dart';
import 'package:riff/features/home/core/logic/cubit/home_state.dart';

class FeedScreen extends StatelessWidget {
  const FeedScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (context) => getIt<FeedCubit>()..getPosts(),
      child: BlocListener<HomeCubit, HomeState>(
        listener: (context, state) {
          state.maybeWhen(
            changeScreen: (index) {
              if (index == 0) {
                // when Home tab changes to Feed, refresh posts
                final feedCubit = context.read<FeedCubit>();
                feedCubit.getPosts(refresh: true);
              }
            },
            orElse: () {},
          );
        },
        child: Stack(
          children: [
            const FeedScreenBody(),
            const FeedBlocListener(),
          ],
        ),
      ),
    );
  }
}
