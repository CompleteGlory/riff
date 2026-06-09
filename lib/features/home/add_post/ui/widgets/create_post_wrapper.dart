import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:riff/core/di/dependency_injection.dart'; // Assumed dependency injection import
import 'package:riff/features/home/add_post/logic/cubit/create_post_cubit.dart';
import 'package:riff/features/home/add_post/ui/widgets/create_post_listener.dart';
import 'package:riff/features/home/add_post/ui/widgets/create_post_screen.dart';

class CreatePostWrapper extends StatelessWidget {
  const CreatePostWrapper({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      // Ensure CreatePostCubit is registered via getIt
      create: (context) => getIt<CreatePostCubit>(),
      child: const Stack(
        children: [
          // The main UI content
          CreatePostScreen(),
          // The listener that handles navigation and showing dialogs/snackbars
          AddPostListener(),
        ],
      ),
    );
  }
}