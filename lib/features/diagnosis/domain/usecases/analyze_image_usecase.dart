import 'dart:math';
import 'package:dartz/dartz.dart';
import '../../../../core/error/failures.dart';
import '../../domain/entities/diagnosis_result.dart';
import '../../domain/entities/crop_type.dart';

class AnalyzeImageUseCase {
  final Random _random = Random();

  Future<Either<Failure, DiagnosisResult>> call(
    String imagePath,
    CropType cropType,
  ) async {
    try {
      await Future.delayed(const Duration(seconds: 2));

      return Right(_getCropSpecificResult(imagePath, cropType));
    } catch (e) {
      return Left(ServerFailure(e.toString()));
    }
  }

  DiagnosisResult _getCropSpecificResult(String imagePath, CropType cropType) {
    final diagnosisData = _getDiagnosisForCrop(cropType);

    return DiagnosisResult(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      imagePath: imagePath,
      type: diagnosisData.type,
      diagnosisName: diagnosisData.name,
      diagnosisNameChichewa: diagnosisData.nameChichewa,
      confidence: diagnosisData.confidence,
      severity: diagnosisData.severity,
      recommendation: diagnosisData.recommendation,
      treatment: diagnosisData.treatment,
      prevention: diagnosisData.prevention,
      timestamp: DateTime.now(),
      cropType: cropType,
      scientificName: diagnosisData.scientificName,
      causingFactors: diagnosisData.causingFactors,
      pesticideRemedy: diagnosisData.pesticideRemedy,
    );
  }

  _DiagnosisData _getDiagnosisForCrop(CropType cropType) {
    switch (cropType) {
      case CropType.maize:
        return _getMaizeDiagnosis();
      case CropType.cassava:
        return _getCassavaDiagnosis();
      case CropType.tomato:
        return _getTomatoDiagnosis();
    }
  }

  _DiagnosisData _getMaizeDiagnosis() {
    final diagnoses = [
      _DiagnosisData(
        type: DiagnosisType.healthy,
        name: 'Healthy Maize',
        nameChichewa: 'Mgamula Yauchipuka',
        confidence: 0.85,
        severity: Severity.low,
        recommendation:
            'Your maize crop is healthy! Continue with regular watering and monitoring.',
        treatment: null,
        prevention: 'Continue with good agricultural practices.',
        scientificName: null,
        causingFactors: null,
        pesticideRemedy: null,
      ),
      _DiagnosisData(
        type: DiagnosisType.disease,
        name: 'Northern Leaf Blight',
        nameChichewa: 'Matenda a Mphepete',
        confidence: 0.78,
        severity: Severity.medium,
        recommendation: 'Consider applying fungicide to prevent spread.',
        treatment: 'Apply Mancozeb or Chlorothalonil fungicide.',
        prevention: 'Use resistant varieties and crop rotation.',
        scientificName: 'Exserohilum turcicum',
        causingFactors:
            'High humidity, warm temperatures, continuous maize cropping.',
        pesticideRemedy: 'Mancozeb 80% WP - 2.5kg/ha',
      ),
      _DiagnosisData(
        type: DiagnosisType.disease,
        name: 'Maize Streak Virus',
        nameChichewa: 'Matenda ya Mphepete',
        confidence: 0.72,
        severity: Severity.high,
        recommendation: 'Remove infected plants to prevent spread.',
        treatment: 'No direct treatment. Remove and destroy infected plants.',
        prevention: 'Use certified virus-free seeds, control leafhoppers.',
        scientificName: 'Maize Streak Virus (MSV)',
        causingFactors: 'Transmitted by leafhoppers, warm dry conditions.',
        pesticideRemedy: 'Imidacloprid for leafhopper control',
      ),
      _DiagnosisData(
        type: DiagnosisType.pest,
        name: 'Fall Armyworm',
        nameChichewa: 'Khumani Wabwino',
        confidence: 0.82,
        severity: Severity.high,
        recommendation: 'Act immediately to prevent crop loss.',
        treatment: 'Apply Spinosad or Flubendiamide.',
        prevention: 'Early planting, crop rotation, intercropping.',
        scientificName: 'Spodoptera frugiperda',
        causingFactors: 'Dry conditions, late planting, monocropping.',
        pesticideRemedy:
            'Spinosad 48% SC - 150ml/ha or Flubendiamide 480 SC - 50ml/ha',
      ),
      _DiagnosisData(
        type: DiagnosisType.deficiency,
        name: 'Nitrogen Deficiency',
        nameChichewa: 'Vuto LA Azoti',
        confidence: 0.75,
        severity: Severity.medium,
        recommendation: 'Apply nitrogen fertilizer to correct deficiency.',
        treatment: 'Apply Urea or CAN fertilizer.',
        prevention:
            'Soil testing, balanced fertilization, crop rotation with legumes.',
        scientificName: null,
        causingFactors: 'Leaching, heavy rainfall, poor soil fertility.',
        pesticideRemedy:
            'Urea (46% N) - 100-150 kg/ha or CAN (26% N) - 200 kg/ha',
      ),
    ];

    return diagnoses[_random.nextInt(diagnoses.length)];
  }

  _DiagnosisData _getCassavaDiagnosis() {
    final diagnoses = [
      _DiagnosisData(
        type: DiagnosisType.healthy,
        name: 'Healthy Cassava',
        nameChichewa: 'Chikanda Chauchipuka',
        confidence: 0.88,
        severity: Severity.low,
        recommendation:
            'Your cassava crop is healthy! Continue with regular monitoring.',
        treatment: null,
        prevention: 'Continue with good agricultural practices.',
        scientificName: null,
        causingFactors: null,
        pesticideRemedy: null,
      ),
      _DiagnosisData(
        type: DiagnosisType.disease,
        name: 'Cassava Mosaic Disease',
        nameChichewa: 'Matenda ya Chikanda',
        confidence: 0.80,
        severity: Severity.high,
        recommendation: 'Remove infected plants immediately.',
        treatment: 'No cure. Remove and destroy infected plants.',
        prevention: 'Use resistant varieties, plant disease-free cuttings.',
        scientificName: 'Cassava Mosaic Virus (CMV)',
        causingFactors:
            'Whitefly transmission, using infected planting material.',
        pesticideRemedy: 'No pesticide. Use resistant variety TME 14 or 419.',
      ),
      _DiagnosisData(
        type: DiagnosisType.disease,
        name: 'Cassava Brown Streak Disease',
        nameChichewa: 'Matenda a Mtsinje wa Chikanda',
        confidence: 0.74,
        severity: Severity.high,
        recommendation: 'Remove infected plants to prevent spread.',
        treatment: 'No cure. Remove and destroy infected plants.',
        prevention: 'Use clean planting material from certified sources.',
        scientificName: 'Cassava Brown Streak Virus (CBSV)',
        causingFactors:
            'Whitefly transmission, poor quality planting material.',
        pesticideRemedy: 'Control whitefly with imidacloprid.',
      ),
      _DiagnosisData(
        type: DiagnosisType.pest,
        name: 'Cassava Green Mite',
        nameChichewa: 'Khumani wa Chikanda',
        confidence: 0.71,
        severity: Severity.medium,
        recommendation: 'Monitor and apply miticide if severe.',
        treatment: 'Apply sulfur-based miticides.',
        prevention: 'Use resistant varieties, early planting.',
        scientificName: 'Mononychellus tanajoa',
        causingFactors: 'Dry conditions, late planting.',
        pesticideRemedy: 'Sulfur 80% WDG - 2-3 kg/ha',
      ),
      _DiagnosisData(
        type: DiagnosisType.deficiency,
        name: 'Potassium Deficiency',
        nameChichewa: 'Vuto LA Potassium',
        confidence: 0.68,
        severity: Severity.medium,
        recommendation: 'Apply potassium fertilizer.',
        treatment: 'Apply Muriate of Potash or sulfate of potash.',
        prevention: 'Balanced fertilization, use of compost.',
        scientificName: null,
        causingFactors: 'Leaching, sandy soils, heavy rainfall.',
        pesticideRemedy: 'MOP (60% K2O) - 100-150 kg/ha',
      ),
    ];

    return diagnoses[_random.nextInt(diagnoses.length)];
  }

  _DiagnosisData _getTomatoDiagnosis() {
    final diagnoses = [
      _DiagnosisData(
        type: DiagnosisType.healthy,
        name: 'Healthy Tomato',
        nameChichewa: 'Tomato Yauchipuka',
        confidence: 0.90,
        severity: Severity.low,
        recommendation: 'Your tomato crop is healthy! Keep up the good work.',
        treatment: null,
        prevention: 'Continue regular watering and monitor for pests.',
        scientificName: null,
        causingFactors: null,
        pesticideRemedy: null,
      ),
      _DiagnosisData(
        type: DiagnosisType.disease,
        name: 'Bacterial Wilt',
        nameChichewa: 'Matenda ya Bacterial',
        confidence: 0.76,
        severity: Severity.high,
        recommendation: 'Remove infected plants immediately.',
        treatment:
            'No effective treatment. Remove and destroy infected plants.',
        prevention:
            'Crop rotation, use resistant varieties, avoid overwatering.',
        scientificName: 'Ralstonia solanacearum',
        causingFactors: 'Warm temperatures, high soil moisture, poor drainage.',
        pesticideRemedy: 'No effective pesticide. Use resistant varieties.',
      ),
      _DiagnosisData(
        type: DiagnosisType.disease,
        name: 'Tomato Blight',
        nameChichewa: 'Matenda ya Tomato',
        confidence: 0.82,
        severity: Severity.high,
        recommendation: 'Apply fungicide immediately.',
        treatment: 'Apply Mancozeb or Copper-based fungicide.',
        prevention:
            'Good spacing, avoid overhead irrigation, remove infected leaves.',
        scientificName: 'Phytophthora infestans',
        causingFactors: 'Cool wet conditions, high humidity.',
        pesticideRemedy:
            'Mancozeb 80% WP - 2.5 kg/ha or Copper Oxychloride 50% WP - 3 kg/ha',
      ),
      _DiagnosisData(
        type: DiagnosisType.disease,
        name: 'Tomato Yellow Leaf Curl Virus',
        nameChichewa: 'Matenda ya Mitu Yatsala',
        confidence: 0.73,
        severity: Severity.high,
        recommendation: 'Control whitefly to prevent spread.',
        treatment: 'No cure. Remove infected plants.',
        prevention: 'Use yellow sticky traps, control whitefly.',
        scientificName: 'Tomato Yellow Leaf Curl Virus (TYLCV)',
        causingFactors: 'Whitefly transmission, late planting.',
        pesticideRemedy: 'Imidacloprid 70% WG - 70g/ha for whitefly control',
      ),
      _DiagnosisData(
        type: DiagnosisType.pest,
        name: 'Tomato Fruitworm',
        nameChichewa: 'Khumani wa Tomato',
        confidence: 0.79,
        severity: Severity.medium,
        recommendation: 'Apply insecticide to control larvae.',
        treatment: 'Apply Lambda-cyhalothrin or Spinosad.',
        prevention: 'Crop rotation, hand-pick larvae, use traps.',
        scientificName: 'Helicoverpa armigera',
        causingFactors: 'Warm weather, presence of flowers and fruits.',
        pesticideRemedy:
            'Lambda-cyhalothrin 5% EC - 300 ml/ha or Spinosad 48% SC - 150 ml/ha',
      ),
      _DiagnosisData(
        type: DiagnosisType.deficiency,
        name: 'Calcium Deficiency (Blossom End Rot)',
        nameChichewa: 'Vuto LA Calcium',
        confidence: 0.81,
        severity: Severity.medium,
        recommendation: 'Apply calcium fertilizer and adjust watering.',
        treatment: 'Foliar spray with calcium nitrate.',
        prevention: 'Consistent watering, add lime to soil.',
        scientificName: null,
        causingFactors: 'Irregular watering, calcium deficiency in soil.',
        pesticideRemedy: 'Calcium nitrate foliar spray - 2%',
      ),
    ];

    return diagnoses[_random.nextInt(diagnoses.length)];
  }
}

class _DiagnosisData {
  final DiagnosisType type;
  final String name;
  final String nameChichewa;
  final double confidence;
  final Severity severity;
  final String? recommendation;
  final String? treatment;
  final String? prevention;
  final String? scientificName;
  final String? causingFactors;
  final String? pesticideRemedy;

  _DiagnosisData({
    required this.type,
    required this.name,
    required this.nameChichewa,
    required this.confidence,
    required this.severity,
    this.recommendation,
    this.treatment,
    this.prevention,
    this.scientificName,
    this.causingFactors,
    this.pesticideRemedy,
  });
}
