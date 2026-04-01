import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:equatable/equatable.dart';
import '../../domain/entities/alert.dart';
import '../../data/datasources/alerts_local_datasource.dart';

abstract class AlertsEvent extends Equatable {
  const AlertsEvent();
  @override
  List<Object?> get props => [];
}

class AlertsLoadRequested extends AlertsEvent {}

class AlertSent extends AlertsEvent {
  final Alert alert;
  const AlertSent(this.alert);
  @override
  List<Object?> get props => [alert];
}

class AlertMarkAsRead extends AlertsEvent {
  final String alertId;
  const AlertMarkAsRead(this.alertId);
  @override
  List<Object?> get props => [alertId];
}

class AlertResponseAdded extends AlertsEvent {
  final String alertId;
  final String response;
  const AlertResponseAdded(this.alertId, this.response);
  @override
  List<Object?> get props => [alertId, response];
}

abstract class AlertsState extends Equatable {
  const AlertsState();
  @override
  List<Object?> get props => [];
}

class AlertsInitial extends AlertsState {}

class AlertsLoading extends AlertsState {}

class AlertsLoaded extends AlertsState {
  final List<Alert> alerts;
  final int unreadCount;

  const AlertsLoaded({required this.alerts, required this.unreadCount});

  @override
  List<Object?> get props => [alerts, unreadCount];
}

class AlertsError extends AlertsState {
  final String message;
  const AlertsError(this.message);
}

class AlertsBloc extends Bloc<AlertsEvent, AlertsState> {
  final AlertsLocalDataSource dataSource;

  AlertsBloc({required this.dataSource}) : super(AlertsInitial()) {
    on<AlertsLoadRequested>(_onLoadRequested);
    on<AlertSent>(_onAlertSent);
    on<AlertMarkAsRead>(_onMarkAsRead);
    on<AlertResponseAdded>(_onResponseAdded);
  }

  Future<void> _onLoadRequested(
    AlertsLoadRequested event,
    Emitter<AlertsState> emit,
  ) async {
    emit(AlertsLoading());
    try {
      final alerts = await dataSource.getAllAlerts();
      final unread = await dataSource.getUnreadAlerts();
      emit(AlertsLoaded(alerts: alerts, unreadCount: unread.length));
    } catch (e) {
      emit(AlertsError(e.toString()));
    }
  }

  Future<void> _onAlertSent(
    AlertSent event,
    Emitter<AlertsState> emit,
  ) async {
    try {
      await dataSource.saveAlert(event.alert);
      add(AlertsLoadRequested());
    } catch (e) {
      emit(AlertsError(e.toString()));
    }
  }

  Future<void> _onMarkAsRead(
    AlertMarkAsRead event,
    Emitter<AlertsState> emit,
  ) async {
    try {
      await dataSource.markAsRead(event.alertId);
      add(AlertsLoadRequested());
    } catch (e) {
      emit(AlertsError(e.toString()));
    }
  }

  Future<void> _onResponseAdded(
    AlertResponseAdded event,
    Emitter<AlertsState> emit,
  ) async {
    try {
      await dataSource.addResponse(event.alertId, event.response);
      add(AlertsLoadRequested());
    } catch (e) {
      emit(AlertsError(e.toString()));
    }
  }
}
