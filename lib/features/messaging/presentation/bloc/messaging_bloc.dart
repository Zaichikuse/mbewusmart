import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:equatable/equatable.dart';
import '../../domain/entities/message.dart';
import '../../domain/entities/conversation.dart';
import '../../domain/repositories/messaging_repository.dart';

abstract class MessagingEvent extends Equatable {
  const MessagingEvent();

  @override
  List<Object?> get props => [];
}

class MessagingLoadConversations extends MessagingEvent {}

class MessagingLoadMessages extends MessagingEvent {
  final String conversationId;

  const MessagingLoadMessages(this.conversationId);

  @override
  List<Object?> get props => [conversationId];
}

class MessagingSendMessage extends MessagingEvent {
  final Message message;

  const MessagingSendMessage(this.message);

  @override
  List<Object?> get props => [message];
}

class MessagingMarkAsRead extends MessagingEvent {
  final String conversationId;
  final String userId;

  const MessagingMarkAsRead({
    required this.conversationId,
    required this.userId,
  });

  @override
  List<Object?> get props => [conversationId, userId];
}

class MessagingStartConversation extends MessagingEvent {
  final String userId;
  final String targetRole;
  final String? targetEpa;
  final String? targetDistrict;
  final String? targetUserId;

  const MessagingStartConversation({
    required this.userId,
    required this.targetRole,
    this.targetEpa,
    this.targetDistrict,
    this.targetUserId,
  });

  @override
  List<Object?> get props => [userId, targetRole, targetEpa, targetDistrict, targetUserId];
}

class MessagingConversationUpdated extends MessagingEvent {
  final List<Conversation> conversations;

  const MessagingConversationUpdated(this.conversations);

  @override
  List<Object?> get props => [conversations];
}

class MessagingMessagesUpdated extends MessagingEvent {
  final List<Message> messages;

  const MessagingMessagesUpdated(this.messages);

  @override
  List<Object?> get props => [messages];
}

abstract class MessagingState extends Equatable {
  const MessagingState();

  @override
  List<Object?> get props => [];
}

class MessagingInitial extends MessagingState {}

class MessagingLoading extends MessagingState {}

class MessagingConversationsLoaded extends MessagingState {
  final List<Conversation> conversations;

  const MessagingConversationsLoaded(this.conversations);

  @override
  List<Object?> get props => [conversations];
}

class MessagingMessagesLoaded extends MessagingState {
  final String conversationId;
  final List<Message> messages;

  const MessagingMessagesLoaded({
    required this.conversationId,
    required this.messages,
  });

  @override
  List<Object?> get props => [conversationId, messages];
}

class MessagingConversationCreated extends MessagingState {
  final Conversation conversation;

  const MessagingConversationCreated(this.conversation);

  @override
  List<Object?> get props => [conversation];
}

class MessagingError extends MessagingState {
  final String message;

  const MessagingError(this.message);

  @override
  List<Object?> get props => [message];
}

class MessagingBloc extends Bloc<MessagingEvent, MessagingState> {
  final MessagingRepository messagingRepository;
  String? _currentConversationId;
  String? _currentUserId;

  MessagingBloc({required this.messagingRepository}) : super(MessagingInitial()) {
    on<MessagingLoadConversations>(_onLoadConversations);
    on<MessagingLoadMessages>(_onLoadMessages);
    on<MessagingSendMessage>(_onSendMessage);
    on<MessagingMarkAsRead>(_onMarkAsRead);
    on<MessagingStartConversation>(_onStartConversation);
    on<MessagingConversationUpdated>(_onConversationUpdated);
    on<MessagingMessagesUpdated>(_onMessagesUpdated);
  }

  Future<void> _onLoadConversations(
    MessagingLoadConversations event,
    Emitter<MessagingState> emit,
  ) async {
    emit(MessagingLoading());
    
    if (_currentUserId == null) {
      emit(const MessagingError('User not authenticated'));
      return;
    }

    final result = await messagingRepository.getConversations(_currentUserId!);
    
    result.fold(
      (failure) => emit(MessagingError(failure.message)),
      (conversations) => emit(MessagingConversationsLoaded(conversations)),
    );
  }

  Future<void> _onLoadMessages(
    MessagingLoadMessages event,
    Emitter<MessagingState> emit,
  ) async {
    emit(MessagingLoading());
    _currentConversationId = event.conversationId;

    final result = await messagingRepository.getMessages(event.conversationId);
    
    result.fold(
      (failure) => emit(MessagingError(failure.message)),
      (messages) => emit(MessagingMessagesLoaded(
        conversationId: event.conversationId,
        messages: messages,
      )),
    );
  }

  Future<void> _onSendMessage(
    MessagingSendMessage event,
    Emitter<MessagingState> emit,
  ) async {
    final result = await messagingRepository.sendMessage(event.message);
    
    result.fold(
      (failure) => emit(MessagingError(failure.message)),
      (message) {
        if (_currentConversationId != null) {
          add(MessagingLoadMessages(_currentConversationId!));
        }
      },
    );
  }

  Future<void> _onMarkAsRead(
    MessagingMarkAsRead event,
    Emitter<MessagingState> emit,
  ) async {
    await messagingRepository.markAsRead(event.conversationId, event.userId);
  }

  Future<void> _onStartConversation(
    MessagingStartConversation event,
    Emitter<MessagingState> emit,
  ) async {
    emit(MessagingLoading());
    
    _currentUserId = event.userId;

    final result = await messagingRepository.createConversation(
      userId: event.userId,
      participantIds: event.targetUserId != null ? [event.targetUserId!] : [],
      targetRole: event.targetRole,
      targetEpa: event.targetEpa,
      targetDistrict: event.targetDistrict,
    );
    
    result.fold(
      (failure) => emit(MessagingError(failure.message)),
      (conversation) => emit(MessagingConversationCreated(conversation)),
    );
  }

  void _onConversationUpdated(
    MessagingConversationUpdated event,
    Emitter<MessagingState> emit,
  ) {
    emit(MessagingConversationsLoaded(event.conversations));
  }

  void _onMessagesUpdated(
    MessagingMessagesUpdated event,
    Emitter<MessagingState> emit,
  ) {
    if (_currentConversationId != null) {
      emit(MessagingMessagesLoaded(
        conversationId: _currentConversationId!,
        messages: event.messages,
      ));
    }
  }

  void setCurrentUserId(String userId) {
    _currentUserId = userId;
  }
}
