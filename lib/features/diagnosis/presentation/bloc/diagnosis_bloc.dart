import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:equatable/equatable.dart';
import '../../domain/entities/diagnosis_result.dart';
import '../../domain/entities/crop_type.dart';
import '../../domain/usecases/analyze_image_usecase.dart';
import '../../domain/usecases/get_history_usecase.dart';
import '../../domain/usecases/save_diagnosis_usecase.dart';

abstract class DiagnosisEvent extends Equatable {
  const DiagnosisEvent();
  @override
  List<Object?> get props => [];
}

class DiagnosisAnalyzeRequested extends DiagnosisEvent {
  final String imagePath;
  final CropType cropType;
  final String? userId;
  const DiagnosisAnalyzeRequested(this.imagePath, {required this.cropType, this.userId});
  @override
  List<Object?> get props => [imagePath, cropType, userId];
}

class DiagnosisHistoryRequested extends DiagnosisEvent {
  final String? userId;
  const DiagnosisHistoryRequested({this.userId});
  @override
  List<Object?> get props => [userId];
}

class DiagnosisSaveRequested extends DiagnosisEvent {
  final DiagnosisResult result;
  const DiagnosisSaveRequested(this.result);
  @override
  List<Object?> get props => [result];
}

class DiagnosisReset extends DiagnosisEvent {}

abstract class DiagnosisState extends Equatable {
  const DiagnosisState();
  @override
  List<Object?> get props => [];
}

class DiagnosisInitial extends DiagnosisState {}

class DiagnosisLoading extends DiagnosisState {}

class DiagnosisAnalyzing extends DiagnosisState {
  final String imagePath;
  const DiagnosisAnalyzing(this.imagePath);
  @override
  List<Object?> get props => [imagePath];
}

class DiagnosisSuccess extends DiagnosisState {
  final DiagnosisResult result;
  const DiagnosisSuccess(this.result);
  @override
  List<Object?> get props => [result];
}

class DiagnosisHistoryLoaded extends DiagnosisState {
  final List<DiagnosisResult> history;
  const DiagnosisHistoryLoaded(this.history);
  @override
  List<Object?> get props => [history];
}

class DiagnosisError extends DiagnosisState {
  final String message;
  const DiagnosisError(this.message);
  @override
  List<Object?> get props => [message];
}

class DiagnosisBloc extends Bloc<DiagnosisEvent, DiagnosisState> {
  final AnalyzeImageUseCase analyzeImageUseCase;
  final GetHistoryUseCase getHistoryUseCase;
  final SaveDiagnosisUseCase saveDiagnosisUseCase;

  DiagnosisBloc({
    required this.analyzeImageUseCase,
    required this.getHistoryUseCase,
    required this.saveDiagnosisUseCase,
  }) : super(DiagnosisInitial()) {
    on<DiagnosisAnalyzeRequested>(_onAnalyzeRequested);
    on<DiagnosisHistoryRequested>(_onHistoryRequested);
    on<DiagnosisSaveRequested>(_onSaveRequested);
    on<DiagnosisReset>(_onReset);
  }

  Future<void> _onAnalyzeRequested(
    DiagnosisAnalyzeRequested event,
    Emitter<DiagnosisState> emit,
  ) async {
    emit(DiagnosisAnalyzing(event.imagePath));

    final result = await analyzeImageUseCase(event.imagePath, event.cropType);

    result.fold(
      (failure) => emit(DiagnosisError(failure.message)),
      (diagnosis) => emit(DiagnosisSuccess(diagnosis)),
    );
  }

  Future<void> _onHistoryRequested(
    DiagnosisHistoryRequested event,
    Emitter<DiagnosisState> emit,
  ) async {
    emit(DiagnosisLoading());

    final result = await getHistoryUseCase(event.userId);

    result.fold(
      (failure) => emit(DiagnosisError(failure.message)),
      (history) => emit(DiagnosisHistoryLoaded(history)),
    );
  }

  Future<void> _onSaveRequested(
    DiagnosisSaveRequested event,
    Emitter<DiagnosisState> emit,
  ) async {
    await saveDiagnosisUseCase(event.result);
  }

  void _onReset(
    DiagnosisReset event,
    Emitter<DiagnosisState> emit,
  ) {
    emit(DiagnosisInitial());
  }
}