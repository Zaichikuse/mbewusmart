class AppConstants {
  AppConstants._();

  static const String appName = 'MbewuSmart';
  static const String appVersion = '1.0.0';

  // Hive box names
  static const String userBox = 'user_box';
  static const String diagnosisBox = 'diagnosis_box';
  static const String settingsBox = 'settings_box';
  static const String cacheBox = 'cache_box';
  static const String alertsBox = 'alerts_box';

  // Settings keys
  static const String languageKey = 'language';
  static const String themeKey = 'theme';
  static const String pinKey = 'pin';
  static const String lastSyncKey = 'last_sync';
  static const String userKey = 'current_user';
  static const String aiChatHistoryKey = 'ai_chat_history';
  static const String aiSupportContextKey = 'ai_support_context';

  // API / Firebase
  static const String firebaseProjectId = 'mbewusmart-app';

  // Image settings
  static const int maxImageWidth = 1024;
  static const int maxImageHeight = 1024;
  static const int imageQuality = 85;

  // Analysis settings
  static const double confidenceThreshold = 0.6;
  static const int modelInputSize = 224;

  // Validation
  static const int phoneMinLength = 8;
  static const int phoneMaxLength = 15;
  static const int nationalIdMinLength = 6;
  static const int nationalIdMaxLength = 20;
  static const int pinLength = 4;
}

class UserRoles {
  static const String farmer = 'farmer';
  static const String extensionOfficer = 'extension_officer';
  static const String agricultureManager = 'agriculture_manager';
  static const String agroDealer = 'agro_dealer';

  static List<String> get all => [
    farmer,
    extensionOfficer,
    agricultureManager,
    agroDealer,
  ];
}

class DiagnosisTypes {
  static const String healthy = 'healthy';
  static const String disease = 'disease';
  static const String pest = 'pest';
  static const String deficiency = 'deficiency';
  static const String unknown = 'unknown';
}

class SeverityLevels {
  static const String low = 'low';
  static const String medium = 'medium';
  static const String high = 'high';
}
