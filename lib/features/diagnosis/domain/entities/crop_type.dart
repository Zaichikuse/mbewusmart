enum CropType {
  maize,
  cassava,
  tomato,
}

extension CropTypeExtension on CropType {
  String get displayName {
    switch (this) {
      case CropType.maize:
        return 'Maize';
      case CropType.cassava:
        return 'Cassava';
      case CropType.tomato:
        return 'Tomato';
    }
  }

  String get displayNameChichewa {
    switch (this) {
      case CropType.maize:
        return 'Mgamula';
      case CropType.cassava:
        return 'Chikanda';
      case CropType.tomato:
        return 'Tomato';
    }
  }

  String get icon {
    switch (this) {
      case CropType.maize:
        return '🌽';
      case CropType.cassava:
        return '🌿';
      case CropType.tomato:
        return '🍅';
    }
  }
}
