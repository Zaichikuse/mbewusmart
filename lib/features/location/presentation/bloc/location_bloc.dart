import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:geolocator/geolocator.dart';
import 'package:equatable/equatable.dart';
import '../../domain/entities/location_info.dart';
import '../../domain/entities/extension_officer.dart';
import '../../domain/entities/agro_dealer.dart';
import '../../domain/usecases/get_current_location.dart';
import '../../domain/usecases/get_nearest_extension_officer.dart';
import '../../domain/usecases/get_nearest_agro_dealer.dart';

abstract class LocationEvent extends Equatable {
  const LocationEvent();
  @override
  List<Object?> get props => [];
}

class LocationGetCurrent extends LocationEvent {}

class LocationFindNearestOfficer extends LocationEvent {
  final double latitude;
  final double longitude;
  const LocationFindNearestOfficer(this.latitude, this.longitude);
  @override
  List<Object?> get props => [latitude, longitude];
}

class LocationFindNearestDealer extends LocationEvent {
  final double latitude;
  final double longitude;
  const LocationFindNearestDealer(this.latitude, this.longitude);
  @override
  List<Object?> get props => [latitude, longitude];
}

abstract class LocationState extends Equatable {
  const LocationState();
  @override
  List<Object?> get props => [];
}

class LocationInitial extends LocationState {}

class LocationLoading extends LocationState {}

class LocationLoaded extends LocationState {
  final LocationInfo location;
  final ExtensionOfficer? nearestOfficer;
  final AgroDealer? nearestDealer;

  const LocationLoaded({
    required this.location,
    this.nearestOfficer,
    this.nearestDealer,
  });

  LocationLoaded copyWith({
    LocationInfo? location,
    ExtensionOfficer? nearestOfficer,
    AgroDealer? nearestDealer,
  }) {
    return LocationLoaded(
      location: location ?? this.location,
      nearestOfficer: nearestOfficer ?? this.nearestOfficer,
      nearestDealer: nearestDealer ?? this.nearestDealer,
    );
  }

  @override
  List<Object?> get props => [location, nearestOfficer, nearestDealer];
}

class LocationError extends LocationState {
  final String message;
  const LocationError(this.message);
}

class LocationBloc extends Bloc<LocationEvent, LocationState> {
  final GetCurrentLocationUseCase getCurrentLocation;
  final GetNearestExtensionOfficerUseCase getNearestExtensionOfficer;
  final GetNearestAgroDealerUseCase getNearestAgroDealer;

  LocationBloc({
    required this.getCurrentLocation,
    required this.getNearestExtensionOfficer,
    required this.getNearestAgroDealer,
  }) : super(LocationInitial()) {
    on<LocationGetCurrent>(_onGetCurrent);
    on<LocationFindNearestOfficer>(_onFindNearestOfficer);
    on<LocationFindNearestDealer>(_onFindNearestDealer);
  }

  Future<void> _onGetCurrent(
    LocationGetCurrent event,
    Emitter<LocationState> emit,
  ) async {
    emit(LocationLoading());

    final permission = await Geolocator.checkPermission();
    final requestedPermission =
        permission == LocationPermission.denied ||
            permission == LocationPermission.deniedForever
        ? await Geolocator.requestPermission()
        : permission;

    if (requestedPermission == LocationPermission.denied ||
        requestedPermission == LocationPermission.deniedForever) {
      emit(const LocationError('Location permission denied'));
      return;
    }

    final result = await getCurrentLocation();

    result.fold((failure) => emit(LocationError(failure.message)), (
      location,
    ) async {
      // Also find nearest officer and dealer
      final officerResult = await getNearestExtensionOfficer(
        location.latitude,
        location.longitude,
      );
      final dealerResult = await getNearestAgroDealer(
        location.latitude,
        location.longitude,
      );

      emit(
        LocationLoaded(
          location: location,
          nearestOfficer: officerResult.fold((l) => null, (r) => r),
          nearestDealer: dealerResult.fold((l) => null, (r) => r),
        ),
      );
    });
  }

  Future<void> _onFindNearestOfficer(
    LocationFindNearestOfficer event,
    Emitter<LocationState> emit,
  ) async {
    if (state is LocationLoaded) {
      final currentState = state as LocationLoaded;
      final result = await getNearestExtensionOfficer(
        event.latitude,
        event.longitude,
      );

      result.fold(
        (failure) => null,
        (officer) => emit(currentState.copyWith(nearestOfficer: officer)),
      );
    }
  }

  Future<void> _onFindNearestDealer(
    LocationFindNearestDealer event,
    Emitter<LocationState> emit,
  ) async {
    if (state is LocationLoaded) {
      final currentState = state as LocationLoaded;
      final result = await getNearestAgroDealer(
        event.latitude,
        event.longitude,
      );

      result.fold(
        (failure) => null,
        (dealer) => emit(currentState.copyWith(nearestDealer: dealer)),
      );
    }
  }
}
