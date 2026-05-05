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
      final diagnoses = diagnosisBox.values
          .whereType<Map>()
          .map(
            (item) => DiagnosisResult.fromMap(Map<String, dynamic>.from(item)),
          )
          .where((diagnosis) => userId == null || diagnosis.userId == userId)
          .toList();

      diagnoses.sort((a, b) => b.timestamp.compareTo(a.timestamp));
      return diagnoses.take(20).toList();
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
