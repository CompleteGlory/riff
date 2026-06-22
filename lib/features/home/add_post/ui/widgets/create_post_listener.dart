// This file is intentionally kept minimal.
// Upload progress + success/failure handling for CreatePostCubit is now done
// globally by the BlocListener<CreatePostCubit, CreatePostState> inside
// HomeLayout so that it survives navigation away from the create-post screen.
//
// This widget is still exported for any screen that pushes CreatePostScreen
// via a modal route (e.g. the social-share flow) and needs local feedback.
// For those cases it simply re-exports the listener from HomeLayout's context.
//
// If you add your own local listener here, make sure it does NOT call
// Navigator.pushNamedAndRemoveUntil — that is handled globally.

export 'package:riff/features/home/add_post/ui/widgets/create_post_wrapper.dart'
    show CreatePostWrapper;
