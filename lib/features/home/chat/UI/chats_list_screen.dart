// ignore_for_file: use_build_context_synchronously
import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:riff/core/di/dependency_injection.dart';
import 'package:riff/core/themes/colors/color_manager.dart';
import 'package:riff/core/themes/text_styles/text_styles.dart';
import 'package:riff/features/home/chat/data/models/chat_models.dart';
import 'package:riff/features/home/chat/logic/cubit/chats_list_cubit.dart';
import 'package:riff/features/home/chat/logic/cubit/chat_cubit.dart';
import 'package:riff/features/home/chat/UI/chat_detail_screen.dart';
import 'package:riff/features/home/chat/UI/create_group_screen.dart';
import 'package:riff/features/home/chat/data/repos/chat_repo.dart';
import 'package:riff/features/home/chat/data/services/chat_socket_service.dart';
import 'package:riff/features/home/search/data/repos/search_repo.dart';
import 'package:riff/features/home/search/data/models/search_user.dart';
import 'package:riff/core/helpers/shared_pref_helper.dart';
import 'package:riff/core/widgets/app_error_widget.dart';
import 'package:riff/core/helpers/constants.dart';
import 'package:riff/generated/l10n.dart';

class ChatsListScreen extends StatefulWidget {
  const ChatsListScreen({super.key});

  @override
  State<ChatsListScreen> createState() => _ChatsListScreenState();
}

class _ChatsListScreenState extends State<ChatsListScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabs;
  final _searchCtrl = TextEditingController();
  String _query = '';
  String _myId = '';

  // User search state
  List<SearchUser> _userResults = [];
  bool _searchingUsers = false;
  Timer? _debounce;

  // IDs of users already in a conversation (to exclude from user results)
  Set<String> _existingUserIds = {};

  @override
  void initState() {
    super.initState();
    _tabs = TabController(length: 2, vsync: this);
    context.read<ChatsListCubit>().load();
    _searchCtrl.addListener(_onQueryChanged);
    _loadMyId();
  }

  Future<void> _loadMyId() async {
    final id = await SharedPrefHelper.getString(SharedPrefKeys.userId) as String? ?? '';
    if (mounted) setState(() => _myId = id);
  }

  void _onQueryChanged() {
    final q = _searchCtrl.text.trim();
    setState(() => _query = q.toLowerCase());

    _debounce?.cancel();
    if (q.isEmpty) {
      setState(() { _userResults = []; _searchingUsers = false; });
      return;
    }
    _debounce = Timer(const Duration(milliseconds: 350), () => _searchUsers(q));
  }

  Future<void> _searchUsers(String q) async {
    setState(() => _searchingUsers = true);
    try {
      final results = await getIt<SearchRepo>().searchUsers(q);
      if (!mounted) return;
      setState(() {
        _userResults = results;
        _searchingUsers = false;
      });
    } catch (_) {
      if (mounted) setState(() => _searchingUsers = false);
    }
  }

  void _showConvOptions(BuildContext ctx, Conversation conv) {
    final s = S.of(ctx);
    showModalBottomSheet(
      context: ctx,
      builder: (_) => SafeArea(
        child: Wrap(children: [
          ListTile(
            leading:
                const Icon(Icons.delete_outline_rounded, color: ColorManager.red),
            title: Text(s.deleteForEveryoneBtn,
                style: const TextStyle(color: ColorManager.red)),
            onTap: () {
              Navigator.pop(ctx);
              _confirmDeleteConv(ctx, conv);
            },
          ),
          ListTile(
            leading: const Icon(Icons.close_rounded),
            title: Text(s.cancelBtn),
            onTap: () => Navigator.pop(ctx),
          ),
        ]),
      ),
    );
  }

  void _confirmDeleteConv(BuildContext ctx, Conversation conv) {
    final s = S.of(ctx);
    showDialog(
      context: ctx,
      builder: (_) => AlertDialog(
        title: Text(s.deleteConversationTitle),
        content: Text(s.deleteConversationContent),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text(s.cancelBtn),
          ),
          TextButton(
            onPressed: () async {
              Navigator.pop(ctx);
              try {
                await getIt<ChatRepo>().deleteConversation(conv.id);
                if (mounted) {
                  ctx.read<ChatsListCubit>().removeConversation(conv.id);
                }
              } catch (_) {
                if (mounted) {
                  ScaffoldMessenger.of(ctx).showSnackBar(
                    SnackBar(content: Text(s.couldNotDeleteConversation)),
                  );
                }
              }
            },
            child: Text(s.deleteBtn, style: const TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }

  @override
  void dispose() {
    _debounce?.cancel();
    _tabs.dispose();
    _searchCtrl.dispose();
    super.dispose();
  }

  Future<void> _openChat(Conversation conv) async {
    // Zero out the badge immediately so it feels instant
    context.read<ChatsListCubit>().markConversationRead(conv.id);

    await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => MultiBlocProvider(
          providers: [
            BlocProvider.value(value: context.read<ChatsListCubit>()),
            BlocProvider(
              create: (_) => ChatCubit(getIt<ChatRepo>(), getIt<ChatSocketService>()),
            ),
          ],
          child: ChatDetailScreen(conversation: conv),
        ),
      ),
    );

    // On return: instantly zero the opened chat's badge, then do a full
    // refresh so counts for *other* conversations that got messages while
    // we were chatting are also accurate.
    if (mounted) {
      context.read<ChatsListCubit>().markConversationRead(conv.id);
      context.read<ChatsListCubit>().refresh();
    }
  }

  /// Opens a message request — does NOT mark as read (user hasn't accepted yet).
  Future<void> _openRequest(Conversation req) async {
    await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => MultiBlocProvider(
          providers: [
            BlocProvider.value(value: context.read<ChatsListCubit>()),
            BlocProvider(
              create: (_) => ChatCubit(getIt<ChatRepo>(), getIt<ChatSocketService>()),
            ),
          ],
          child: ChatDetailScreen(conversation: req),
        ),
      ),
    );
  }

  Future<void> _startChat(SearchUser user) async {
    try {
      final conv = await getIt<ChatRepo>().startDirectConversation(user.id);
      if (!mounted) return;
      context.read<ChatsListCubit>().prependConversation(conv);
      _openChat(conv);
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(_friendlyError(e.toString()))),
      );
    }
  }

  String _friendlyError(String err) {
    if (err.contains('blocked')) return 'You cannot message this user.';
    if (err.contains('not_following')) return 'You need to follow this user first.';
    return 'Could not start conversation.';
  }

  List<Conversation> _filterConvs(List<Conversation> list) {
    if (_query.isEmpty) return list;
    return list.where((c) => c.displayName.toLowerCase().contains(_query)).toList();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Scaffold(
      appBar: AppBar(
        title: Text(S.of(context).chatMessagesTitle),
        actions: [
          IconButton(
            icon: const Icon(Icons.group_add_outlined),
            onPressed: () => Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) => BlocProvider.value(
                  value: context.read<ChatsListCubit>(),
                  child: const CreateGroupScreen(),
                ),
              ),
            ),
          ),
        ],
        bottom: _query.isEmpty
            ? TabBar(
                controller: _tabs,
                tabs: [Tab(text: S.of(context).chatTabChats), Tab(text: S.of(context).chatTabRequests)],
                labelColor: ColorManager.accent,
                unselectedLabelColor: ColorManager.normalGrey,
                indicatorColor: ColorManager.accent,
              )
            : null,
      ),
      body: Column(children: [
        // Search bar
        Padding(
          padding: EdgeInsets.fromLTRB(16.w, 12.h, 16.w, 8.h),
          child: TextField(
            controller: _searchCtrl,
            decoration: InputDecoration(
              hintText: S.of(context).searchConversationsHint,
              prefixIcon: const Icon(Icons.search_rounded),
              suffixIcon: _query.isNotEmpty
                  ? IconButton(
                      icon: const Icon(Icons.close_rounded),
                      onPressed: () => _searchCtrl.clear(),
                    )
                  : null,
              filled: true,
              fillColor: isDark ? const Color(0xFF2A2A2A) : const Color(0xFFF5F5F5),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(14.r),
                borderSide: BorderSide.none,
              ),
              contentPadding: EdgeInsets.symmetric(vertical: 10.h),
            ),
          ),
        ),

        // Loading indicator for user search
        if (_searchingUsers) const LinearProgressIndicator(minHeight: 2),

        Expanded(
          child: BlocBuilder<ChatsListCubit, ChatsListState>(
            builder: (ctx, state) {
              // Build the set of user IDs already in conversations
              if (state is ChatsListLoaded) {
                _existingUserIds = state.conversations
                    .where((c) => c.type == 'direct' && c.otherUser != null)
                    .map((c) => c.otherUser!.id)
                    .toSet();
              }

              if (_query.isNotEmpty) {
                return _SearchResults(
                  query: _query,
                  state: state,
                  userResults: _userResults,
                  existingUserIds: _existingUserIds,
                  onConvTap: _openChat,
                  onUserTap: _startChat,
                  filterConvs: _filterConvs,
                  myId: _myId,
                );
              }

              // Normal tabs view
              if (state is ChatsListLoading) {
                return const Center(child: CircularProgressIndicator());
              }
              if (state is ChatsListError) {
                return AppErrorWidget(
                  message: state.message,
                  onRetry: () => ctx.read<ChatsListCubit>().load(),
                );
              }
              if (state is ChatsListLoaded) {
                return TabBarView(
                  controller: _tabs,
                  children: [
                    _ConversationList(
                      conversations: state.conversations,
                      onTap: _openChat,
                      onLongPress: (conv) => _showConvOptions(context, conv),
                      emptyLabel: S.of(context).noConversationsYet,
                      myId: _myId,
                    ),
                    _RequestList(
                      requests: state.requests,
                      onTap: _openRequest,
                    ),
                  ],
                );
              }
              return const SizedBox();
            },
          ),
        ),
      ]),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
/// Shown while the user is typing — merges filtered conversations with user search results.
class _SearchResults extends StatelessWidget {
  final String query;
  final ChatsListState state;
  final List<SearchUser> userResults;
  final Set<String> existingUserIds;
  final ValueChanged<Conversation> onConvTap;
  final ValueChanged<SearchUser> onUserTap;
  final List<Conversation> Function(List<Conversation>) filterConvs;
  final String myId;

  const _SearchResults({
    required this.query,
    required this.state,
    required this.userResults,
    required this.existingUserIds,
    required this.onConvTap,
    required this.onUserTap,
    required this.filterConvs,
    required this.myId,
  });

  @override
  Widget build(BuildContext context) {
    final matchingConvs = state is ChatsListLoaded
        ? filterConvs((state as ChatsListLoaded).conversations)
        : <Conversation>[];

    // Users not already in a conversation
    final newUsers = userResults.where((u) => !existingUserIds.contains(u.id)).toList();

    if (matchingConvs.isEmpty && newUsers.isEmpty && state is ChatsListLoaded) {
      return Center(
        child: Column(mainAxisSize: MainAxisSize.min, children: [
          Icon(Icons.search_off_rounded, size: 48.r, color: ColorManager.lightGrey),
          SizedBox(height: 12.h),
          Text(S.of(context).noResultsForQuery(query),
              style: TextStyles.font16Medium.copyWith(color: ColorManager.normalGrey)),
        ]),
      );
    }

    return ListView(
      children: [
        // Matching existing conversations
        if (matchingConvs.isNotEmpty) ...[
          _SectionHeader(title: S.of(context).conversationsSectionLabel),
          ...matchingConvs.map((c) => _ConvTile(conv: c, onTap: onConvTap, myId: myId)),
        ],

        // Users to start a new chat with
        if (newUsers.isNotEmpty) ...[
          _SectionHeader(title: S.of(context).peopleSection),
          ...newUsers.map((u) => _UserTile(user: u, onTap: onUserTap)),
        ],
      ],
    );
  }
}

class _SectionHeader extends StatelessWidget {
  final String title;
  const _SectionHeader({required this.title});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Padding(
      padding: EdgeInsets.fromLTRB(16.w, 12.h, 16.w, 4.h),
      child: Text(
        title.toUpperCase(),
        style: TextStyles.font12semiBold.copyWith(
          color: isDark ? ColorManager.normalGrey : ColorManager.darkGrey,
          letterSpacing: 0.8,
        ),
      ),
    );
  }
}

/// Tile for a user who doesn't have an existing conversation — shows a "Message" button.
class _UserTile extends StatefulWidget {
  final SearchUser user;
  final ValueChanged<SearchUser> onTap;
  const _UserTile({required this.user, required this.onTap});

  @override
  State<_UserTile> createState() => _UserTileState();
}

class _UserTileState extends State<_UserTile> {
  bool _loading = false;

  @override
  Widget build(BuildContext context) {
    final img = widget.user.profileImageUrl;
    final label = widget.user.username.isNotEmpty
        ? widget.user.username[0].toUpperCase()
        : '?';

    return ListTile(
      leading: CircleAvatar(
        radius: 22.r,
        backgroundColor: ColorManager.lightBlack,
        backgroundImage: img != null ? NetworkImage(img) : null,
        child: img == null
            ? Text(label, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w700))
            : null,
      ),
      title: Text('@${widget.user.username}', style: TextStyles.font15semiBold),
      subtitle: widget.user.fullName.isNotEmpty
          ? Text(widget.user.fullName,
              style: TextStyles.font12regular.copyWith(color: ColorManager.normalGrey))
          : null,
      trailing: _loading
          ? SizedBox(
              width: 20.w,
              height: 20.h,
              child: CircularProgressIndicator(strokeWidth: 2.w),
            )
          : GestureDetector(
              onTap: () async {
                setState(() => _loading = true);
                widget.onTap(widget.user);
                if (mounted) setState(() => _loading = false);
              },
              child: Container(
                padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 7.h),
                decoration: BoxDecoration(
                  color: ColorManager.accent,
                  borderRadius: BorderRadius.circular(20.r),
                ),
                child: Text(
                  S.of(context).messageBtn,
                  style: TextStyles.font12semiBold.copyWith(color: ColorManager.black),
                ),
              ),
            ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
class _ConversationList extends StatelessWidget {
  final List<Conversation> conversations;
  final ValueChanged<Conversation> onTap;
  final void Function(Conversation)? onLongPress;
  final String emptyLabel;
  final String myId;

  const _ConversationList({
    required this.conversations,
    required this.onTap,
    required this.emptyLabel,
    required this.myId,
    this.onLongPress,
  });

  @override
  Widget build(BuildContext context) {
    if (conversations.isEmpty) {
      return Center(
        child: Padding(
          padding: EdgeInsets.symmetric(horizontal: 32.w),
          child: Text(emptyLabel,
              textAlign: TextAlign.center,
              style: TextStyles.font16Medium.copyWith(color: ColorManager.normalGrey)),
        ),
      );
    }
    return RefreshIndicator(
      onRefresh: () => context.read<ChatsListCubit>().refresh(),
      child: ListView.separated(
        itemCount: conversations.length,
        separatorBuilder: (_, __) => const Divider(height: 1, indent: 72),
        itemBuilder: (_, i) => _ConvTile(
          conv: conversations[i],
          onTap: onTap,
          myId: myId,
          onLongPress: onLongPress != null ? () => onLongPress!(conversations[i]) : null,
        ),
      ),
    );
  }
}

class _ConvTile extends StatelessWidget {
  final Conversation conv;
  final ValueChanged<Conversation> onTap;
  final String myId;
  final VoidCallback? onLongPress;
  const _ConvTile({
    required this.conv,
    required this.onTap,
    required this.myId,
    this.onLongPress,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final rawPreview = conv.latestMessage?.preview ?? '';
    final isMine = myId.isNotEmpty && conv.latestMessage?.sender?.id == myId;
    final preview = rawPreview.isNotEmpty && isMine ? 'You: $rawPreview' : rawPreview;
    final time = conv.latestMessage?.createdAt ?? conv.lastMessageAt;
    final hasUnread = conv.unreadCount > 0;

    return ListTile(
      onTap: () => onTap(conv),
      onLongPress: onLongPress,
      leading: _ConvAvatar(conv: conv),
      title: Text(
        conv.displayName,
        style: TextStyles.font15semiBold.copyWith(
            fontWeight: hasUnread ? FontWeight.w700 : FontWeight.w500),
        overflow: TextOverflow.ellipsis,
      ),
      subtitle: preview.isNotEmpty
          ? Text(
              preview,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyles.font12regular.copyWith(
                color: hasUnread
                    ? (isDark ? ColorManager.white : ColorManager.black)
                    : ColorManager.normalGrey,
                fontWeight: hasUnread ? FontWeight.w600 : FontWeight.normal,
              ),
            )
          : null,
      trailing: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.end,
        mainAxisSize: MainAxisSize.min,
        children: [
          if (time != null)
            Text(
              _shortTime(time),
              style: TextStyles.font12regular.copyWith(
                fontSize: 11,
                color: hasUnread
                    ? ColorManager.accent
                    : (isDark ? ColorManager.normalGrey : ColorManager.darkGrey),
              ),
            ),
          if (hasUnread) ...[
            SizedBox(height: 4.h),
            Container(
              padding: EdgeInsets.symmetric(horizontal: 6.w, vertical: 2.h),
              constraints: BoxConstraints(minWidth: 20.r),
              decoration: BoxDecoration(
                color: ColorManager.accent,
                borderRadius: BorderRadius.circular(10.r),
              ),
              child: Text(
                conv.unreadCount > 99 ? '99+' : '${conv.unreadCount}',
                style: TextStyles.font12semiBold
                    .copyWith(color: ColorManager.black, fontSize: 10),
                textAlign: TextAlign.center,
              ),
            ),
          ],
        ],
      ),
    );
  }

  String _shortTime(DateTime dt) {
    final now = DateTime.now();
    if (now.difference(dt).inDays == 0) {
      return '${dt.hour.toString().padLeft(2, '0')}:${dt.minute.toString().padLeft(2, '0')}';
    } else if (now.difference(dt).inDays < 7) {
      const days = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];
      return days[dt.weekday - 1];
    } else {
      return '${dt.day}/${dt.month}';
    }
  }
}

class _ConvAvatar extends StatelessWidget {
  final Conversation conv;
  const _ConvAvatar({required this.conv});

  @override
  Widget build(BuildContext context) {
    final url = conv.displayImageUrl;
    final label =
        conv.displayName.isNotEmpty ? conv.displayName[0].toUpperCase() : '?';
    final isOnline = !conv.isGroup && (conv.otherUser?.isOnline ?? false);

    return Stack(children: [
      CircleAvatar(
        radius: 26.r,
        backgroundColor: ColorManager.lightBlack,
        backgroundImage: url != null ? NetworkImage(url) : null,
        child: url == null
            ? Text(label,
                style: const TextStyle(
                    color: Colors.white, fontWeight: FontWeight.w700))
            : null,
      ),
      if (isOnline)
        Positioned(
          right: 1,
          bottom: 1,
          child: Container(
            width: 12.r,
            height: 12.r,
            decoration: BoxDecoration(
              color: Colors.green,
              shape: BoxShape.circle,
              border: Border.all(
                  color: Theme.of(context).scaffoldBackgroundColor, width: 2),
            ),
          ),
        ),
    ]);
  }
}

// ─────────────────────────────────────────────────────────────────────────────
class _RequestList extends StatelessWidget {
  final List<Conversation> requests;
  final ValueChanged<Conversation> onTap;

  const _RequestList({
    required this.requests,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    if (requests.isEmpty) {
      return Center(
        child: Text(S.of(context).noMessageRequests,
            style: TextStyles.font16Medium.copyWith(color: ColorManager.normalGrey)),
      );
    }
    return ListView.separated(
      itemCount: requests.length,
      separatorBuilder: (_, __) => const Divider(height: 1, indent: 72),
      itemBuilder: (_, i) {
        final req = requests[i];
        return ListTile(
          onTap: () => onTap(req),
          leading: _ConvAvatar(conv: req),
          title: Text(req.displayName, style: TextStyles.font15semiBold),
          subtitle: Text(
            req.latestMessage?.preview ?? '',
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyles.font12regular.copyWith(color: ColorManager.normalGrey),
          ),
          trailing: Icon(Icons.chevron_right_rounded, color: ColorManager.normalGrey),
        );
      },
    );
  }
}
