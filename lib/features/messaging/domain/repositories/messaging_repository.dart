import 'package:dartz/dartz.dart';
import '../../../../core/error/failures.dart';
import '../entities/message.dart';
import '../entities/conversation.dart';

abstract class MessagingRepository {
  Future<Either<Failure, List<Conversation>>> getConversations(String userId);
  
  Future<Either<Failure, List<Message>>> getMessages(String conversationId);
  
  Future<Either<Failure, Message>> sendMessage(Message message);
  
  Future<Either<Failure, void>> markAsRead(String conversationId, String userId);
  
  Future<Either<Failure, Conversation>> createConversation({
    required String userId,
    required List<String> participantIds,
    required String targetRole,
    String? targetEpa,
    String? targetDistrict,
  });

  Stream<List<Message>> watchMessages(String conversationId);
  
  Stream<List<Conversation>> watchConversations(String userId);
}
