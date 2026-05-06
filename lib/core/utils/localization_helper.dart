import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../l10n/app_localizations.dart';
import '../../features/settings/presentation/bloc/settings_bloc.dart';

class LocalizationHelper {
  /// Get AppLocalizations from context (uses Material's LocalizationsDelegate system)
  static AppLocalizations getAppLocalizations(BuildContext context) {
    final appLoc = AppLocalizations.of(context);
    if (appLoc == null) {
      throw Exception(
        'AppLocalizations not found in context. '
        'Make sure LocalizationsDelegates are properly configured.',
      );
    }
    return appLoc;
  }

  /// Watch language code from SettingsBloc (rebuilds on language change)
  static String watchLanguageCode(BuildContext context) {
    final settingsState = context.watch<SettingsBloc>().state;
    return settingsState is SettingsLoaded ? settingsState.languageCode : 'ny';
  }

  /// Read language code without rebuilding
  static String readLanguageCode(BuildContext context) {
    try {
      final settingsState = context.read<SettingsBloc>().state;
      return settingsState is SettingsLoaded
          ? settingsState.languageCode
          : 'ny';
    } catch (e) {
      return 'ny';
    }
  }

  static bool isChichewa(BuildContext context) {
    // IMPORTANT: depend on Localizations so widgets rebuild when locale changes,
    // even if they don't watch SettingsBloc directly.
    return Localizations.localeOf(context).languageCode == 'ny';
  }

  static bool isEnglish(BuildContext context) {
    return !isChichewa(context);
  }

  static Locale getCurrentLocale(BuildContext context) {
    final locale = Localizations.localeOf(context);
    return locale.languageCode == 'ny' ? const Locale('ny', 'MW') : const Locale('en');
  }

  /// Get current locale from Material context (most reliable)
  static Locale getLocaleFromContext(BuildContext context) {
    return Localizations.localeOf(context);
  }

  static String translate(BuildContext context, String key) {
    try {
      final appLoc = AppLocalizations.of(context);
      return appLoc?.translate(key) ?? key;
    } catch (e) {
      return key;
    }
  }

  /// Get time-based greeting that updates with language changes
  static String getGreeting(BuildContext context) {
    final appLoc = getAppLocalizations(context);
    final hour = DateTime.now().hour;

    if (hour < 12) {
      return appLoc.greetingMorning;
    } else if (hour < 17) {
      return appLoc.greetingAfternoon;
    } else {
      return appLoc.greetingEvening;
    }
  }

  static String getLocalizedRoleName(BuildContext context, String role) {
    final appLoc = getAppLocalizations(context);

    switch (role.toLowerCase()) {
      case 'farmer':
        return appLoc.farmer;
      case 'extensionofficer':
      case 'extension_officer':
        return appLoc.extensionOfficer;
      case 'agriculturemanager':
      case 'agriculture_manager':
        return appLoc.agricultureManager;
      case 'agrodealer':
      case 'agro_dealer':
        return appLoc.agroDealer;
      default:
        return role;
    }
  }

  static String getLocalizedSeverity(BuildContext context, String severity) {
    final appLoc = getAppLocalizations(context);

    switch (severity.toLowerCase()) {
      case 'low':
        return appLoc.low;
      case 'medium':
        return appLoc.medium;
      case 'high':
        return appLoc.high;
      default:
        return severity;
    }
  }

  static String getLocalizedDiagnosisType(BuildContext context, String type) {
    final appLoc = getAppLocalizations(context);

    switch (type.toLowerCase()) {
      case 'disease':
        return appLoc.disease;
      case 'pest':
        return appLoc.pest;
      case 'deficiency':
        return appLoc.deficiency;
      case 'healthy':
        return appLoc.healthy;
      default:
        return type;
    }
  }
}
