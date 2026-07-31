import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:riff/core/logic/app_scoped_cubit.dart';
import '../../data/models/chat_models.dart';
import '../../data/repos/chat_repo.dart';
import 'conversation_dedupe.dart';

part 'chats_list_state.dart';

class ChatsListCubit extends Cubit<ChatsListState>
    with AppScopedCubit<ChatsListState> {
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
      if (!isClosed) {
        // Collapse the duplicate direct conversations some accounts already
        // have on the server — see conversation_dedupe.dart.
        emit(ChatsListLoaded(
          conversations: dedupeConversations(convs),
          requests: dedupeConversations(reqs),
        ));
      }
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

    final idx = cur.conversations.indexWhere((c) => c.id == msg.conversationId);
    if (idx == -1) return; // Conversation not in the list yet — nothing to move.

    final conv = cur.conversations[idx];
    conv.latestMessage = msg;
    // Only increment if the user isn't actively viewing this conversation
    // AND this message wasn't sent by the current user themselves.
    final isOwnMessage = myId != null && myId.isNotEmpty && msg.sender?.id == myId;
    if (conv.id != openConversationId && !isOwnMessage) {
      conv.unreadCount = conv.unreadCount + 1;
    }

    // Move the conversation to the top. A new message always makes it the most
    // recent, so we reorder explicitly rather than sort by timestamp — the socket
    // and REST payloads can serialize `created_at` with different timezone info
    // (naive vs. UTC `Z`), which made a timestamp comparison put new messages in
    // the wrong position and left the list stale until an app restart.
    final reordered = List<Conversation>.from(cur.conversations)
      ..removeAt(idx)
      ..insert(0, conv);

    emit(ChatsListLoaded(conversations: reordered, requests: cur.requests));
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
    // dedupe, not just an id check: starting a chat with someone already in the
    // list must not add a second row for them.
    emit(ChatsListLoaded(
      conversations: dedupeConversations([conv, ...list]),
      requests: reqs,
    ));
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
    // An accepted request can already be in the list if a refresh landed first;
    // without the dedupe that showed the same person twice.
    emit(ChatsListLoaded(
      conversations: dedupeConversations([conv, ...cur.conversations]),
      requests: cur.requests.where((c) => c.id != conv.id).toList(),
    ));
  }
}
