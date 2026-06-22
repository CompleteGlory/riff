import 'package:flutter_bloc/flutter_bloc.dart';
import '../../data/models/chat_models.dart';
import '../../data/repos/chat_repo.dart';

part 'chats_list_state.dart';

class ChatsListCubit extends Cubit<ChatsListState> {
  final ChatRepo _repo;

  ChatsListCubit(this._repo) : super(ChatsListInitial());

  Future<void> load() async {
    if (state is! ChatsListLoaded) emit(ChatsListLoading());
    await _refresh();
  }

  Future<void> refresh() => _refresh();

  Future<void> _refresh() async {
    try {
      final convs = await _repo.getConversations();
      final reqs  = await _repo.getMessageRequests();
      if (!isClosed) emit(ChatsListLoaded(conversations: convs, requests: reqs));
    } catch (e) {
      if (!isClosed) emit(ChatsListError(e.toString()));
    }
  }

  /// Called when a new socket message arrives — update latest message, increment
  /// unread count if the conversation isn't currently open, and re-sort.
  ///
  /// [myId] — the current user's ID. Own messages (echoed back via personal room)
  /// are excluded from unread-count increments.
  void onNewMessage(ChatMessage msg, {String? openConversationId, String? myId}) {
    final cur = state;
    if (cur is! ChatsListLoaded || isClosed) return;
    final updated = cur.conversations.map((c) {
      if (c.id == msg.conversationId) {
        c.latestMessage = msg;
        // Only increment if the user isn't actively viewing this conversation
        // AND this message wasn't sent by the current user themselves.
        final isOwnMessage = myId != null && myId.isNotEmpty && msg.sender?.id == myId;
        if (c.id != openConversationId && !isOwnMessage) {
          c.unreadCount = c.unreadCount + 1;
        }
        return c;
      }
      return c;
    }).toList()
      ..sort((a, b) {
        final aTime = a.latestMessage?.createdAt ?? a.lastMessageAt ?? a.createdAt;
        final bTime = b.latestMessage?.createdAt ?? b.lastMessageAt ?? b.createdAt;
        return bTime.compareTo(aTime);
      });
    emit(ChatsListLoaded(conversations: updated, requests: cur.requests));
  }

  /// Zero out the unread count for a conversation instantly (called when user
  /// opens or returns from a chat, before the network re-fetch).
  void markConversationRead(String convId) {
    final cur = state;
    if (cur is! ChatsListLoaded || isClosed) return;
    for (final c in cur.conversations) {
      if (c.id == convId) c.unreadCount = 0;
    }
    emit(ChatsListLoaded(conversations: cur.conversations, requests: cur.requests));
  }

  void prependConversation(Conversation conv) {
    final cur = state;
    if (isClosed) return;
    final list = cur is ChatsListLoaded ? cur.conversations : <Conversation>[];
    final reqs  = cur is ChatsListLoaded ? cur.requests    : <Conversation>[];
    if (list.any((c) => c.id == conv.id)) return;
    emit(ChatsListLoaded(conversations: [conv, ...list], requests: reqs));
  }

  void removeRequest(String conversationId) {
    final cur = state;
    if (cur is! ChatsListLoaded || isClosed) return;
    emit(ChatsListLoaded(
      conversations: cur.conversations,
      requests: cur.requests.where((c) => c.id != conversationId).toList(),
    ));
  }

  /// Remove a conversation from the list (used when it's deleted by either participant).
  void removeConversation(String conversationId) {
    final cur = state;
    if (cur is! ChatsListLoaded || isClosed) return;
    emit(ChatsListLoaded(
      conversations: cur.conversations.where((c) => c.id != conversationId).toList(),
      requests: cur.requests,
    ));
  }

  /// Clear all state — call on logout so the next user starts with a blank slate.
  void reset() {
    if (!isClosed) emit(ChatsListInitial());
  }

  void acceptRequest(Conversation conv) {
    final cur = state;
    if (cur is! ChatsListLoaded || isClosed) return;
    emit(ChatsListLoaded(
      conversations: [conv, ...cur.conversations],
      requests: cur.requests.where((c) => c.id != conv.id).toList(),
    ));
  }
}
