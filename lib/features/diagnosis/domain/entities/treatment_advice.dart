import 'package:equatable/equatable.dart';

class TreatmentAdvice extends Equatable {
  final String id;
  final String diagnosisId;
  final String treatmentEn;
  final String treatmentChichewa;
  final String preventionEn;
  final String preventionChichewa;
  final String pesticideName;
  final String pesticideDosage;
  final String applicationMethod;
  final int daysToReentry;
  final String? imageUrl;
  final DateTime createdAt;

  const TreatmentAdvice({
    required this.id,
    required this.diagnosisId,
    required this.treatmentEn,
    required this.treatmentChichewa,
    required this.preventionEn,
    required this.preventionChichewa,
    required this.pesticideName,
    required this.pesticideDosage,
    required this.applicationMethod,
    required this.daysToReentry,
    this.imageUrl,
    required this.createdAt,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'diagnosisId': diagnosisId,
      'treatmentEn': treatmentEn,
      'treatmentChichewa': treatmentChichewa,
      'preventionEn': preventionEn,
      'preventionChichewa': preventionChichewa,
      'pesticideName': pesticideName,
      'pesticideDosage': pesticideDosage,
      'applicationMethod': applicationMethod,
      'daysToReentry': daysToReentry,
      'imageUrl': imageUrl,
      'createdAt': createdAt.toIso8601String(),
    };
  }

  factory TreatmentAdvice.fromMap(Map<String, dynamic> map) {
    return TreatmentAdvice(
      id: map['id'] ?? '',
      diagnosisId: map['diagnosisId'] ?? '',
      treatmentEn: map['treatmentEn'] ?? '',
      treatmentChichewa: map['treatmentChichewa'] ?? '',
      preventionEn: map['preventionEn'] ?? '',
      preventionChichewa: map['preventionChichewa'] ?? '',
      pesticideName: map['pesticideName'] ?? '',
      pesticideDosage: map['pesticideDosage'] ?? '',
      applicationMethod: map['applicationMethod'] ?? '',
      daysToReentry: map['daysToReentry'] ?? 0,
      imageUrl: map['imageUrl'],
      createdAt: DateTime.tryParse(map['createdAt'] ?? '') ?? DateTime.now(),
    );
  }

  String getLocalizedTreatment(bool isChichewa) {
    return isChichewa ? treatmentChichewa : treatmentEn;
  }

  String getLocalizedPrevention(bool isChichewa) {
    return isChichewa ? preventionChichewa : preventionEn;
  }

  @override
  List<Object?> get props => [
        id,
        diagnosisId,
        treatmentEn,
        treatmentChichewa,
        preventionEn,
        preventionChichewa,
        pesticideName,
        pesticideDosage,
        applicationMethod,
        daysToReentry,
        imageUrl,
        createdAt,
      ];
}
