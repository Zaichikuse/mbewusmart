import 'package:flutter/material.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../l10n/app_localizations.dart';
import '../../../../core/utils/localization_helper.dart';
import '../../data/services/notification_service.dart';
import '../../domain/entities/notification.dart';

class NotificationsPage extends StatefulWidget {
  const NotificationsPage({super.key});

  @override
  _NotificationsPageState createState() => _NotificationsPageState();
}

class _NotificationsPageState extends State<NotificationsPage> {
  final NotificationService _notificationService = NotificationService.instance;
  List<AppNotification> _notifications = [];

  @override
  void initState() {
    super.initState();
    _loadNotifications();
  }

  void _loadNotifications() {
    setState(() {
      _notifications = _notificationService.notifications;
    });
  }

  @override
  Widget build(BuildContext context) {
    final appLoc = AppLocalizations.of(context);
    final isChichewa = LocalizationHelper.isChichewa(context);

    return Scaffold(
      appBar: AppBar(
        title: Text(appLoc?.notificationsTitle ?? 'Notifications'),
        actions: [
          if (_notifications.isNotEmpty)
            TextButton(
              onPressed: () {
                _notificationService.markAllAsRead();
                _loadNotifications();
              },
              child: Text(
                isChichewa ? 'Sungani ngati adawoneka' : 'Mark all read',
                style: const TextStyle(color: Colors.white),
              ),
            ),
          if (_notifications.isNotEmpty)
            IconButton(
              icon: const Icon(Icons.delete_sweep),
              onPressed: () {
                _showClearAllDialog(context, isChichewa, appLoc);
              },
            ),
        ],
      ),
      body: _notifications.isEmpty
          ? _buildEmptyState(isChichewa, appLoc)
          : _buildNotificationList(),
    );
  }

  Widget _buildEmptyState(bool isChichewa, AppLocalizations? appLoc) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.notifications_none,
            size: 80,
            color: AppTheme.primaryGreen.withValues(alpha: 0.5),
          ),
          const SizedBox(height: 16),
          Text(
            appLoc?.noNotifications ?? 'No notifications',
            style: AppTextStyles.headingMedium,
          ),
          const SizedBox(height: 8),
          Text(
            isChichewa
                ? 'Mauthenga adzawonekera apa'
                : 'Notifications will appear here',
            style: AppTextStyles.bodyMedium.copyWith(color: AppTheme.textMuted),
          ),
        ],
      ),
    );
  }

  Widget _buildNotificationList() {
    return ListView.builder(
      itemCount: _notifications.length,
      itemBuilder: (context, index) {
        return _buildNotificationTile(_notifications[index]);
      },
    );
  }

  Widget _buildNotificationTile(AppNotification notification) {
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      color: notification.isRead ? Colors.white : Colors.blue[50],
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: _getNotificationColor(notification.type),
          child: Icon(
            _getNotificationIcon(notification.type),
            color: Colors.white,
            size: 20,
          ),
        ),
        title: Text(
          notification.title,
          style: AppTextStyles.bodyLarge.copyWith(
            fontWeight: notification.isRead
                ? FontWeight.normal
                : FontWeight.bold,
          ),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              notification.body,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
            const SizedBox(height: 4),
            Row(
              children: [
                Icon(Icons.access_time, size: 12, color: AppTheme.textMuted),
                const SizedBox(width: 4),
                Text(
                  _formatTime(notification.timestamp),
                  style: AppTextStyles.caption,
                ),
                if (notification.epa != null) ...[
                  const SizedBox(width: 8),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 6,
                      vertical: 2,
                    ),
                    decoration: BoxDecoration(
                      color: AppTheme.primaryGreen.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: Text(
                      notification.epa!,
                      style: AppTextStyles.caption.copyWith(
                        color: AppTheme.primaryGreen,
                        fontSize: 10,
                      ),
                    ),
                  ),
                ],
              ],
            ),
          ],
        ),
        trailing: notification.isRead
            ? null
            : Container(
                width: 8,
                height: 8,
                decoration: const BoxDecoration(
                  color: AppTheme.primaryGreen,
                  shape: BoxShape.circle,
                ),
              ),
        onTap: () {
          _notificationService.markAsRead(notification.id);
          _loadNotifications();
          _handleNotificationTap(notification);
        },
        onLongPress: () {
          _showNotificationOptions(notification);
        },
      ),
    );
  }

  void _handleNotificationTap(AppNotification notification) {
    if (notification.type == NotificationType.diseaseAlert) {
      // Navigate to disease details
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            LocalizationHelper.isChichewa(context)
                ? 'Kuwona zambiri za matenda...'
                : 'Viewing disease details...',
          ),
        ),
      );
    } else if (notification.type == NotificationType.messageReceived) {
      // Navigate to conversation
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            LocalizationHelper.isChichewa(context)
                ? 'Kukugwira kanembo...'
                : 'Opening conversation...',
          ),
        ),
      );
    }
  }

  void _showNotificationOptions(AppNotification notification) {
    showModalBottomSheet(
      context: context,
      builder: (bottomSheetContext) {
        return Container(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ListTile(
                leading: const Icon(Icons.check_circle),
                title: Text(
                  LocalizationHelper.isChichewa(context)
                      ? 'Sungani ngati adawoneka'
                      : 'Mark as read',
                ),
                onTap: () {
                  Navigator.pop(bottomSheetContext);
                  _notificationService.markAsRead(notification.id);
                  _loadNotifications();
                },
              ),
              ListTile(
                leading: const Icon(Icons.delete, color: AppTheme.errorRed),
                title: Text(
                  LocalizationHelper.isChichewa(context) ? 'Fatsa' : 'Delete',
                ),
                onTap: () {
                  Navigator.pop(bottomSheetContext);
                  _notificationService.deleteNotification(notification.id);
                  _loadNotifications();
                },
              ),
            ],
          ),
        );
      },
    );
  }

  void _showClearAllDialog(
    BuildContext context,
    bool isChichewa,
    AppLocalizations? appLoc,
  ) {
    showDialog(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          title: Text(isChichewa ? 'Kufafaniza Zonse?' : 'Clear All?'),
          content: Text(
            isChichewa
                ? 'Kodi mukufuna kufafaniza mauthenga onse?'
                : 'Are you sure you want to clear all notifications?',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogContext),
              child: Text(isChichewa ? 'Ayi' : 'Cancel'),
            ),
            ElevatedButton(
              onPressed: () {
                Navigator.pop(dialogContext);
                _notificationService.clearAll();
                _loadNotifications();
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: AppTheme.errorRed,
              ),
              child: Text(isChichewa ? 'Fafaniza' : 'Clear'),
            ),
          ],
        );
      },
    );
  }

  Color _getNotificationColor(NotificationType type) {
    switch (type) {
      case NotificationType.diseaseAlert:
        return AppTheme.diseaseRed;
      case NotificationType.messageReceived:
        return AppTheme.primaryGreen;
      case NotificationType.reportUpdate:
        return AppTheme.warningAmber;
      case NotificationType.systemAlert:
        return AppTheme.accentOrange;
      case NotificationType.locationAlert:
        return Colors.blue;
    }
  }

  IconData _getNotificationIcon(NotificationType type) {
    switch (type) {
      case NotificationType.diseaseAlert:
        return Icons.warning_amber;
      case NotificationType.messageReceived:
        return Icons.message;
      case NotificationType.reportUpdate:
        return Icons.update;
      case NotificationType.systemAlert:
        return Icons.info;
      case NotificationType.locationAlert:
        return Icons.location_on;
    }
  }

  String _formatTime(DateTime time) {
    final now = DateTime.now();
    final difference = now.difference(time);

    if (difference.inMinutes < 1) {
      return 'Just now';
    } else if (difference.inHours < 1) {
      return '${difference.inMinutes}m ago';
    } else if (difference.inDays < 1) {
      return '${difference.inHours}h ago';
    } else if (difference.inDays == 1) {
      return 'Yesterday';
    } else if (difference.inDays < 7) {
      return '${difference.inDays}d ago';
    } else {
      return '${time.day}/${time.month}/${time.year}';
    }
  }
}
