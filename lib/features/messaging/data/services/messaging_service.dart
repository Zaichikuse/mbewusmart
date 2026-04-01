import 'dart:async';
import 'package:dartz/dartz.dart';
import '../../../../core/error/failures.dart';
import '../../../auth/domain/entities/user.dart';
import '../../domain/entities/message.dart';
import '../../domain/entities/conversation.dart';
import '../../domain/repositories/messaging_repository.dart';
import '../../../location/domain/entities/extension_officer.dart';
import '../../../location/domain/entities/agro_dealer.dart';

class MessagingService implements MessagingRepository {
  final Map<String, List<Message>> _messages = {};
  final Map<String, Conversation> _conversations = {};
  final _messageStreamController = StreamController<List<Message>>.broadcast();
  final _conversationStreamController = StreamController<List<Conversation>>.broadcast();

  @override
  Future<Either<Failure, List<Conversation>>> getConversations(String userId) async {
    try {
      await Future.delayed(const Duration(milliseconds: 100));
      
      final conversations = _conversations.values
          .where((c) => c.participantIds.contains(userId))
          .toList();
      
      conversations.sort((a, b) {
        final aTime = a.lastMessageTimestamp ?? a.createdAt;
        final bTime = b.lastMessageTimestamp ?? b.createdAt;
        return bTime.compareTo(aTime);
      });
      
      return Right(conversations);
    } catch (e) {
      return Left(NetworkFailure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, List<Message>>> getMessages(String conversationId) async {
    try {
      await Future.delayed(const Duration(milliseconds: 100));
      
      final messages = _messages[conversationId] ?? [];
      messages.sort((a, b) => a.timestamp.compareTo(b.timestamp));
      
      return Right(messages);
    } catch (e) {
      return Left(NetworkFailure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, Message>> sendMessage(Message message) async {
    try {
      _messages.putIfAbsent(message.conversationId, () => []);
      _messages[message.conversationId]!.add(message);
      
      final conversation = _conversations[message.conversationId];
      if (conversation != null) {
        _conversations[message.conversationId] = conversation.copyWith(
          lastMessageContent: message.content,
          lastMessageTimestamp: message.timestamp,
        );
      }
      
      _messageStreamController.add(_messages[message.conversationId] ?? []);
      
      return Right(message);
    } catch (e) {
      return Left(NetworkFailure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, void>> markAsRead(String conversationId, String userId) async {
    try {
      final conversation = _conversations[conversationId];
      if (conversation != null) {
        _conversations[conversationId] = conversation.copyWith(unreadCount: 0);
        _conversationStreamController.add(_conversations.values.toList());
      }
      
      return const Right(null);
    } catch (e) {
      return Left(NetworkFailure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, Conversation>> createConversation({
    required String userId,
    required List<String> participantIds,
    required String targetRole,
    String? targetEpa,
    String? targetDistrict,
  }) async {
    try {
      final existingConversation = _conversations.values.firstWhere(
        (c) => 
            c.participantIds.contains(userId) &&
            c.participantIds.contains(participantIds.first) &&
            c.targetRole.name == targetRole,
        orElse: () => Conversation(
          id: '',
          participantIds: [],
          targetRole: UserRole.farmer,
          createdAt: DateTime.now(),
        ),
      );
      
      if (existingConversation.id.isNotEmpty) {
        return Right(existingConversation);
      }
      
      final conversation = Conversation(
        id: 'conv_${DateTime.now().millisecondsSinceEpoch}',
        participantIds: [userId, ...participantIds],
        targetRole: UserRoleExtension.fromString(targetRole),
        targetEpa: targetEpa,
        targetDistrict: targetDistrict,
        createdAt: DateTime.now(),
      );
      
      _conversations[conversation.id] = conversation;
      _conversationStreamController.add(_conversations.values.toList());
      
      return Right(conversation);
    } catch (e) {
      return Left(NetworkFailure(e.toString()));
    }
  }

  @override
  Stream<List<Message>> watchMessages(String conversationId) {
    return _messageStreamController.stream
        .where((messages) => messages.isEmpty || messages.first.conversationId == conversationId);
  }

  @override
  Stream<List<Conversation>> watchConversations(String userId) {
    return _conversationStreamController.stream
        .map((conversations) => conversations
            .where((c) => c.participantIds.contains(userId))
            .toList());
  }

  Future<Conversation?> startConversationWithOfficer({
    required String farmerId,
    required ExtensionOfficer officer,
    String? epa,
    String? district,
  }) async {
    final result = await createConversation(
      userId: farmerId,
      participantIds: [officer.id],
      targetRole: 'extensionOfficer',
      targetEpa: epa ?? officer.area,
      targetDistrict: district ?? officer.district,
    );
    
    return result.fold(
      (failure) => null,
      (conversation) => conversation,
    );
  }

  Future<Conversation?> startConversationWithDealer({
    required String farmerId,
    required AgroDealer dealer,
    String? epa,
    String? district,
  }) async {
    final result = await createConversation(
      userId: farmerId,
      participantIds: [dealer.id],
      targetRole: 'agroDealer',
      targetEpa: epa ?? dealer.area,
      targetDistrict: district ?? dealer.district,
    );
    
    return result.fold(
      (failure) => null,
      (conversation) => conversation,
    );
  }

  Future<Conversation?> startConversationWithManager({
    required String farmerId,
    String? epa,
    String? district,
  }) async {
    final result = await createConversation(
      userId: farmerId,
      participantIds: ['manager_default'],
      targetRole: 'agricultureManager',
      targetEpa: epa,
      targetDistrict: district,
    );
    
    return result.fold(
      (failure) => null,
      (conversation) => conversation,
    );
  }

  void dispose() {
    _messageStreamController.close();
    _conversationStreamController.close();
  }
}
