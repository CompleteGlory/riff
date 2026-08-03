// ignore_for_file: use_build_context_synchronously
import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:riff/core/helpers/constants.dart';
import 'package:riff/core/helpers/shared_pref_helper.dart';
import 'package:riff/core/themes/colors/color_manager.dart';
import 'package:riff/core/themes/text_styles/text_styles.dart';
import 'package:riff/features/home/chat/data/models/chat_models.dart';
import 'package:riff/features/home/chat/logic/cubit/chat_cubit.dart';
import 'package:riff/features/home/chat/UI/widgets/message_bubble.dart';
import 'package:riff/features/home/chat/UI/widgets/chat_input_bar.dart';
import 'package:riff/features/home/chat/logic/cubit/chats_list_cubit.dart';
import 'package:riff/features/home/chat/logic/voice_note_playback.dart';
import 'package:riff/features/home/user_profile/ui/user_profile_screen.dart';
import 'package:riff/features/home/chat/UI/group_details_screen.dart';
import 'package:riff/core/widgets/app_error_widget.dart';
import 'package:riff/core/widgets/offline_banner.dart';
import 'package:riff/generated/l10n.dart';

class ChatDetailScreen extends StatefulWidget {
  final Conversation conversation;
  const ChatDetailScreen({super.key, required this.conversation});

  @override
  State<ChatDetailScreen> createState() => _ChatDetailScreenState();
}

class _ChatDetailScreenState extends State<ChatDetailScreen> {
  final _scrollCtrl = ScrollController();
  String _myId = '';

  /// Rough height of one bubble, used to aim the jump-to-quoted-message
  /// scroll. Bubbles vary, so this lands the message on screen rather than at
  /// an exact offset — good enough for "show me what this answers".
  static const _estimatedBubbleExtent = 72.0;

  /// The message briefly tinted after jumping to it from a reply's quote.
  String? _highlightedMessageId;
  Timer? _highlightTimer;

  @override
  void initState() {
    super.initState();
    _scrollCtrl.addListener(_onScroll);
    _init();
  }

  /// Load the current user ID first, then open the conversation.
  /// Doing them in the same initState without awaiting caused _myId to still be
  /// '' when the first batch of messages rendered → all bubbles appeared on the
  /// wrong (left) side until the next rebuild.
  Future<void> _init() async {
    final id =
        await SharedPrefHelper.getString(SharedPrefKeys.userId) as String? ?? '';
    if (!mounted) return;
    setState(() => _myId = id);
    context.read<ChatCubit>().open(widget.conversation);
  }

  /// reverse:true → position 0 = bottom (newest). Load older when near top (maxScrollExtent).
  void _onScroll() {
    if (!_scrollCtrl.hasClients) return;
    final pos = _scrollCtrl.position;
    if (pos.pixels >= pos.maxScrollExtent - 120) {
      context.read<ChatCubit>().loadMore();
    }
  }

  /// Scroll to 0 = bottom (newest message) in reverse list.
  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollCtrl.hasClients) {
        _scrollCtrl.animateTo(0,
            duration: const Duration(milliseconds: 200), curve: Curves.easeOut);
      }
    });
  }

  @override
  void dispose() {
    _highlightTimer?.cancel();
    _scrollCtrl.dispose();
    // Leaving the chat silences whatever voice note was playing. The bubbles go
    // away with the list, but their audio isn't tied to being on screen —
    // without this, a note kept talking over whatever the user moved on to.
    unawaited(VoiceNotePlayback.instance.stopAll());
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final conv = widget.conversation;

    return Scaffold(
      appBar: AppBar(
        titleSpacing: 0,
        title: GestureDetector(
          onTap: conv.otherUser != null
              ? () => Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) =>
                          UserProfileScreen(userId: conv.otherUser!.id),
                    ),
                  )
              : null,
          child: BlocBuilder<ChatCubit, ChatState>(
            buildWhen: (prev, cur) {
              if (prev is ChatLoaded && cur is ChatLoaded) {
                return prev.conversation.otherUser?.isOnline !=
                    cur.conversation.otherUser?.isOnline;
              }
              return cur is ChatLoaded && prev is! ChatLoaded;
            },
            builder: (_, s) {
              final liveConv = (s is ChatLoaded) ? s.conversation : conv;
              return Row(children: [
                _HeaderAvatar(conv: liveConv),
                SizedBox(width: 10.w),
                Flexible(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(liveConv.displayName,
                          style: TextStyles.font15semiBold,
                          overflow: TextOverflow.ellipsis),
                      _PresenceSubtitle(conv: liveConv),
                    ],
                  ),
                ),
              ]);
            },
          ),
        ),
        actions: [
          if (conv.isGroup)
            IconButton(
              icon: const Icon(Icons.info_outline_rounded),
              onPressed: () => Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => GroupDetailsScreen(conversation: conv),
                ),
              ),
            ),
          PopupMenuButton<String>(
            onSelected: (value) {
              if (value == 'delete') _showDeleteConvConfirm(context);
            },
            itemBuilder: (menuCtx) => [
              PopupMenuItem<String>(
                value: 'delete',
                child: Row(children: [
                  const Icon(Icons.delete_outline_rounded, color: Colors.red, size: 20),
                  const SizedBox(width: 10),
                  Text(S.of(menuCtx).deleteForEveryoneBtn,
                      style: const TextStyle(color: Colors.red)),
                ]),
              ),
            ],
          ),
        ],
      ),
      body: BlocConsumer<ChatCubit, ChatState>(
        listenWhen: (prev, cur) {
          if (cur is ChatDeleted) return true;
          // Scroll to bottom only when a new message arrives at the front
          if (prev is ChatLoaded && cur is ChatLoaded) {
            return cur.messages.isNotEmpty &&
                (prev.messages.isEmpty ||
                    cur.messages.first.id != prev.messages.first.id);
          }
          return cur is ChatLoaded && prev is ChatLoading;
        },
        listener: (ctx, state) {
          if (state is ChatDeleted) {
            ctx.read<ChatsListCubit>().removeConversation(widget.conversation.id);
            Navigator.pop(ctx);
            ScaffoldMessenger.of(ctx).showSnackBar(
              SnackBar(content: Text(S.of(ctx).conversationDeleted)),
            );
            return;
          }
          _scrollToBottom();
        },
        builder: (ctx, state) {
          if (state is ChatLoading) {
            return const Center(child: CircularProgressIndicator());
          }
          if (state is ChatError) {
            return AppErrorWidget(message: state.message);
          }
          if (state is ChatLoaded) {
            final isRequest = state.conversation.isRequest;
            // Extra slot at the end (top in reverse) for the request info tile
            final requestInfoCount = isRequest ? 1 : 0;
            return Column(children: [
              // Say so when this history came off disk rather than the server.
              if (state.isFromCache) const OfflineCachedNotice(),
              Expanded(
                child: ListView.builder(
                  controller: _scrollCtrl,
                  reverse: true, // index 0 at bottom → newest visible without scrolling
                  padding:
                      EdgeInsets.symmetric(horizontal: 12.w, vertical: 12.h),
                  itemCount: state.messages.length + requestInfoCount,
                  itemBuilder: (_, i) {
                    // Request info tile at the top (last index in reverse list)
                    if (isRequest && i == state.messages.length) {
                      return _RequestInfoTile(conv: state.conversation);
                    }
                    final msg = state.messages[i];
                    // An optimistic bubble normally carries the signed-in user
                    // as its sender, so the usual check works. The fallback is
                    // for the case where the stored user id was unavailable
                    // when the bubble was built: only our own sends have a
                    // client id, and only an unattributed one has no sender.
                    final isMe = msg.sender?.id == _myId ||
                        (msg.clientId != null && msg.sender == null);
                    // Show checkmarks on all own messages (WhatsApp-style)
                    return AnimatedContainer(
                      duration: const Duration(milliseconds: 250),
                      margin: EdgeInsets.only(bottom: 6.h),
                      decoration: BoxDecoration(
                        // Tints the message a reply's quote just jumped to, so
                        // it's findable among bubbles that otherwise look alike.
                        color: _highlightedMessageId == msg.id
                            ? ColorManager.accent.withValues(alpha: 0.15)
                            : Colors.transparent,
                        borderRadius: BorderRadius.circular(12.r),
                      ),
                      child: MessageBubble(
                        message: msg,
                        isMe: isMe,
                        showSender: conv.isGroup,
                        showStatus: isMe,
                        myId: _myId,
                        onReactionTap: msg.isDeleted
                            ? null
                            : (emoji) => ctx
                                .read<ChatCubit>()
                                .toggleReaction(msg.id, emoji),
                        onRetry: msg.hasFailed
                            ? () => ctx
                                .read<ChatCubit>()
                                .retryMessage(msg.clientId!)
                            : null,
                        // Nothing to offer while a send is still in flight, or
                        // once the message is gone: reacting to — or deleting
                        // "for everyone" — a message the server has never
                        // heard of means nothing.
                        onQuoteTap: _jumpToMessage,
                        // A message still in flight has no server id to quote,
                        // and a deleted one has nothing left to answer.
                        onSwipeReply: msg.isPending ||
                                msg.hasFailed ||
                                msg.isDeleted
                            ? null
                            : () => ctx.read<ChatCubit>().startReplying(msg),
                        onLongPress: msg.isPending || msg.isDeleted
                            ? null
                            : () => msg.hasFailed
                                ? _showFailedOptions(ctx, msg.clientId!)
                                : _showMessageOptions(ctx, msg, isMe: isMe),
                      ),
                    );
                  },
                ),
              ),
              // Typing indicator (only for accepted chats)
              if (!isRequest)
                BlocBuilder<ChatCubit, ChatState>(
                  builder: (_, s) {
                    if (s is! ChatLoaded) return const SizedBox.shrink();
                    final anyTyping = s.typingUsers.entries
                        .any((e) => e.value && e.key != _myId);
                    if (!anyTyping) return const SizedBox.shrink();
                    return Padding(
                      padding: EdgeInsets.fromLTRB(16.w, 0, 16.w, 4.h),
                      child: Align(
                          alignment: Alignment.centerLeft,
                          child: _TypingDots()),
                    );
                  },
                ),
              // Accept/Decline banner for requests; normal input for accepted chats
              if (isRequest)
                _RequestActionBar(
                  onAccept: () => _handleAccept(ctx),
                  onDecline: () => _handleDecline(ctx),
                )
              else
                ChatInputBar(cubit: ctx.read<ChatCubit>()),
            ]);
          }
          return const SizedBox();
        },
      ),
    );
  }

  Future<void> _handleAccept(BuildContext ctx) async {
    final chatCubit = ctx.read<ChatCubit>();
    final chatsListCubit = ctx.read<ChatsListCubit>();
    await chatCubit.acceptRequest();
    if (!mounted) return;
    final s = chatCubit.state;
    if (s is ChatLoaded) chatsListCubit.acceptRequest(s.conversation);
  }

  Future<void> _handleDecline(BuildContext ctx) async {
    final convId = widget.conversation.id;
    await ctx.read<ChatCubit>().declineRequest();
    if (!mounted) return;
    ctx.read<ChatsListCubit>().removeRequest(convId);
    Navigator.pop(ctx);
  }

  void _showDeleteConvConfirm(BuildContext ctx) {
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
            onPressed: () {
              Navigator.pop(ctx);
              ctx.read<ChatCubit>().deleteConversation();
            },
            child: Text(s.deleteBtn, style: const TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }

  /// Options for a message that never reached the server: send it again, or
  /// throw it away. Leaving the user with only "delete" would mean retyping.
  void _showFailedOptions(BuildContext ctx, String clientId) {
    final s = S.of(ctx);
    showModalBottomSheet(
      context: ctx,
      builder: (_) => SafeArea(
        child: Wrap(children: [
          ListTile(
            dense: true,
            title: Text(s.messageFailedSheetTitle,
                style: TextStyles.font12regular
                    .copyWith(color: ColorManager.normalGrey)),
          ),
          ListTile(
            leading: const Icon(Icons.refresh_rounded),
            title: Text(s.messageRetrySend),
            onTap: () {
              Navigator.pop(ctx);
              ctx.read<ChatCubit>().retryMessage(clientId);
            },
          ),
          ListTile(
            leading:
                const Icon(Icons.delete_outline_rounded, color: ColorManager.red),
            title: Text(s.messageDiscard,
                style: const TextStyle(color: ColorManager.red)),
            onTap: () {
              Navigator.pop(ctx);
              ctx.read<ChatCubit>().discardMessage(clientId);
            },
          ),
        ]),
      ),
    );
  }

  /// Scrolls to the message a reply quotes.
  ///
  /// Only reaches messages already loaded — the quoted message may be far
  /// enough back that it hasn't been paged in, and there is no endpoint for
  /// "fetch around this id". In that case the tap does nothing rather than
  /// jumping somewhere arbitrary; scrolling up to load more history brings it
  /// into range.
  void _jumpToMessage(String messageId) {
    final state = context.read<ChatCubit>().state;
    if (state is! ChatLoaded) return;
    final index = state.messages.indexWhere((m) => m.id == messageId);
    if (index == -1 || !_scrollCtrl.hasClients) return;

    // The list is reverse:true, so index 0 sits at the bottom and the offset
    // grows going back in time. Bubbles vary in height, so this is an estimate
    // that lands the message on screen rather than an exact position.
    final target = (index * _estimatedBubbleExtent)
        .clamp(0.0, _scrollCtrl.position.maxScrollExtent);
    _scrollCtrl.animateTo(
      target,
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeOut,
    );
    setState(() => _highlightedMessageId = messageId);
    // The highlight is a pointer, not a selection — it fades on its own so the
    // user doesn't have to dismiss it.
    _highlightTimer?.cancel();
    _highlightTimer = Timer(const Duration(milliseconds: 1600), () {
      if (mounted) setState(() => _highlightedMessageId = null);
    });
  }

  /// The emoji the signed-in user has on [msg], or null if they haven't
  /// reacted — a user holds at most one reaction per message.
  String? _myReactionEmoji(ChatMessage msg) {
    if (_myId.isEmpty) return null;
    for (final r in msg.reactions) {
      if (r.userId == _myId) return r.emoji;
    }
    return null;
  }

  /// The long-press sheet: react to any message, plus edit and delete on your
  /// own.
  ///
  /// Reactions come first and are available on everyone's messages — they're
  /// the thing you reach for most and the only thing you can do to someone
  /// else's message.
  void _showMessageOptions(
    BuildContext ctx,
    ChatMessage msg, {
    required bool isMe,
  }) {
    final s = S.of(ctx);
    final cubit = ctx.read<ChatCubit>();
    final myEmoji = _myReactionEmoji(msg);

    showModalBottomSheet(
      context: ctx,
      builder: (_) => SafeArea(
        child: Wrap(children: [
          ListTile(
            dense: true,
            title: Text(s.reactToMessageTitle,
                style: TextStyles.font12regular
                    .copyWith(color: ColorManager.normalGrey)),
          ),
          _ReactionPickerRow(
            selected: myEmoji,
            onPick: (emoji) {
              Navigator.pop(ctx);
              cubit.toggleReaction(msg.id, emoji);
            },
          ),
          ListTile(
            leading: const Icon(Icons.reply_rounded),
            title: Text(s.replyMessageOption),
            onTap: () {
              Navigator.pop(ctx);
              cubit.startReplying(msg);
            },
          ),
          if (myEmoji != null)
            ListTile(
              leading: const Icon(Icons.remove_circle_outline_rounded),
              title: Text(s.removeReactionOption),
              onTap: () {
                Navigator.pop(ctx);
                // Toggling the emoji they already picked is how the server
                // clears it, so there's no separate "remove" call to make.
                cubit.toggleReaction(msg.id, myEmoji);
              },
            ),
          if (isMe && msg.canBeEdited)
            ListTile(
              leading: const Icon(Icons.edit_outlined),
              title: Text(s.editMessageOption),
              onTap: () {
                Navigator.pop(ctx);
                cubit.startEditing(msg);
              },
            ),
          if (isMe)
            ListTile(
              leading: const Icon(Icons.delete_outline_rounded,
                  color: ColorManager.red),
              title: Text(s.deleteMessageOption,
                  style: const TextStyle(color: ColorManager.red)),
              onTap: () {
                Navigator.pop(ctx);
                cubit.deleteMessage(msg.id);
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
}

// ─── Quick reaction picker ────────────────────────────────────────────────────

/// The row of emoji at the top of the long-press sheet.
///
/// A fixed short set rather than a full picker: these cover almost every
/// reaction anyone sends, and one tap beats a search field.
class _ReactionPickerRow extends StatelessWidget {
  static const emojis = ['❤️', '😂', '👍', '😮', '😢', '🙏'];

  final String? selected;
  final void Function(String emoji) onPick;

  const _ReactionPickerRow({required this.onPick, this.selected});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 4.h),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          for (final emoji in emojis)
            GestureDetector(
              onTap: () => onPick(emoji),
              child: Container(
                padding: EdgeInsets.all(8.r),
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: emoji == selected
                      ? ColorManager.accent.withValues(alpha: 0.25)
                      : Colors.transparent,
                ),
                child: Text(emoji, style: TextStyle(fontSize: 22.sp)),
              ),
            ),
        ],
      ),
    );
  }
}

// ─── Presence subtitle (Online / Last seen …) ─────────────────────────────────

class _PresenceSubtitle extends StatelessWidget {
  final Conversation conv;
  const _PresenceSubtitle({required this.conv});

  String _fmt(BuildContext context, DateTime? dt) {
    if (dt == null) return '';
    final s = S.of(context);
    final now = DateTime.now();
    final diff = now.difference(dt);
    if (diff.inMinutes < 1) return s.presenceLastSeenJustNow;
    if (diff.inMinutes < 60) return s.presenceLastSeenMinutes(diff.inMinutes);
    final hm =
        '${dt.hour.toString().padLeft(2, '0')}:${dt.minute.toString().padLeft(2, '0')}';
    if (diff.inDays == 0) return s.presenceLastSeenTodayAt(hm);
    if (diff.inDays == 1) return s.presenceLastSeenYesterdayAt(hm);
    return s.presenceLastSeenDate('${dt.day}/${dt.month}');
  }

  @override
  Widget build(BuildContext context) {
    if (conv.isGroup) return const SizedBox.shrink();
    final other = conv.otherUser;
    if (other == null) return const SizedBox.shrink();
    final text = other.isOnline ? S.of(context).presenceOnline : _fmt(context, other.lastSeen);
    if (text.isEmpty) return const SizedBox.shrink();
    final color = other.isOnline ? Colors.green : ColorManager.normalGrey;
    return Text(text,
        style: TextStyles.font12regular.copyWith(color: color, fontSize: 11));
  }
}

// ─── Header avatar with green online dot ─────────────────────────────────────

class _HeaderAvatar extends StatelessWidget {
  final Conversation conv;
  const _HeaderAvatar({required this.conv});

  @override
  Widget build(BuildContext context) {
    final url = conv.displayImageUrl;
    final label =
        conv.displayName.isNotEmpty ? conv.displayName[0].toUpperCase() : '?';
    final isOnline = !conv.isGroup && (conv.otherUser?.isOnline ?? false);

    return Stack(children: [
      CircleAvatar(
        radius: 18.r,
        backgroundColor: ColorManager.lightBlack,
        backgroundImage: url != null ? NetworkImage(url) : null,
        child: url == null
            ? Text(label,
                style: const TextStyle(
                    color: Colors.white, fontWeight: FontWeight.w600))
            : null,
      ),
      if (isOnline)
        Positioned(
          right: 0,
          bottom: 0,
          child: Container(
            width: 10.r,
            height: 10.r,
            decoration: BoxDecoration(
              color: Colors.green,
              shape: BoxShape.circle,
              border: Border.all(
                  color: Theme.of(context).scaffoldBackgroundColor, width: 1.5),
            ),
          ),
        ),
    ]);
  }
}

// ─── Animated typing dots ─────────────────────────────────────────────────────

class _TypingDots extends StatefulWidget {
  @override
  State<_TypingDots> createState() => _TypingDotsState();
}

class _TypingDotsState extends State<_TypingDots>
    with SingleTickerProviderStateMixin {
  late AnimationController _ctrl;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 1200))
      ..repeat();
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 14.w, vertical: 10.h),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF2A2A2A) : const Color(0xFFF0F0F0),
        borderRadius: BorderRadius.circular(18.r),
      ),
      child: Row(mainAxisSize: MainAxisSize.min, children: [
        for (int i = 0; i < 3; i++) ...[
          _Dot(ctrl: _ctrl, delay: i * 0.3),
          if (i < 2) SizedBox(width: 4.w),
        ],
      ]),
    );
  }
}

class _Dot extends StatelessWidget {
  final AnimationController ctrl;
  final double delay;
  const _Dot({required this.ctrl, required this.delay});

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: ctrl,
      builder: (_, __) {
        final t = ((ctrl.value - delay) % 1.0).clamp(0.0, 1.0);
        final scale = 0.6 + 0.4 * (1 - (2 * t - 1).abs());
        return Transform.scale(
          scale: scale,
          child: Container(
            width: 7.r,
            height: 7.r,
            decoration: const BoxDecoration(
                color: ColorManager.normalGrey, shape: BoxShape.circle),
          ),
        );
      },
    );
  }
}

// ─── Request info tile (shown at the top of the message list) ─────────────────

class _RequestInfoTile extends StatelessWidget {
  final Conversation conv;
  const _RequestInfoTile({required this.conv});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final name = conv.displayName;
    final url = conv.displayImageUrl;
    final label = name.isNotEmpty ? name[0].toUpperCase() : '?';

    return Padding(
      padding: EdgeInsets.symmetric(vertical: 24.h, horizontal: 16.w),
      child: Column(
        children: [
          CircleAvatar(
            radius: 36.r,
            backgroundColor: ColorManager.lightBlack,
            backgroundImage: url != null ? NetworkImage(url) : null,
            child: url == null
                ? Text(label,
                    style: TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.w700,
                        fontSize: 22.sp))
                : null,
          ),
          SizedBox(height: 12.h),
          Text(
            name,
            style: TextStyles.font15semiBold,
            textAlign: TextAlign.center,
          ),
          SizedBox(height: 6.h),
          Container(
            padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 6.h),
            decoration: BoxDecoration(
              color: isDark ? const Color(0xFF2A2A2A) : const Color(0xFFF0F0F0),
              borderRadius: BorderRadius.circular(8.r),
            ),
            child: Text(
              S.of(context).requestInfoMessage(name),
              textAlign: TextAlign.center,
              style: TextStyles.font12regular.copyWith(
                color: ColorManager.normalGrey,
                height: 1.5,
              ),
            ),
          ),
          SizedBox(height: 16.h),
          const Divider(),
        ],
      ),
    );
  }
}

// ─── Accept / Decline action bar (bottom of the screen for requests) ──────────

class _RequestActionBar extends StatefulWidget {
  final VoidCallback onAccept;
  final VoidCallback onDecline;
  const _RequestActionBar({required this.onAccept, required this.onDecline});

  @override
  State<_RequestActionBar> createState() => _RequestActionBarState();
}

class _RequestActionBarState extends State<_RequestActionBar> {
  bool _loading = false;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return SafeArea(
      top: false,
      child: Container(
        padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 12.h),
        decoration: BoxDecoration(
          color: isDark ? const Color(0xFF1C1C1C) : Colors.white,
          border: Border(
            top: BorderSide(
              color: isDark
                  ? Colors.white.withValues(alpha: 0.08)
                  : Colors.black.withValues(alpha: 0.08),
            ),
          ),
        ),
        child: _loading
            ? const Center(child: CircularProgressIndicator())
            : Row(children: [
                // Decline
                Expanded(
                  child: GestureDetector(
                    onTap: () async {
                      setState(() => _loading = true);
                      widget.onDecline();
                    },
                    child: Container(
                      padding: EdgeInsets.symmetric(vertical: 13.h),
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(12.r),
                        border: Border.all(
                          color: ColorManager.red.withValues(alpha: 0.6),
                        ),
                      ),
                      child: Text(
                        S.of(context).declineBtn,
                        textAlign: TextAlign.center,
                        style: TextStyles.font14semiBold
                            .copyWith(color: ColorManager.red),
                      ),
                    ),
                  ),
                ),
                SizedBox(width: 12.w),
                // Accept
                Expanded(
                  child: GestureDetector(
                    onTap: () async {
                      setState(() => _loading = true);
                      widget.onAccept();
                    },
                    child: Container(
                      padding: EdgeInsets.symmetric(vertical: 13.h),
                      decoration: BoxDecoration(
                        color: ColorManager.accent,
                        borderRadius: BorderRadius.circular(12.r),
                      ),
                      child: Text(
                        S.of(context).acceptBtn,
                        textAlign: TextAlign.center,
                        style: TextStyles.font14semiBold
                            .copyWith(color: ColorManager.black),
                      ),
                    ),
                  ),
                ),
              ]),
      ),
    );
  }
}
