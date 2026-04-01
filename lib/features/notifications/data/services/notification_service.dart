import 'dart:async';
import '../../domain/entities/notification.dart';

class NotificationService {
  static NotificationService? _instance;
  static NotificationService get instance => _instance ??= NotificationService._();

  NotificationService._();

  final List<AppNotification> _notifications = [];
  final _notificationController = StreamController<AppNotification>.broadcast();

  Stream<AppNotification> get notificationStream => _notificationController.stream;
  List<AppNotification> get notifications => List.unmodifiable(_notifications);

  void addNotification(AppNotification notification) {
    _notifications.insert(0, notification);
    _notificationController.add(notification);
  }

  Future<void> notifyDiseaseDetected({
    required String farmerId,
    required String farmerName,
    required String epa,
    required String district,
    required String diagnosis,
    required double confidence,
    String? imagePath,
  }) async {
    final notification = AppNotification(
      id: 'notif_${DateTime.now().millisecondsSinceEpoch}',
      title: 'New disease reported',
      body: 'Disease detected in $epa: $diagnosis (${(confidence * 100).toStringAsFixed(0)}% confidence)',
      type: NotificationType.diseaseAlert,
      senderId: farmerId,
      senderName: farmerName,
      epa: epa,
      district: district,
      timestamp: DateTime.now(),
      metadata: {
        'diagnosis': diagnosis,
        'confidence': confidence,
        'imagePath': imagePath,
        'farmerId': farmerId,
        'farmerName': farmerName,
      },
    );

    addNotification(notification);
  }

  Future<void> notifyEpaUsers({
    required String epa,
    required String district,
    required String diagnosis,
    required String farmerId,
    required String farmerName,
    String? imagePath,
  }) async {
    final notification = AppNotification(
      id: 'notif_${DateTime.now().millisecondsSinceEpoch}',
      title: 'New disease reported in $epa',
      body: '$farmerName reported: $diagnosis',
      type: NotificationType.diseaseAlert,
      senderId: farmerId,
      senderName: farmerName,
      epa: epa,
      district: district,
      timestamp: DateTime.now(),
      metadata: {
        'diagnosis': diagnosis,
        'imagePath': imagePath,
        'farmerId': farmerId,
        'farmerName': farmerName,
        'target': 'epa_users',
      },
    );

    addNotification(notification);
  }

  void notifyMessageReceived({
    required String senderId,
    required String senderName,
    required String conversationId,
    required String messagePreview,
  }) {
    final notification = AppNotification(
      id: 'notif_${DateTime.now().millisecondsSinceEpoch}',
      title: 'New message from $senderName',
      body: messagePreview,
      type: NotificationType.messageReceived,
      senderId: senderId,
      senderName: senderName,
      timestamp: DateTime.now(),
      metadata: {
        'conversationId': conversationId,
        'type': 'message',
      },
    );

    addNotification(notification);
  }

  void notifyReportUpdate({
    required String reportId,
    required String reportName,
    required String status,
    String? officerResponse,
  }) {
    final notification = AppNotification(
      id: 'notif_${DateTime.now().millisecondsSinceEpoch}',
      title: 'Report update: $reportName',
      body: officerResponse ?? 'Status changed to: $status',
      type: NotificationType.reportUpdate,
      timestamp: DateTime.now(),
      metadata: {
        'reportId': reportId,
        'status': status,
        'officerResponse': officerResponse,
      },
    );

    addNotification(notification);
  }

  void markAsRead(String notificationId) {
    final index = _notifications.indexWhere((n) => n.id == notificationId);
    if (index != -1) {
      _notifications[index] = _notifications[index].copyWith(isRead: true);
    }
  }

  void markAllAsRead() {
    for (int i = 0; i < _notifications.length; i++) {
      if (!_notifications[i].isRead) {
        _notifications[i] = _notifications[i].copyWith(isRead: true);
      }
    }
  }

  void clearAll() {
    _notifications.clear();
  }

  void deleteNotification(String notificationId) {
    _notifications.removeWhere((n) => n.id == notificationId);
  }

  int get unreadCount => _notifications.where((n) => !n.isRead).length;

  List<AppNotification> getUnreadNotifications() {
    return _notifications.where((n) => !n.isRead).toList();
  }

  List<AppNotification> getNotificationsByType(NotificationType type) {
    return _notifications.where((n) => n.type == type).toList();
  }

  List<AppNotification> getNotificationsByEpa(String epa) {
    return _notifications.where((n) => n.epa == epa).toList();
  }

  List<AppNotification> getNotificationsByDistrict(String district) {
    return _notifications.where((n) => n.district == district).toList();
  }

  void dispose() {
    _notificationController.close();
  }
}
