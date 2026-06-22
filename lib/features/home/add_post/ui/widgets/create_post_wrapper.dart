import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:riff/core/di/dependency_injection.dart';
import 'package:riff/features/home/add_post/logic/cubit/create_post_cubit.dart';
import 'package:riff/features/home/add_post/ui/widgets/create_post_screen.dart';

/// Thin wrapper that ensures the [CreatePostCubit] singleton is reset to its
/// initial state each time the create-post tab becomes active.
///
/// Uses [BlocProvider.value] (not [BlocProvider]) so the singleton is never
/// closed when the user switches tabs or navigates away mid-upload.
class CreatePostWrapper extends StatefulWidget {
  const CreatePostWrapper({super.key, this.initialMediaPaths});

  final List<String>? initialMediaPaths;

  @override
  State<CreatePostWrapper> createState() => _CreatePostWrapperState();
}

class _CreatePostWrapperState extends State<CreatePostWrapper> {
  @override
  void initState() {
    super.initState();
    // Reset form fields for a fresh post — no-op if an upload is in flight.
    getIt<CreatePostCubit>().reset();
  }

  @override
  Widget build(BuildContext context) {
    return BlocProvider.value(
      value: getIt<CreatePostCubit>(),
      child: CreatePostScreen(initialMediaPaths: widget.initialMediaPaths),
    );
  }
}
