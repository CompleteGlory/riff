import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/annotations.dart';
import 'package:mockito/mockito.dart';
import 'package:riff/core/networks/api_error_model.dart';
import 'package:riff/core/networks/api_result.dart';
import 'package:riff/features/home/feed/data/models/post.dart';
import 'package:riff/features/home/feed/data/repos/feed_repo.dart';
import 'package:riff/features/home/feed/data/repos/like_repo.dart';
import 'package:riff/features/home/feed/logic/cubit/posts/post_cubit.dart';

import 'post_cubit_test.mocks.dart';

/// See post_cubit_test.md for what this covers and why.

@GenerateMocks([LikeRepo, FeedRepo])
void main() {
  late MockLikeRepo likeRepo;
  late PostCubit cubit;

  Post post({bool isLiked = false, String likesCount = '5'}) => Post(
        id: 1,
        author: null,
        content: null,
        createdAt: '',
        updatedAt: '',
        isLiked: isLiked,
        likesCount: likesCount,
      );

  setUp(() {
    likeRepo = MockLikeRepo();
    cubit = PostCubit(likeRepo, MockFeedRepo());
  });

  tearDown(() async => cubit.close());

  group('toggleLike is optimistic', () {
    test('the UI is updated before the request is even sent', () async {
      // Never completes — if the optimistic callback waited on the network,
      // this test would hang instead of asserting.
      final networkCall = Completer<ApiResult<bool>>();
      when(likeRepo.likePost(any)).thenAnswer((_) => networkCall.future);

      bool? optimisticLiked;
      int? optimisticCount;

      unawaited(cubit.toggleLike(
        post(),
        onOptimisticUpdate: (liked, count) {
          optimisticLiked = liked;
          optimisticCount = count;
        },
        onRevert: () {},
        onError: (_) {},
      ));

      expect(optimisticLiked, isTrue);
      expect(optimisticCount, 6);
      verify(likeRepo.likePost('1')).called(1);

      networkCall.complete(const ApiResult.success(true));
    });

    test('it reverts when the server rejects the like', () async {
      when(likeRepo.likePost(any))
          .thenAnswer((_) async => ApiResult.failure(ApiErrorModel()));

      var reverted = false;
      await cubit.toggleLike(
        post(),
        onOptimisticUpdate: (_, __) {},
        onRevert: () => reverted = true,
        onError: (_) {},
      );

      expect(reverted, isTrue);
    });
  });

  group('the caller owns the current state', () {
    test('a second tap unlikes instead of liking again', () async {
      when(likeRepo.likePost(any))
          .thenAnswer((_) async => const ApiResult.success(true));
      when(likeRepo.unlikePost(any))
          .thenAnswer((_) async => const ApiResult.success(true));

      // The Post model is the server's answer from when the feed loaded and
      // nothing writes back to it, so the second call passes what is actually
      // on screen. Without that it recomputed `!post.isLiked` — the same value
      // — and sent a second *like*.
      final model = post();

      await cubit.toggleLike(
        model,
        currentIsLiked: false,
        currentLikeCount: 5,
        onOptimisticUpdate: (_, __) {},
        onRevert: () {},
        onError: (_) {},
      );
      await cubit.toggleLike(
        model,
        currentIsLiked: true,
        currentLikeCount: 6,
        onOptimisticUpdate: (_, __) {},
        onRevert: () {},
        onError: (_) {},
      );

      verify(likeRepo.likePost('1')).called(1);
      verify(likeRepo.unlikePost('1')).called(1);
    });

    test('it falls back to the model when the caller passes nothing', () async {
      when(likeRepo.unlikePost(any))
          .thenAnswer((_) async => const ApiResult.success(true));

      await cubit.toggleLike(
        post(isLiked: true, likesCount: '9'),
        onOptimisticUpdate: (liked, count) {
          expect(liked, isFalse);
          expect(count, 8);
        },
        onRevert: () {},
        onError: (_) {},
      );

      verify(likeRepo.unlikePost('1')).called(1);
    });
  });
}
