import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../../core/error/failures.dart';
import '../../../diagnosis/domain/entities/diagnosis_category.dart';
import '../../domain/entities/disease_trend_card.dart';
import '../../domain/usecases/get_disease_trends_by_crop_usecase.dart';

// Events
abstract class DiseaseWatchEvent extends Equatable {
  const DiseaseWatchEvent();
  @override
  List<Object?> get props => [];
}

class LoadDiseaseWatchRequested extends DiseaseWatchEvent {
  final String cropType;

  const LoadDiseaseWatchRequested(this.cropType);

  @override
  List<Object?> get props => [cropType];
}

class FilterByCategoryRequested extends DiseaseWatchEvent {
  final DiagnosisCategory? category;

  const FilterByCategoryRequested(this.category);

  @override
  List<Object?> get props => [category];
}

class RefreshDiseaseWatchRequested extends DiseaseWatchEvent {
  final String cropType;

  const RefreshDiseaseWatchRequested(this.cropType);

  @override
  List<Object?> get props => [cropType];
}

// States
abstract class DiseaseWatchState extends Equatable {
  const DiseaseWatchState();
  @override
  List<Object?> get props => [];
}

class DiseaseWatchInitial extends DiseaseWatchState {}

class DiseaseWatchLoading extends DiseaseWatchState {}

class DiseaseWatchSuccess extends DiseaseWatchState {
  final List<DiseaseTrendCard> trends;
  final int totalReportMonth;
  final DiagnosisCategory? activeFilter;

  const DiseaseWatchSuccess({
    required this.trends,
    required this.totalReportMonth,
    this.activeFilter,
  });

  @override
  List<Object?> get props => [trends, totalReportMonth, activeFilter];
}

class DiseaseWatchEmpty extends DiseaseWatchState {
  final DiagnosisCategory? activeFilter;

  const DiseaseWatchEmpty({this.activeFilter});

  @override
  List<Object?> get props => [activeFilter];
}

class DiseaseWatchError extends DiseaseWatchState {
  final String message;

  const DiseaseWatchError(this.message);

  @override
  List<Object?> get props => [message];
}

// BLoC
class DiseaseWatchBloc extends Bloc<DiseaseWatchEvent, DiseaseWatchState> {
  final GetDiseaseTrendsByCropUseCase getDiseaseTrendsByCrop;

  String _currentCropType = '';
  DiagnosisCategory? _currentFilter;
  List<DiseaseTrendCard> _allTrends = [];

  DiseaseWatchBloc({required this.getDiseaseTrendsByCrop})
    : super(DiseaseWatchInitial()) {
    on<LoadDiseaseWatchRequested>(_onLoadDiseaseWatch);
    on<FilterByCategoryRequested>(_onFilterByCategory);
    on<RefreshDiseaseWatchRequested>(_onRefreshDiseaseWatch);
  }

  Future<void> _onLoadDiseaseWatch(
    LoadDiseaseWatchRequested event,
    Emitter<DiseaseWatchState> emit,
  ) async {
    emit(DiseaseWatchLoading());
    _currentCropType = event.cropType;
    _currentFilter = null;

    final result = await getDiseaseTrendsByCrop(
      _currentCropType,
      category: null,
      limitMonths: 1,
    );

    result.fold(
      (failure) {
        emit(DiseaseWatchError(_getErrorMessage(failure)));
      },
      (trends) {
        _allTrends = trends;
        if (trends.isEmpty) {
          emit(const DiseaseWatchEmpty());
        } else {
          emit(
            DiseaseWatchSuccess(
              trends: trends,
              totalReportMonth: trends.fold<int>(
                0,
                (sum, trend) => sum + trend.reportCount,
              ),
              activeFilter: null,
            ),
          );
        }
      },
    );
  }

  Future<void> _onFilterByCategory(
    FilterByCategoryRequested event,
    Emitter<DiseaseWatchState> emit,
  ) async {
    _currentFilter = event.category;

    if (_allTrends.isEmpty) {
      emit(DiseaseWatchEmpty(activeFilter: event.category));
      return;
    }

    // Filter existing trends by category
    List<DiseaseTrendCard> filtered;
    if (event.category == null) {
      filtered = _allTrends;
    } else {
      filtered = _allTrends.where((t) => t.category == event.category).toList();
    }

    if (filtered.isEmpty) {
      emit(DiseaseWatchEmpty(activeFilter: event.category));
    } else {
      emit(
        DiseaseWatchSuccess(
          trends: filtered,
          totalReportMonth: filtered.fold<int>(
            0,
            (sum, trend) => sum + trend.reportCount,
          ),
          activeFilter: event.category,
        ),
      );
    }
  }

  Future<void> _onRefreshDiseaseWatch(
    RefreshDiseaseWatchRequested event,
    Emitter<DiseaseWatchState> emit,
  ) async {
    emit(DiseaseWatchLoading());
    _currentCropType = event.cropType;

    final result = await getDiseaseTrendsByCrop(
      _currentCropType,
      category: null,
      limitMonths: 1,
    );

    result.fold(
      (failure) {
        emit(DiseaseWatchError(_getErrorMessage(failure)));
      },
      (trends) {
        _allTrends = trends;
        if (trends.isEmpty) {
          emit(const DiseaseWatchEmpty());
        } else {
          // Reapply filter if one was active
          List<DiseaseTrendCard> filtered;
          if (_currentFilter == null) {
            filtered = trends;
          } else {
            filtered = trends
                .where((t) => t.category == _currentFilter)
                .toList();
          }

          if (filtered.isEmpty) {
            emit(DiseaseWatchEmpty(activeFilter: _currentFilter));
          } else {
            emit(
              DiseaseWatchSuccess(
                trends: filtered,
                totalReportMonth: filtered.fold<int>(
                  0,
                  (sum, trend) => sum + trend.reportCount,
                ),
                activeFilter: _currentFilter,
              ),
            );
          }
        }
      },
    );
  }

  String _getErrorMessage(Failure failure) {
    if (failure is CacheFailure) {
      return 'Could not load disease reports. Please check your connection.';
    }
    if (failure is NetworkFailure) {
      return 'No internet connection. Showing cached data if available.';
    }
    return failure.message;
  }
}
