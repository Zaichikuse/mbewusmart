enum DiagnosisCategory { pest, disease, deficiency }

extension DiagnosisCategoryExtension on DiagnosisCategory {
  String get displayName {
    switch (this) {
      case DiagnosisCategory.pest:
        return 'Pest';
      case DiagnosisCategory.disease:
        return 'Disease';
      case DiagnosisCategory.deficiency:
        return 'Deficiency';
    }
  }

  String get displayNameChichewa {
    switch (this) {
      case DiagnosisCategory.pest:
        return 'Malalire';
      case DiagnosisCategory.disease:
        return 'Matenda';
      case DiagnosisCategory.deficiency:
        return 'Kudapitilira';
    }
  }

  String get icon {
    switch (this) {
      case DiagnosisCategory.pest:
        return '🐛';
      case DiagnosisCategory.disease:
        return '🦠';
      case DiagnosisCategory.deficiency:
        return '🌱';
    }
  }

  String get colorCode {
    switch (this) {
      case DiagnosisCategory.pest:
        return '#FF9800'; // Orange
      case DiagnosisCategory.disease:
        return '#D32F2F'; // Red
      case DiagnosisCategory.deficiency:
        return '#4CAF50'; // Green
    }
  }
}
