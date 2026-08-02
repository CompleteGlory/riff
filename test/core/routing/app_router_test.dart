import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:riff/core/di/dependency_injection.dart';
import 'package:riff/core/routing/app_router.dart';
import 'package:riff/core/routing/routes.dart';
import 'package:riff/core/services/notification_route.dart';
import 'package:riff/features/auth/onboarding/onboarding_screen.dart';
import 'package:riff/features/home/chat/data/repos/chat_repo.dart';
import 'package:riff/features/home/chat/logic/cubit/chats_list_cubit.dart';
import 'package:riff/features/home/notifications/UI/flagged_comment_detail_screen.dart';
import 'package:riff/features/home/notifications/UI/flagged_post_detail_screen.dart';
import 'package:riff/features/home/notifications/data/repos/notifications_repo.dart';
import 'package:riff/core/networks/socket_service.dart';
import 'package:riff/features/home/notifications/logic/cubit/notifications_cubit.dart';

/// See app_router_test.md for what this covers and why.
void main() {
  late AppRouter router;
  late NotificationsCubit notificationsCubit;
  late ChatsListCubit chatsListCubit;

  setUp(() {
    router = AppRouter();
    // Only the singletons the routes under test resolve. Constructing these is
    // side-effect free — nothing here talks to the network unless load() is
    // called, which none of these routes do.
    notificationsCubit =
        NotificationsCubit(NotificationsRepo(Dio()), SocketService());
    chatsListCubit = ChatsListCubit(ChatRepo(Dio()));
    getIt
      ..registerSingleton<NotificationsCubit>(notificationsCubit)
      ..registerSingleton<ChatsListCubit>(chatsListCubit);
  });

  tearDown(() async {
    await getIt.reset();
    await notificationsCubit.disposePermanently();
    await chatsListCubit.disposePermanently();
  });

  Route<dynamic> generate(String name, {Object? arguments}) =>
      router.generateRoute(RouteSettings(name: name, arguments: arguments));

  /// Builds the widget a route would show, without mounting it.
  ///
  /// Mounting the real screens would drag in Firebase and the network; all
  /// these tests need is the widget the router hands back.
  Future<Widget> widgetFor(
    WidgetTester tester,
    String name, {
    Object? arguments,
  }) async {
    await tester.pumpWidget(const MaterialApp(home: SizedBox()));
    final route = generate(name, arguments: arguments) as MaterialPageRoute;
    return route.builder(tester.element(find.byType(SizedBox)));
  }

  /// Mounts [provider] around a probe child and returns the cubit it exposes,
  /// so we can assert *which instance* a route shares without booting the real
  /// screen underneath it.
  Future<T> providedCubit<T extends StateStreamableSource<Object?>>(
    WidgetTester tester,
    BlocProvider<T> provider,
  ) async {
    late T captured;
    await tester.pumpWidget(MaterialApp(
      home: provider.buildWithChild(
        tester.element(find.byType(SizedBox)),
        Builder(builder: (context) {
          captured = context.read<T>();
          return const SizedBox();
        }),
      ),
    ));
    return captured;
  }

  group('notification destinations', () {
    testWidgets('the notifications route shares the singleton cubit',
        (tester) async {
      final widget = await widgetFor(tester, Routes.notifications);

      // .value, not create: — providing the singleton with create: would close
      // it when this route pops, and a closed cubit can never emit again, which
      // is what silently broke "mark all as read".
      expect(widget, isA<BlocProvider<NotificationsCubit>>());
      final provided = await providedCubit<NotificationsCubit>(
        tester,
        widget as BlocProvider<NotificationsCubit>,
      );
      expect(provided, same(notificationsCubit));
    });

    testWidgets('the flagged-comment route carries every id through',
        (tester) async {
      const route = NotificationRoute(
        kind: NotificationRouteKind.flaggedComment,
        commentId: 42,
        postId: 9,
        title: 'Comment removed',
        body: 'It broke the rules',
      );

      final widget = await widgetFor(
        tester,
        Routes.flaggedComment,
        arguments: route,
      ) as FlaggedCommentDetailScreen;

      expect(widget.commentId, 42);
      expect(widget.postId, 9);
      expect(widget.flagTitle, 'Comment removed');
      expect(widget.flagBody, 'It broke the rules');
    });

    testWidgets('the flagged-post route carries the post id through',
        (tester) async {
      const route = NotificationRoute(
        kind: NotificationRouteKind.flaggedPost,
        postId: 15,
        title: 'Post removed',
      );

      final widget = await widgetFor(
        tester,
        Routes.flaggedPost,
        arguments: route,
      ) as FlaggedPostDetailScreen;

      expect(widget.postId, 15);
      expect(widget.flagTitle, 'Post removed');
    });

    testWidgets('a flagged route with no arguments still builds',
        (tester) async {
      // Defensive: an older push payload may not carry ids at all, and the
      // screens already handle a null id by showing an error state.
      final widget =
          await widgetFor(tester, Routes.flaggedPost) as FlaggedPostDetailScreen;

      expect(widget.postId, isNull);
    });
  });

  group('chat destinations', () {
    testWidgets('the chats-list route shares the singleton cubit',
        (tester) async {
      final widget = await widgetFor(tester, Routes.chatsList);

      expect(widget, isA<BlocProvider<ChatsListCubit>>());
      final provided = await providedCubit<ChatsListCubit>(
        tester,
        widget as BlocProvider<ChatsListCubit>,
      );
      expect(provided, same(chatsListCubit));
    });
  });

  group('route resolution', () {
    for (final name in [
      Routes.notifications,
      Routes.flaggedComment,
      Routes.flaggedPost,
      Routes.chatsList,
      Routes.login,
      Routes.onBoarding,
    ]) {
      test('$name resolves to a route', () {
        expect(generate(name), isA<MaterialPageRoute<dynamic>>());
      });
    }

    testWidgets('an unknown route falls back to onboarding', (tester) async {
      final widget = await widgetFor(tester, '/does-not-exist');

      expect(widget, isA<OnBoardingScreen>());
    });
  });
}
