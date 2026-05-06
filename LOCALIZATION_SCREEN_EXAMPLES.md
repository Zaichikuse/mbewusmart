# Screen Implementation Examples - Localization in MbewuSmart

This file shows best-practice examples for implementing localization in different types of screens in MbewuSmart.

---

## 1. Dashboard/Home Screen (With Dynamic Greeting)

```dart
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../l10n/app_localizations.dart';
import '../../../core/utils/localization_helper.dart';

class DashboardPage extends StatelessWidget {
  const DashboardPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(AppLocalizations.of(context)?.home ?? 'Home'),
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Dynamic greeting that updates with language
              Text(
                LocalizationHelper.getGreeting(context),
                style: Theme.of(context).textTheme.headlineSmall,
              ),
              const SizedBox(height: 8),
              Text(
                'Welcome to MbewuSmart',
                style: Theme.of(context).textTheme.bodyMedium,
              ),
              const SizedBox(height: 24),
              _buildRecentScansSection(context),
              const SizedBox(height: 24),
              _buildQuickActionsSection(context),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildRecentScansSection(BuildContext context) {
    final appLoc = AppLocalizations.of(context)!;
    
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          appLoc.recentScans,
          style: Theme.of(context).textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 12),
        // Your recent scans list here
        Text(appLoc.noRecentScans),
      ],
    );
  }

  Widget _buildQuickActionsSection(BuildContext context) {
    final appLoc = AppLocalizations.of(context)!;
    
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
      children: [
        _buildQuickActionButton(
          context,
          label: appLoc.scanCrop,
          icon: Icons.camera,
          onTap: () {},
        ),
        _buildQuickActionButton(
          context,
          label: appLoc.history,
          icon: Icons.history,
          onTap: () {},
        ),
        _buildQuickActionButton(
          context,
          label: appLoc.alerts,
          icon: Icons.notifications,
          onTap: () {},
        ),
      ],
    );
  }

  Widget _buildQuickActionButton({
    required BuildContext context,
    required String label,
    required IconData icon,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Column(
        children: [
          CircleAvatar(
            child: Icon(icon),
          ),
          const SizedBox(height: 8),
          Text(label, textAlign: TextAlign.center),
        ],
      ),
    );
  }
}
```

---

## 2. Diagnosis Result Screen (With Enum Localization)

```dart
import 'package:flutter/material.dart';
import '../../../l10n/app_localizations.dart';
import '../../../core/utils/localization_helper.dart';
import '../../../features/diagnosis/domain/entities/diagnosis_result.dart';

class DiagnosisResultScreen extends StatelessWidget {
  final DiagnosisResult result;

  const DiagnosisResultScreen({
    super.key,
    required this.result,
  });

  @override
  Widget build(BuildContext context) {
    final appLoc = AppLocalizations.of(context)!;
    
    return Scaffold(
      appBar: AppBar(
        title: Text(appLoc.diagnosisResult),
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Localized disease type
              _buildResultCard(
                context,
                title: appLoc.disease,
                value: LocalizationHelper.getLocalizedDiagnosisType(
                  context,
                  result.diseaseType,
                ),
              ),
              const SizedBox(height: 12),
              
              // Localized severity
              _buildResultCard(
                context,
                title: appLoc.severity,
                value: LocalizationHelper.getLocalizedSeverity(
                  context,
                  result.severity,
                ),
              ),
              const SizedBox(height: 12),
              
              // Confidence score
              _buildResultCard(
                context,
                title: appLoc.confidence,
                value: '${(result.confidence * 100).toStringAsFixed(1)}%',
              ),
              const SizedBox(height: 24),
              
              // Recommendation
              Text(
                appLoc.recommendation,
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 12),
              Text(result.recommendation),
              const SizedBox(height: 24),
              
              // Action buttons
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () {},
                  child: Text(appLoc.saveResult),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildResultCard(
    BuildContext context, {
    required String title,
    required String value,
  }) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.grey[100],
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(title),
          Text(
            value,
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }
}
```

---

## 3. Settings Screen (With Language Selection)

```dart
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../l10n/app_localizations.dart';
import '../../../core/utils/localization_helper.dart';
import '../bloc/settings_bloc.dart';

class SettingsPage extends StatelessWidget {
  const SettingsPage({super.key});

  @override
  Widget build(BuildContext context) {
    final isChichewa = LocalizationHelper.isChichewa(context);
    
    return Scaffold(
      appBar: AppBar(
        title: Text(isChichewa ? 'Zochitika' : 'Settings'),
      ),
      body: BlocBuilder<SettingsBloc, SettingsState>(
        builder: (context, state) {
          if (state is SettingsLoaded) {
            return ListView(
              padding: const EdgeInsets.all(16),
              children: [
                _buildSectionTitle(context, 'General'),
                const SizedBox(height: 8),
                _buildLanguageSelector(context, state.languageCode),
                const SizedBox(height: 24),
                _buildSectionTitle(context, 'Notifications'),
                const SizedBox(height: 8),
                _buildNotificationToggle(context, state.notificationsEnabled),
                const SizedBox(height: 24),
                _buildSectionTitle(context, 'About'),
                const SizedBox(height: 8),
                _buildAboutInfo(context),
              ],
            );
          }
          
          return const Center(child: CircularProgressIndicator());
        },
      ),
    );
  }

  Widget _buildSectionTitle(BuildContext context, String title) {
    return Text(
      title,
      style: Theme.of(context).textTheme.titleMedium?.copyWith(
        fontWeight: FontWeight.bold,
      ),
    );
  }

  Widget _buildLanguageSelector(BuildContext context, String currentLanguage) {
    final appLoc = AppLocalizations.of(context)!;
    
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.grey[300]!),
      ),
      child: Column(
        children: [
          _buildLanguageOption(
            context,
            code: 'en',
            name: appLoc.english,
            isSelected: currentLanguage == 'en',
          ),
          Divider(height: 1, color: Colors.grey[300]),
          _buildLanguageOption(
            context,
            code: 'ny',
            name: appLoc.chichewa,
            isSelected: currentLanguage == 'ny',
          ),
        ],
      ),
    );
  }

  Widget _buildLanguageOption(
    BuildContext context, {
    required String code,
    required String name,
    required bool isSelected,
  }) {
    return ListTile(
      title: Text(name),
      trailing: isSelected
          ? const Icon(Icons.check, color: Colors.green)
          : null,
      onTap: () {
        if (!isSelected) {
          context.read<SettingsBloc>().add(
            SettingsLanguageChanged(code),
          );
          // Optional: Show snackbar
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                LocalizationHelper.isChichewa(context)
                    ? 'Chilankhulo chesankhidwa'
                    : 'Language changed',
              ),
              duration: const Duration(seconds: 2),
            ),
          );
        }
      },
    );
  }

  Widget _buildNotificationToggle(BuildContext context, bool enabled) {
    return SwitchListTile(
      title: Text(
        LocalizationHelper.isChichewa(context)
            ? 'Zizindikiro'
            : 'Notifications',
      ),
      value: enabled,
      onChanged: (value) {
        context.read<SettingsBloc>().add(
          SettingsNotificationsToggled(value),
        );
      },
    );
  }

  Widget _buildAboutInfo(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.grey[300]!),
      ),
      child: Column(
        children: [
          ListTile(
            title: const Text('MbewuSmart'),
            subtitle: const Text('v1.0.0'),
          ),
          Divider(height: 1, color: Colors.grey[300]),
          ListTile(
            title: Text(
              LocalizationHelper.isChichewa(context) ? 'Mwini' : 'Developer',
            ),
            subtitle: const Text('Malawi Agricultural Services'),
          ),
        ],
      ),
    );
  }
}
```

---

## 4. History/Reports Screen (With List Localization)

```dart
import 'package:flutter/material.dart';
import '../../../l10n/app_localizations.dart';
import '../../../core/utils/localization_helper.dart';

class HistoryPage extends StatelessWidget {
  final List<DiagnosisResult> results = [];

  HistoryPage({super.key});

  @override
  Widget build(BuildContext context) {
    final appLoc = AppLocalizations.of(context)!;
    
    return Scaffold(
      appBar: AppBar(
        title: Text(appLoc.history),
      ),
      body: results.isEmpty
          ? _buildEmptyState(context)
          : _buildHistoryList(context),
    );
  }

  Widget _buildEmptyState(BuildContext context) {
    final appLoc = AppLocalizations.of(context)!;
    
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.history,
            size: 48,
            color: Colors.grey[400],
          ),
          const SizedBox(height: 16),
          Text(appLoc.noHistory),
          const SizedBox(height: 8),
          Text(
            appLoc.noHistoryMessage,
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.bodySmall,
          ),
          const SizedBox(height: 24),
          ElevatedButton(
            onPressed: () {},
            child: Text(appLoc.startScanning),
          ),
        ],
      ),
    );
  }

  Widget _buildHistoryList(BuildContext context) {
    final appLoc = AppLocalizations.of(context)!;
    
    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: results.length,
      itemBuilder: (context, index) {
        final result = results[index];
        
        return Card(
          margin: const EdgeInsets.only(bottom: 12),
          child: ListTile(
            leading: Icon(
              _getSeverityIcon(result.severity),
              color: _getSeverityColor(result.severity),
            ),
            title: Text(
              LocalizationHelper.getLocalizedDiagnosisType(
                context,
                result.diseaseType,
              ),
            ),
            subtitle: Text(
              '${appLoc.severity}: ${LocalizationHelper.getLocalizedSeverity(context, result.severity)}',
            ),
            trailing: Text(
              '${(result.confidence * 100).toStringAsFixed(0)}%',
              style: Theme.of(context).textTheme.bodySmall,
            ),
            onTap: () => _navigateToDetail(context, result),
          ),
        );
      },
    );
  }

  IconData _getSeverityIcon(String severity) {
    switch (severity.toLowerCase()) {
      case 'high':
        return Icons.warning;
      case 'medium':
        return Icons.info;
      default:
        return Icons.check_circle;
    }
  }

  Color _getSeverityColor(String severity) {
    switch (severity.toLowerCase()) {
      case 'high':
        return Colors.red;
      case 'medium':
        return Colors.orange;
      default:
        return Colors.green;
    }
  }

  void _navigateToDetail(BuildContext context, DiagnosisResult result) {
    // Navigate to detail screen
  }
}
```

---

## 5. Dialog with Localization

```dart
void showLanguageSelectionDialog(BuildContext context) {
  final appLoc = AppLocalizations.of(context)!;
  final currentLanguage = LocalizationHelper.readLanguageCode(context);
  
  showDialog(
    context: context,
    builder: (dialogContext) {
      return AlertDialog(
        title: Text(appLoc.selectLanguage),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              title: Text(appLoc.english),
              leading: Radio<String>(
                value: 'en',
                groupValue: currentLanguage,
                onChanged: (value) {
                  context.read<SettingsBloc>().add(
                    SettingsLanguageChanged(value!),
                  );
                  Navigator.pop(dialogContext);
                },
              ),
            ),
            ListTile(
              title: Text(appLoc.chichewa),
              leading: Radio<String>(
                value: 'ny',
                groupValue: currentLanguage,
                onChanged: (value) {
                  context.read<SettingsBloc>().add(
                    SettingsLanguageChanged(value!),
                  );
                  Navigator.pop(dialogContext);
                },
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: Text(appLoc.cancelText ?? 'Cancel'),
          ),
        ],
      );
    },
  );
}
```

---

## 6. Stateful Widget with Language Watch (Advanced)

```dart
class RealTimeLocalizationExample extends StatefulWidget {
  const RealTimeLocalizationExample({super.key});

  @override
  State<RealTimeLocalizationExample> createState() =>
      _RealTimeLocalizationExampleState();
}

class _RealTimeLocalizationExampleState
    extends State<RealTimeLocalizationExample> {
  late StreamSubscription<SettingsState> _languageSubscription;

  @override
  void initState() {
    super.initState();
    // Listen to language changes and rebuild
    _languageSubscription = context.read<SettingsBloc>().stream.listen(
      (state) {
        if (state is SettingsLoaded) {
          setState(() {
            // Force rebuild when language changes
          });
        }
      },
    );
  }

  @override
  void dispose() {
    _languageSubscription.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final appLoc = AppLocalizations.of(context)!;
    final greeting = LocalizationHelper.getGreeting(context);
    
    return Scaffold(
      appBar: AppBar(title: Text(appLoc.home)),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(greeting),
            const SizedBox(height: 16),
            Text(appLoc.welcome),
          ],
        ),
      ),
    );
  }
}
```

---

## 7. Best Practices Summary

### ✅ DO:
1. Always use `AppLocalizations.of(context)!` for simple text
2. Use `LocalizationHelper.getGreeting(context)` for dynamic greetings
3. Use `LocalizationHelper.watchLanguageCode(context)` when you need to rebuild on language change
4. Call `SettingsBloc.add(SettingsLanguageChanged(...))` when user changes language
5. Keep localization strings in `app_en.arb` and `app_ny.arb`

### ❌ DON'T:
1. Hardcode language strings
2. Use `context.read<SettingsBloc>()` to determine UI layout (use `watch` instead)
3. Forget to handle null when getting AppLocalizations
4. Manually manage language state in individual screens
5. Create custom localization systems - use Flutter's built-in system

---

## 8. Adding New Localization Keys

To add new strings:

1. **Add to `app_en.arb`:**
   ```json
   "myNewKey": "My English Text"
   ```

2. **Add to `app_ny.arb`:**
   ```json
   "myNewKey": "Mwansinthupi Wanga"
   ```

3. **Use in code:**
   ```dart
   final appLoc = AppLocalizations.of(context)!;
   Text(appLoc.myNewKey)
   ```

4. **Run codegen (if needed):**
   ```bash
   flutter pub run intl_utils:generate
   ```
