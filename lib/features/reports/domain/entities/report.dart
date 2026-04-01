import 'package:equatable/equatable.dart';

enum ReportType {
  monthly,
  weekly,
  quarterly,
  annual,
  custom,
}

class Report extends Equatable {
  final String id;
  final String userId;
  final ReportType type;
  final DateTime startDate;
  final DateTime endDate;
  final int totalDiagnoses;
  final int diseaseCount;
  final int pestCount;
  final int deficiencyCount;
  final int healthyCount;
  final Map<String, int> cropDistribution;
  final Map<String, int> districtDistribution;
  final String? generatedBy;
  final DateTime generatedAt;
  final bool isSynced;

  const Report({
    required this.id,
    required this.userId,
    required this.type,
    required this.startDate,
    required this.endDate,
    required this.totalDiagnoses,
    required this.diseaseCount,
    required this.pestCount,
    required this.deficiencyCount,
    required this.healthyCount,
    required this.cropDistribution,
    required this.districtDistribution,
    this.generatedBy,
    required this.generatedAt,
    this.isSynced = false,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'userId': userId,
      'type': type.name,
      'startDate': startDate.toIso8601String(),
      'endDate': endDate.toIso8601String(),
      'totalDiagnoses': totalDiagnoses,
      'diseaseCount': diseaseCount,
      'pestCount': pestCount,
      'deficiencyCount': deficiencyCount,
      'healthyCount': healthyCount,
      'cropDistribution': cropDistribution,
      'districtDistribution': districtDistribution,
      'generatedBy': generatedBy,
      'generatedAt': generatedAt.toIso8601String(),
      'isSynced': isSynced,
    };
  }

  factory Report.fromMap(Map<String, dynamic> map) {
    return Report(
      id: map['id'] ?? '',
      userId: map['userId'] ?? '',
      type: ReportType.values.firstWhere(
        (e) => e.name == map['type'],
        orElse: () => ReportType.monthly,
      ),
      startDate: DateTime.tryParse(map['startDate'] ?? '') ?? DateTime.now(),
      endDate: DateTime.tryParse(map['endDate'] ?? '') ?? DateTime.now(),
      totalDiagnoses: map['totalDiagnoses'] ?? 0,
      diseaseCount: map['diseaseCount'] ?? 0,
      pestCount: map['pestCount'] ?? 0,
      deficiencyCount: map['deficiencyCount'] ?? 0,
      healthyCount: map['healthyCount'] ?? 0,
      cropDistribution: Map<String, int>.from(map['cropDistribution'] ?? {}),
      districtDistribution: Map<String, int>.from(map['districtDistribution'] ?? {}),
      generatedBy: map['generatedBy'],
      generatedAt: DateTime.tryParse(map['generatedAt'] ?? '') ?? DateTime.now(),
      isSynced: map['isSynced'] ?? false,
    );
  }

  Report copyWith({
    String? id,
    String? userId,
    ReportType? type,
    DateTime? startDate,
    DateTime? endDate,
    int? totalDiagnoses,
    int? diseaseCount,
    int? pestCount,
    int? deficiencyCount,
    int? healthyCount,
    Map<String, int>? cropDistribution,
    Map<String, int>? districtDistribution,
    String? generatedBy,
    DateTime? generatedAt,
    bool? isSynced,
  }) {
    return Report(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      type: type ?? this.type,
      startDate: startDate ?? this.startDate,
      endDate: endDate ?? this.endDate,
      totalDiagnoses: totalDiagnoses ?? this.totalDiagnoses,
      diseaseCount: diseaseCount ?? this.diseaseCount,
      pestCount: pestCount ?? this.pestCount,
      deficiencyCount: deficiencyCount ?? this.deficiencyCount,
      healthyCount: healthyCount ?? this.healthyCount,
      cropDistribution: cropDistribution ?? this.cropDistribution,
      districtDistribution: districtDistribution ?? this.districtDistribution,
      generatedBy: generatedBy ?? this.generatedBy,
      generatedAt: generatedAt ?? this.generatedAt,
      isSynced: isSynced ?? this.isSynced,
    );
  }

  String getTypeName() {
    switch (type) {
      case ReportType.monthly:
        return 'Monthly Report';
      case ReportType.weekly:
        return 'Weekly Report';
      case ReportType.quarterly:
        return 'Quarterly Report';
      case ReportType.annual:
        return 'Annual Report';
      case ReportType.custom:
        return 'Custom Report';
    }
  }

  @override
  List<Object?> get props => [
        id,
        userId,
        type,
        startDate,
        endDate,
        totalDiagnoses,
        diseaseCount,
        pestCount,
        deficiencyCount,
        healthyCount,
        cropDistribution,
        districtDistribution,
        generatedBy,
        generatedAt,
        isSynced,
      ];
}
