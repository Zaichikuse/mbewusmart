import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:equatable/equatable.dart';
import '../../domain/repositories/settings_repository.dart';

abstract class SettingsEvent extends Equatable {
  const SettingsEvent();
  @override
  List<Object?> get props => [];
}

class SettingsLoadRequested extends SettingsEvent {}

class SettingsLanguageChanged extends SettingsEvent {
  final String languageCode;
  const SettingsLanguageChanged(this.languageCode);
  @override
  List<Object?> get props => [languageCode];
}

class SettingsNotificationsToggled extends SettingsEvent {
  final bool enabled;
  const SettingsNotificationsToggled(this.enabled);
  @override
  List<Object?> get props => [enabled];
}

class SettingsSyncRequested extends SettingsEvent {}

abstract class SettingsState extends Equatable {
  const SettingsState();
  @override
  List<Object?> get props => [];
}

class SettingsInitial extends SettingsState {}

class SettingsLoading extends SettingsState {}

class SettingsLoaded extends SettingsState {
  final String languageCode;
  final bool notificationsEnabled;
  final DateTime? lastSyncTime;

  const SettingsLoaded({
    required this.languageCode,
    required this.notificationsEnabled,
    this.lastSyncTime,
  });

  SettingsLoaded copyWith({
    String? languageCode,
    bool? notificationsEnabled,
    DateTime? lastSyncTime,
  }) {
    return SettingsLoaded(
      languageCode: languageCode ?? this.languageCode,
      notificationsEnabled: notificationsEnabled ?? this.notificationsEnabled,
      lastSyncTime: lastSyncTime ?? this.lastSyncTime,
    );
  }

  @override
  List<Object?> get props => [languageCode, notificationsEnabled, lastSyncTime];
}

class SettingsError extends SettingsState {
  final String message;
  const SettingsError(this.message);
}

class SettingsBloc extends Bloc<SettingsEvent, SettingsState> {
  final SettingsRepository settingsRepository;

  SettingsBloc({required this.settingsRepository}) : super(SettingsInitial()) {
    on<SettingsLoadRequested>(_onLoadRequested);
    on<SettingsLanguageChanged>(_onLanguageChanged);
    on<SettingsNotificationsToggled>(_onNotificationsToggled);
  }

  Future<void> _onLoadRequested(
    SettingsLoadRequested event,
    Emitter<SettingsState> emit,
  ) async {
    emit(SettingsLoading());

    final languageResult = await settingsRepository.getLanguage();
    final notificationsResult = await settingsRepository.getNotificationsEnabled();
    final syncResult = await settingsRepository.getLastSyncTime();

    emit(SettingsLoaded(
      languageCode: languageResult.fold((l) => 'ny', (r) => r),
      notificationsEnabled: notificationsResult.fold((l) => true, (r) => r),
      lastSyncTime: syncResult.fold((l) => null, (r) => r),
    ));
  }

  Future<void> _onLanguageChanged(
    SettingsLanguageChanged event,
    Emitter<SettingsState> emit,
  ) async {
    if (state is SettingsLoaded) {
      final currentState = state as SettingsLoaded;
      await settingsRepository.setLanguage(event.languageCode);
      emit(currentState.copyWith(languageCode: event.languageCode));
    }
  }

  Future<void> _onNotificationsToggled(
    SettingsNotificationsToggled event,
    Emitter<SettingsState> emit,
  ) async {
    if (state is SettingsLoaded) {
      final currentState = state as SettingsLoaded;
      await settingsRepository.setNotificationsEnabled(event.enabled);
      emit(currentState.copyWith(notificationsEnabled: event.enabled));
    }
  }
}