import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'features/auth/presentation/bloc/auth_bloc.dart';
import 'features/auth/presentation/bloc/auth_event.dart';
import 'features/settings/presentation/bloc/settings_bloc.dart';
import 'features/settings/presentation/bloc/settings_bloc.dart' as settings_events;
import 'features/diagnosis/presentation/bloc/diagnosis_bloc.dart';
import 'features/location/presentation/bloc/location_bloc.dart';
import 'features/alerts/presentation/bloc/alerts_bloc.dart';
import 'features/connectivity/presentation/bloc/connectivity_bloc.dart';
import 'shared/routes/app_router.dart';
import 'core/di/injection_container.dart' as di;
import 'core/theme/app_theme.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await di.initDependencies();
  runApp(const MbewuSmartApp());
}

class MbewuSmartApp extends StatefulWidget {
  const MbewuSmartApp({super.key});

  @override
  State<MbewuSmartApp> createState() => _MbewuSmartAppState();
}

class _MbewuSmartAppState extends State<MbewuSmartApp> {
  late final AuthBloc _authBloc;
  late final SettingsBloc _settingsBloc;
  late final DiagnosisBloc _diagnosisBloc;
  late final AlertsBloc _alertsBloc;
  late final AppRouter _appRouter;

  @override
  void initState() {
    super.initState();
    _authBloc = di.sl<AuthBloc>();
    _authBloc.add(AuthCheckRequested());
    _settingsBloc = di.sl<SettingsBloc>()..add(settings_events.SettingsLoadRequested());
    _diagnosisBloc = di.sl<DiagnosisBloc>();
    _alertsBloc = di.sl<AlertsBloc>();
    _appRouter = AppRouter(authBloc: _authBloc);
  }

  @override
  void dispose() {
    _authBloc.close();
    _settingsBloc.close();
    _diagnosisBloc.close();
    _alertsBloc.close();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return MultiBlocProvider(
      providers: [
        BlocProvider<AuthBloc>.value(value: _authBloc),
        BlocProvider<SettingsBloc>.value(value: _settingsBloc),
        BlocProvider<DiagnosisBloc>.value(value: _diagnosisBloc),
        BlocProvider<LocationBloc>(create: (_) => di.sl<LocationBloc>()),
        BlocProvider<AlertsBloc>.value(value: _alertsBloc),
        BlocProvider<ConnectivityBloc>(create: (_) => di.sl<ConnectivityBloc>()..add(ConnectivityStarted())),
      ],
      child: BlocBuilder<SettingsBloc, SettingsState>(
        builder: (context, settingsState) {
          final locale = const Locale('en'); // always use English for Flutter system

          return MaterialApp.router(
            title: 'MbewuSmart',
            debugShowCheckedModeBanner: false,
            theme: AppTheme.lightTheme,
            locale: locale,
            supportedLocales: const [
              Locale('en'),
            ],
            localeResolutionCallback: (deviceLocale, supportedLocales) {
          if (deviceLocale != null && deviceLocale.languageCode == 'ny') {
          return const Locale('en');
          }
        return deviceLocale;
   },
            routerConfig: _appRouter.router,
          );
        },
      ),
    );
  }
}
