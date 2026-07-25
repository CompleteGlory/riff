import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/annotations.dart';
import 'package:mockito/mockito.dart';
import 'package:riff/core/networks/api_result.dart';
import 'package:riff/core/widgets/button.dart';
import 'package:riff/features/home/add_post/data/repos/create_post_repo.dart';
import 'package:riff/features/home/add_post/logic/cubit/create_post_cubit.dart';
import 'package:riff/features/home/add_post/ui/widgets/create_post_screen.dart';
import 'package:riff/features/home/feed/data/models/post.dart';

import '../../../../../helpers/pump_app.dart';
import 'create_post_screen_test.mocks.dart';

// Regression test for the "blank screen after posting" bug.
//
// CreatePostScreen is used two ways:
//   • As the "Create Post" tab inside HomeLayout (NOT its own route). Popping
//     here would remove HomeLayout itself → blank screen.
//   • Pushed as its own route by the share flows, where popping correctly
//     returns to what's underneath.
//
// The `popOnSubmit` flag distinguishes them: only pop when true.
@GenerateMocks([CreatePostRepo])
void main() {
  late MockCreatePostRepo mockRepo;
  late CreatePostCubit cubit;

  setUp(() {
    mockRepo = MockCreatePostRepo();
    cubit = CreatePostCubit(mockRepo);
    // The repo call hangs (never completes) so the submit's synchronous
    // navigation logic runs, but the upload doesn't "finish" during the test.
    // The pop decision happens right after createPost() is invoked, so the
    // upload's outcome is irrelevant here.
    when(mockRepo.createPost(
      any,
      mediaFiles: anyNamed('mediaFiles'),
      onProgress: anyNamed('onProgress'),
    )).thenAnswer((_) => Completer<ApiResult<Post>>().future);
  });

  tearDown(() => cubit.close());

  /// Pushes [CreatePostScreen] on top of a placeholder "BELOW" route, matching
  /// how the share flows present it, so we can observe whether submitting pops
  /// back to reveal the route underneath.
  Future<void> pumpPushed(
    WidgetTester tester, {
    required bool popOnSubmit,
  }) async {
    await pumpApp(
      tester,
      Builder(
        builder: (context) => Scaffold(
          body: Center(
            child: ElevatedButton(
              onPressed: () => Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (_) => BlocProvider<CreatePostCubit>.value(
                    value: cubit,
                    child: CreatePostScreen(popOnSubmit: popOnSubmit),
                  ),
                ),
              ),
              child: const Text('BELOW'),
            ),
          ),
        ),
      ),
    );
    await tester.tap(find.text('BELOW'));
    await tester.pumpAndSettle();
  }

  Future<void> enterContentAndTapPost(WidgetTester tester) async {
    // Content is required — otherwise _handlePost shows a snackbar and returns.
    await tester.enterText(find.byType(TextField).first, 'my first post');
    await tester.tap(find.widgetWithText(AppButton, 'Post'));
    // Run createPost() + the pop decision, then let any route transition finish.
    await tester.pumpAndSettle();
  }

  testWidgets(
    'Create Post tab (popOnSubmit=false): submitting does NOT pop — HomeLayout '
    'stays put instead of showing a blank screen',
    (tester) async {
      await pumpPushed(tester, popOnSubmit: false);
      expect(find.byType(CreatePostScreen), findsOneWidget);

      await enterContentAndTapPost(tester);

      // Still on the create-post screen; the underlying route was NOT revealed.
      expect(find.byType(CreatePostScreen), findsOneWidget);
      expect(find.text('BELOW'), findsNothing);
      // The post was still submitted (upload continues in the background).
      verify(mockRepo.createPost(
        any,
        mediaFiles: anyNamed('mediaFiles'),
        onProgress: anyNamed('onProgress'),
      )).called(1);
    },
  );

  testWidgets(
    'Pushed share flow (popOnSubmit=true): submitting pops back to reveal the '
    'route underneath (the feed)',
    (tester) async {
      await pumpPushed(tester, popOnSubmit: true);
      expect(find.byType(CreatePostScreen), findsOneWidget);

      await enterContentAndTapPost(tester);

      // Popped — back to the route below, and the post was submitted.
      expect(find.byType(CreatePostScreen), findsNothing);
      expect(find.text('BELOW'), findsOneWidget);
      verify(mockRepo.createPost(
        any,
        mediaFiles: anyNamed('mediaFiles'),
        onProgress: anyNamed('onProgress'),
      )).called(1);
    },
  );

  testWidgets(
    'empty content is rejected: no pop and no upload',
    (tester) async {
      await pumpPushed(tester, popOnSubmit: true);

      // Tap Post without entering any content.
      await tester.tap(find.widgetWithText(AppButton, 'Post'));
      await tester.pump();
      await tester.pump();

      // Stayed on the screen, and no upload was attempted.
      expect(find.byType(CreatePostScreen), findsOneWidget);
      verifyNever(mockRepo.createPost(
        any,
        mediaFiles: anyNamed('mediaFiles'),
        onProgress: anyNamed('onProgress'),
      ));
    },
  );
}
