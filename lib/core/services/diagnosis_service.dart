import 'package:dartz/dartz.dart';
import '../error/failures.dart';
import '../../features/diagnosis/domain/entities/diagnosis_result.dart';
import '../../features/diagnosis/domain/entities/crop_type.dart';
import 'mock_diagnosis_service.dart';

abstract class DiagnosisService {
  Future<Either<Failure, DiagnosisResult>> analyzeImage(
    String imagePath,
    CropType cropType,
  );
  
  Future<Either<Failure, bool>> isModelLoaded();
  
  Future<void> dispose();
}

class DiagnosisServiceFactory {
  static DiagnosisService create() {
    return MockDiagnosisService();
  }
}
