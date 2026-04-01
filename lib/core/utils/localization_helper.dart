import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../l10n/app_localizations.dart';
import '../../features/settings/presentation/bloc/settings_bloc.dart';

class LocalizationHelper {
  static AppLocalizations? getAppLocalizations(BuildContext context) {
    return AppLocalizations.of(context);
  }

  static bool isChichewa(BuildContext context) {
    try {
      final settingsState = context.read<SettingsBloc>().state;
      return settingsState is SettingsLoaded 
          ? settingsState.languageCode == 'ny' 
          : true;
    } catch (e) {
      return true;
    }
  }

  static bool isEnglish(BuildContext context) {
    return !isChichewa(context);
  }

  static Locale getCurrentLocale(BuildContext context) {
    try {
      final settingsState = context.read<SettingsBloc>().state;
      if (settingsState is SettingsLoaded) {
        final code = settingsState.languageCode;
        return code == 'ny' ? const Locale('ny', 'MW') : const Locale('en');
      }
    } catch (e) {
      // Fall through to default
    }
    return const Locale('ny', 'MW');
  }

  static String translate(BuildContext context, String key) {
    try {
      final appLoc = AppLocalizations.of(context);
      return appLoc?.translate(key) ?? key;
    } catch (e) {
      return key;
    }
  }

  static String getGreeting(BuildContext context) {
    final appLoc = getAppLocalizations(context);
    if (appLoc == null) return 'Moni';

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
    if (appLoc == null) return role;

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
    if (appLoc == null) return severity;

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
    if (appLoc == null) return type;

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
