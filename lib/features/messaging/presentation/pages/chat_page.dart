import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../l10n/app_localizations.dart';
import '../../../../core/utils/localization_helper.dart';
import '../../domain/entities/message.dart';
import '../../domain/entities/conversation.dart';
import '../bloc/messaging_bloc.dart';
import '../../../auth/presentation/bloc/auth_bloc.dart';
import '../../../auth/presentation/bloc/auth_state.dart' show AuthState, AuthStatus;
import '../../../auth/domain/entities/user.dart';
import '../widgets/message_bubble.dart';

class ChatPage extends StatefulWidget {
  final Conversation conversation;

  const ChatPage({
    super.key,
    required this.conversation,
  });

  @override
  _ChatPageState createState() => _ChatPageState();
}

class _ChatPageState extends State<ChatPage> {
  final TextEditingController _messageController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  String? _currentUserId;

  @override
  void initState() {
    super.initState();
    _currentUserId = _getCurrentUserId();
    _loadMessages();
  }

  @override
  void dispose() {
    _messageController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  String? _getCurrentUserId() {
    try {
      final authState = context.read<AuthBloc>().state;
      if (authState.status == AuthStatus.authenticated && authState.user != null) {
        return authState.user!.id;
      }
    } catch (e) {
      // Ignore
    }
    return null;
  }

  void _loadMessages() {
    if (_currentUserId != null) {
      context.read<MessagingBloc>().add(
        MessagingLoadMessages(widget.conversation.id),
      );
      context.read<MessagingBloc>().add(
        MessagingMarkAsRead(
          conversationId: widget.conversation.id,
          userId: _currentUserId!,
        ),
      );
    }
  }

  void _sendMessage() {
    final content = _messageController.text.trim();
    if (content.isEmpty || _currentUserId == null) return;

    final message = Message(
      id: 'msg_${DateTime.now().millisecondsSinceEpoch}',
      conversationId: widget.conversation.id,
      senderId: _currentUserId!,
      receiverId: widget.conversation.participantIds
          .firstWhere((id) => id != _currentUserId, orElse: () => ''),
      content: content,
      timestamp: DateTime.now(),
      type: MessageType.text,
      status: MessageStatus.sending,
    );

    context.read<MessagingBloc>().add(MessagingSendMessage(message));
    _messageController.clear();

    Future.delayed(const Duration(milliseconds: 300), () {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
  }

  void _sendReport(String diseaseInfo) {
    if (_currentUserId == null) return;

    final message = Message(
      id: 'msg_${DateTime.now().millisecondsSinceEpoch}',
      conversationId: widget.conversation.id,
      senderId: _currentUserId!,
      receiverId: widget.conversation.participantIds
          .firstWhere((id) => id != _currentUserId, orElse: () => ''),
      content: diseaseInfo,
      timestamp: DateTime.now(),
      type: MessageType.report,
      status: MessageStatus.sending,
    );

    context.read<MessagingBloc>().add(MessagingSendMessage(message));
  }

  @override
  Widget build(BuildContext context) {
    final appLoc = AppLocalizations.of(context);
    final isChichewa = LocalizationHelper.isChichewa(context);

    return Scaffold(
      appBar: AppBar(
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              widget.conversation.getDisplayName(UserRole.farmer),
              style: AppTextStyles.bodyLarge.copyWith(fontWeight: FontWeight.bold),
            ),
            if (widget.conversation.targetEpa != null)
              Text(
                widget.conversation.targetEpa!,
                style: AppTextStyles.caption.copyWith(color: Colors.white70),
              ),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.more_vert),
            onPressed: () {},
          ),
        ],
      ),
      body: Column(
        children: [
          Expanded(
            child: BlocBuilder<MessagingBloc, MessagingState>(
              builder: (context, state) {
                if (state is MessagingLoading) {
                  return const Center(child: CircularProgressIndicator());
                }

                if (state is MessagingMessagesLoaded &&
                    state.conversationId == widget.conversation.id) {
                  if (state.messages.isEmpty) {
                    return _buildEmptyChat(isChichewa, appLoc);
                  }

                  return ListView.builder(
                    controller: _scrollController,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    itemCount: state.messages.length,
                    itemBuilder: (context, index) {
                      final message = state.messages[index];
                      final isMe = message.senderId == _currentUserId;
                      return MessageBubble(
                        message: message,
                        isMe: isMe,
                        onTap: () {},
                      );
                    },
                  );
                }

                return _buildEmptyChat(isChichewa, appLoc);
              },
            ),
          ),
          _buildMessageInput(isChichewa, appLoc),
        ],
      ),
    );
  }

  Widget _buildEmptyChat(bool isChichewa, AppLocalizations? appLoc) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.chat_bubble_outline,
            size: 80,
            color: AppTheme.primaryGreen.withValues(alpha: 0.5),
          ),
          const SizedBox(height: 16),
          Text(
            appLoc?.noMessages ?? 'No messages yet',
            style: AppTextStyles.headingMedium,
          ),
          const SizedBox(height: 8),
          Text(
            appLoc?.startConversation ?? 'Start the conversation',
            style: AppTextStyles.bodyMedium.copyWith(color: AppTheme.textMuted),
          ),
        ],
      ),
    );
  }

  Widget _buildMessageInput(bool isChichewa, AppLocalizations? appLoc) {
    return Container(
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 10,
            offset: const Offset(0, -2),
          ),
        ],
      ),
      child: SafeArea(
        child: Row(
          children: [
            IconButton(
              icon: const Icon(Icons.attach_file),
              onPressed: () {
                _showAttachmentOptions(isChichewa, appLoc);
              },
              color: AppTheme.primaryGreen,
            ),
            Expanded(
              child: TextField(
                controller: _messageController,
                decoration: InputDecoration(
                  hintText: appLoc?.typeMessage ?? 'Type a message...',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(24),
                    borderSide: BorderSide.none,
                  ),
                  filled: true,
                  fillColor: Colors.grey[100],
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 8,
                  ),
                ),
                maxLines: null,
                textCapitalization: TextCapitalization.sentences,
                onSubmitted: (_) => _sendMessage(),
              ),
            ),
            const SizedBox(width: 8),
            CircleAvatar(
              backgroundColor: AppTheme.primaryGreen,
              child: IconButton(
                icon: const Icon(Icons.send, color: Colors.white),
                onPressed: _sendMessage,
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showAttachmentOptions(bool isChichewa, AppLocalizations? appLoc) {
    showModalBottomSheet(
      context: context,
      builder: (bottomSheetContext) {
        return Container(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                appLoc?.sendReport ?? 'Send Report',
                style: AppTextStyles.headingMedium,
              ),
              const SizedBox(height: 16),
              ListTile(
                leading: const Icon(Icons.warning_amber, color: AppTheme.warningAmber),
                title: Text(appLoc?.reportDisease ?? 'Report Disease'),
                subtitle: Text(isChichewa ? 'Tumiza report ya matenda' : 'Send disease report'),
                onTap: () {
                  Navigator.pop(bottomSheetContext);
                  _sendReport('Disease report from crop scan');
                },
              ),
              ListTile(
                leading: const Icon(Icons.image, color: AppTheme.primaryGreen),
                title: Text(appLoc?.uploadPhoto ?? 'Upload Photo'),
                subtitle: Text(isChichewa ? 'Lemba chithunzi' : 'Upload crop image'),
                onTap: () {
                  Navigator.pop(bottomSheetContext);
                },
              ),
            ],
          ),
        );
      },
    );
  }
}
