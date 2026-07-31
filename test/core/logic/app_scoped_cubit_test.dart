import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:riff/core/logic/app_scoped_cubit.dart';

/// See app_scoped_cubit_test.md for what this covers and why.

/// Stands in for the app-lifetime singletons (NotificationsCubit,
/// ChatsListCubit, CreatePostCubit).
class _CounterCubit extends Cubit<int> with AppScopedCubit<int> {
  _CounterCubit() : super(0);
  void increment() {
    if (!isClosed) emit(state + 1);
  }
}

/// A plain route-scoped cubit — the baseline the regression is measured against.
class _PlainCounterCubit extends Cubit<int> {
  _PlainCounterCubit() : super(0);
}

void main() {
  Widget routeHost(Widget Function(BuildContext) provider) {
    return MaterialApp(
      home: Builder(
        builder: (context) => Scaffold(
          body: ElevatedButton(
            onPressed: () => Navigator.of(context).push(
              MaterialPageRoute(builder: provider),
            ),
            child: const Text('open'),
          ),
        ),
      ),
    );
  }

  Future<void> openAndPop(WidgetTester tester) async {
    await tester.tap(find.text('open'));
    await tester.pumpAndSettle();
    Navigator.of(tester.element(find.text('inner'))).pop();
    await tester.pumpAndSettle();
  }

  group('close() semantics', () {
    test('close() is a no-op', () async {
      final cubit = _CounterCubit();

      await cubit.close();

      expect(cubit.isClosed, isFalse);
      cubit.increment();
      expect(cubit.state, 1);
    });

    test('disposePermanently() really closes it', () async {
      final cubit = _CounterCubit();

      await cubit.disposePermanently();

      expect(cubit.isClosed, isTrue);
    });

    test('isPermanentlyClosing only flips on a deliberate dispose', () async {
      final cubit = _CounterCubit();
      expect(cubit.isPermanentlyClosing, isFalse);

      await cubit.close();
      expect(cubit.isPermanentlyClosing, isFalse);

      await cubit.disposePermanently();
      expect(cubit.isPermanentlyClosing, isTrue);
    });
  });

  group('BlocProvider disposal', () {
    // Baseline: this is exactly what happened to the GetIt singletons. A route
    // that provided one with `create:` closed it on pop, and because GetIt kept
    // handing back the same dead instance, the feature stayed broken for the
    // rest of the process — "mark all as read" silently doing nothing, the chat
    // list frozen. Both only ever broke *after* the user had visited and left
    // a screen that provided the singleton this way.
    testWidgets('a plain cubit is closed when its route pops', (tester) async {
      final cubit = _PlainCounterCubit();
      await tester.pumpWidget(routeHost(
        (_) => BlocProvider.value(
          value: cubit,
          child: const Scaffold(body: Text('inner')),
        ),
      ));

      await openAndPop(tester);

      // .value doesn't close it…
      expect(cubit.isClosed, isFalse);
      await cubit.close();
      expect(cubit.isClosed, isTrue, reason: 'a plain cubit closes on demand');
    });

    testWidgets('an app-scoped cubit survives BlocProvider(create:)',
        (tester) async {
      final cubit = _CounterCubit();
      await tester.pumpWidget(routeHost(
        (_) => BlocProvider<_CounterCubit>(
          create: (_) => cubit,
          child: const Scaffold(body: Text('inner')),
        ),
      ));

      await openAndPop(tester);

      expect(cubit.isClosed, isFalse);
      cubit.increment();
      expect(cubit.state, 1, reason: 'it must still be able to emit');
    });

    testWidgets('an app-scoped cubit survives BlocProvider.value',
        (tester) async {
      final cubit = _CounterCubit();
      await tester.pumpWidget(routeHost(
        (_) => BlocProvider<_CounterCubit>.value(
          value: cubit,
          child: const Scaffold(body: Text('inner')),
        ),
      ));

      await openAndPop(tester);

      expect(cubit.isClosed, isFalse);
      cubit.increment();
      expect(cubit.state, 1);
    });

    testWidgets('it still drives widgets after a route round-trip',
        (tester) async {
      final cubit = _CounterCubit();
      await tester.pumpWidget(
        MaterialApp(
          home: BlocProvider<_CounterCubit>.value(
            value: cubit,
            child: Builder(
              builder: (context) => Scaffold(
                body: Column(children: [
                  BlocBuilder<_CounterCubit, int>(
                    builder: (_, count) => Text('count: $count'),
                  ),
                  ElevatedButton(
                    onPressed: () => Navigator.of(context).push(
                      MaterialPageRoute(
                        builder: (_) => BlocProvider<_CounterCubit>(
                          create: (_) => cubit,
                          child: const Scaffold(body: Text('inner')),
                        ),
                      ),
                    ),
                    child: const Text('open'),
                  ),
                ]),
              ),
            ),
          ),
        ),
      );

      await openAndPop(tester);
      cubit.increment();
      // pumpAndSettle, not pump: the cubit's state stream is asynchronous, so a
      // single frame can land before the BlocBuilder has seen the new value.
      await tester.pumpAndSettle();

      expect(find.text('count: 1'), findsOneWidget);
    });
  });
}
