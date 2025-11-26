import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:riff/features/home/feed/Ui/widgets/post_item.dart';
import 'package:riff/features/home/feed/logic/cubit/feed_cubit.dart';
import 'package:riff/features/home/feed/logic/cubit/feed_state.dart';

class FeedScreenBody extends StatelessWidget {
  const FeedScreenBody({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<FeedCubit, FeedState>(
      builder: (context, state) {
        return state.when(
          initial: () => const Center(child: Text("No posts loaded")),
          loading: () => const Center(child: CircularProgressIndicator()),
          success: (postsResponse) {
            final posts = postsResponse.data;

            if (posts.isEmpty) {
              return const Center(child: Text("No posts yet"));
            }

            return ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: posts.length,
              itemBuilder: (context, index) {
                final post = posts[index];
                return PostItem(
                  post: post,
                );
              },
            );
          },
          failure: (error) {
            return Center(child: Text(error.errors?[0].message??"An error occurred"));
          },
        );
      },
    );
  }
}
