import 'package:get_it/get_it.dart';
import 'package:hive_flutter/hive_flutter.dart';

import '../constants/app_constants.dart';
import '../../features/auth/data/datasources/auth_local_datasource.dart';
import '../../features/auth/data/repositories/auth_repository_impl.dart';
import '../../features/auth/domain/repositories/auth_repository.dart';
import '../../features/auth/domain/usecases/login_usecase.dart';
import '../../features/auth/domain/usecases/register_usecase.dart';
import '../../features/auth/domain/usecases/logout_usecase.dart';
import '../../features/auth/domain/usecases/get_current_user_usecase.dart';
import '../../features/auth/presentation/bloc/auth_bloc.dart';
import '../../features/settings/data/datasources/settings_local_datasource.dart';
import '../../features/settings/data/repositories/settings_repository_impl.dart';
import '../../features/settings/domain/repositories/settings_repository.dart';
import '../../features/settings/presentation/bloc/settings_bloc.dart';
import '../../features/diagnosis/data/datasources/diagnosis_local_datasource.dart';
import '../../features/diagnosis/data/repositories/diagnosis_repository_impl.dart';
import '../../features/diagnosis/domain/repositories/diagnosis_repository.dart';
import '../../features/diagnosis/domain/usecases/analyze_image_usecase.dart';
import '../../features/diagnosis/domain/usecases/get_history_usecase.dart';
import '../../features/diagnosis/domain/usecases/save_diagnosis_usecase.dart';
import '../../features/diagnosis/presentation/bloc/diagnosis_bloc.dart';
import '../../features/location/data/datasources/malawi_data_source.dart';
import '../../features/location/data/repositories/location_repository_impl.dart';
import '../../features/location/domain/repositories/location_repository.dart';
import '../../features/location/domain/usecases/get_current_location.dart';
import '../../features/location/domain/usecases/get_nearest_extension_officer.dart';
import '../../features/location/domain/usecases/get_nearest_agro_dealer.dart';
import '../../features/location/presentation/bloc/location_bloc.dart';
import '../../features/alerts/data/datasources/alerts_local_datasource.dart';
import '../../features/alerts/presentation/bloc/alerts_bloc.dart';
import '../../features/connectivity/presentation/bloc/connectivity_bloc.dart';
import '../../features/messaging/data/services/messaging_service.dart';
import '../../features/messaging/domain/repositories/messaging_repository.dart';
import '../../features/messaging/presentation/bloc/messaging_bloc.dart';
import '../../features/notifications/data/services/notification_service.dart';
import '../services/ai_assistant_service.dart';
import '../services/fcm_notification_service.dart';
import '../services/user_directory_service.dart';
import '../../features/reports/data/services/report_service.dart';

final sl = GetIt.instance;

Future<void> initDependencies() async {
  await Hive.initFlutter();

  await Hive.openBox(AppConstants.userBox);
  await Hive.openBox(AppConstants.diagnosisBox);
  await Hive.openBox(AppConstants.settingsBox);
  await Hive.openBox(AppConstants.cacheBox);
  await Hive.openBox(AppConstants.alertsBox);

  sl.registerLazySingleton<AuthLocalDataSource>(
    () => AuthLocalDataSourceImpl(userBox),
  );

  sl.registerLazySingleton<SettingsLocalDataSource>(
    () => SettingsLocalDataSourceImpl(settingsBox),
  );

  sl.registerLazySingleton<DiagnosisLocalDataSource>(
    () => DiagnosisLocalDataSourceImpl(diagnosisBox),
  );

  sl.registerLazySingleton<MalawiDataSource>(() => MalawiDataSource());

  sl.registerLazySingleton<AlertsLocalDataSource>(
    () => AlertsLocalDataSourceImpl(alertsBox),
  );

  sl.registerLazySingleton<AuthRepository>(
    () => AuthRepositoryImpl(sl(), sl()),
  );

  sl.registerLazySingleton<SettingsRepository>(
    () => SettingsRepositoryImpl(sl()),
  );

  sl.registerLazySingleton<DiagnosisRepository>(
    () => DiagnosisRepositoryImpl(sl()),
  );

  sl.registerLazySingleton<LocationRepository>(
    () => LocationRepositoryImpl(malawiDataSource: sl()),
  );

  sl.registerLazySingleton(() => LoginUseCase(sl()));
  sl.registerLazySingleton(() => RegisterUseCase(sl()));
  sl.registerLazySingleton(() => LogoutUseCase(sl()));
  sl.registerLazySingleton(() => GetCurrentUserUseCase(sl()));

  sl.registerLazySingleton(() => AnalyzeImageUseCase());
  sl.registerLazySingleton(() => GetHistoryUseCase(sl()));
  sl.registerLazySingleton(() => SaveDiagnosisUseCase(sl()));

  sl.registerLazySingleton(() => GetCurrentLocationUseCase(sl()));
  sl.registerLazySingleton(() => GetNearestExtensionOfficerUseCase(sl()));
  sl.registerLazySingleton(() => GetNearestAgroDealerUseCase(sl()));

  sl.registerFactory(
    () => AuthBloc(
      loginUseCase: sl(),
      registerUseCase: sl(),
      logoutUseCase: sl(),
      getCurrentUserUseCase: sl(),
      userDirectoryService: sl(),
    ),
  );

  sl.registerFactory(() => SettingsBloc(settingsRepository: sl()));

  sl.registerFactory(
    () => DiagnosisBloc(
      analyzeImageUseCase: sl(),
      getHistoryUseCase: sl(),
      saveDiagnosisUseCase: sl(),
    ),
  );

  sl.registerFactory(
    () => LocationBloc(
      getCurrentLocation: sl(),
      getNearestExtensionOfficer: sl(),
      getNearestAgroDealer: sl(),
    ),
  );

  sl.registerFactory(() => AlertsBloc(dataSource: sl()));

  sl.registerFactory(() => ConnectivityBloc());

  // Messaging
  sl.registerLazySingleton<MessagingRepository>(() => MessagingService());

  sl.registerFactory(() => MessagingBloc(messagingRepository: sl()));

  // Notifications
  sl.registerLazySingleton(() => NotificationService.instance);

  // Firebase reporting + directory
  sl.registerLazySingleton(() => FcmNotificationService());
  sl.registerLazySingleton(() => UserDirectoryService());
  sl.registerLazySingleton(
    () =>
        ReportService(userDirectoryService: sl(), fcmNotificationService: sl()),
  );

  // AI Assistant
  sl.registerLazySingleton(() => AiAssistantService(cacheBox: cacheBox));
}

Box get userBox => Hive.box(AppConstants.userBox);
Box get diagnosisBox => Hive.box(AppConstants.diagnosisBox);
Box get settingsBox => Hive.box(AppConstants.settingsBox);
Box get cacheBox => Hive.box(AppConstants.cacheBox);
Box get alertsBox => Hive.box(AppConstants.alertsBox);
