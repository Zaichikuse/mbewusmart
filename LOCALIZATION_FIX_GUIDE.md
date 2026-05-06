# MbewuSmart Localization Bug Fix - Complete Guide

## 🔴 PROBLEM FIXED

### What Was Wrong
The app's language switching only worked on the welcome/login page before authentication. After login, changing language in Settings only updated the Settings page, not the rest of the app.

**Root Cause**: In `lib/main.dart`, the MaterialApp's locale was **hardcoded to English**:
```dart
final locale = const Locale('en'); // always use English for Flutter system
```

This meant:
1. SettingsBloc state changes were emitted
2. Settings page would rebuild (because it watched SettingsBloc)
3. But the entire app's MaterialApp didn't rebuild with the new locale
4. AppLocalizations.of(context) would still get the old locale
5. Other pages wouldn't rebuild at all

## ✅ SOLUTION IMPLEMENTED

### 1. **main.dart - Dynamic Locale Binding** 
Fixed the hardcoded locale by using SettingsBloc state:

```dart
BlocBuilder<SettingsBloc, SettingsState>(
  builder: (context, settingsState) {
    // Dynamically set locale based on SettingsBloc state
    Locale locale;
    if (settingsState is SettingsLoaded) {
      if (settingsState.languageCode == 'ny') {
        locale = const Locale('ny', 'MW');
      } else {
        locale = const Locale('en');
      }
    } else {
      locale = const Locale('ny', 'MW');
    }

    return MaterialApp.router(
      // ...
      locale: locale,  // ✅ NOW DYNAMIC!
      supportedLocales: const [
        Locale('en'),
        Locale('ny', 'MW'),
      ],
      localizationsDelegates: const [
        AppLocalizations.delegate,
      ],
      // ...
    );
  },
)
```

**Key Changes:**
- Locale now follows `settingsState.languageCode`
- When language changes → BlocBuilder rebuilds → MaterialApp rebuilds → entire app gets new locale
- Added proper `localizationsDelegates` and `supportedLocales`

### 2. **SettingsBloc - Improved Error Handling**
Enhanced the bloc to handle errors gracefully:

```dart
Future<void> _onLanguageChanged(
  SettingsLanguageChanged event,
  Emitter<SettingsState> emit,
) async {
  if (state is SettingsLoaded) {
    final currentState = state as SettingsLoaded;
    try {
      // Save to repository first
      await settingsRepository.setLanguage(event.languageCode);
      // Then emit new state (triggers BlocBuilder in main.dart)
      emit(currentState.copyWith(languageCode: event.languageCode));
    } catch (e) {
      emit(SettingsError('Failed to change language: $e'));
      // Revert to previous state on error
      emit(currentState);
    }
  }
}
```

### 3. **LocalizationHelper - App-Wide Access**
Improved the helper with better context usage:

```dart
// Get AppLocalizations (guaranteed to work after app loads)
static AppLocalizations getAppLocalizations(BuildContext context) {
  final appLoc = AppLocalizations.of(context);
  if (appLoc == null) {
    throw Exception('AppLocalizations not found');
  }
  return appLoc;
}

// Watch language changes (rebuilds on change)
static String watchLanguageCode(BuildContext context) {
  final settingsState = context.watch<SettingsBloc>().state;
  return settingsState is SettingsLoaded 
      ? settingsState.languageCode 
      : 'ny';
}

// Get current locale from Material system
static Locale getLocaleFromContext(BuildContext context) {
  return Localizations.localeOf(context);
}

// Get greeting that updates with language
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
```

### 4. **Welcome Page - Seamless Integration**
Cleaner welcome page that properly updates language:

```dart
void _continueToLogin() {
  // Update SettingsBloc with selected language
  // This triggers BlocBuilder in main.dart → entire app rebuilds
  context.read<SettingsBloc>().add(
    SettingsLanguageChanged(_selectedLanguage)
  );
  
  // Navigate to login
  context.go(AppRoutes.login);
}
```

---

## 🚀 HOW TO USE LOCALIZATION IN YOUR SCREENS

### **Pattern 1: Simple Static Text**
```dart
class MyScreen extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final appLoc = AppLocalizations.of(context)!;
    
    return Scaffold(
      appBar: AppBar(title: Text(appLoc.home)),
      body: Text(appLoc.welcome),
    );
  }
}
```

### **Pattern 2: Dynamic Text That Updates on Language Change**
```dart
class GreetingWidget extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    // Use LocalizationHelper to get language-aware greeting
    final greeting = LocalizationHelper.getGreeting(context);
    
    return Text(greeting);
  }
}
```

### **Pattern 3: Watch Language Changes (Full Widget Rebuild)**
```dart
class DashboardPage extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    // Watch language code to rebuild when it changes
    final languageCode = LocalizationHelper.watchLanguageCode(context);
    
    return Scaffold(
      appBar: AppBar(
        title: Text(
          languageCode == 'ny' ? 'Mphamvu' : 'Home'
        ),
      ),
      body: _buildContent(context),
    );
  }
  
  Widget _buildContent(BuildContext context) {
    final appLoc = AppLocalizations.of(context)!;
    
    return ListView(
      children: [
        Text(appLoc.greetingMorning),
        Text(appLoc.recentScans),
        // ... more content
      ],
    );
  }
}
```

### **Pattern 4: Handle Language-Specific Layouts**
```dart
class SettingsPage extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final isChichewa = LocalizationHelper.isChichewa(context);
    
    return Scaffold(
      appBar: AppBar(
        title: Text(
          isChichewa ? 'Zochitika' : 'Settings'
        ),
      ),
      body: ListView(
        children: [
          // Localized text flows naturally without extra params
          Text(AppLocalizations.of(context)!.language),
        ],
      ),
    );
  }
}
```

### **Pattern 5: Format Localized Enum Values**
```dart
// When displaying severity, role, diagnosis type, etc.
String localizedSeverity = LocalizationHelper.getLocalizedSeverity(
  context,
  'high'
);

String localizedRole = LocalizationHelper.getLocalizedRoleName(
  context,
  'farmer'
);

String localizedType = LocalizationHelper.getLocalizedDiagnosisType(
  context,
  'disease'
);
```

---

## 🔄 PERSISTENCE & RESTORATION

### Language Persists Across App Restarts
The system uses **Hive local storage**:

1. When user selects language → `SettingsBloc` saves to `SettingsRepository`
2. `SettingsRepository` → `SettingsLocalDataSource` → `Hive` box
3. On app restart → `main.dart` initializes → `SettingsBloc.add(SettingsLoadRequested())`
4. Bloc loads from Hive → emits `SettingsLoaded` with saved language
5. `BlocBuilder` in `main.dart` rebuilds MaterialApp with loaded language

**Storage Details:**
- Box: `AppConstants.settingsBox` (Hive)
- Key: `'language'`
- Default: `'ny'` (Chichewa)

### Automatic on App Startup
```dart
void main() {
  // ... initialization ...
  await di.initDependencies(); // Sets up Hive boxes
  runApp(const MbewuSmartApp());
}

class _MbewuSmartAppState {
  @override
  void initState() {
    // This loads saved settings from Hive
    _settingsBloc = di.sl<SettingsBloc>()
      ..add(settings_events.SettingsLoadRequested());
  }
}
```

---

## ✨ TESTING THE FIX

### Test Case 1: Welcome Page → Settings → Language Change
1. ✅ Start app → Welcome page shows in Chichewa (default)
2. ✅ Select English → "Continue" button text changes
3. ✅ Login → Dashboard should be in English
4. ✅ Go to Settings → Everything is English
5. ✅ Change to Chichewa → Entire app becomes Chichewa
6. ✅ Go back to dashboard → Chichewa throughout

### Test Case 2: Language Persistence
1. ✅ Change to English in Settings
2. ✅ Close and reopen app
3. ✅ App should still be in English

### Test Case 3: Dynamic Greetings
1. ✅ Change to Chichewa → Greeting says "Mwadzuka bwanji" (morning)
2. ✅ Change to English → Greeting says "Good morning"
3. ✅ No need to reload page

### Test Case 4: All Screens Update
- ✅ Diagnosis page
- ✅ History page  
- ✅ Reports page
- ✅ Dialogs & modals
- ✅ Navigation labels
- ✅ Cards & buttons
- ✅ Dashboard

---

## 🎯 KEY IMPROVEMENTS

| Issue | Before | After |
|-------|--------|-------|
| **Hardcoded locale** | `const Locale('en')` | Dynamic from SettingsBloc |
| **Settings page rebuild** | Only Settings rebuilt | Entire app rebuilds |
| **Greetings update** | ❌ No | ✅ Yes, instantly |
| **Language persistence** | Uncertain | ✅ Works with Hive |
| **All pages update** | ❌ Only Settings | ✅ All screens |
| **No logout needed** | ❌ User must logout | ✅ Instant update |
| **Error handling** | Missing | ✅ Graceful fallback |

---

## 🛠️ FILES MODIFIED

1. **lib/main.dart**
   - Fixed hardcoded locale
   - Added dynamic BlocBuilder logic
   - Added localizationsDelegates

2. **lib/features/settings/presentation/bloc/settings_bloc.dart**
   - Added error handling
   - Improved language change flow
   - Better state management

3. **lib/core/utils/localization_helper.dart**
   - Added `watchLanguageCode()` for reactive updates
   - Added `getLocaleFromContext()` for system locale
   - Improved documentation
   - Better null safety

4. **lib/features/welcome/presentation/pages/welcome_page.dart**
   - Removed unnecessary Hive manual operations
   - Cleaner language selection flow
   - Better integration with SettingsBloc

---

## 📱 ARCHITECTURE DIAGRAM

```
┌─────────────────────────────────────┐
│         MbewuSmartApp               │
│   (MultiBlocProvider)               │
└──────────────┬──────────────────────┘
               │
               ▼
┌─────────────────────────────────────┐
│  BlocBuilder<SettingsBloc>          │
│  Listens to: languageCode changes   │
└──────────────┬──────────────────────┘
               │
               ▼
┌─────────────────────────────────────┐
│  MaterialApp.router                 │
│  • locale = settingsState.language  │ ◄─── DYNAMIC!
│  • localizationsDelegates set       │
│  • Rebuilds entire app              │
└──────────────┬──────────────────────┘
               │
               ▼
┌─────────────────────────────────────┐
│  All Pages & Screens                │
│  ✅ Use AppLocalizations.of()       │
│  ✅ Get new locale automatically    │
│  ✅ Rebuild with new strings        │
└─────────────────────────────────────┘

On Language Change:
User: Settings → Select Chichewa
                    ▼
        SettingsBloc.add(SettingsLanguageChanged('ny'))
                    ▼
        SettingsRepository.setLanguage('ny')
                    ▼
        Hive.settingsBox.put('language', 'ny')
                    ▼
        SettingsBloc emits: SettingsLoaded(languageCode: 'ny')
                    ▼
        BlocBuilder triggers rebuild
                    ▼
        MaterialApp rebuilds with new locale
                    ▼
        All pages get new AppLocalizations instance
                    ▼
        🎉 Entire app is now Chichewa!
```

---

## 🐛 COMMON MISTAKES TO AVOID

### ❌ DON'T: Hardcode locale
```dart
// WRONG!
final locale = const Locale('en');
```

### ✅ DO: Use SettingsBloc state
```dart
// CORRECT!
if (settingsState is SettingsLoaded) {
  final locale = settingsState.languageCode == 'ny' 
    ? const Locale('ny', 'MW') 
    : const Locale('en');
}
```

### ❌ DON'T: Manually manage language with setState in each page
```dart
// WRONG - localized strings won't update app-wide
setState(() {
  _language = 'en';
});
```

### ✅ DO: Use SettingsBloc.add()
```dart
// CORRECT - triggers app-wide rebuild
context.read<SettingsBloc>().add(
  SettingsLanguageChanged('en')
);
```

### ❌ DON'T: Forget localizationsDelegates in MaterialApp
```dart
// WRONG!
MaterialApp(
  locale: locale,
  supportedLocales: [...],
  // Missing localizationsDelegates!
)
```

### ✅ DO: Include delegates
```dart
// CORRECT!
MaterialApp(
  locale: locale,
  supportedLocales: [...],
  localizationsDelegates: const [
    AppLocalizations.delegate,
  ],
)
```

---

## 📚 REFERENCES

- Flutter Localization: https://docs.flutter.dev/development/accessibility-and-localization/internationalization
- Flutter BLoC Pattern: https://bloclibrary.dev/
- Hive Database: https://docs.hivedb.dev/

---

## ✅ VERIFICATION CHECKLIST

- [x] Language change updates entire app
- [x] Settings page shows correct language
- [x] Greetings update dynamically
- [x] Navigation labels change
- [x] Dialogs and modals localize
- [x] Cards and buttons localize
- [x] Language persists across app restarts
- [x] No errors on language switch
- [x] No memory leaks
- [x] Error states handled gracefully
