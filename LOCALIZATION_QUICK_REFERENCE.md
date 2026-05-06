# Quick Reference: MbewuSmart Localization API

## 🚀 Quick Start

```dart
// Get localization strings
final appLoc = AppLocalizations.of(context)!;
Text(appLoc.home)

// Get greeting (time-aware)
Text(LocalizationHelper.getGreeting(context))

// Check current language
if (LocalizationHelper.isChichewa(context)) { ... }

// Change language (triggers app-wide update)
context.read<SettingsBloc>().add(
  SettingsLanguageChanged('en')
);
```

---

## 📖 Complete API Reference

### `AppLocalizations`
Get Flutter's localization system instance.

```dart
// Get instance (throws if not found)
final appLoc = AppLocalizations.of(context)!;

// Access any key
Text(appLoc.home)        // → "Home" or "Mphamvu"
Text(appLoc.greetingMorning)  // → "Good morning" or "Mwadzuka bwanji"

// Generic key access
String value = appLoc.translate('any_key');
```

**Available Properties:** `home`, `scan`, `history`, `settings`, `profile`, `logout`, `welcome`, `goodMorning`, `goodAfternoon`, `goodEvening`, `scanCrop`, `diseased`, `healthy`, `confidence`, `recommendation`, `language`, `english`, `chichewa`, and 100+ more...

---

### `LocalizationHelper`

#### Check Language
```dart
// Check if Chichewa
if (LocalizationHelper.isChichewa(context)) { ... }

// Check if English  
if (LocalizationHelper.isEnglish(context)) { ... }

// Get language code
String code = LocalizationHelper.readLanguageCode(context); // 'en' or 'ny'

// Watch for changes (triggers rebuild)
String code = LocalizationHelper.watchLanguageCode(context);
```

#### Get Localized Values
```dart
// Get time-based greeting
String greeting = LocalizationHelper.getGreeting(context);
// Morning: "Good morning" or "Mwadzuka bwanji"
// Afternoon: "Good afternoon" or "Mwaswera bwanji"
// Evening: "Good evening" or "Mwaswera bwanji"

// Localize roles
String role = LocalizationHelper.getLocalizedRoleName(context, 'farmer');
// → "Farmer" or "Mlimi"

// Localize severity
String sev = LocalizationHelper.getLocalizedSeverity(context, 'high');
// → "High" or "Yakulu"

// Localize diagnosis types
String type = LocalizationHelper.getLocalizedDiagnosisType(context, 'disease');
// → "Disease" or "Matenda"
```

#### Get Current Locale
```dart
// Get as Locale object
Locale locale = LocalizationHelper.getCurrentLocale(context);
// → Locale('ny', 'MW') or Locale('en')

// Get from Material system
Locale locale = LocalizationHelper.getLocaleFromContext(context);
```

---

### `SettingsBloc` Events

```dart
// Change language (MAIN WAY to switch language)
context.read<SettingsBloc>().add(SettingsLanguageChanged('ny'));
// or
context.read<SettingsBloc>().add(SettingsLanguageChanged('en'));

// Toggle notifications
context.read<SettingsBloc>().add(SettingsNotificationsToggled(true));

// Load settings on app start
context.read<SettingsBloc>().add(SettingsLoadRequested());
```

---

### `SettingsBloc` State

```dart
// Check if loaded
if (state is SettingsLoaded) {
  String langCode = state.languageCode;      // 'en' or 'ny'
  bool notifEnabled = state.notificationsEnabled;
  DateTime? lastSync = state.lastSyncTime;
}

// Watch in BlocBuilder
BlocBuilder<SettingsBloc, SettingsState>(
  builder: (context, state) {
    if (state is SettingsLoaded) {
      // Current language: state.languageCode
    }
  },
)

// Read in event handlers
var state = context.read<SettingsBloc>().state;
if (state is SettingsLoaded) {
  // ...
}
```

---

## 🎯 Common Patterns

### Pattern 1: Simple Localization
```dart
Widget build(BuildContext context) {
  final appLoc = AppLocalizations.of(context)!;
  return Text(appLoc.home);
}
```

### Pattern 2: Conditional Text
```dart
Text(
  LocalizationHelper.isChichewa(context) 
    ? 'Chichewa Text' 
    : 'English Text'
)
```

### Pattern 3: Language-Aware Lists
```dart
List<String> options = [
  AppLocalizations.of(context)!.english,
  AppLocalizations.of(context)!.chichewa,
];
```

### Pattern 4: Dynamic Greeting
```dart
Text(LocalizationHelper.getGreeting(context))
// Changes with time AND language
```

### Pattern 5: Enum Localization
```dart
// Localize database values
String displayText = LocalizationHelper.getLocalizedSeverity(
  context,
  resultFromDatabase.severity  // 'high', 'medium', 'low'
);
```

### Pattern 6: Change Language
```dart
// In Settings, Drawer, Language Menu, etc.
context.read<SettingsBloc>().add(
  SettingsLanguageChanged(_selectedLanguage)
);
// → Entire app rebuilds with new language
// → All screens update instantly
// → Language persists to device storage
```

### Pattern 7: Language-Responsive Layout
```dart
final isChichewa = LocalizationHelper.isChichewa(context);

return Padding(
  padding: EdgeInsets.only(
    left: isChichewa ? 16 : 24,   // Example
    right: isChichewa ? 24 : 16,
  ),
  child: Text(AppLocalizations.of(context)!.home),
);
```

---

## 🔧 Troubleshooting

### "AppLocalizations not found in context"
**Problem:** Using AppLocalizations before app loads
**Solution:** Check MaterialApp has localizationsDelegates

```dart
MaterialApp(
  localizationsDelegates: const [
    AppLocalizations.delegate,
  ],
)
```

### Language doesn't change in other screens
**Problem:** Screen doesn't rebuild on language change
**Solution:** Make sure it's under the BlocBuilder or use context.watch()

```dart
// DON'T do this alone:
final appLoc = AppLocalizations.of(context)!;

// DO: Ensure parent rebuilds
BlocBuilder<SettingsBloc, SettingsState>(
  builder: (context, state) {
    final appLoc = AppLocalizations.of(context)!;
    // Now safe to use
  },
)
```

### Greeting doesn't update with time
**Problem:** Greeting cached from first build
**Solution:** Use LocalizationHelper.getGreeting() which calculates on each build

```dart
// WRONG - static greeting
String greeting = "Good morning";

// CORRECT - dynamic greeting
String greeting = LocalizationHelper.getGreeting(context);
```

### Language reverts after restart
**Problem:** SettingsBloc not loading saved preference
**Solution:** Call SettingsLoadRequested() on app startup

```dart
// main.dart
_settingsBloc = di.sl<SettingsBloc>()
  ..add(settings_events.SettingsLoadRequested());
```

---

## 📊 Flow Diagram

```
User selects language in Settings
        ↓
SettingsBloc.add(SettingsLanguageChanged('ny'))
        ↓
SettingsBloc saves to Hive
        ↓
SettingsBloc emits SettingsLoaded(languageCode: 'ny')
        ↓
BlocBuilder in main.dart detects change
        ↓
MaterialApp rebuilds with new locale
        ↓
All pages get new AppLocalizations instance
        ↓
All Text widgets display new language
        ↓
🎉 Entire app is now Chichewa
```

---

## ✅ Checklist: Adding Localization to New Screen

- [ ] Import `AppLocalizations` and `LocalizationHelper`
- [ ] Get `appLoc = AppLocalizations.of(context)!`
- [ ] Replace hardcoded strings with `appLoc.keyName`
- [ ] Use dynamic greetings: `LocalizationHelper.getGreeting(context)`
- [ ] Wrap enums: `LocalizationHelper.getLocalizedSeverity(context, value)`
- [ ] Test language switch in Settings
- [ ] Verify screen rebuilds with new language
- [ ] Check for any hardcoded strings
- [ ] Add any new keys to `app_en.arb` and `app_ny.arb`

---

## 🚨 DO NOT

❌ Hardcode strings
❌ Store language in local variables
❌ Use different approaches for each screen
❌ Forget about localization in new features
❌ Mix Chichewa and English in same string
❌ Skip adding keys to .arb files

---

## ✅ DO

✅ Use `AppLocalizations.of(context)!`
✅ Change language via `SettingsBloc.add(SettingsLanguageChanged(...))`
✅ Use `LocalizationHelper` for dynamic content
✅ Test all screens after language change
✅ Keep strings in `.arb` files
✅ Document non-obvious localizations

---

## 📞 Need More Help?

- **Full Guide:** [LOCALIZATION_FIX_GUIDE.md](./LOCALIZATION_FIX_GUIDE.md)
- **Screen Examples:** [LOCALIZATION_SCREEN_EXAMPLES.md](./LOCALIZATION_SCREEN_EXAMPLES.md)
- **Flutter i18n Docs:** https://docs.flutter.dev/development/accessibility-and-localization/internationalization
- **BLoC Pattern:** https://bloclibrary.dev/

---

## 🎓 Learning Path

1. **Start with:** Pattern 1 (Simple Localization)
2. **Then learn:** Patterns 2-5 (Conditional & Dynamic)
3. **Master:** Pattern 6 (Language Change)
4. **Apply:** Pattern 7 (Layout Adaptation)
5. **Reference:** API Reference & Troubleshooting

---

## Version

- **Updated:** 2026-05-06
- **Status:** ✅ Production Ready
- **Tested:** ✅ All platforms
