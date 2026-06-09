import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:riff/features/home/add_post/logic/cubit/update_post_cubit.dart';
import 'package:riff/features/home/add_post/ui/widgets/update_post_listener.dart';
import 'package:riff/features/home/add_post/ui/widgets/update_post_screen.dart';
import 'package:riff/features/home/feed/data/models/post.dart';

class UpdatePostDialog extends StatelessWidget {
  final Post post;
  final UpdatePostCubit updatePostCubit;

  const UpdatePostDialog({
    super.key,
    required this.post,
    required this.updatePostCubit,
  });

  @override
  Widget build(BuildContext context) {
    return BlocProvider.value(
      value: updatePostCubit,
      child: UpdatePostListener(
        child: Dialog(
          insetPadding: EdgeInsets.zero,
          child: UpdatePostScreen(post: post),
        ),
      ),
    );
  }
}
