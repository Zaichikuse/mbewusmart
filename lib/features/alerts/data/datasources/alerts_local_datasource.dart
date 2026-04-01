import 'package:hive/hive.dart';
import '../../domain/entities/alert.dart';

abstract class AlertsLocalDataSource {
  Future<List<Alert>> getAllAlerts();
  Future<List<Alert>> getUnreadAlerts();
  Future<Alert> saveAlert(Alert alert);
  Future<void> markAsRead(String alertId);
  Future<void> addResponse(String alertId, String response);
  Future<void> deleteAlert(String alertId);
}

class AlertsLocalDataSourceImpl implements AlertsLocalDataSource {
  final Box alertBox;

  AlertsLocalDataSourceImpl(this.alertBox);

  @override
  Future<List<Alert>> getAllAlerts() async {
    try {
      final alerts = alertBox.values
          .map((item) => Alert.fromMap(Map<String, dynamic>.from(item)))
          .toList();
      alerts.sort((a, b) => b.timestamp.compareTo(a.timestamp));
      return alerts;
    } catch (e) {
      return [];
    }
  }

  @override
  Future<List<Alert>> getUnreadAlerts() async {
    final all = await getAllAlerts();
    return all.where((alert) => !alert.isRead).toList();
  }

  @override
  Future<Alert> saveAlert(Alert alert) async {
    await alertBox.put(alert.id, alert.toMap());
    return alert;
  }

  @override
  Future<void> markAsRead(String alertId) async {
    final data = alertBox.get(alertId);
    if (data != null) {
      final alert = Alert.fromMap(Map<String, dynamic>.from(data));
      final updated = alert.copyWith(isRead: true);
      await alertBox.put(alertId, updated.toMap());
    }
  }

  @override
  Future<void> addResponse(String alertId, String response) async {
    final data = alertBox.get(alertId);
    if (data != null) {
      final alert = Alert.fromMap(Map<String, dynamic>.from(data));
      final updated = alert.copyWith(
        officerResponse: response,
        respondedAt: DateTime.now(),
      );
      await alertBox.put(alertId, updated.toMap());
    }
  }

  @override
  Future<void> deleteAlert(String alertId) async {
    await alertBox.delete(alertId);
  }
}
