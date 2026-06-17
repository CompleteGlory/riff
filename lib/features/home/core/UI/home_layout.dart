// ignore_for_file: deprecated_member_use
import 'dart:async';
import 'package:flutter/material.dart';
import 'package:riff/generated/l10n.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:riff/core/services/push_notification_service.dart';
import 'package:riff/features/home/core/UI/app_bottom_nav.dart';
import 'package:riff/features/home/core/UI/drawer/app_drawer.dart';
import 'package:riff/features/home/core/logic/cubit/home_cubit.dart';
import 'package:riff/features/home/core/logic/cubit/home_state.dart';
import 'package:riff/features/home/notifications/data/models/notification_model.dart';
import 'package:riff/features/home/notifications/logic/cubit/notifications_cubit.dart';
import 'package:riff/features/home/notifications/UI/notifications_screen.dart';

class HomeLayout extends StatefulWidget {
  const HomeLayout({super.key});

  @override
  State<HomeLayout> createState() => _HomeLayoutState();
}

class _HomeLayoutState extends State<HomeLayout> with WidgetsBindingObserver {
  StreamSubscription<NotificationModel>? _notifSub;
  StreamSubscription<void>? _pushRefreshSub;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);

    // Refresh badge + list the moment any foreground FCM message arrives,
    // so the user never has to restart the app to see new notifications.
    _pushRefreshSub = PushNotificationService.refreshStream.listen((_) {
      if (mounted) {
        context.read<NotificationsCubit>().silentRefresh();
      }
    });
  }

  





  /// When app comes back to foreground, silently refresh so badge and list
  /// reflect any notifications received while in background.
  /// silentRefresh() already emits to onNewNotification stream for new items,
  /// so the banner fires automatically via _notifSub.
  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed && mounted) {
      context.read<NotificationsCubit>().silentRefresh();
    }
  }

  @override
  void dispose() {
    _notifSub?.cancel();
    _pushRefreshSub?.cancel();
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  Future<bool> _onWillPop() async {
    final s = S.of(context);
    final shouldExit = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(s.exitAppTitle),
        content: Text(s.doYouWantToExit),
        actions: [
          TextButton(onPressed: () => Navigator.of(ctx).pop(false),
              child: Text(s.cancelBtn)),
          TextButton(onPressed: () => Navigator.of(ctx).pop(true),
              child: Text(s.exitBtn)),
        ],
      ),
    );
    if (shouldExit == true) SystemNavigator.pop();
    return false;
  }

  String _navTitle(BuildContext context, int index) {
    final s = S.of(context);
    switch (index) {
      case 0: return s.feedTitle;
      case 1: return s.searchTitle;
      case 2: return s.postScreenTitle;
      case 3: return s.reelsTitle;
      default: return '';
    }
  }

  @override
  Widget build(BuildContext context) {
    return WillPopScope(
      onWillPop: _onWillPop,
      child: BlocBuilder<HomeCubit, HomeState>(
          builder: (context, state) {
            final cubit = context.read<HomeCubit>();
            final isProfile = cubit.currentIndex == 3;

            return Scaffold(
              extendBody: true,
              appBar: isProfile
                  ? null
                  : AppBar(
                      title: Text(_navTitle(context, cubit.currentIndex)),
                      actions: [
                        if (cubit.currentIndex == 0)
                          BlocBuilder<NotificationsCubit, NotificationsState>(
                            builder: (ctx, notifState) {
                              final unread = notifState is NotificationsLoaded
                                  ? notifState.unreadCount
                                  : 0;
                              return Stack(children: [
                                IconButton(
                                  icon: const Icon(
                                      Icons.notifications_outlined),
                                  onPressed: () async {
                                    await Navigator.push(
                                      context,
                                      MaterialPageRoute(
                                        builder: (_) => BlocProvider.value(
                                          value: ctx
                                              .read<NotificationsCubit>(),
                                          child:
                                              const NotificationsScreen(),
                                        ),
                                      ),
                                    );
                                    if (context.mounted) {
                                      ctx
                                          .read<NotificationsCubit>()
                                          .silentRefresh();
                                    }
                                  },
                                ),
                                if (unread > 0)
                                  Positioned(
                                    right: 8,
                                    top: 8,
                                    child: Container(
                                      width: 16,
                                      height: 16,
                                      decoration: const BoxDecoration(
                                        color: Colors.red,
                                        shape: BoxShape.circle,
                                      ),
                                      child: Center(
                                        child: Text(
                                          unread > 9 ? '9+' : '$unread',
                                          style: const TextStyle(
                                              color: Colors.white,
                                              fontSize: 9,
                                              fontWeight: FontWeight.bold),
                                        ),
                                      ),
                                    ),
                                  ),
                              ]);
                            },
                          ),
                      ],
                    ),
              drawer: const AppDrawer(),
              body: cubit.screens[cubit.currentIndex],
              bottomNavigationBar: AppBottomNav(cubit: cubit),
            );
          },
        ),
    );
  }
}
