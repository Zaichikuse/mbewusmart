import 'package:hive/hive.dart';
import '../../../../core/di/injection_container.dart';

abstract class SettingsLocalDataSource {
  Future<String> getLanguage();
  Future<void> setLanguage(String languageCode);
  Future<bool> getNotificationsEnabled();
  Future<void> setNotificationsEnabled(bool enabled);
  Future<DateTime?> getLastSyncTime();
  Future<void> setLastSyncTime(DateTime time);
}

class SettingsLocalDataSourceImpl implements SettingsLocalDataSource {
  final Box settingsBox;

  SettingsLocalDataSourceImpl(this.settingsBox);

  @override
  Future<String> getLanguage() async {
    return settingsBox.get('language', defaultValue: 'ny');
  }

  @override
  Future<void> setLanguage(String languageCode) async {
    await settingsBox.put('language', languageCode);
  }

  @override
  Future<bool> getNotificationsEnabled() async {
    return settingsBox.get('notifications_enabled', defaultValue: true);
  }

  @override
  Future<void> setNotificationsEnabled(bool enabled) async {
    await settingsBox.put('notifications_enabled', enabled);
  }

  @override
  Future<DateTime?> getLastSyncTime() async {
    final timeString = settingsBox.get('last_sync');
    if (timeString != null) {
      return DateTime.tryParse(timeString);
    }
    return null;
  }

  @override
  Future<void> setLastSyncTime(DateTime time) async {
    await settingsBox.put('last_sync', time.toIso8601String());
  }
}