import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../l10n/app_localizations.dart';
import '../../../../core/utils/localization_helper.dart';
import '../../domain/entities/conversation.dart';
import '../bloc/messaging_bloc.dart';
import '../../../auth/presentation/bloc/auth_bloc.dart';
import '../../../auth/presentation/bloc/auth_state.dart' show AuthStatus;
import 'chat_page.dart';

class ConversationsPage extends StatelessWidget {
  const ConversationsPage({super.key});

  @override
  Widget build(BuildContext context) {
    final appLoc = AppLocalizations.of(context);
    final isChichewa = LocalizationHelper.isChichewa(context);

    return Scaffold(
      appBar: AppBar(title: Text(appLoc?.communicate ?? 'Communicate')),
      body: BlocConsumer<MessagingBloc, MessagingState>(
        listener: (context, state) {
          if (state is MessagingConversationCreated) {
            Navigator.of(context).push(
              MaterialPageRoute(
                builder: (_) => BlocProvider.value(
                  value: context.read<MessagingBloc>(),
                  child: ChatPage(conversation: state.conversation),
                ),
              ),
            );
          }
        },
        builder: (context, state) {
          if (state is MessagingLoading) {
            return const Center(child: CircularProgressIndicator());
          }

          if (state is MessagingError) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(
                    Icons.error_outline,
                    size: 48,
                    color: AppTheme.errorRed,
                  ),
                  const SizedBox(height: 16),
                  Text(state.message),
                  const SizedBox(height: 16),
                  ElevatedButton(
                    onPressed: () {
                      context.read<MessagingBloc>().add(
                        MessagingLoadConversations(),
                      );
                    },
                    child: Text(appLoc?.retry ?? 'Retry'),
                  ),
                ],
              ),
            );
          }

          if (state is MessagingConversationsLoaded) {
            if (state.conversations.isEmpty) {
              return _buildEmptyState(context, appLoc, isChichewa);
            }

            return RefreshIndicator(
              onRefresh: () async {
                context.read<MessagingBloc>().add(MessagingLoadConversations());
              },
              child: ListView.builder(
                itemCount: state.conversations.length,
                itemBuilder: (context, index) {
                  return _buildConversationTile(
                    context,
                    state.conversations[index],
                    isChichewa,
                  );
                },
              ),
            );
          }

          return _buildEmptyState(context, appLoc, isChichewa);
        },
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _showNewConversationDialog(context),
        backgroundColor: AppTheme.primaryGreen,
        child: const Icon(Icons.message),
      ),
    );
  }

  Widget _buildEmptyState(
    BuildContext context,
    AppLocalizations? appLoc,
    bool isChichewa,
  ) {
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
            appLoc?.startConversation ?? 'Start a conversation',
            style: AppTextStyles.bodyMedium.copyWith(color: AppTheme.textMuted),
          ),
        ],
      ),
    );
  }

  Widget _buildConversationTile(
    BuildContext context,
    Conversation conversation,
    bool isChichewa,
  ) {
    final currentUserId = _getCurrentUserId(context);
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: AppTheme.primaryGreen,
          child: Icon(
            _getRoleIcon(conversation.targetRole.name),
            color: Colors.white,
          ),
        ),
        title: Text(
          conversation.getDisplayName(
            currentUserId != null ? AuthStatus.authenticated as dynamic : null,
          ),
          style: AppTextStyles.bodyLarge.copyWith(fontWeight: FontWeight.w600),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (conversation.lastMessageContent != null)
              Text(
                conversation.lastMessageContent!,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: AppTextStyles.bodySmall.copyWith(
                  color: AppTheme.textMuted,
                ),
              ),
            if (conversation.targetEpa != null)
              Text(
                conversation.targetEpa!,
                style: AppTextStyles.caption.copyWith(
                  color: AppTheme.primaryGreen,
                ),
              ),
          ],
        ),
        trailing: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            if (conversation.lastMessageTimestamp != null)
              Text(
                _formatDate(conversation.lastMessageTimestamp!),
                style: AppTextStyles.caption,
              ),
            if (conversation.unreadCount > 0)
              Container(
                margin: const EdgeInsets.only(top: 4),
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                decoration: BoxDecoration(
                  color: AppTheme.primaryGreen,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Text(
                  conversation.unreadCount.toString(),
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
          ],
        ),
        onTap: () {
          Navigator.of(context).push(
            MaterialPageRoute(
              builder: (_) => BlocProvider.value(
                value: context.read<MessagingBloc>(),
                child: ChatPage(conversation: conversation),
              ),
            ),
          );
        },
      ),
    );
  }

  void _showNewConversationDialog(BuildContext context) {
    final appLoc = AppLocalizations.of(context);
    final isChichewa = LocalizationHelper.isChichewa(context);

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
                appLoc?.newMessage ?? 'New Message',
                style: AppTextStyles.headingMedium,
              ),
              const SizedBox(height: 16),
              ListTile(
                leading: CircleAvatar(
                  backgroundColor: AppTheme.accentOrange,
                  child: const Icon(Icons.person, color: Colors.white),
                ),
                title: Text(appLoc?.extensionOfficer ?? 'Extension Officer'),
                subtitle: Text(
                  isChichewa ? 'Afesa Officer' : 'Contact for help',
                ),
                onTap: () {
                  Navigator.pop(bottomSheetContext);
                  _startConversation(context, 'extensionOfficer');
                },
              ),
              ListTile(
                leading: CircleAvatar(
                  backgroundColor: AppTheme.primaryGreen,
                  child: const Icon(Icons.store, color: Colors.white),
                ),
                title: Text(appLoc?.agroDealer ?? 'Agro-Dealer'),
                subtitle: Text(isChichewa ? 'Agro-Dealer' : 'Buy products'),
                onTap: () {
                  Navigator.pop(bottomSheetContext);
                  _startConversation(context, 'agroDealer');
                },
              ),
              ListTile(
                leading: CircleAvatar(
                  backgroundColor: AppTheme.primaryGreenLight,
                  child: const Icon(Icons.manage_accounts, color: Colors.white),
                ),
                title: Text(
                  appLoc?.agricultureManager ?? 'Agriculture Manager',
                ),
                subtitle: Text(
                  isChichewa ? 'Manager Waulimi' : 'Report issues',
                ),
                onTap: () {
                  Navigator.pop(bottomSheetContext);
                  _startConversation(context, 'agricultureManager');
                },
              ),
            ],
          ),
        );
      },
    );
  }

  void _startConversation(BuildContext context, String targetRole) {
    final userId = _getCurrentUserId(context);
    if (userId != null) {
      context.read<MessagingBloc>().add(
        MessagingStartConversation(userId: userId, targetRole: targetRole),
      );
    }
  }

  String? _getCurrentUserId(BuildContext context) {
    try {
      final authState = context.read<AuthBloc>().state;
      if (authState.status == AuthStatus.authenticated &&
          authState.user != null) {
        return authState.user!.id;
      }
    } catch (e) {
      // Ignore
    }
    return null;
  }

  IconData _getRoleIcon(String role) {
    switch (role) {
      case 'extensionOfficer':
        return Icons.person;
      case 'agroDealer':
        return Icons.store;
      case 'agricultureManager':
        return Icons.manage_accounts;
      default:
        return Icons.person;
    }
  }

  String _formatDate(DateTime date) {
    final now = DateTime.now();
    final difference = now.difference(date);

    if (difference.inDays == 0) {
      return '${date.hour}:${date.minute.toString().padLeft(2, '0')}';
    } else if (difference.inDays == 1) {
      return 'Yesterday';
    } else if (difference.inDays < 7) {
      return '${difference.inDays}d ago';
    } else {
      return '${date.day}/${date.month}';
    }
  }
}
