import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:riff/core/di/dependency_injection.dart';
import 'package:riff/features/home/feed/Ui/widgets/feed/feed_bloc_listener.dart';
import 'package:riff/features/home/feed/Ui/widgets/feed/feed_screen_body.dart';
import 'package:riff/features/home/feed/logic/cubit/feed/feed_cubit.dart';
import 'package:riff/features/home/core/logic/cubit/home_cubit.dart';
import 'package:riff/features/home/core/logic/cubit/home_state.dart';

class FeedScreen extends StatelessWidget {
  const FeedScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (context) => getIt<FeedCubit>()..getPosts(),
      child: _FeedRefreshListener(
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
          child: const Stack(
            children: [
              FeedScreenBody(),
              FeedBlocListener(),
            ],
          ),
        ),
      ),
    );
  }
}

/// Refreshes the feed when [FeedCubit.requestRefresh] fires (e.g. after a new
/// post finishes uploading), so the just-created post appears without the user
/// having to pull-to-refresh. Lives below the [BlocProvider] so it can reach the
/// feed cubit via context.
class _FeedRefreshListener extends StatefulWidget {
  const _FeedRefreshListener({required this.child});

  final Widget child;

  @override
  State<_FeedRefreshListener> createState() => _FeedRefreshListenerState();
}

class _FeedRefreshListenerState extends State<_FeedRefreshListener> {
  StreamSubscription<void>? _sub;

  @override
  void initState() {
    super.initState();
    _sub = FeedCubit.refreshRequests.listen((_) {
      if (mounted) context.read<FeedCubit>().getPosts(refresh: true);
    });
  }

  @override
  void dispose() {
    _sub?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => widget.child;
}
