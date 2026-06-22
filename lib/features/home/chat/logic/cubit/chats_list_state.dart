part of 'chats_list_cubit.dart';

abstract class ChatsListState {}

class ChatsListInitial extends ChatsListState {}
class ChatsListLoading extends ChatsListState {}

class ChatsListLoaded extends ChatsListState {
  final List<Conversation> conversations;
  final List<Conversation> requests;
  final int requestCount;
  ChatsListLoaded({
    required this.conversations,
    required this.requests,
  }) : requestCount = requests.length;
}

class ChatsListError extends ChatsListState {
  final String message;
  ChatsListError(this.message);
}
