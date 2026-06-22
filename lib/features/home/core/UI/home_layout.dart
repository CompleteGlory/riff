// ignore_for_file: deprecated_member_use
import 'dart:async';
import 'package:flutter/material.dart';
import 'package:riff/features/home/add_post/ui/widgets/create_post_wrapper.dart';
import 'package:riff/generated/l10n.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:riff/core/helpers/constants.dart';
import 'package:riff/core/helpers/shared_pref_helper.dart';
import 'package:riff/core/di/dependency_injection.dart';
import 'package:riff/core/routing/routes.dart';
import 'package:riff/core/services/push_notification_service.dart';
import 'package:riff/features/home/core/UI/app_bottom_nav.dart';
import 'package:riff/features/home/core/UI/drawer/app_drawer.dart';
import 'package:riff/features/home/core/logic/cubit/home_cubit.dart';
import 'package:riff/features/home/core/logic/cubit/home_state.dart';
import 'package:riff/features/home/notifications/data/models/notification_model.dart';
import 'package:riff/features/home/notifications/logic/cubit/notifications_cubit.dart';
import 'package:riff/features/home/notifications/UI/notifications_screen.dart';
import 'package:riff/features/home/chat/data/models/chat_models.dart';
import 'package:riff/features/home/chat/data/services/chat_socket_service.dart';
import 'package:riff/features/home/chat/logic/cubit/chats_list_cubit.dart';
import 'package:riff/features/home/add_post/logic/cubit/create_post_cubit.dart';
import 'package:riff/features/home/add_post/logic/cubit/create_post_state.dart';
import 'package:riff/features/home/add_post/ui/widgets/create_post_screen.dart';
import 'package:riff/features/social_share/services/share_receiver_service.dart';

class HomeLayout extends StatefulWidget {
  const HomeLayout({super.key});

  @override
  State<HomeLayout> createState() => _HomeLayoutState();
}

class _HomeLayoutState extends State<HomeLayout> with WidgetsBindingObserver {
  StreamSubscription<NotificationModel>? _notifSub;
  StreamSubscription<void>? _pushRefreshSub;
  StreamSubscription<ChatMessage>? _chatMsgSub;
  StreamSubscription<String>? _convDeletedSub;
  // Cached current-user ID so we can skip own messages in onNewMessage().
  // The server now echoes message_received to the sender's personal room too
  // (to fix the cold-start race), so without this filter the sender's own
  // messages would incorrectly increment their unread badge.
  String _myId = '';

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

    // Load conversations for the current user. Must be called here (not in
    // the router) because we use BlocProvider.value to avoid closing the
    // singleton on logout — so the router no longer calls ..load().
    getIt<ChatsListCubit>().load();

    // Listen for content shared to Riff from the system share sheet.
    // IG/TikTok links open CreatePostScreen with pre-filled caption + source.
    // Spotify/generic URLs go to the chat composer.
    // Media files go to the post-creation tab.
    ShareReceiverService.instance.init();
    ShareReceiverService.instance.receivedContent.addListener(_onSharedContent);
    ShareReceiverService.instance.receivedMedia.addListener(_onSharedMedia);

    // Connect chat socket using stored token
    _connectChatSocket();
  }

  Future<void> _connectChatSocket() async {
    final token = await SharedPrefHelper.getString(SharedPrefKeys.userToken) as String? ?? '';
    if (token.isEmpty) return;

    // Load the current user ID so we can filter own messages from unread count.
    final id = await SharedPrefHelper.getString(SharedPrefKeys.userId) as String? ?? '';
    if (mounted) setState(() => _myId = id);

    final socket = getIt<ChatSocketService>();
    socket.connect(token);

    // Forward every incoming socket message to ChatsListCubit so the badge
    // count updates in real-time without requiring the user to open the chat list.
    _chatMsgSub?.cancel();
    _chatMsgSub = socket.onMessage.listen((msg) {
      if (mounted) {
        // Pass the currently open conversation so onNewMessage() doesn't
        // increment the unread count when the user is already viewing that chat.
        // Pass myId so the sender's own echo doesn't bump their unread badge.
        getIt<ChatsListCubit>().onNewMessage(
          msg,
          openConversationId: socket.currentConversationId,
          myId: _myId,
        );
      }
    });

    // When any participant deletes a conversation, remove it from the list.
    _convDeletedSub?.cancel();
    _convDeletedSub = socket.onConversationDeleted.listen((convId) {
      if (mounted) getIt<ChatsListCubit>().removeConversation(convId);
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
      // Refresh chat list so unread counts are accurate after the app was
      // backgrounded (socket may have been paused / missed messages).
      getIt<ChatsListCubit>().refresh();
      // Re-connect socket in case it dropped while in background.
      _connectChatSocket();
      // Re-init the share receiver: shares delivered while the app was
      // backgrounded arrive via getInitialMedia() on this re-call.
      // Without this, Spotify/TikTok shares into a backgrounded app are
      // silently lost because the stream alone doesn't deliver them.
      ShareReceiverService.instance.init();
    }
  }

  void _onSharedContent() {
    final content = ShareReceiverService.instance.receivedContent.value;
    if (content == null || !mounted) return;
    ShareReceiverService.instance.clearContent();

    // Delay navigation until after the first frame AND a short additional
    // delay to let the navigator settle after cold starts. Without the extra
    // delay the push occasionally fires before the route animation finishes,
    // producing a frozen white screen (observed with TikTok / Spotify).
    WidgetsBinding.instance.addPostFrameCallback((_) {
      Future.delayed(const Duration(milliseconds: 300), () {
        if (!mounted) return;
        // All inbound shares open CreatePostScreen so the user can post about it.
        // Use BlocProvider.value (not BlocProvider) so the singleton cubit is
        // never closed when the route is popped mid-upload.
        // The global BlocListener in HomeLayout handles success/failure.
        getIt<CreatePostCubit>().reset();
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => BlocProvider.value(
              value: getIt<CreatePostCubit>(),
              child: CreatePostScreen(
                initialCaption: content.captionText,
                sourceUrl: content.isSocialShare ? content.url : null,
                sourcePlatform: content.isSocialShare ? content.platform : null,
              ),
            ),
          ),
        );
      });
    });
  }

  void _onSharedMedia() {
    final files = ShareReceiverService.instance.receivedMedia.value;
    if (files == null || files.isEmpty || !mounted) return;
    ShareReceiverService.instance.clearMedia();

    final paths = files.map((f) => f.path).where((p) => p.isNotEmpty).toList();
    if (paths.isEmpty) return;

    WidgetsBinding.instance.addPostFrameCallback((_) {
      Future.delayed(const Duration(milliseconds: 300), () {
        if (!mounted) return;
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => CreatePostWrapper(initialMediaPaths: paths),
          ),
        );
      });
    });
  }

  @override
  void dispose() {
    _notifSub?.cancel();
    _pushRefreshSub?.cancel();
    _chatMsgSub?.cancel();
    _convDeletedSub?.cancel();
    ShareReceiverService.instance.receivedContent.removeListener(_onSharedContent);
    ShareReceiverService.instance.receivedMedia.removeListener(_onSharedMedia);
    ShareReceiverService.instance.dispose();
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
    return BlocListener<CreatePostCubit, CreatePostState>(
      // Only react to terminal states — uploading progress is shown via
      // the global UploadProgressService overlay in RiffApp.
      listenWhen: (_, curr) => curr is Loading || curr is Success || curr is Failure,
      listener: (ctx, state) {
        state.whenOrNull(
          // Switch to feed the moment the upload starts so the user
          // cannot tap Post again and accidentally duplicate.
          loading: () {
            try {
              ctx.read<HomeCubit>().changeScreen(0);
            } catch (_) {}
          },
          success: (_) {
            ScaffoldMessenger.of(ctx).showSnackBar(
              SnackBar(
                content: Text(S.of(ctx).postCreatedSuccessfully),
              ),
            );
            getIt<CreatePostCubit>().reset();
          },
          failure: (err) {
            final msg = err.errors?[0].message ?? S.of(ctx).failedToCreatePost;
            ScaffoldMessenger.of(ctx).showSnackBar(SnackBar(content: Text(msg)));
            getIt<CreatePostCubit>().reset();
          },
        );
      },
      child: WillPopScope(
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
                          BlocBuilder<ChatsListCubit, ChatsListState>(
                            builder: (ctx, chatState) {
                              final totalUnread = chatState is ChatsListLoaded
                                  ? chatState.conversations.fold<int>(
                                      0, (sum, c) => sum + c.unreadCount)
                                  : 0;
                              return Stack(children: [
                                IconButton(
                                  icon: const Icon(Icons.chat_bubble_outline_rounded),
                                  onPressed: () => Navigator.pushNamed(context, Routes.chatsList),
                                ),
                                if (totalUnread > 0)
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
                                          totalUnread > 9 ? '9+' : '$totalUnread',
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
      ), // WillPopScope
    ); // BlocListener<CreatePostCubit>
  }
}
