import 'dart:math';
import 'package:dartz/dartz.dart';
import '../error/failures.dart';
import '../../features/diagnosis/domain/entities/diagnosis_result.dart';
import '../../features/diagnosis/domain/entities/crop_type.dart';
import 'diagnosis_service.dart';

class MockDiagnosisService implements DiagnosisService {
  final Random _random = Random();
  bool _isModelLoaded = true;

  @override
  Future<Either<Failure, DiagnosisResult>> analyzeImage(
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

  @override
  Future<Either<Failure, bool>> isModelLoaded() async {
    return Right(_isModelLoaded);
  }

  @override
  Future<void> dispose() async {
    _isModelLoaded = false;
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
      recommendation: diagnosisData.recommendationEn,
      treatment: diagnosisData.treatmentEn,
      prevention: diagnosisData.preventionEn,
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
        nameChichewa: 'Mphesa Yauchipuka',
        confidence: 0.85,
        severity: Severity.low,
        recommendationEn: 'Your maize crop is healthy! Continue with regular care.',
        recommendationChichewa: 'Mphesa yanu ili yauchipuka! Pitirizani kuteteza.',
        treatmentEn: null,
        treatmentChichewa: null,
        preventionEn: 'Continue with good agricultural practices.',
        preventionChichewa: 'Pitirizani kuchita bwino.',
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
        recommendationEn: 'Consider applying fungicide to prevent spread.',
        recommendationChichewa: 'Funsani fungicide kuti muteteze kusasula.',
        treatmentEn: 'Apply Mancozeb or Chlorothalonil fungicide.',
        treatmentChichewa: 'Gulitsani Mancozebu kapena Chlorothalonili.',
        preventionEn: 'Use resistant varieties and crop rotation.',
        preventionChichewa: 'Gulitsani mbewu zolimba ndi kugwiritsa ntchito mizere.',
        scientificName: 'Exserohilum turcicum',
        causingFactors: 'High humidity, warm temperatures, continuous maize cropping.',
        pesticideRemedy: 'Mancozeb 80% WP - 2.5kg/ha',
      ),
      _DiagnosisData(
        type: DiagnosisType.disease,
        name: 'Maize Streak Virus',
        nameChichewa: 'Matenda ya Mphepete',
        confidence: 0.72,
        severity: Severity.high,
        recommendationEn: 'Remove infected plants to prevent spread.',
        recommendationChichewa: 'Chotsani zizizngo zopatsidwa matenda.',
        treatmentEn: 'No direct treatment. Remove and destroy infected plants.',
        treatmentChichewa: 'Palibe chikalata. Chotsani ndi kuvunda zizizngo.',
        preventionEn: 'Use certified virus-free seeds, control leafhoppers.',
        preventionChichewa: 'Gulitsani mbewu zosapatsidwa matenda, tanga makwangapi.',
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
        recommendationEn: 'Act immediately to prevent crop loss.',
        recommendationChichewa: 'Chitani chisangalatsi kuti muchepetse kupedzeka.',
        treatmentEn: 'Apply Spinosad or Flubendiamide.',
        treatmentChichewa: 'Gulitsani Spinosadi kapena Flubendiamide.',
        preventionEn: 'Early planting, crop rotation, intercropping.',
        preventionChichewa: 'Kolanani mphesa yayitali, sinthani mbeu, sindikizani.',
        scientificName: 'Spodoptera frugiperda',
        causingFactors: 'Dry conditions, late planting, monocropping.',
        pesticideRemedy: 'Spinosad 48% SC - 150ml/ha',
      ),
      _DiagnosisData(
        type: DiagnosisType.deficiency,
        name: 'Nitrogen Deficiency',
        nameChichewa: 'Vuto LA Azoti',
        confidence: 0.75,
        severity: Severity.medium,
        recommendationEn: 'Apply nitrogen fertilizer to correct deficiency.',
        recommendationChichewa: 'Gulitsani feteleza ya Azoti.',
        treatmentEn: 'Apply Urea or CAN fertilizer.',
        treatmentChichewa: 'Gulitsani Urea kapena CAN.',
        preventionEn: 'Soil testing, balanced fertilization.',
        preventionChichewa: 'Pangani pemosi, gulitsani feteleza yoyimirirana.',
        scientificName: null,
        causingFactors: 'Leaching, heavy rainfall, poor soil fertility.',
        pesticideRemedy: 'Urea (46% N) - 100-150 kg/ha',
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
        recommendationEn: 'Your cassava crop is healthy! Continue with regular monitoring.',
        recommendationChichewa: 'Chikanda chanu chili chauchipuka! Pitirizani kuchita bwino.',
        treatmentEn: null,
        treatmentChichewa: null,
        preventionEn: 'Continue with good agricultural practices.',
        preventionChichewa: 'Pitirizani kuchita bwino.',
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
        recommendationEn: 'Remove infected plants immediately.',
        recommendationChichewa: 'Chotsani zizizngo zopatsidwa.',
        treatmentEn: 'No cure. Remove and destroy infected plants.',
        treatmentChichewa: 'Palibe chikalata. Chotsani ndi kuvunda.',
        preventionEn: 'Use resistant varieties, plant disease-free cuttings.',
        preventionChichewa: 'Gulitsani mbewu zolimba, sankhani mbewu zosadwala.',
        scientificName: 'Cassava Mosaic Virus (CMV)',
        causingFactors: 'Whitefly transmission, using infected planting material.',
        pesticideRemedy: 'No pesticide. Use resistant variety TME 14.',
      ),
      _DiagnosisData(
        type: DiagnosisType.disease,
        name: 'Cassava Brown Streak Disease',
        nameChichewa: 'Matenda ya Mtsogolo',
        confidence: 0.74,
        severity: Severity.high,
        recommendationEn: 'Remove infected plants to prevent spread.',
        recommendationChichewa: 'Chotsani zizizngo kuti zisasefe.',
        treatmentEn: 'No cure. Remove and destroy infected plants.',
        treatmentChichewa: 'Palibe chikalata. Chotsani ndi kuvunda.',
        preventionEn: 'Use clean planting material from certified sources.',
        preventionChichewa: 'Gulitsani mbewu zoyera kuchokera ku malo otetezedwa.',
        scientificName: 'Cassava Brown Streak Virus (CBSV)',
        causingFactors: 'Whitefly transmission, poor quality planting material.',
        pesticideRemedy: 'Control whitefly with imidacloprid.',
      ),
      _DiagnosisData(
        type: DiagnosisType.pest,
        name: 'Cassava Green Mite',
        nameChichewa: 'Khumani wa Chikanda',
        confidence: 0.71,
        severity: Severity.medium,
        recommendationEn: 'Monitor and apply miticide if severe.',
        recommendationChichewa: 'Yang\'anani ndikagwiritsa ntchito miticide.',
        treatmentEn: 'Apply sulfur-based miticides.',
        treatmentChichewa: 'Gulitsani sulfur-based miticides.',
        preventionEn: 'Use resistant varieties, early planting.',
        preventionChichewa: 'Gulitsani mbewu zolimba, kukanika nthawi.',
        scientificName: 'Mononychellus tanajoa',
        causingFactors: 'Dry conditions, late planting.',
        pesticideRemedy: 'Sulfur 80% WDG - 2-3 kg/ha',
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
        recommendationEn: 'Your tomato crop is healthy! Keep up the good work.',
        recommendationChichewa: 'Tomato yanu ili yauchipuka! Pitirizani kuteteza.',
        treatmentEn: null,
        treatmentChichewa: null,
        preventionEn: 'Continue regular watering and monitor for pests.',
        preventionChichewa: 'Pitirizani kuteteza ndi kuyang\'ana.',
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
        recommendationEn: 'Remove infected plants immediately.',
        recommendationChichewa: 'Chotsani zizizngo zopatsidwa.',
        treatmentEn: 'No effective treatment. Remove and destroy infected plants.',
        treatmentChichewa: 'Palibe chikalata. Chotsani ndi kuvunda.',
        preventionEn: 'Crop rotation, use resistant varieties.',
        preventionChichewa: 'Sindikizani, gulitsani mbewu zolimba.',
        scientificName: 'Ralstonia solanacearum',
        causingFactors: 'Warm temperatures, high soil moisture.',
        pesticideRemedy: 'No effective pesticide. Use resistant varieties.',
      ),
      _DiagnosisData(
        type: DiagnosisType.disease,
        name: 'Tomato Blight',
        nameChichewa: 'Matenda ya Tomato',
        confidence: 0.82,
        severity: Severity.high,
        recommendationEn: 'Apply fungicide immediately.',
        recommendationChichewa: 'Gulitsani fungicide nthawi yambiri.',
        treatmentEn: 'Apply Mancozeb or Copper-based fungicide.',
        treatmentChichewa: 'Gulitsani Mancozebi kapena fungicide ya Copper.',
        preventionEn: 'Good spacing, avoid overhead irrigation.',
        preventionChichewa: 'Chotsani maguwa opatsidwa, chichani pansi.',
        scientificName: 'Phytophthora infestans',
        causingFactors: 'Cool wet conditions, high humidity.',
        pesticideRemedy: 'Mancozeb 80% WP - 2.5 kg/ha',
      ),
      _DiagnosisData(
        type: DiagnosisType.pest,
        name: 'Tomato Fruitworm',
        nameChichewa: 'Khumani wa Tomato',
        confidence: 0.79,
        severity: Severity.medium,
        recommendationEn: 'Apply insecticide to control larvae.',
        recommendationChichewa: 'Gulitsani insecticides kuti muteteze.',
        treatmentEn: 'Apply Lambda-cyhalothrin or Spinosad.',
        treatmentChichewa: 'Gulitsani Lambda-cyhalothrin kapena Spinosad.',
        preventionEn: 'Crop rotation, hand-pick larvae.',
        preventionChichewa: 'Sindikizani, chotsani anyani.',
        scientificName: 'Helicoverpa armigera',
        causingFactors: 'Warm weather, presence of flowers and fruits.',
        pesticideRemedy: 'Lambda-cyhalothrin 5% EC - 300 ml/ha',
      ),
      _DiagnosisData(
        type: DiagnosisType.deficiency,
        name: 'Calcium Deficiency',
        nameChichewa: 'Vuto LA Calcium',
        confidence: 0.81,
        severity: Severity.medium,
        recommendationEn: 'Apply calcium fertilizer and adjust watering.',
        recommendationChichewa: 'Gulitsani feteleza ya Calcium.',
        treatmentEn: 'Foliar spray with calcium nitrate.',
        treatmentChichewa: 'Gulitsani calcium nitrate ya mphamvu.',
        preventionEn: 'Consistent watering, add lime to soil.',
        preventionChichewa: 'Madzi osakayika, onjezerani nthaka.',
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
  final String? recommendationEn;
  final String? recommendationChichewa;
  final String? treatmentEn;
  final String? treatmentChichewa;
  final String? preventionEn;
  final String? preventionChichewa;
  final String? scientificName;
  final String? causingFactors;
  final String? pesticideRemedy;

  _DiagnosisData({
    required this.type,
    required this.name,
    required this.nameChichewa,
    required this.confidence,
    required this.severity,
    this.recommendationEn,
    this.recommendationChichewa,
    this.treatmentEn,
    this.treatmentChichewa,
    this.preventionEn,
    this.preventionChichewa,
    this.scientificName,
    this.causingFactors,
    this.pesticideRemedy,
  });
}
