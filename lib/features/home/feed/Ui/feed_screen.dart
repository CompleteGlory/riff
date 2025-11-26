import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:riff/core/di/dependency_injection.dart';
import 'package:riff/features/home/feed/Ui/widgets/feed_bloc_listener.dart';
import 'package:riff/features/home/feed/Ui/widgets/feed_screen_body.dart';
import 'package:riff/features/home/feed/logic/cubit/feed_cubit.dart';

class FeedScreen extends StatelessWidget {
  const FeedScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (context) => getIt<FeedCubit>()..getPosts(),
      child: Stack(
          children: [
            const FeedScreenBody(),
            const FeedBlocListener(),
            ],
      ),
    );
  }
}
