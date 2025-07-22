import 'package:cloud_firestore/cloud_firestore.dart';
import 'dart:math' as math;

/// Detaylı beslenme bilgisi modeli
class DetailedNutritionInfo {
  final String productId;
  
  // Temel besin değerleri (100g için)
  final double? calories; // kcal
  final double? protein; // g
  final double? carbs; // g
  final double? fat; // g
  final double? fiber; // g
  final double? sugar; // g
  final double? sodium; // mg
  final double? saturatedFat; // g
  final double? transFat; // g
  final double? cholesterol; // mg
  final double? potassium; // mg
  
  // Vitaminler (günlük ihtiyacın yüzdesi)
  final Map<String, double> vitamins; // vitamin adı -> % değeri
  final Map<String, double> minerals; // mineral adı -> % değeri
  
  // Porsiyon bilgileri
  final String servingSize; // "100g", "1 adet", "1 dilim"
  final double servingSizeGrams; // gram cinsinden
  final int? servingsPerContainer;
  
  // Sertifikalar ve özel durumlar
  final List<String> certifications; // ["organik", "helal", "kosher", "fair-trade"]
  final List<String> specialDiets; // ["vegetarian", "vegan", "keto", "paleo"]
  final String? ingredients; // İçerik listesi
  final List<String> allergens; // Alerjen uyarıları
  final List<String> mayContain; // "Bulunabilir" uyarıları
  
  // Ek bilgiler
  final String? additionalInfo;
  final bool isApproved; // Beslenme uzmanı onayı
  final DateTime? lastUpdated;
  final String? verifiedBy; // Onaylayan kişi/kurum

  const DetailedNutritionInfo({
    required this.productId,
    this.calories,
    this.protein,
    this.carbs,
    this.fat,
    this.fiber,
    this.sugar,
    this.sodium,
    this.saturatedFat,
    this.transFat,
    this.cholesterol,
    this.potassium,
    required this.vitamins,
    required this.minerals,
    required this.servingSize,
    required this.servingSizeGrams,
    this.servingsPerContainer,
    required this.certifications,
    required this.specialDiets,
    this.ingredients,
    required this.allergens,
    required this.mayContain,
    this.additionalInfo,
    required this.isApproved,
    this.lastUpdated,
    this.verifiedBy,
  });

  /// Boş beslenme bilgisi oluştur
  factory DetailedNutritionInfo.empty(String productId) {
    return DetailedNutritionInfo(
      productId: productId,
      vitamins: {},
      minerals: {},
      servingSize: '100g',
      servingSizeGrams: 100.0,
      certifications: [],
      specialDiets: [],
      allergens: [],
      mayContain: [],
      isApproved: false,
    );
  }

  /// Firestore'dan oluşturma
  factory DetailedNutritionInfo.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    
    return DetailedNutritionInfo(
      productId: doc.id,
      calories: data['calories']?.toDouble(),
      protein: data['protein']?.toDouble(),
      carbs: data['carbs']?.toDouble(),
      fat: data['fat']?.toDouble(),
      fiber: data['fiber']?.toDouble(),
      sugar: data['sugar']?.toDouble(),
      sodium: data['sodium']?.toDouble(),
      saturatedFat: data['saturatedFat']?.toDouble(),
      transFat: data['transFat']?.toDouble(),
      cholesterol: data['cholesterol']?.toDouble(),
      potassium: data['potassium']?.toDouble(),
      vitamins: Map<String, double>.from(data['vitamins'] ?? {}),
      minerals: Map<String, double>.from(data['minerals'] ?? {}),
      servingSize: data['servingSize'] ?? '100g',
      servingSizeGrams: data['servingSizeGrams']?.toDouble() ?? 100.0,
      servingsPerContainer: data['servingsPerContainer'],
      certifications: List<String>.from(data['certifications'] ?? []),
      specialDiets: List<String>.from(data['specialDiets'] ?? []),
      ingredients: data['ingredients'],
      allergens: List<String>.from(data['allergens'] ?? []),
      mayContain: List<String>.from(data['mayContain'] ?? []),
      additionalInfo: data['additionalInfo'],
      isApproved: data['isApproved'] ?? false,
      lastUpdated: data['lastUpdated'] != null 
          ? (data['lastUpdated'] as Timestamp).toDate()
          : null,
      verifiedBy: data['verifiedBy'],
    );
  }

  /// Firestore'a dönüştürme
  Map<String, dynamic> toFirestore() {
    return {
      'calories': calories,
      'protein': protein,
      'carbs': carbs,
      'fat': fat,
      'fiber': fiber,
      'sugar': sugar,
      'sodium': sodium,
      'saturatedFat': saturatedFat,
      'transFat': transFat,
      'cholesterol': cholesterol,
      'potassium': potassium,
      'vitamins': vitamins,
      'minerals': minerals,
      'servingSize': servingSize,
      'servingSizeGrams': servingSizeGrams,
      'servingsPerContainer': servingsPerContainer,
      'certifications': certifications,
      'specialDiets': specialDiets,
      'ingredients': ingredients,
      'allergens': allergens,
      'mayContain': mayContain,
      'additionalInfo': additionalInfo,
      'isApproved': isApproved,
      'lastUpdated': lastUpdated != null ? Timestamp.fromDate(lastUpdated!) : null,
      'verifiedBy': verifiedBy,
    };
  }

  /// Kopya oluşturma
  DetailedNutritionInfo copyWith({
    double? calories,
    double? protein,
    double? carbs,
    double? fat,
    double? fiber,
    double? sugar,
    double? sodium,
    double? saturatedFat,
    double? transFat,
    double? cholesterol,
    double? potassium,
    Map<String, double>? vitamins,
    Map<String, double>? minerals,
    String? servingSize,
    double? servingSizeGrams,
    int? servingsPerContainer,
    List<String>? certifications,
    List<String>? specialDiets,
    String? ingredients,
    List<String>? allergens,
    List<String>? mayContain,
    String? additionalInfo,
    bool? isApproved,
    DateTime? lastUpdated,
    String? verifiedBy,
  }) {
    return DetailedNutritionInfo(
      productId: productId,
      calories: calories ?? this.calories,
      protein: protein ?? this.protein,
      carbs: carbs ?? this.carbs,
      fat: fat ?? this.fat,
      fiber: fiber ?? this.fiber,
      sugar: sugar ?? this.sugar,
      sodium: sodium ?? this.sodium,
      saturatedFat: saturatedFat ?? this.saturatedFat,
      transFat: transFat ?? this.transFat,
      cholesterol: cholesterol ?? this.cholesterol,
      potassium: potassium ?? this.potassium,
      vitamins: vitamins ?? this.vitamins,
      minerals: minerals ?? this.minerals,
      servingSize: servingSize ?? this.servingSize,
      servingSizeGrams: servingSizeGrams ?? this.servingSizeGrams,
      servingsPerContainer: servingsPerContainer ?? this.servingsPerContainer,
      certifications: certifications ?? this.certifications,
      specialDiets: specialDiets ?? this.specialDiets,
      ingredients: ingredients ?? this.ingredients,
      allergens: allergens ?? this.allergens,
      mayContain: mayContain ?? this.mayContain,
      additionalInfo: additionalInfo ?? this.additionalInfo,
      isApproved: isApproved ?? this.isApproved,
      lastUpdated: lastUpdated ?? this.lastUpdated,
      verifiedBy: verifiedBy ?? this.verifiedBy,
    );
  }

  // ============================================================================
  // HELPER METHODS
  // ============================================================================

  /// Toplam karbonhidrat hesapla
  double? get totalCarbs {
    if (carbs == null) return null;
    return carbs;
  }

  /// Net karbonhidrat hesapla (toplam - lif)
  double? get netCarbs {
    if (carbs == null) return null;
    final fiberValue = fiber ?? 0;
    return carbs! - fiberValue;
  }

  /// Kalori yoğunluğu (kalori/gram)
  double? get caloriesPerGram {
    if (calories == null || servingSizeGrams == 0) return null;
    return calories! / servingSizeGrams;
  }

  /// Protein yüzdesi
  double? get proteinPercentage {
    if (protein == null || calories == null || calories! == 0) return null;
    return (protein! * 4) / calories! * 100; // 1g protein = 4 kalori
  }

  /// Karbonhidrat yüzdesi
  double? get carbsPercentage {
    if (carbs == null || calories == null || calories! == 0) return null;
    return (carbs! * 4) / calories! * 100; // 1g karbonhidrat = 4 kalori
  }

  /// Yağ yüzdesi
  double? get fatPercentage {
    if (fat == null || calories == null || calories! == 0) return null;
    return (fat! * 9) / calories! * 100; // 1g yağ = 9 kalori
  }

  /// Beslenme puanı hesapla (0-100)
  double calculateNutritionScore() {
    double score = 0;
    int factors = 0;

    // Protein içeriği (yüksek protein +puan)
    if (protein != null) {
      score += protein! > 20 ? 20 : protein!;
      factors++;
    }

    // Lif içeriği (yüksek lif +puan)
    if (fiber != null) {
      score += fiber! > 10 ? 20 : fiber! * 2;
      factors++;
    }

    // Şeker içeriği (düşük şeker +puan)
    if (sugar != null) {
      score += sugar! < 5 ? 20 : math.max(0, 20 - sugar!);
      factors++;
    }

    // Doymuş yağ (düşük doymuş yağ +puan)
    if (saturatedFat != null) {
      score += saturatedFat! < 3 ? 20 : math.max(0, 20 - saturatedFat! * 3);
      factors++;
    }

    // Sodyum (düşük sodyum +puan)
    if (sodium != null) {
      final sodiumG = sodium! / 1000; // mg to g
      score += sodiumG < 0.5 ? 20 : math.max(0, 20 - sodiumG * 40);
      factors++;
    }

    return factors > 0 ? score / factors : 0;
  }

  /// Diyet uyumluluğu kontrol et
  bool isCompatibleWithDiet(String diet) {
    return specialDiets.contains(diet.toLowerCase());
  }

  /// Alerjen içeriyor mu?
  bool containsAllergen(String allergen) {
    return allergens.any((a) => a.toLowerCase() == allergen.toLowerCase()) ||
           mayContain.any((a) => a.toLowerCase() == allergen.toLowerCase());
  }

  /// Vitamin/mineral eksiklik uyarısı
  List<String> getNutrientDeficiencies() {
    final deficiencies = <String>[];
    
    // Temel besinler için minimum değerler
    const minimums = {
      'protein': 10.0,
      'fiber': 3.0,
      'vitamin-c': 10.0,
      'calcium': 10.0,
      'iron': 10.0,
    };

    if (protein != null && protein! < minimums['protein']!) {
      deficiencies.add('Düşük protein');
    }

    if (fiber != null && fiber! < minimums['fiber']!) {
      deficiencies.add('Düşük lif');
    }

    for (final entry in vitamins.entries) {
      if (entry.value < (minimums[entry.key] ?? 10.0)) {
        deficiencies.add('Düşük ${entry.key}');
      }
    }

    return deficiencies;
  }

  /// Sağlık uyarıları
  List<String> getHealthWarnings() {
    final warnings = <String>[];

    if (calories != null && calories! > 500) {
      warnings.add('Yüksek kalorili');
    }

    if (sugar != null && sugar! > 15) {
      warnings.add('Yüksek şeker içeriği');
    }

    if (saturatedFat != null && saturatedFat! > 10) {
      warnings.add('Yüksek doymuş yağ');
    }

    if (sodium != null && sodium! > 1000) {
      warnings.add('Yüksek sodyum');
    }

    if (transFat != null && transFat! > 0) {
      warnings.add('Trans yağ içerir');
    }

    return warnings;
  }

  @override
  String toString() {
    return 'DetailedNutritionInfo(productId: $productId, calories: $calories, isApproved: $isApproved)';
  }
}

/// Vitamin ve mineral sabitleri
class NutrientConstants {
  // Günlük önerilen değerler (RDA)
  static const Map<String, double> dailyValues = {
    // Vitaminler (mg/µg)
    'vitamin-a': 900, // µg
    'vitamin-c': 90, // mg
    'vitamin-d': 20, // µg
    'vitamin-e': 15, // mg
    'vitamin-k': 120, // µg
    'thiamin': 1.2, // mg
    'riboflavin': 1.3, // mg
    'niacin': 16, // mg
    'vitamin-b6': 1.7, // mg
    'folate': 400, // µg
    'vitamin-b12': 2.4, // µg
    
    // Mineraller (mg/g)
    'calcium': 1000, // mg
    'iron': 18, // mg
    'magnesium': 400, // mg
    'phosphorus': 1250, // mg
    'potassium': 4700, // mg
    'sodium': 2300, // mg
    'zinc': 11, // mg
    'copper': 0.9, // mg
    'manganese': 2.3, // mg
    'selenium': 55, // µg
  };

  /// Besin değerinden yüzde hesapla
  static double calculatePercentDV(String nutrient, double amount) {
    final dv = dailyValues[nutrient.toLowerCase()];
    if (dv == null) return 0;
    return (amount / dv) * 100;
  }
}

 