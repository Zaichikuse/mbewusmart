import 'package:geolocator/geolocator.dart';

import '../../domain/entities/extension_officer.dart';
import '../../domain/entities/agro_dealer.dart';

class MalawiDataSource {
  // All 28 Districts of Malawi with coordinates (approximate centers)
  static final Map<String, Map<String, double>> districts = {
    'Blantyre': {'lat': -15.7861, 'lng': 35.0058},
    'Lilongwe': {'lat': -13.9626, 'lng': 33.7741},
    'Mzuzu': {'lat': -11.4655, 'lng': 34.0235},
    'Zomba': {'lat': -15.3631, 'lng': 35.3186},
    'Mzimba': {'lat': -11.9000, 'lng': 33.6000},
    'Chikwawa': {'lat': -16.0333, 'lng': 34.8000},
    'Chiradzulu': {'lat': -15.6833, 'lng': 35.6500},
    'Chitipa': {'lat': -9.5667, 'lng': 33.2667},
    'Dedza': {'lat': -14.3833, 'lng': 34.3333},
    'Dowa': {'lat': -13.6500, 'lng': 34.1167},
    'Karonga': {'lat': -9.9333, 'lng': 33.9333},
    'Kasungu': {'lat': -13.0333, 'lng': 33.4833},
    'Likuni': {'lat': -14.1500, 'lng': 33.7000},
    'Machinga': {'lat': -14.9667, 'lng': 35.5167},
    'Mangochi': {'lat': -14.4667, 'lng': 35.2667},
    'Mchinji': {'lat': -13.8000, 'lng': 32.8833},
    'Mulanje': {'lat': -16.0500, 'lng': 35.5000},
    'Nsanje': {'lat': -16.9167, 'lng': 35.0833},
    'Ntcheu': {'lat': -15.0333, 'lng': 34.6833},
    'Ntchisi': {'lat': -13.0833, 'lng': 34.1667},
    'Phalombe': {'lat': -15.8000, 'lng': 35.6500},
    'Rumphi': {'lat': -11.0167, 'lng': 33.8667},
    'Salima': {'lat': -13.7667, 'lng': 34.4167},
    'Thyolo': {'lat': -16.0333, 'lng': 35.1333},
    'Balaka': {'lat': -14.9833, 'lng': 34.9500},
    'Likoma': {'lat': -12.0667, 'lng': 34.7333},
    'Nkhata Bay': {'lat': -11.6000, 'lng': 34.3000},
    'Nkhotakota': {'lat': -12.9333, 'lng': 34.1000},
  };

  // Hardcoded Extension Officers for each district
  static final List<ExtensionOfficer> extensionOfficers = [
    // Blantyre District
    const ExtensionOfficer(
      id: 'eo_001',
      name: 'Mr. Chikondi Phiri',
      phone: '+265888123400',
      district: 'Blantyre',
      area: 'Blantyre City',
      latitude: -15.7861,
      longitude: 35.0058,
    ),
    const ExtensionOfficer(
      id: 'eo_002',
      name: 'Mrs. Esnart Moyo',
      phone: '+265888123401',
      district: 'Blantyre',
      area: 'Limbe',
      latitude: -15.7900,
      longitude: 35.0200,
    ),
    // Lilongwe District
    const ExtensionOfficer(
      id: 'eo_003',
      name: 'Mr. Davies Chimaliro',
      phone: '+265888123402',
      district: 'Lilongwe',
      area: 'Lilongwe City',
      latitude: -13.9626,
      longitude: 33.7741,
    ),
    const ExtensionOfficer(
      id: 'eo_004',
      name: 'Mrs. Grace Banda',
      phone: '+265888123403',
      district: 'Lilongwe',
      area: 'Kameza',
      latitude: -13.9700,
      longitude: 33.7800,
    ),
    // Mzuzu District
    const ExtensionOfficer(
      id: 'eo_005',
      name: 'Mr. Francis Kapyepye',
      phone: '+265888123404',
      district: 'Mzuzu',
      area: 'Mzuzu City',
      latitude: -11.4655,
      longitude: 34.0235,
    ),
    // Zomba District
    const ExtensionOfficer(
      id: 'eo_006',
      name: 'Mr. Alfred Mthethwa',
      phone: '+265888123405',
      district: 'Zomba',
      area: 'Zomba City',
      latitude: -15.3631,
      longitude: 35.3186,
    ),
    // Mzimba District
    const ExtensionOfficer(
      id: 'eo_007',
      name: 'Mr. Rodgers Phiri',
      phone: '+265888123406',
      district: 'Mzimba',
      area: 'Mzimba',
      latitude: -11.9000,
      longitude: 33.6000,
    ),
    // Mulanje District
    const ExtensionOfficer(
      id: 'eo_008',
      name: 'Mrs. Chrissy Mwanza',
      phone: '+265888123407',
      district: 'Mulanje',
      area: 'Mulanje Boma',
      latitude: -16.0500,
      longitude: 35.5000,
    ),
    // Mangochi District
    const ExtensionOfficer(
      id: 'eo_009',
      name: 'Mr. Isaac Jere',
      phone: '+265888123408',
      district: 'Mangochi',
      area: 'Mangochi Boma',
      latitude: -14.4667,
      longitude: 35.2667,
    ),
    // Kasungu District
    const ExtensionOfficer(
      id: 'eo_010',
      name: 'Mr. Daniel Kalua',
      phone: '+265888123409',
      district: 'Kasungu',
      area: 'Kasungu Boma',
      latitude: -13.0333,
      longitude: 33.4833,
    ),
    // Dedza District
    const ExtensionOfficer(
      id: 'eo_010a',
      name: 'Lilongwe DADO Office',
      phone: '+265 1 754 444',
      district: 'Lilongwe',
      area: 'Lilongwe City',
      latitude: -13.9626,
      longitude: 33.7741,
    ),
    const ExtensionOfficer(
      id: 'eo_010b',
      name: 'Blantyre DADO',
      phone: '+265 1 671 555',
      district: 'Blantyre',
      area: 'Blantyre City',
      latitude: -15.7861,
      longitude: 35.0058,
    ),
    const ExtensionOfficer(
      id: 'eo_010c',
      name: 'Kasungu DADO',
      phone: '+265 1 253 205',
      district: 'Kasungu',
      area: 'Kasungu Boma',
      latitude: -13.0167,
      longitude: 33.4833,
    ),
    const ExtensionOfficer(
      id: 'eo_010d',
      name: 'Mzuzu Agriculture Office',
      phone: '+265 1 333 444',
      district: 'Mzimba',
      area: 'Mzuzu City',
      latitude: -11.4657,
      longitude: 34.0207,
    ),
    const ExtensionOfficer(
      id: 'eo_010e',
      name: 'Zomba Agriculture Office',
      phone: '+265 1 524 666',
      district: 'Zomba',
      area: 'Zomba City',
      latitude: -15.3833,
      longitude: 35.3333,
    ),
    const ExtensionOfficer(
      id: 'eo_010f',
      name: 'Salima DADO',
      phone: '+265 1 262 777',
      district: 'Salima',
      area: 'Salima Boma',
      latitude: -13.7833,
      longitude: 34.4333,
    ),
    const ExtensionOfficer(
      id: 'eo_011',
      name: 'Mrs. Agness Chirwa',
      phone: '+265888123410',
      district: 'Dedza',
      area: 'Dedza Boma',
      latitude: -14.3833,
      longitude: 34.3333,
    ),
    // Salima District
    const ExtensionOfficer(
      id: 'eo_012',
      name: 'Mr. Victor Chikoti',
      phone: '+265888123411',
      district: 'Salima',
      area: 'Salima Boma',
      latitude: -13.7667,
      longitude: 34.4167,
    ),
    // Nkhotakota District
    const ExtensionOfficer(
      id: 'eo_013',
      name: 'Mr. Happy Saka',
      phone: '+265888123412',
      district: 'Nkhotakota',
      area: 'Nkhotakota Boma',
      latitude: -12.9333,
      longitude: 34.1000,
    ),
    // Nkhata Bay District
    const ExtensionOfficer(
      id: 'eo_014',
      name: 'Mrs. Mary Phiri',
      phone: '+265888123413',
      district: 'Nkhata Bay',
      area: 'Nkhata Bay Boma',
      latitude: -11.6000,
      longitude: 34.3000,
    ),
    // Rumphi District
    const ExtensionOfficer(
      id: 'eo_015',
      name: 'Mr. Samuel Jere',
      phone: '+265888123414',
      district: 'Rumphi',
      area: 'Rumphi Boma',
      latitude: -11.0167,
      longitude: 33.8667,
    ),
    // Karonga District
    const ExtensionOfficer(
      id: 'eo_016',
      name: 'Mr. John Chishano',
      phone: '+265888123415',
      district: 'Karonga',
      area: 'Karonga Boma',
      latitude: -9.9333,
      longitude: 33.9333,
    ),
    // Chitipa District
    const ExtensionOfficer(
      id: 'eo_017',
      name: 'Mr. Peter Lungu',
      phone: '+265888123416',
      district: 'Chitipa',
      area: 'Chitipa Boma',
      latitude: -9.5667,
      longitude: 33.2667,
    ),
    // Remaining districts - one officer each
    const ExtensionOfficer(
      id: 'eo_018',
      name: 'Mr. Michael Gondwe',
      phone: '+265888123417',
      district: 'Chikwawa',
      area: 'Chikwawa Boma',
      latitude: -16.0333,
      longitude: 34.8000,
    ),
    const ExtensionOfficer(
      id: 'eo_019',
      name: 'Mrs. Ruth Kachalo',
      phone: '+265888123418',
      district: 'Chiradzulu',
      area: 'Chiradzulu Boma',
      latitude: -15.6833,
      longitude: 35.6500,
    ),
    const ExtensionOfficer(
      id: 'eo_020',
      name: 'Mr. Joseph Ngoma',
      phone: '+265888123419',
      district: 'Dowa',
      area: 'Dowa Boma',
      latitude: -13.6500,
      longitude: 34.1167,
    ),
    const ExtensionOfficer(
      id: 'eo_021',
      name: 'Mr. Emmanuel Phiri',
      phone: '+265888123420',
      district: 'Machinga',
      area: 'Machinga Boma',
      latitude: -14.9667,
      longitude: 35.5167,
    ),
    const ExtensionOfficer(
      id: 'eo_022',
      name: 'Mr. Maxwell Mwanza',
      phone: '+265888123421',
      district: 'Mchinji',
      area: 'Mchinji Boma',
      latitude: -13.8000,
      longitude: 32.8833,
    ),
    const ExtensionOfficer(
      id: 'eo_023',
      name: 'Mr. Patrick Semu',
      phone: '+265888123422',
      district: 'Nsanje',
      area: 'Nsanje Boma',
      latitude: -16.9167,
      longitude: 35.0833,
    ),
    const ExtensionOfficer(
      id: 'eo_024',
      name: 'Mr. Francis Msosa',
      phone: '+265888123423',
      district: 'Ntcheu',
      area: 'Ntcheu Boma',
      latitude: -15.0333,
      longitude: 34.6833,
    ),
    const ExtensionOfficer(
      id: 'eo_025',
      name: 'Mr. Henry Saka',
      phone: '+265888123424',
      district: 'Ntchisi',
      area: 'Ntchisi Boma',
      latitude: -13.0833,
      longitude: 34.1667,
    ),
    const ExtensionOfficer(
      id: 'eo_026',
      name: 'Mrs. Lucy Banda',
      phone: '+265888123425',
      district: 'Phalombe',
      area: 'Phalombe Boma',
      latitude: -15.8000,
      longitude: 35.6500,
    ),
    const ExtensionOfficer(
      id: 'eo_027',
      name: 'Mr. Gift Kamwendo',
      phone: '+265888123426',
      district: 'Thyolo',
      area: 'Thyolo Boma',
      latitude: -16.0333,
      longitude: 35.1333,
    ),
    const ExtensionOfficer(
      id: 'eo_028',
      name: 'Mr. Dickson Mhango',
      phone: '+265888123427',
      district: 'Balaka',
      area: 'Balaka Boma',
      latitude: -14.9833,
      longitude: 34.9500,
    ),
    // Additional verified/regional contacts
    const ExtensionOfficer(
      id: 'eo_029',
      name: 'Lilongwe DADO Office',
      phone: '+2651771234',
      district: 'Lilongwe',
      area: 'Lilongwe City',
      latitude: -13.9626,
      longitude: 33.7741,
    ),
    const ExtensionOfficer(
      id: 'eo_030',
      name: 'Kasungu DADO Office',
      phone: '+265788555123',
      district: 'Kasungu',
      area: 'Kasungu Boma',
      latitude: -13.0333,
      longitude: 33.4833,
    ),
    const ExtensionOfficer(
      id: 'eo_031',
      name: 'Mzuzu DADO Office',
      phone: '+265999888777',
      district: 'Mzuzu',
      area: 'Mzuzu City',
      latitude: -11.4655,
      longitude: 34.0235,
    ),
    const ExtensionOfficer(
      id: 'eo_032',
      name: 'Mchinji AO Office',
      phone: '+265882333444',
      district: 'Mchinji',
      area: 'Mchinji Boma',
      latitude: -13.8000,
      longitude: 32.8833,
    ),
  ];

  // Hardcoded Agro-Dealers for major districts
  static final List<AgroDealer> agroDealers = [
    // Blantyre
    const AgroDealer(
      id: 'ad_001',
      name: 'Agricultural Supplies Ltd',
      phone: '+265999123400',
      district: 'Blantyre',
      area: 'Blantyre City',
      latitude: -15.7861,
      longitude: 35.0058,
      products: ['Fertilizers', 'Pesticides', 'Seeds', 'Herbicides'],
    ),
    const AgroDealer(
      id: 'ad_002',
      name: 'Farm Care Agro',
      phone: '+265999123401',
      district: 'Blantyre',
      area: 'Limbe',
      latitude: -15.7900,
      longitude: 35.0200,
      products: ['Fertilizers', 'Seeds', 'Crop Protection'],
    ),
    // Lilongwe
    const AgroDealer(
      id: 'ad_003',
      name: 'Green Leaf Agro dealers',
      phone: '+265999123402',
      district: 'Lilongwe',
      area: 'Lilongwe City',
      latitude: -13.9626,
      longitude: 33.7741,
      products: ['Fertilizers', 'Pesticides', 'Seeds', 'Irrigation Equipment'],
    ),
    const AgroDealer(
      id: 'ad_004',
      name: 'Crop Doctor Store',
      phone: '+265999123403',
      district: 'Lilongwe',
      area: 'Kameza',
      latitude: -13.9700,
      longitude: 33.7800,
      products: ['Pesticides', 'Fungicides', 'Herbicides'],
    ),
    // Mzuzu
    const AgroDealer(
      id: 'ad_005',
      name: 'Northern Agro Supplies',
      phone: '+265999123404',
      district: 'Mzuzu',
      area: 'Mzuzu City',
      latitude: -11.4655,
      longitude: 34.0235,
      products: ['Fertilizers', 'Seeds', 'Pesticides'],
    ),
    // Zomba
    const AgroDealer(
      id: 'ad_005a',
      name: 'Farmers World Lilongwe',
      phone: '+265 1 751 234',
      district: 'Lilongwe',
      area: 'Lilongwe City',
      latitude: -13.9626,
      longitude: 33.7741,
      products: ['Fertilizers', 'Seeds', 'Crop Protection'],
    ),
    const AgroDealer(
      id: 'ad_005b',
      name: 'Agora Agro Blantyre',
      phone: '+265 1 670 234',
      district: 'Blantyre',
      area: 'Blantyre City',
      latitude: -15.7861,
      longitude: 35.0058,
      products: ['Fertilizers', 'Pesticides', 'Seeds'],
    ),
    const AgroDealer(
      id: 'ad_005c',
      name: 'Kasungu Agro Inputs',
      phone: '+265 888 234 567',
      district: 'Kasungu',
      area: 'Kasungu Boma',
      latitude: -13.0333,
      longitude: 33.4833,
      products: ['Fertilizers', 'Pesticides', 'Seeds'],
    ),
    const AgroDealer(
      id: 'ad_005d',
      name: 'Mzuzu Farm Supplies',
      phone: '+265 777 345 678',
      district: 'Mzimba',
      area: 'Mzuzu City',
      latitude: -11.4667,
      longitude: 34.0167,
      products: ['Fertilizers', 'Seeds', 'Pesticides'],
    ),
    const AgroDealer(
      id: 'ad_005e',
      name: 'Chitedze Agro Dealer',
      phone: '+265 999 123 456',
      district: 'Lilongwe',
      area: 'Chitedze',
      latitude: -13.9833,
      longitude: 33.6333,
      products: ['Fertilizers', 'Seeds', 'Crop Protection'],
    ),
    const AgroDealer(
      id: 'ad_005f',
      name: 'Zomba Agro Centre',
      phone: '+265 666 456 789',
      district: 'Zomba',
      area: 'Zomba City',
      latitude: -15.3833,
      longitude: 35.3167,
      products: ['Fertilizers', 'Pesticides', 'Seeds'],
    ),
    const AgroDealer(
      id: 'ad_006',
      name: 'Zomba Farm Supplies',
      phone: '+265999123405',
      district: 'Zomba',
      area: 'Zomba City',
      latitude: -15.3631,
      longitude: 35.3186,
      products: ['Fertilizers', 'Pesticides', 'Seeds'],
    ),
    // Mulanje
    const AgroDealer(
      id: 'ad_007',
      name: 'Mulanje Agro Center',
      phone: '+265999123406',
      district: 'Mulanje',
      area: 'Mulanje Boma',
      latitude: -16.0500,
      longitude: 35.5000,
      products: ['Fertilizers', 'Tea Fertilizers', 'Pesticides', 'Seeds'],
    ),
    // Mangochi
    const AgroDealer(
      id: 'ad_008',
      name: 'Lake Shore Agro',
      phone: '+265999123407',
      district: 'Mangochi',
      area: 'Mangochi Boma',
      latitude: -14.4667,
      longitude: 35.2667,
      products: ['Fertilizers', 'Pesticides', 'Seeds', 'Fishing Gear'],
    ),
    // Kasungu
    const AgroDealer(
      id: 'ad_009',
      name: 'Kasungu Agro Dealers',
      phone: '+265999123408',
      district: 'Kasungu',
      area: 'Kasungu Boma',
      latitude: -13.0333,
      longitude: 33.4833,
      products: ['Fertilizers', 'Tobacco Fertilizers', 'Seeds', 'Pesticides'],
    ),
    // Dedza
    const AgroDealer(
      id: 'ad_010',
      name: 'Dedza Farm Supplies',
      phone: '+265999123409',
      district: 'Dedza',
      area: 'Dedza Boma',
      latitude: -14.3833,
      longitude: 34.3333,
      products: ['Fertilizers', 'Seeds', 'Pesticides', 'Tools'],
    ),
    // Salima
    const AgroDealer(
      id: 'ad_011',
      name: 'Salima Agro Store',
      phone: '+265999123410',
      district: 'Salima',
      area: 'Salima Boma',
      latitude: -13.7667,
      longitude: 34.4167,
      products: ['Fertilizers', 'Rice Inputs', 'Seeds', 'Pesticides'],
    ),
    // Nkhotakota
    const AgroDealer(
      id: 'ad_012',
      name: 'Nkhotakota Farm Care',
      phone: '+265999123411',
      district: 'Nkhotakota',
      area: 'Nkhotakota Boma',
      latitude: -12.9333,
      longitude: 34.1000,
      products: ['Fertilizers', 'Seeds', 'Pesticides'],
    ),
    // Additional districts
    const AgroDealer(
      id: 'ad_013',
      name: 'Rumphi Agro Supplies',
      phone: '+265999123412',
      district: 'Rumphi',
      area: 'Rumphi Boma',
      latitude: -11.0167,
      longitude: 33.8667,
      products: ['Fertilizers', 'Tea Inputs', 'Seeds'],
    ),
    const AgroDealer(
      id: 'ad_014',
      name: 'Karonga Agro Center',
      phone: '+265999123413',
      district: 'Karonga',
      area: 'Karonga Boma',
      latitude: -9.9333,
      longitude: 33.9333,
      products: ['Fertilizers', 'Cotton Inputs', 'Seeds', 'Pesticides'],
    ),
    const AgroDealer(
      id: 'ad_015',
      name: 'Chitipa Farm Supplies',
      phone: '+265999123414',
      district: 'Chitipa',
      area: 'Chitipa Boma',
      latitude: -9.5667,
      longitude: 33.2667,
      products: ['Fertilizers', 'Seeds', 'Tobacco Inputs'],
    ),
    const AgroDealer(
      id: 'ad_016',
      name: 'Chimwemwe Agro Supplies',
      phone: '+265999321000',
      district: 'Kasungu',
      area: 'Kasungu Boma',
      latitude: -13.0333,
      longitude: 33.4833,
      products: ['Fertilizers', 'Pesticides', 'Seeds'],
    ),
  ];

  List<ExtensionOfficer> getAllExtensionOfficers() {
    return extensionOfficers;
  }

  List<AgroDealer> getAllAgroDealers() {
    return agroDealers;
  }

  List<ExtensionOfficer> getExtensionOfficersByDistrict(String district) {
    return extensionOfficers.where((eo) => eo.district == district).toList();
  }

  List<AgroDealer> getAgroDealersByDistrict(String district) {
    return agroDealers.where((ad) => ad.district == district).toList();
  }

  ExtensionOfficer? getNearestExtensionOfficer(
    double latitude,
    double longitude,
  ) {
    if (extensionOfficers.isEmpty) return null;

    ExtensionOfficer nearest = extensionOfficers.first;
    double minDistance = double.infinity;

    for (final officer in extensionOfficers) {
      final distance = Geolocator.distanceBetween(
        latitude,
        longitude,
        officer.latitude,
        officer.longitude,
      );
      if (distance < minDistance) {
        minDistance = distance;
        nearest = officer;
      }
    }

    return nearest;
  }

  AgroDealer? getNearestAgroDealer(double latitude, double longitude) {
    if (agroDealers.isEmpty) return null;

    AgroDealer nearest = agroDealers.first;
    double minDistance = double.infinity;

    for (final dealer in agroDealers) {
      final distance = Geolocator.distanceBetween(
        latitude,
        longitude,
        dealer.latitude,
        dealer.longitude,
      );
      if (distance < minDistance) {
        minDistance = distance;
        nearest = dealer;
      }
    }

    return nearest;
  }
}
