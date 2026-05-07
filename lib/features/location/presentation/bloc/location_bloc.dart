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

    // Step 1: Permission check
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

    // Step 2: Verify location services are enabled
    final serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      emit(
        const LocationError(
          'Location services are turned off. Please enable GPS.',
        ),
      );
      return;
    }

    // Step 3: Get current location (await fully — no nested callbacks)
    final result = await getCurrentLocation();

    // FIX: Properly await both arms of the fold instead of using
    // a fire-and-forget async closure inside fold().
    final LocationInfo? location = result.fold((failure) => null, (loc) => loc);

    if (location == null) {
      final failureMessage = result.fold(
        (failure) => failure.message,
        (_) => 'Could not get location',
      );
      emit(LocationError(failureMessage));
      return;
    }

    // Step 4: Find nearest officer and dealer (sequential awaits)
    final officerResult = await getNearestExtensionOfficer(
      location.latitude,
      location.longitude,
    );
    final dealerResult = await getNearestAgroDealer(
      location.latitude,
      location.longitude,
    );

    // Step 5: Emit final state — guarded against handler completion
    if (emit.isDone) return;

    emit(
      LocationLoaded(
        location: location,
        nearestOfficer: officerResult.fold((l) => null, (r) => r),
        nearestDealer: dealerResult.fold((l) => null, (r) => r),
      ),
    );
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

      if (emit.isDone) return;

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

      if (emit.isDone) return;

      result.fold(
        (failure) => null,
        (dealer) => emit(currentState.copyWith(nearestDealer: dealer)),
      );
    }
  }
}
