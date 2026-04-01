import 'dart:async';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:equatable/equatable.dart';
import 'package:connectivity_plus/connectivity_plus.dart';

abstract class ConnectivityEvent extends Equatable {
  const ConnectivityEvent();
  @override
  List<Object?> get props => [];
}

class ConnectivityStarted extends ConnectivityEvent {}

class ConnectivityChanged extends ConnectivityEvent {
  final List<ConnectivityResult> result;
  const ConnectivityChanged(this.result);
  @override
  List<Object?> get props => [result];
}

abstract class ConnectivityState extends Equatable {
  const ConnectivityState();
  @override
  List<Object?> get props => [];
}

class ConnectivityInitial extends ConnectivityState {}

class ConnectivityOnline extends ConnectivityState {}

class ConnectivityOffline extends ConnectivityState {}

class ConnectivityBloc extends Bloc<ConnectivityEvent, ConnectivityState> {
  final Connectivity _connectivity = Connectivity();
  StreamSubscription<ConnectivityResult>? _subscription;

  ConnectivityBloc() : super(ConnectivityInitial()) {
    on<ConnectivityStarted>(_onStarted);
    on<ConnectivityChanged>(_onChanged);
  }

  Future<void> _onStarted(ConnectivityStarted event, Emitter<ConnectivityState> emit) async {
    final result = await _connectivity.checkConnectivity();
    _emitFromResult([result], emit);
    
    _subscription = _connectivity.onConnectivityChanged.listen((result) {
      add(ConnectivityChanged([result]));
    });
  }

  void _onChanged(ConnectivityChanged event, Emitter<ConnectivityState> emit) {
    _emitFromResult(event.result, emit);
  }

  void _emitFromResult(List<ConnectivityResult> result, Emitter<ConnectivityState> emit) {
    if (result.contains(ConnectivityResult.none) || result.isEmpty) {
      emit(ConnectivityOffline());
    } else {
      emit(ConnectivityOnline());
    }
  }

  @override
  Future<void> close() {
    _subscription?.cancel();
    return super.close();
  }
}
