import 'package:hive/hive.dart';
import '../../domain/entities/diagnosis_result.dart';

abstract class DiagnosisLocalDataSource {
  Future<List<DiagnosisResult>> getHistory(String? userId);
  Future<DiagnosisResult> saveDiagnosis(DiagnosisResult result);
  Future<void> deleteDiagnosis(String id);
}

class DiagnosisLocalDataSourceImpl implements DiagnosisLocalDataSource {
  final Box diagnosisBox;

  DiagnosisLocalDataSourceImpl(this.diagnosisBox);

  @override
  Future<List<DiagnosisResult>> getHistory(String? userId) async {
    try {
      final allDiagnoses = diagnosisBox.values.toList();
      final diagnoses = <DiagnosisResult>[];
      
      for (final item in allDiagnoses) {
        if (item is Map) {
          final diagnosis = DiagnosisResult.fromMap(Map<String, dynamic>.from(item));
          if (userId == null || diagnosis.userId == userId) {
            diagnoses.add(diagnosis);
          }
        }
      }
      
      // Sort by date, most recent first
      diagnoses.sort((a, b) => b.timestamp.compareTo(a.timestamp));
      return diagnoses;
    } catch (e) {
      return [];
    }
  }

  @override
  Future<DiagnosisResult> saveDiagnosis(DiagnosisResult result) async {
    await diagnosisBox.put(result.id, result.toMap());
    return result;
  }

  @override
  Future<void> deleteDiagnosis(String id) async {
    await diagnosisBox.delete(id);
  }
}