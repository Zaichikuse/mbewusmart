import 'package:cloud_firestore/cloud_firestore.dart';

/// Seeds the diagnosis_categories Firestore collection with common diagnoses.
/// Run once on app startup to populate the lookup table.
/// Safely handles duplicates by checking if diagnosis already exists.
class DiagnosisCategorySeeder {
  final FirebaseFirestore _firestore;

  DiagnosisCategorySeeder({FirebaseFirestore? firestore})
    : _firestore = firestore ?? FirebaseFirestore.instance;

  /// Pre-populated list of diagnoses from Gemini AI analysis.
  /// Maps each diagnosis name to its category and display names.
  static const List<DiagnosisCategory> _seedData = [
    // Maize - Pests
    DiagnosisCategory(
      diagnosisName: 'Fall Armyworm',
      crop: 'maize',
      category: 'pest',
      displayNameEnglish: 'Fall Armyworm',
      displayNameChichewa: 'Nkhomani za Masikidwe',
    ),
    DiagnosisCategory(
      diagnosisName: 'Maize Stem Borer',
      crop: 'maize',
      category: 'pest',
      displayNameEnglish: 'Maize Stem Borer',
      displayNameChichewa: 'Njira Yozizira Chimanga',
    ),
    DiagnosisCategory(
      diagnosisName: 'Armyworm',
      crop: 'maize',
      category: 'pest',
      displayNameEnglish: 'Armyworm',
      displayNameChichewa: 'Khumani za Njira',
    ),

    // Maize - Diseases
    DiagnosisCategory(
      diagnosisName: 'Gray Leaf Spot',
      crop: 'maize',
      category: 'disease',
      displayNameEnglish: 'Gray Leaf Spot',
      displayNameChichewa: 'Matenda a Mabala Akusefuka',
    ),
    DiagnosisCategory(
      diagnosisName: 'Northern Corn Leaf Blight',
      crop: 'maize',
      category: 'disease',
      displayNameEnglish: 'Northern Corn Leaf Blight',
      displayNameChichewa: 'Matenda a Mabala a Chimanga Kumtebvu',
    ),
    DiagnosisCategory(
      diagnosisName: 'Common Rust',
      crop: 'maize',
      category: 'disease',
      displayNameEnglish: 'Common Rust',
      displayNameChichewa: 'Kukhumbika Kwa Chimanga',
    ),
    DiagnosisCategory(
      diagnosisName: 'Anthracnose',
      crop: 'maize',
      category: 'disease',
      displayNameEnglish: 'Anthracnose',
      displayNameChichewa: 'Matenda a Mtaka',
    ),

    // Maize - Deficiencies
    DiagnosisCategory(
      diagnosisName: 'Nitrogen Deficiency',
      crop: 'maize',
      category: 'deficiency',
      displayNameEnglish: 'Nitrogen Deficiency',
      displayNameChichewa: 'Kudapitilira kwa Nitrogen',
    ),
    DiagnosisCategory(
      diagnosisName: 'Phosphorus Deficiency',
      crop: 'maize',
      category: 'deficiency',
      displayNameEnglish: 'Phosphorus Deficiency',
      displayNameChichewa: 'Kudapitilira kwa Phosphorus',
    ),
    DiagnosisCategory(
      diagnosisName: 'Iron Deficiency Chlorosis',
      crop: 'maize',
      category: 'deficiency',
      displayNameEnglish: 'Iron Deficiency Chlorosis',
      displayNameChichewa: 'Kudapitilira kwa Iron',
    ),

    // Cassava - Pests
    DiagnosisCategory(
      diagnosisName: 'Cassava Whitefly',
      crop: 'cassava',
      category: 'pest',
      displayNameEnglish: 'Cassava Whitefly',
      displayNameChichewa: 'Nkhomani Zimepukira za Cassava',
    ),
    DiagnosisCategory(
      diagnosisName: 'Cassava Mealybug',
      crop: 'cassava',
      category: 'pest',
      displayNameEnglish: 'Cassava Mealybug',
      displayNameChichewa: 'Njira Zochepa za Cassava',
    ),

    // Cassava - Diseases
    DiagnosisCategory(
      diagnosisName: 'Cassava Brown Streak Virus',
      crop: 'cassava',
      category: 'disease',
      displayNameEnglish: 'Cassava Brown Streak Virus',
      displayNameChichewa: 'Matenda a Cassava',
    ),
    DiagnosisCategory(
      diagnosisName: 'Cassava Mosaic Disease',
      crop: 'cassava',
      category: 'disease',
      displayNameEnglish: 'Cassava Mosaic Disease',
      displayNameChichewa: 'Matenda Owala a Cassava',
    ),

    // Cassava - Deficiencies
    DiagnosisCategory(
      diagnosisName: 'Cassava Potassium Deficiency',
      crop: 'cassava',
      category: 'deficiency',
      displayNameEnglish: 'Potassium Deficiency',
      displayNameChichewa: 'Kudapitilira kwa Potassium',
    ),

    // Tomato - Pests
    DiagnosisCategory(
      diagnosisName: 'Tomato Whitefly',
      crop: 'tomato',
      category: 'pest',
      displayNameEnglish: 'Tomato Whitefly',
      displayNameChichewa: 'Nkhomani Zimepukira za Tomato',
    ),
    DiagnosisCategory(
      diagnosisName: 'Tomato Hornworm',
      crop: 'tomato',
      category: 'pest',
      displayNameEnglish: 'Tomato Hornworm',
      displayNameChichewa: 'Khumani Kakulu ka Tomato',
    ),

    // Tomato - Diseases
    DiagnosisCategory(
      diagnosisName: 'Early Blight',
      crop: 'tomato',
      category: 'disease',
      displayNameEnglish: 'Early Blight',
      displayNameChichewa: 'Matenda a Tomato Kumbuyo',
    ),
    DiagnosisCategory(
      diagnosisName: 'Late Blight',
      crop: 'tomato',
      category: 'disease',
      displayNameEnglish: 'Late Blight',
      displayNameChichewa: 'Matenda a Tomato Kumapeto',
    ),
    DiagnosisCategory(
      diagnosisName: 'Bacterial Wilt',
      crop: 'tomato',
      category: 'disease',
      displayNameEnglish: 'Bacterial Wilt',
      displayNameChichewa: 'Matenda a Kasalidwe a Tomato',
    ),
    DiagnosisCategory(
      diagnosisName: 'Septoria Leaf Spot',
      crop: 'tomato',
      category: 'disease',
      displayNameEnglish: 'Septoria Leaf Spot',
      displayNameChichewa: 'Mabala a Tomato',
    ),

    // Tomato - Deficiencies
    DiagnosisCategory(
      diagnosisName: 'Tomato Calcium Deficiency',
      crop: 'tomato',
      category: 'deficiency',
      displayNameEnglish: 'Calcium Deficiency (Blossom End Rot)',
      displayNameChichewa: 'Kudapitilira kwa Calcium',
    ),
    DiagnosisCategory(
      diagnosisName: 'Magnesium Deficiency',
      crop: 'tomato',
      category: 'deficiency',
      displayNameEnglish: 'Magnesium Deficiency',
      displayNameChichewa: 'Kudapitilira kwa Magnesium',
    ),
  ];

  /// Seed the diagnosis_categories collection.
  /// Checks if each diagnosis already exists before inserting (idempotent).
  /// Returns the number of documents successfully seeded.
  Future<int> seed() async {
    try {
      int seededCount = 0;

      for (final diagnosis in _seedData) {
        final docRef = _firestore
            .collection('diagnosis_categories')
            .doc(diagnosis.diagnosisName);

        // Check if document exists
        final snapshot = await docRef.get();
        if (!snapshot.exists) {
          await docRef.set({
            'diagnosisName': diagnosis.diagnosisName,
            'crop': diagnosis.crop,
            'category': diagnosis.category,
            'displayNameEnglish': diagnosis.displayNameEnglish,
            'displayNameChichewa': diagnosis.displayNameChichewa,
            'createdAt': FieldValue.serverTimestamp(),
            'updatedAt': FieldValue.serverTimestamp(),
          });
          seededCount++;
        }
      }

      print(
        '[DiagnosisCategorySeeder] Seeded $seededCount diagnosis categories.',
      );
      return seededCount;
    } catch (e) {
      print('[DiagnosisCategorySeeder] Error seeding: $e');
      rethrow;
    }
  }

  /// Retrieves a diagnosis category from Firestore.
  /// Returns null if the diagnosis is not found.
  Future<String?> getCategory(String diagnosisName) async {
    try {
      final docRef = _firestore
          .collection('diagnosis_categories')
          .doc(diagnosisName);
      final snapshot = await docRef.get();

      if (snapshot.exists) {
        return snapshot.data()?['category'] as String?;
      }
      return null;
    } catch (e) {
      print('[DiagnosisCategorySeeder] Error fetching category: $e');
      return null;
    }
  }
}

/// Internal model for seed data.
class DiagnosisCategory {
  final String diagnosisName;
  final String crop;
  final String category; // 'pest', 'disease', 'deficiency'
  final String displayNameEnglish;
  final String displayNameChichewa;

  const DiagnosisCategory({
    required this.diagnosisName,
    required this.crop,
    required this.category,
    required this.displayNameEnglish,
    required this.displayNameChichewa,
  });
}
