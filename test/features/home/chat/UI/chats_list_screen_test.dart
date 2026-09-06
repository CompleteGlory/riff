import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/annotations.dart';
import 'package:mockito/mockito.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:riff/core/cache/offline_cache.dart';
import 'package:riff/core/di/dependency_injection.dart';
import 'package:riff/core/networks/connectivity_service.dart';
import 'package:riff/features/home/chat/UI/chats_list_screen.dart';
import 'package:riff/features/home/chat/data/repos/chat_repo.dart';
import 'package:riff/features/home/chat/logic/cubit/chats_list_cubit.dart';
import 'package:riff/features/home/chat/logic/cubit/user_search_cubit.dart';
import 'package:riff/features/home/search/data/repos/search_repo.dart';
import 'package:riff/generated/l10n.dart';

import 'chats_list_screen_test.mocks.dart';

/// See chats_list_screen_test.md for what this covers and why.
@GenerateMocks([ChatRepo, SearchRepo])
void main() {
  late MockChatRepo chatRepo;
  late MockSearchRepo searchRepo;
  late ChatsListCubit chatsList;

  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    OfflineCache.resetInstanceForTest();
    ConnectivityService.resetInstanceForTest();

    chatRepo = MockChatRepo();
    searchRepo = MockSearchRepo();
    when(chatRepo.getConversations()).thenAnswer((_) async => []);
    when(chatRepo.getMessageRequests()).thenAnswer((_) async => []);
    when(searchRepo.searchUsers(any)).thenAnswer((_) async => []);

    // The screen resolves its own search cubit from GetIt, so that is the one
    // dependency the test has to provide.
    if (getIt.isRegistered<UserSearchCubit>()) {
      getIt.unregister<UserSearchCubit>();
    }
    getIt.registerFactory<UserSearchCubit>(() => UserSearchCubit(searchRepo));

    chatsList = ChatsListCubit(chatRepo);
  });

  tearDown(() async {
    await chatsList.close();
    if (getIt.isRegistered<UserSearchCubit>()) {
      getIt.unregister<UserSearchCubit>();
    }
  });

  /// Deliberately not `pumpAndSettle`: the screen shows a
  /// `LinearProgressIndicator` while a search is running and a
  /// `CircularProgressIndicator` while the list loads, and neither ever
  /// settles.
  Future<void> pumpScreen(WidgetTester tester) async {
    await tester.pumpWidget(ScreenUtilInit(
      designSize: const Size(375, 812),
      builder: (_, __) => MaterialApp(
        localizationsDelegates: const [
          S.delegate,
          GlobalMaterialLocalizations.delegate,
          GlobalWidgetsLocalizations.delegate,
          GlobalCupertinoLocalizations.delegate,
        ],
        supportedLocales: S.delegate.supportedLocales,
        home: BlocProvider<ChatsListCubit>.value(
          value: chatsList,
          child: const ChatsListScreen(),
        ),
      ),
    ));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 50));
  }

  testWidgets('builds without a search query', (tester) async {
    await pumpScreen(tester);

    expect(tester.takeException(), isNull);
    expect(find.byType(TextField), findsOneWidget);
  });

  testWidgets('typing a query does not lose the UserSearchCubit',
      (tester) async {
    // The regression. `build` wraps the screen in a `BlocProvider.value` for
    // UserSearchCubit and then calls `_buildBody(context)`. Passing the
    // *outer* context means everything inside looks the cubit up from above
    // its own provider — and the only such lookup sits behind
    // `if (_query.isNotEmpty)`, so the screen built fine and then threw
    // ProviderNotFoundException the moment anyone typed. It reached
    // production: 72 events, 3 users, fatal, and nobody could start a chat.
    await pumpScreen(tester);

    await tester.enterText(find.byType(TextField), 'ali');
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 50));

    expect(tester.takeException(), isNull);
  });

  testWidgets('clearing the query returns to the list without throwing',
      (tester) async {
    await pumpScreen(tester);

    await tester.enterText(find.byType(TextField), 'ali');
    await tester.pump(const Duration(milliseconds: 50));
    await tester.enterText(find.byType(TextField), '');
    await tester.pump(const Duration(milliseconds: 50));

    expect(tester.takeException(), isNull);
  });
}
