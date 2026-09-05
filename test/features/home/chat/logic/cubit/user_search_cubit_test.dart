import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/annotations.dart';
import 'package:mockito/mockito.dart';
import 'package:riff/features/home/chat/logic/cubit/user_search_cubit.dart';
import 'package:riff/features/home/search/data/models/search_user.dart';
import 'package:riff/features/home/search/data/repos/search_repo.dart';

import 'user_search_cubit_test.mocks.dart';

/// See user_search_cubit_test.md for what this covers and why.
@GenerateMocks([SearchRepo])
void main() {
  late MockSearchRepo repo;
  late UserSearchCubit cubit;

  SearchUser user(String id) => SearchUser(
        id: id,
        username: id,
        fullName: id,
        isPrivate: false,
      );

  setUp(() {
    repo = MockSearchRepo();
    cubit = UserSearchCubit(repo);
  });

  tearDown(() => cubit.close());

  /// Longer than the debounce, so a queued search actually runs.
  Future<void> pastDebounce() =>
      Future<void>.delayed(UserSearchCubit.debounce + const Duration(milliseconds: 50));

  test('starts idle, with nothing searched yet', () {
    expect(cubit.state.isSearching, isFalse);
    expect(cubit.state.results, isEmpty);
    expect(cubit.state.hasQuery, isFalse);
  });

  test('debounces: typing several characters sends one request', () async {
    when(repo.searchUsers(any)).thenAnswer((_) async => [user('alice')]);

    cubit.search('a');
    cubit.search('al');
    cubit.search('ali');
    await pastDebounce();

    // The whole point of the debounce, and the copy in create_group_screen
    // did not have one — it fired a request per keystroke.
    verify(repo.searchUsers('ali')).called(1);
    verifyNoMoreInteractions(repo);
    expect(cubit.state.results.single.id, 'alice');
  });

  test('an empty query clears immediately and sends nothing', () async {
    cubit.search('   ');
    await pastDebounce();

    expect(cubit.state.hasQuery, isFalse);
    expect(cubit.state.results, isEmpty);
    verifyNever(repo.searchUsers(any));
  });

  test('a slow response for an older query cannot overwrite a newer one',
      () async {
    // Type "ali", then "alice"; "ali" answers second. Without the epoch guard
    // the stale results win and the field shows the wrong people.
    when(repo.searchUsers('ali')).thenAnswer(
      (_) => Future.delayed(
        const Duration(milliseconds: 120),
        () => [user('stale')],
      ),
    );
    when(repo.searchUsers('alice')).thenAnswer((_) async => [user('fresh')]);

    await cubit.searchNow('ali');
    await cubit.searchNow('alice');
    await Future<void>.delayed(const Duration(milliseconds: 200));

    expect(cubit.state.results.single.id, 'fresh');
  });

  test('a failed search shows no results rather than an error', () async {
    when(repo.searchUsers(any)).thenThrow(Exception('network'));

    await cubit.searchNow('bob');

    // The user is mid-sentence; the next keystroke tries again. An error
    // banner under a search field is noise.
    expect(cubit.state.isSearching, isFalse);
    expect(cubit.state.results, isEmpty);
    expect(cubit.state.isEmptyResult, isTrue);
  });

  test('distinguishes "nothing typed" from "nobody matched"', () async {
    when(repo.searchUsers(any)).thenAnswer((_) async => []);

    expect(cubit.state.isEmptyResult, isFalse);

    await cubit.searchNow('nobody');

    // Two states that look identical to a widget holding only a list, and
    // they need different UI: a prompt versus "no results".
    expect(cubit.state.isEmptyResult, isTrue);
  });

  test('clear() cancels a pending search and sends nothing', () async {
    when(repo.searchUsers(any)).thenAnswer((_) async => [user('alice')]);

    cubit.search('alice');
    cubit.clear();
    await pastDebounce();

    verifyNever(repo.searchUsers(any));
    expect(cubit.state.hasQuery, isFalse);
  });

  test('closing cancels the debounce timer', () async {
    when(repo.searchUsers(any)).thenAnswer((_) async => [user('alice')]);

    cubit.search('alice');
    await cubit.close();
    await pastDebounce();

    // A timer that fires after close would emit on a closed cubit.
    verifyNever(repo.searchUsers(any));
  });
}
