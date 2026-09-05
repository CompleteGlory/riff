import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:riff/core/cache/cache_keys.dart';
import 'package:riff/core/cache/offline_cache.dart';
import 'package:riff/core/logic/app_scoped_cubit.dart';
import 'package:riff/core/logic/reconnect_refresh.dart';
import '../../data/models/chat_models.dart';
import '../../data/repos/chat_repo.dart';
import 'conversation_dedupe.dart';
import 'conversation_ordering.dart';

part 'chats_list_state.dart';

class ChatsListCubit extends Cubit<ChatsListState>
    // Order matters: AppScopedCubit must be applied last so its `close()`
    // override runs first and short-circuits a route-level close. The other way
    // round, popping a route that provided this singleton would cancel the
    // reconnect subscription for the rest of the process while the cubit itself
    // stayed alive.
    with ReconnectRefresh<ChatsListState>, AppScopedCubit<ChatsListState> {
  final ChatRepo _repo;
  final OfflineCache _cache;

  ChatsListCubit(this._repo, {OfflineCache? cache})
      : _cache = cache ?? OfflineCache.instance,
        super(ChatsListInitial()) {
    refreshOnReconnect(() {
      if (_isShowingCached) _refresh();
    });
  }

  bool _isShowingCached = false;

  /// True while the list on screen was restored from the offline cache.
  bool get isShowingCached => _isShowingCached;

  /// When the cached copy on screen was written.
  DateTime? get cacheSavedAt => _cache.savedAt(CacheKeys.conversations);

  Future<void> load() async {
    if (state is! ChatsListLoaded) {
      // Try the cache before the spinner: opening chats with no signal should
      // still show who you were talking to, not an empty screen.
      final cached = await _readCachedList();
      if (isClosed) return;
      if (cached != null) {
        _isShowingCached = true;
        emit(cached);
      } else {
        emit(ChatsListLoading());
      }
    }
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
        final loaded = ChatsListLoaded(
          conversations: dedupeConversations(convs),
          requests: dedupeConversations(reqs),
        );
        _isShowingCached = false;
        emit(loaded);
        unawaited(_cacheList(loaded));
      }
    } catch (e) {
      if (isClosed) return;
      // Keep whatever is already listed — cached or from an earlier fetch —
      // rather than replacing a usable chat list with an error.
      if (state is ChatsListLoaded) return;
      emit(ChatsListError(e.toString()));
    }
  }

  // ── Offline cache ───────────────────────────────────────────────────────────

  Future<ChatsListLoaded?> _readCachedList() async {
    try {
      final convs = await _cache.readList(CacheKeys.conversations);
      if (convs == null) return null;
      final reqs =
          await _cache.readList(CacheKeys.conversationRequests) ?? const [];
      return ChatsListLoaded(
        conversations: convs.map(Conversation.fromJson).toList(),
        requests: reqs.map(Conversation.fromJson).toList(),
      );
    } catch (e) {
      debugPrint('ChatsListCubit: cached conversations unreadable — $e');
      return null;
    }
  }

  Future<void> _cacheList(ChatsListLoaded loaded) async {
    await _cache.writeList(
      CacheKeys.conversations,
      loaded.conversations.map((c) => c.toJson()).toList(),
      limit: CacheKeys.conversationsLimit,
    );
    await _cache.writeList(
      CacheKeys.conversationRequests,
      loaded.requests.map((c) => c.toJson()).toList(),
      limit: CacheKeys.conversationsLimit,
    );
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
    // Keep the sort key in step with the row. The explicit move below is what
    // puts it on top now, but a later re-sort — after a message is deleted
    // somewhere else in the list — reads this, and a stale value would drop
    // the conversation back down as if the new message had never arrived.
    conv.lastMessageAt = msg.createdAt;
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

  /// Called when a message is deleted for everyone — re-sorts the list on the
  /// message that is now the most recent one.
  ///
  /// Deleting the newest message in a conversation moves that conversation
  /// *down*, to wherever the message before it belongs, so unlike
  /// [onNewMessage] this can't be expressed as "move to the front". The server
  /// sends the conversation's new `last_message_at` and preview with the
  /// deletion, and the whole list is re-sorted on the timestamps.
  ///
  /// Deleting anything other than the newest message changes neither, so the
  /// order simply stays as it was.
  void onMessageDeleted(
    String conversationId, {
    required ChatMessage? latestMessage,
    required DateTime? lastMessageAt,
  }) {
    final cur = state;
    if (cur is! ChatsListLoaded || isClosed) return;

    final idx = cur.conversations.indexWhere((c) => c.id == conversationId);
    if (idx == -1) return;

    final conv = cur.conversations[idx];
    conv.latestMessage = latestMessage;
    conv.lastMessageAt = lastMessageAt;

    emit(ChatsListLoaded(
      conversations: sortConversationsByRecency(cur.conversations),
      requests: cur.requests,
    ));
  }

  /// Called when a message's text is rewritten — refreshes the row's preview
  /// when it was the one being previewed. Ordering is untouched: an edit
  /// doesn't make a conversation any more recent.
  void onMessageEdited(ChatMessage edited) {
    final cur = state;
    if (cur is! ChatsListLoaded || isClosed) return;

    final idx =
        cur.conversations.indexWhere((c) => c.id == edited.conversationId);
    if (idx == -1) return;
    final conv = cur.conversations[idx];
    if (conv.latestMessage?.id != edited.id) return;

    conv.latestMessage = conv.latestMessage!
        .copyWith(content: edited.content, editedAt: edited.editedAt);
    emit(ChatsListLoaded(
      conversations: cur.conversations,
      requests: cur.requests,
    ));
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

  // ── Conversation operations ───────────────────────────────────────────────
  //
  // These live here rather than in the screens because each is *one* operation
  // that happens to have two halves: a call to the repository and a change to
  // the list this cubit owns. Splitting them left the screens calling
  // `getIt<ChatRepo>()` directly and then telling the cubit what had happened
  // — so the list could be updated without the server agreeing, or the server
  // could be changed without the list noticing, depending on which half threw.

  /// True when the conversation was deleted and removed from the list.
  ///
  /// Returns a result rather than throwing: the caller's only job is to show a
  /// message, and the list is already correct either way.
  Future<bool> deleteConversation(String conversationId) async {
    try {
      await _repo.deleteConversation(conversationId);
      removeConversation(conversationId);
      return true;
    } catch (_) {
      return false;
    }
  }

  /// Opens (or finds) the direct conversation with [userId] and puts it at the
  /// top of the list. Null means it could not be started.
  ///
  /// The re-entrancy guard is here rather than in the screen because it is
  /// protecting *this* cubit's list: two taps used to race two
  /// `startDirectConversation` calls and prepend the same thread twice.
  Future<Conversation?> startDirectConversation(String userId) async {
    if (_startingConversation) return null;
    _startingConversation = true;
    try {
      final conv = await _repo.startDirectConversation(userId);
      prependConversation(conv);
      return conv;
    } catch (_) {
      return null;
    } finally {
      _startingConversation = false;
    }
  }

  bool _startingConversation = false;

  /// Creates a group and puts it at the top of the list. Null means it failed.
  Future<Conversation?> createGroup({
    required String name,
    String? description,
    String? imageUrl,
    required List<String> memberIds,
  }) async {
    try {
      final conv = await _repo.createGroupConversation(
        name: name,
        description: description,
        imageUrl: imageUrl,
        memberIds: memberIds,
      );
      prependConversation(conv);
      return conv;
    } catch (_) {
      return null;
    }
  }

  /// Uploads a group photo and returns its URL, or null on failure.
  ///
  /// Used before a group exists, when creating one.
  Future<String?> uploadGroupPhoto(String filePath, String fileName) async {
    try {
      return await _repo.uploadGroupPhoto(filePath, fileName);
    } catch (_) {
      return null;
    }
  }

  /// Uploads a new photo for an existing group and applies it, returning the
  /// updated conversation or null on failure.
  Future<Conversation?> updateGroupPhoto(
    String conversationId,
    String filePath,
    String fileName,
  ) async {
    final url = await uploadGroupPhoto(filePath, fileName);
    if (url == null) return null;
    return updateGroup(conversationId, imageUrl: url);
  }

  /// Renames or re-describes a group, and updates the row in the list.
  ///
  /// The list update is the part the screen could not do for itself: it popped
  /// with the updated conversation and left this cubit holding the old name
  /// until the next full refresh.
  Future<Conversation?> updateGroup(
    String conversationId, {
    String? name,
    String? description,
    String? imageUrl,
  }) async {
    try {
      final updated = await _repo.updateGroup(
        conversationId,
        name: name,
        description: description,
        imageUrl: imageUrl,
      );
      final cur = state;
      if (!isClosed && cur is ChatsListLoaded) {
        final idx =
            cur.conversations.indexWhere((c) => c.id == conversationId);
        if (idx != -1) {
          final next = List<Conversation>.from(cur.conversations)
            ..[idx] = updated;
          emit(ChatsListLoaded(conversations: next, requests: cur.requests));
        }
      }
      return updated;
    } catch (_) {
      return null;
    }
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
    _isShowingCached = false;
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
