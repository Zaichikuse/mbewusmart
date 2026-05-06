# MbewuSmart Localization Architecture - Deep Dive

## Overview

This document explains the architecture behind MbewuSmart's localization system, why each component exists, and how they work together.

---

## Problem We Solved

### The Bug
Language switching worked BEFORE login (on Welcome page) but NOT after login (in Settings).

**Why?**
- **Welcome page:** Used local `_selectedLanguage` state with `setState()`
- **Settings page:** Changed SettingsBloc state, but the entire app didn't rebuild
- **Root cause:** MaterialApp's `locale` was hardcoded to `'en'`, never updating

### The Fix
Make the entire app reactive to language changes by:
1. Reading language from SettingsBloc in main.dart
2. Making MaterialApp rebuild when language changes
3. Having all screens use Material's localization system

---

## Architecture Diagram

```
┌─────────────────────────────────────────────────────────┐
│                    main.dart                             │
│  • App entry point                                      │
│  • MultiBlocProvider setup                              │
└──────────┬──────────────────────────────────────────────┘
           │
           ▼
┌─────────────────────────────────────────────────────────┐
│         BlocBuilder<SettingsBloc>                        │
│  • Listens to: SettingsState changes                    │
│  • Rebuilds when: languageCode changes                  │
└──────────┬──────────────────────────────────────────────┘
           │
           ▼
┌─────────────────────────────────────────────────────────┐
│           MaterialApp.router                             │
│  • locale = settingsState.languageCode                  │
│  • localizationsDelegates = [AppLocalizations.delegate] │
│  • supportedLocales = [Locale('en'), Locale('ny','MW')] │
└──────────┬──────────────────────────────────────────────┘
           │
           ▼
┌─────────────────────────────────────────────────────────┐
│      Flutter Localization System                         │
│  • Manages: AppLocalizations instances                  │
│  • Caches: Loaded locale strings                        │
│  • Updates: When MaterialApp.locale changes             │
└──────────┬──────────────────────────────────────────────┘
           │
           ▼
┌─────────────────────────────────────────────────────────┐
│        All App Screens & Widgets                         │
│  • Call: AppLocalizations.of(context)                   │
│  • Get: New strings in current language                 │
│  • Rebuild: With new text automatically                 │
└─────────────────────────────────────────────────────────┘
```

---

## Component Breakdown

### 1. **main.dart** - App Root

```dart
class MbewuSmartApp extends StatefulWidget {
  @override
  State<MbewuSmartApp> createState() => _MbewuSmartAppState();
}

class _MbewuSmartAppState extends State<MbewuSmartApp> {
  @override
  void initState() {
    // Load settings on app startup
    _settingsBloc = di.sl<SettingsBloc>()
      ..add(settings_events.SettingsLoadRequested());
  }

  @override
  Widget build(BuildContext context) {
    return MultiBlocProvider(
      providers: [
        BlocProvider<SettingsBloc>.value(value: _settingsBloc),
        // ... other providers
      ],
      child: BlocBuilder<SettingsBloc, SettingsState>(
        builder: (context, settingsState) {
          // Extract language from state
          Locale locale = (settingsState is SettingsLoaded 
            && settingsState.languageCode == 'ny')
              ? const Locale('ny', 'MW')
              : const Locale('en');

          // Entire MaterialApp rebuilds when language changes
          return MaterialApp.router(
            // This is the KEY - locale is no longer hardcoded!
            locale: locale,
            localizationsDelegates: const [
              AppLocalizations.delegate,  // Tells Flutter how to load strings
            ],
            supportedLocales: const [
              Locale('en'),
              Locale('ny', 'MW'),
            ],
          );
        },
      ),
    );
  }
}
```

**Why this design:**
- `BlocBuilder` only rebuilds when needed (efficiency)
- `locale` field now dynamic (responsive to state)
- All children rebuild with new locale context
- AppLocalizations.delegate handles string loading

---

### 2. **SettingsBloc** - State Management

```dart
class SettingsBloc extends Bloc<SettingsEvent, SettingsState> {
  SettingsBloc({required this.settingsRepository})
      : super(SettingsInitial()) {
    on<SettingsLoadRequested>(_onLoadRequested);
    on<SettingsLanguageChanged>(_onLanguageChanged);
  }

  // Called when app starts
  Future<void> _onLoadRequested(...) async {
    emit(SettingsLoading());
    
    // Read from persistent storage (Hive)
    final languageResult = await settingsRepository.getLanguage();
    
    emit(SettingsLoaded(
      languageCode: languageResult.fold((l) => 'ny', (r) => r),
    ));
  }

  // Called when user changes language
  Future<void> _onLanguageChanged(
    SettingsLanguageChanged event,
    Emitter<SettingsState> emit,
  ) async {
    if (state is SettingsLoaded) {
      final currentState = state as SettingsLoaded;
      
      // 1. Save to device storage
      await settingsRepository.setLanguage(event.languageCode);
      
      // 2. Emit new state
      emit(currentState.copyWith(
        languageCode: event.languageCode
      ));
      
      // ✅ This triggers BlocBuilder in main.dart
      // ✅ MaterialApp rebuilds with new locale
      // ✅ All screens get new AppLocalizations
    }
  }
}
```

**State Flow:**
```
User selects language
       ↓
SettingsLanguageChanged event
       ↓
_onLanguageChanged handler
       ↓
Save to repository (Hive)
       ↓
Emit new SettingsLoaded state
       ↓
BlocBuilder in main.dart detects state change
       ↓
BlocBuilder rebuilds
       ↓
MaterialApp rebuilds with new locale
       ↓
✅ Entire app now speaks new language
```

---

### 3. **AppLocalizations** - String Management

```dart
class AppLocalizations {
  final Locale locale;

  AppLocalizations(this.locale);

  // Called by Flutter's localization system
  static AppLocalizations? of(BuildContext context) {
    return Localizations.of<AppLocalizations>(
      context,
      AppLocalizations
    );
  }

  // Tells Flutter how to create AppLocalizations
  static const LocalizationsDelegate<AppLocalizations> delegate =
      _AppLocalizationsDelegate();

  // Maps keys to localized strings
  static const Map<String, Map<String, String>> _localizedValues = {
    'en': {
      'home': 'Home',
      'greetingMorning': 'Good morning',
      // ... 100+ keys
    },
    'ny': {
      'home': 'Mphamvu',
      'greetingMorning': 'Mwadzuka bwanji',
      // ... 100+ keys
    },
  };

  String get home => _translate('home');
  String get greetingMorning => _translate('greetingMorning');
  // ... all properties

  String _translate(String key) {
    final localeMap = _localizedValues[locale.languageCode];
    return localeMap?[key] ?? _localizedValues['en']?[key] ?? key;
  }
}

// Handles creating AppLocalizations when needed
class _AppLocalizationsDelegate
    extends LocalizationsDelegate<AppLocalizations> {
  
  @override
  bool isSupported(Locale locale) {
    return ['en', 'ny'].contains(locale.languageCode);
  }

  @override
  Future<AppLocalizations> load(Locale locale) async {
    // Instantiate with the requested locale
    return AppLocalizations(locale);
  }

  @override
  bool shouldReload(covariant LocalizationsDelegate<AppLocalizations> old) {
    return false;  // Never reload if delegate hasn't changed
  }
}
```

**Key points:**
- `_localizedValues` is a static map of all strings
- `_AppLocalizationsDelegate` tells Flutter how to create instances
- Flutter automatically creates new instance when `MaterialApp.locale` changes
- Screens call `AppLocalizations.of(context)` to get current instance

---

### 4. **LocalizationHelper** - Utility Functions

```dart
class LocalizationHelper {
  // Get the localization instance
  // (Throws if not available - safer than null check)
  static AppLocalizations getAppLocalizations(BuildContext context) {
    final appLoc = AppLocalizations.of(context);
    if (appLoc == null) {
      throw Exception('AppLocalizations not found in context');
    }
    return appLoc;
  }

  // Watch for language changes (causes rebuild)
  static String watchLanguageCode(BuildContext context) {
    final settingsState = context.watch<SettingsBloc>().state;
    return settingsState is SettingsLoaded 
        ? settingsState.languageCode 
        : 'ny';
  }

  // Read without rebuilding
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

  // Get system locale from Material
  static Locale getLocaleFromContext(BuildContext context) {
    return Localizations.localeOf(context);
  }

  // Dynamic greeting based on time
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

  // Localize enum values
  static String getLocalizedSeverity(
    BuildContext context,
    String severity
  ) {
    final appLoc = getAppLocalizations(context);
    switch (severity.toLowerCase()) {
      case 'high':
        return appLoc.high;
      case 'medium':
        return appLoc.medium;
      case 'low':
        return appLoc.low;
      default:
        return severity;
    }
  }
  
  // ... more helper methods
}
```

**Why this exists:**
- Provides convenient shortcuts
- Handles null safety
- Centralizes localization logic
- Makes code more readable
- Easier to maintain

---

### 5. **SettingsRepository** - Persistence Layer

```dart
abstract class SettingsRepository {
  Future<Either<Failure, String>> getLanguage();
  Future<Either<Failure, void>> setLanguage(String languageCode);
}

class SettingsRepositoryImpl implements SettingsRepository {
  final SettingsLocalDataSource localDataSource;

  @override
  Future<Either<Failure, String>> getLanguage() async {
    try {
      // Read from device storage
      final language = await localDataSource.getLanguage();
      return Right(language);  // Success
    } catch (e) {
      return Left(CacheFailure(e.toString()));  // Failure
    }
  }

  @override
  Future<Either<Failure, void>> setLanguage(String languageCode) async {
    try {
      // Write to device storage
      await localDataSource.setLanguage(languageCode);
      return const Right(null);
    } catch (e) {
      return Left(CacheFailure(e.toString()));
    }
  }
}
```

**Design pattern:** Uses `Either<Failure, T>` for error handling (functional programming style)

---

### 6. **SettingsLocalDataSource** - Storage Access

```dart
class SettingsLocalDataSourceImpl implements SettingsLocalDataSource {
  final Box settingsBox;  // Hive box

  @override
  Future<String> getLanguage() async {
    // Return saved value, default to 'ny' if not found
    return settingsBox.get('language', defaultValue: 'ny');
  }

  @override
  Future<void> setLanguage(String languageCode) async {
    // Save to Hive
    await settingsBox.put('language', languageCode);
  }
}
```

**Storage details:**
- Uses Hive (key-value store)
- Key: `'language'`
- Values: `'en'` or `'ny'`
- Default: `'ny'` (Chichewa)
- Persists across app restarts

---

## Data Flow: Language Change Sequence

```
User clicks "English" in Settings
           ↓
SettingsPage calls:
context.read<SettingsBloc>().add(
  SettingsLanguageChanged('en')
)
           ↓
SettingsBloc._onLanguageChanged triggered
           ↓
Step 1: settingsRepository.setLanguage('en')
  → SettingsRepositoryImpl receives call
  → Calls SettingsLocalDataSource.setLanguage('en')
  → Hive box saves: {'language': 'en'}
           ↓
Step 2: emit(currentState.copyWith(languageCode: 'en'))
  → Bloc emits: SettingsLoaded(languageCode: 'en')
           ↓
Step 3: BlocBuilder in main.dart detects state change
           ↓
Step 4: BlocBuilder rebuilds
  → Evaluates builder function
  → settingsState is now SettingsLoaded(languageCode: 'en')
           ↓
Step 5: Calculate new locale
  locale = Locale('en')  (no longer 'ny')
           ↓
Step 6: MaterialApp rebuilds with new locale
  → Calls setLocale(Locale('en'))
           ↓
Step 7: Flutter's localization system updates
  → Calls AppLocalizations.delegate.load(Locale('en'))
  → Creates new AppLocalizations(Locale('en'))
           ↓
Step 8: All descendant widgets rebuild
  → Calling AppLocalizations.of(context)
  → Getting new instance with 'en' locale
  → Displaying English strings
           ↓
Step 9: Entire app is now English!
  ✅ Dashboard: English
  ✅ Settings: English
  ✅ History: English
  ✅ Alerts: English
  ✅ Reports: English
           ↓
App restart later...
           ↓
Step 10: main.dart initializes
  → Calls SettingsBloc.add(SettingsLoadRequested())
           ↓
Step 11: SettingsBloc._onLoadRequested
  → Calls settingsRepository.getLanguage()
  → Hive returns 'en' (saved from Step 1)
  → Emits SettingsLoaded(languageCode: 'en')
           ↓
Step 12: BlocBuilder rebuilds with saved language
  ✅ App starts in English!
```

---

## Why This Design Works

### 1. **Single Source of Truth**
- Language code stored in one place: SettingsBloc
- All screens get it from same source
- Prevents inconsistencies

### 2. **Reactive Updates**
- BlocBuilder listens to SettingsBloc
- When language changes → entire app rebuilds
- Flutter's localization system handles the rest

### 3. **Persistent Storage**
- Hive stores language preference
- Survives app restarts
- No need to re-select every launch

### 4. **Separation of Concerns**
- Bloc: State management
- Repository: Data access logic
- DataSource: Storage implementation
- Screens: Just use AppLocalizations

### 5. **Clean Architecture**
- Follows SOLID principles
- Easy to test (all layers mockable)
- Easy to maintain (changes isolated)

### 6. **Performance**
- BlocBuilder only rebuilds when needed
- Flutter's build system optimizes rebuilds
- String lookup is O(1) hash table

---

## Why Previous Approach Failed

```dart
// OLD WRONG APPROACH in main.dart:
final locale = const Locale('en');  // ❌ Hardcoded!

return MaterialApp(
  locale: locale,  // Never changes!
  // Even if SettingsBloc emits new state,
  // this locale variable never updates
);
```

**Problems:**
1. `locale` is assigned once and never changes
2. BlocBuilder rebuilds, but `locale` value is still the same
3. MaterialApp gets same locale, so it doesn't rebuild
4. AppLocalizations.delegate is never called
5. Screens still get old AppLocalizations instance
6. Text doesn't update

---

## Key Learnings

1. **Don't hardcode values in builders** - Calculate from state each time
2. **BlocBuilder must return MaterialApp** - Not widgets inside it
3. **Locale must be dynamic** - Part of build calculation
4. **Delegates matter** - Flutter needs them to know how to load strings
5. **Test entire flow** - Language change → Storage → Restart

---

## Future Improvements

Possible enhancements:

1. **Add more languages** - Just add to _localizedValues
2. **Server-based strings** - Fetch from Firebase
3. **Language-specific fonts** - Load different fonts per language
4. **RTL support** - Add Arabic, Hebrew locales
5. **Pluralization** - Handle 1 item vs 2+ items
6. **Date formatting** - Localize dates per language
7. **Number formatting** - Localize thousands separators

---

## Testing Strategy

### Unit Tests
```dart
test('SettingsBloc emits new state on language change', () async {
  final bloc = SettingsBloc(repository: mockRepository);
  bloc.add(SettingsLanguageChanged('en'));
  
  expect(
    bloc.stream,
    emits(SettingsLoaded(languageCode: 'en')),
  );
});
```

### Widget Tests
```dart
testWidgets('App rebuilds in new language', (tester) async {
  await tester.pumpWidget(const MbewuSmartApp());
  
  expect(find.text('Home'), findsOneWidget);
  
  // Change language
  await tester.tap(find.byIcon(Icons.language));
  await tester.pumpAndSettle();
  
  // Should be in new language
  expect(find.text('Mphamvu'), findsOneWidget);
  expect(find.text('Home'), findsNothing);
});
```

### Integration Tests
```dart
testDriver('Language persists across restart', () async {
  // Change language
  await driver.tap(languageButtonFinder);
  
  // Restart app
  await driver.requestData('restart');
  await driver.waitFor(homeFinder);
  
  // Should still be in new language
  expect(await driver.getText(greetingFinder), 'Mwadzuka bwanji');
});
```

---

## References

- Flutter i18n: https://docs.flutter.dev/development/accessibility-and-localization/internationalization
- BLoC Pattern: https://bloclibrary.dev/
- Hive DB: https://docs.hivedb.dev/
- Functional Programming (Either): https://en.wikipedia.org/wiki/Either_type

---

**Last Updated:** 2026-05-06  
**Status:** ✅ Production Ready  
**Tested On:** Android, iOS
