import 'dart:math';

class EpaDataSource {
  static final Map<String, Map<String, dynamic>> districtsWithEpas = {
    'Blantyre': {
      'coordinates': {'lat': -15.7861, 'lng': 35.0058},
      'region': 'Southern Region',
      'epas': [
        {'name': 'Chileka EPA', 'lat': -15.8500, 'lng': 35.0500},
        {'name': 'Limbe EPA', 'lat': -15.7900, 'lng': 35.0200},
        {'name': 'Mpingo EPA', 'lat': -15.7700, 'lng': 34.9800},
        {'name': 'Ndirande EPA', 'lat': -15.7600, 'lng': 35.0100},
        {'name': 'Chigumula EPA', 'lat': -15.7300, 'lng': 35.0400},
        {'name': 'South Lunzu EPA', 'lat': -15.8000, 'lng': 34.9700},
      ],
    },
    'Lilongwe': {
      'coordinates': {'lat': -13.9626, 'lng': 33.7741},
      'region': 'Central Region',
      'epas': [
        {'name': 'Kachere EPA', 'lat': -13.9800, 'lng': 33.7800},
        {'name': 'Mitundu EPA', 'lat': -14.0000, 'lng': 33.7500},
        {'name': 'Mchesna EPA', 'lat': -13.9500, 'lng': 33.7900},
        {'name': 'Chikowa EPA', 'lat': -13.9700, 'lng': 33.7600},
        {'name': 'Kawale EPA', 'lat': -13.9900, 'lng': 33.8000},
        {'name': 'Namitete EPA', 'lat': -14.0500, 'lng': 33.7200},
      ],
    },
    'Mzuzu': {
      'coordinates': {'lat': -11.4655, 'lng': 34.0235},
      'region': 'Northern Region',
      'epas': [
        {'name': 'Mzuzu EPA', 'lat': -11.4655, 'lng': 34.0235},
        {'name': 'Chimwemwe EPA', 'lat': -11.4800, 'lng': 34.0300},
        {'name': 'Mzuzu North EPA', 'lat': -11.4400, 'lng': 34.0100},
        {'name': 'Chikangawa EPA', 'lat': -11.4200, 'lng': 33.9800},
      ],
    },
    'Zomba': {
      'coordinates': {'lat': -15.3631, 'lng': 35.3186},
      'region': 'Southern Region',
      'epas': [
        {'name': 'Zomba EPA', 'lat': -15.3631, 'lng': 35.3186},
        {'name': 'Chikonde EPA', 'lat': -15.3800, 'lng': 35.3300},
        {'name': 'Mtuya EPA', 'lat': -15.3400, 'lng': 35.3000},
        {'name': 'Malemia EPA', 'lat': -15.3900, 'lng': 35.3500},
      ],
    },
    'Mzimba': {
      'coordinates': {'lat': -11.9000, 'lng': 33.6000},
      'region': 'Northern Region',
      'epas': [
        {'name': 'Mzimba EPA', 'lat': -11.9000, 'lng': 33.6000},
        {'name': 'Mzimba North EPA', 'lat': -11.8500, 'lng': 33.6200},
        {'name': 'Mzimba South EPA', 'lat': -11.9500, 'lng': 33.5800},
        {'name': 'Rumphi EPA', 'lat': -11.8500, 'lng': 33.7500},
      ],
    },
    'Chikwawa': {
      'coordinates': {'lat': -16.0333, 'lng': 34.8000},
      'region': 'Southern Region',
      'epas': [
        {'name': 'Chikwawa EPA', 'lat': -16.0333, 'lng': 34.8000},
        {'name': 'Ngabu EPA', 'lat': -16.0500, 'lng': 34.8500},
        {'name': 'Chikwawa North EPA', 'lat': -16.0000, 'lng': 34.7800},
        {'name': 'Chikwawa South EPA', 'lat': -16.0700, 'lng': 34.8300},
      ],
    },
    'Chiradzulu': {
      'coordinates': {'lat': -15.6833, 'lng': 35.6500},
      'region': 'Southern Region',
      'epas': [
        {'name': 'Chiradzulu EPA', 'lat': -15.6833, 'lng': 35.6500},
        {'name': 'Chiradzulu North EPA', 'lat': -15.6600, 'lng': 35.6700},
        {'name': 'Chiradzulu South EPA', 'lat': -15.7000, 'lng': 35.6300},
      ],
    },
    'Chitipa': {
      'coordinates': {'lat': -9.5667, 'lng': 33.2667},
      'region': 'Northern Region',
      'epas': [
        {'name': 'Chitipa EPA', 'lat': -9.5667, 'lng': 33.2667},
        {'name': 'Chitipa North EPA', 'lat': -9.5200, 'lng': 33.2900},
        {'name': 'Chitipa South EPA', 'lat': -9.6100, 'lng': 33.2400},
      ],
    },
    'Dedza': {
      'coordinates': {'lat': -14.3833, 'lng': 34.3333},
      'region': 'Central Region',
      'epas': [
        {'name': 'Dedza EPA', 'lat': -14.3833, 'lng': 34.3333},
        {'name': 'Dedza North EPA', 'lat': -14.3500, 'lng': 34.3600},
        {'name': 'Dedza South EPA', 'lat': -14.4200, 'lng': 34.3000},
        {'name': 'Linthipe EPA', 'lat': -14.3000, 'lng': 34.2800},
      ],
    },
    'Dowa': {
      'coordinates': {'lat': -13.6500, 'lng': 34.1167},
      'region': 'Central Region',
      'epas': [
        {'name': 'Dowa EPA', 'lat': -13.6500, 'lng': 34.1167},
        {'name': 'Dowa North EPA', 'lat': -13.6200, 'lng': 34.1400},
        {'name': 'Dowa South EPA', 'lat': -13.6800, 'lng': 34.0900},
      ],
    },
    'Karonga': {
      'coordinates': {'lat': -9.9333, 'lng': 33.9333},
      'region': 'Northern Region',
      'epas': [
        {'name': 'Karonga EPA', 'lat': -9.9333, 'lng': 33.9333},
        {'name': 'Karonga North EPA', 'lat': -9.9000, 'lng': 33.9600},
        {'name': 'Karonga South EPA', 'lat': -9.9700, 'lng': 33.9000},
      ],
    },
    'Kasungu': {
      'coordinates': {'lat': -13.0333, 'lng': 33.4833},
      'region': 'Central Region',
      'epas': [
        {'name': 'Kasungu EPA', 'lat': -13.0333, 'lng': 33.4833},
        {'name': 'Kasungu North EPA', 'lat': -13.0000, 'lng': 33.5100},
        {'name': 'Kasungu South EPA', 'lat': -13.0700, 'lng': 33.4500},
        {'name': 'L chipped EPA', 'lat': -13.1200, 'lng': 33.5200},
      ],
    },
    'Likuni': {
      'coordinates': {'lat': -14.1500, 'lng': 33.7000},
      'region': 'Central Region',
      'epas': [
        {'name': 'Likuni EPA', 'lat': -14.1500, 'lng': 33.7000},
        {'name': 'Likuni North EPA', 'lat': -14.1200, 'lng': 33.7300},
        {'name': 'Likuni South EPA', 'lat': -14.1800, 'lng': 33.6700},
      ],
    },
    'Machinga': {
      'coordinates': {'lat': -14.9667, 'lng': 35.5167},
      'region': 'Southern Region',
      'epas': [
        {'name': 'Machinga EPA', 'lat': -14.9667, 'lng': 35.5167},
        {'name': 'Machinga North EPA', 'lat': -14.9400, 'lng': 35.5400},
        {'name': 'Machinga South EPA', 'lat': -14.9900, 'lng': 35.4900},
      ],
    },
    'Mangochi': {
      'coordinates': {'lat': -14.4667, 'lng': 35.2667},
      'region': 'Southern Region',
      'epas': [
        {'name': 'Mangochi EPA', 'lat': -14.4667, 'lng': 35.2667},
        {'name': 'Mangochi North EPA', 'lat': -14.4400, 'lng': 35.2900},
        {'name': 'Mangochi South EPA', 'lat': -14.4900, 'lng': 35.2400},
        {'name': 'Monkey Bay EPA', 'lat': -14.4200, 'lng': 35.3000},
      ],
    },
    'Mchinji': {
      'coordinates': {'lat': -13.8000, 'lng': 32.8833},
      'region': 'Central Region',
      'epas': [
        {'name': 'Mchinji EPA', 'lat': -13.8000, 'lng': 32.8833},
        {'name': 'Mchinji North EPA', 'lat': -13.7700, 'lng': 32.9100},
        {'name': 'Mchinji South EPA', 'lat': -13.8300, 'lng': 32.8500},
      ],
    },
    'Mulanje': {
      'coordinates': {'lat': -16.0500, 'lng': 35.5000},
      'region': 'Southern Region',
      'epas': [
        {'name': 'Mulanje EPA', 'lat': -16.0500, 'lng': 35.5000},
        {'name': 'Mulanje North EPA', 'lat': -16.0200, 'lng': 35.5300},
        {'name': 'Mulanje South EPA', 'lat': -16.0800, 'lng': 35.4700},
        {'name': 'Thyolo EPA', 'lat': -16.0800, 'lng': 35.1400},
      ],
    },
    'Nsanje': {
      'coordinates': {'lat': -16.9167, 'lng': 35.0833},
      'region': 'Southern Region',
      'epas': [
        {'name': 'Nsanje EPA', 'lat': -16.9167, 'lng': 35.0833},
        {'name': 'Nsanje North EPA', 'lat': -16.8900, 'lng': 35.1100},
        {'name': 'Nsanje South EPA', 'lat': -16.9400, 'lng': 35.0500},
      ],
    },
    'Ntcheu': {
      'coordinates': {'lat': -15.0333, 'lng': 34.6833},
      'region': 'Central Region',
      'epas': [
        {'name': 'Ntcheu EPA', 'lat': -15.0333, 'lng': 34.6833},
        {'name': 'Ntcheu North EPA', 'lat': -15.0000, 'lng': 34.7100},
        {'name': 'Ntcheu South EPA', 'lat': -15.0700, 'lng': 34.6500},
      ],
    },
    'Ntchisi': {
      'coordinates': {'lat': -13.0833, 'lng': 34.1667},
      'region': 'Central Region',
      'epas': [
        {'name': 'Ntchisi EPA', 'lat': -13.0833, 'lng': 34.1667},
        {'name': 'Ntchisi North EPA', 'lat': -13.0500, 'lng': 34.1900},
        {'name': 'Ntchisi South EPA', 'lat': -13.1200, 'lng': 34.1400},
      ],
    },
    'Phalombe': {
      'coordinates': {'lat': -15.8000, 'lng': 35.6500},
      'region': 'Southern Region',
      'epas': [
        {'name': 'Phalombe EPA', 'lat': -15.8000, 'lng': 35.6500},
        {'name': 'Phalombe North EPA', 'lat': -15.7700, 'lng': 35.6800},
        {'name': 'Phalombe South EPA', 'lat': -15.8300, 'lng': 35.6200},
      ],
    },
    'Rumphi': {
      'coordinates': {'lat': -11.0167, 'lng': 33.8667},
      'region': 'Northern Region',
      'epas': [
        {'name': 'Rumphi EPA', 'lat': -11.0167, 'lng': 33.8667},
        {'name': 'Rumphi North EPA', 'lat': -10.9800, 'lng': 33.9000},
        {'name': 'Rumphi South EPA', 'lat': -11.0500, 'lng': 33.8300},
      ],
    },
    'Salima': {
      'coordinates': {'lat': -13.7667, 'lng': 34.4167},
      'region': 'Central Region',
      'epas': [
        {'name': 'Salima EPA', 'lat': -13.7667, 'lng': 34.4167},
        {'name': 'Salima North EPA', 'lat': -13.7400, 'lng': 34.4400},
        {'name': 'Salima South EPA', 'lat': -13.7900, 'lng': 34.3900},
      ],
    },
    'Thyolo': {
      'coordinates': {'lat': -16.0333, 'lng': 35.1333},
      'region': 'Southern Region',
      'epas': [
        {'name': 'Thyolo EPA', 'lat': -16.0333, 'lng': 35.1333},
        {'name': 'Thyolo North EPA', 'lat': -16.0000, 'lng': 35.1600},
        {'name': 'Thyolo South EPA', 'lat': -16.0700, 'lng': 35.1000},
      ],
    },
    'Balaka': {
      'coordinates': {'lat': -14.9833, 'lng': 34.9500},
      'region': 'Southern Region',
      'epas': [
        {'name': 'Balaka EPA', 'lat': -14.9833, 'lng': 34.9500},
        {'name': 'Balaka North EPA', 'lat': -14.9500, 'lng': 34.9800},
        {'name': 'Balaka South EPA', 'lat': -15.0200, 'lng': 34.9200},
      ],
    },
    'Likoma': {
      'coordinates': {'lat': -12.0667, 'lng': 34.7333},
      'region': 'Northern Region',
      'epas': [
        {'name': 'Likoma EPA', 'lat': -12.0667, 'lng': 34.7333},
        {'name': 'Likoma North EPA', 'lat': -12.0400, 'lng': 34.7500},
        {'name': 'Likoma South EPA', 'lat': -12.0900, 'lng': 34.7100},
      ],
    },
    'Nkhata Bay': {
      'coordinates': {'lat': -11.6000, 'lng': 34.3000},
      'region': 'Northern Region',
      'epas': [
        {'name': 'Nkhata Bay EPA', 'lat': -11.6000, 'lng': 34.3000},
        {'name': 'Nkhata Bay North EPA', 'lat': -11.5700, 'lng': 34.3300},
        {'name': 'Nkhata Bay South EPA', 'lat': -11.6300, 'lng': 34.2700},
      ],
    },
    'Nkhotakota': {
      'coordinates': {'lat': -12.9333, 'lng': 34.1000},
      'region': 'Central Region',
      'epas': [
        {'name': 'Nkhotakota EPA', 'lat': -12.9333, 'lng': 34.1000},
        {'name': 'Nkhotakota North EPA', 'lat': -12.9000, 'lng': 34.1300},
        {'name': 'Nkhotakota South EPA', 'lat': -12.9700, 'lng': 34.0700},
      ],
    },
  };

  static String? findEpaByCoordinates(double lat, double lng) {
    String? nearestEpa;
    double minDistance = double.infinity;

    for (final districtEntry in districtsWithEpas.entries) {
      final epas = districtEntry.value['epas'] as List;
      for (final epa in epas) {
        final distance = _calculateDistance(
          lat, lng,
          epa['lat'], epa['lng'],
        );
        if (distance < minDistance) {
          minDistance = distance;
          nearestEpa = epa['name'];
        }
      }
    }

    return nearestEpa;
  }

  static String? findDistrictByCoordinates(double lat, double lng) {
    String? nearestDistrict;
    double minDistance = double.infinity;

    for (final entry in districtsWithEpas.entries) {
      final coords = entry.value['coordinates'];
      final distance = _calculateDistance(
        lat, lng,
        coords['lat'], coords['lng'],
      );
      if (distance < minDistance) {
        minDistance = distance;
        nearestDistrict = entry.key;
      }
    }

    return nearestDistrict;
  }

  static String? findRegionByCoordinates(double lat, double lng) {
    final district = findDistrictByCoordinates(lat, lng);
    if (district != null) {
      return districtsWithEpas[district]?['region'] as String?;
    }
    return null;
  }

  static List<String> getAllDistricts() {
    return districtsWithEpas.keys.toList();
  }

  static List<String> getEpasForDistrict(String district) {
    final districtData = districtsWithEpas[district];
    if (districtData == null) return [];
    return (districtData['epas'] as List).map((e) => e['name'] as String).toList();
  }

  static String? getRegionForDistrict(String district) {
    return districtsWithEpas[district]?['region'] as String?;
  }

  static Map<String, dynamic>? getEpaDetails(String epaName) {
    for (final districtEntry in districtsWithEpas.entries) {
      final epas = districtEntry.value['epas'] as List;
      for (final epa in epas) {
        if (epa['name'] == epaName) {
          return {
            ...epa,
            'district': districtEntry.key,
            'region': districtEntry.value['region'],
          };
        }
      }
    }
    return null;
  }

  static List<String> getEpasByRegion(String region) {
    final epas = <String>[];
    for (final entry in districtsWithEpas.entries) {
      if (entry.value['region'] == region) {
        final districtEpas = entry.value['epas'] as List;
        epas.addAll(districtEpas.map((e) => e['name'] as String));
      }
    }
    return epas;
  }

  static Map<String, double>? getEpaCoordinates(String epaName) {
    for (final districtEntry in districtsWithEpas.entries) {
      final epas = districtEntry.value['epas'] as List;
      for (final epa in epas) {
        if (epa['name'] == epaName) {
          return {
            'lat': epa['lat'],
            'lng': epa['lng'],
          };
        }
      }
    }
    return null;
  }

  static double _calculateDistance(double lat1, double lng1, double lat2, double lng2) {
    const double earthRadius = 6371;
    final double dLat = _degreesToRadians(lat2 - lat1);
    final double dLng = _degreesToRadians(lng2 - lng1);
    
    final double a = sin(dLat / 2) * sin(dLat / 2) +
        cos(_degreesToRadians(lat1)) * cos(_degreesToRadians(lat2)) *
        sin(dLng / 2) * sin(dLng / 2);
    
    final double c = 2 * atan2(sqrt(a), sqrt(1 - a));
    
    return earthRadius * c;
  }

  static double _degreesToRadians(double degrees) {
    return degrees * pi / 180;
  }

  static List<String> getAllRegions() {
    return [
      'Northern Region',
      'Central Region',
      'Southern Region',
    ];
  }
}
