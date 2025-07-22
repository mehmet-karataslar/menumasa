import 'package:cloud_firestore/cloud_firestore.dart';

/// Müşteri alerjen ve diyet profili
class AllergenProfile {
  final String customerId;
  
  // Alerjen bilgileri
  final List<String> allergens; // Müşterinin alerjisi olan maddeler
  final List<String> intolerances; // Hoşgörüsüzlükler (laktozsuzluk vb.)
  final Map<String, AllergenSeverity> allergenSeverity; // Alerjen şiddeti
  
  // Diyet tercihleri
  final List<String> dietaryRestrictions; // Diyet kısıtlamaları
  final List<String> dislikes; // Sevmediği yiyecekler
  final List<String> preferences; // Tercihleri
  final List<String> avoidIngredients; // Kaçınılacak içerikler
  
  // Ayarlar
  final bool showWarnings; // Alerjen uyarılarını göster
  final bool autoFilter; // Otomatik filtrele
  final bool strictMode; // Sıkı mod ("bulunabilir" uyarıları da dahil)
  final AllergenAlertLevel alertLevel; // Uyarı seviyesi
  
  // Sağlık bilgileri
  final String? medicalCondition; // Tıbbi durum
  final List<String> medications; // Kullandığı ilaçlar
  final String? doctorNotes; // Doktor notları
  final bool isVerifiedByDoctor; // Doktor onayı var mı?
  
  // Meta bilgiler
  final DateTime createdAt;
  final DateTime updatedAt;
  final DateTime? lastReviewDate; // Son gözden geçirme tarihi

  const AllergenProfile({
    required this.customerId,
    required this.allergens,
    required this.intolerances,
    required this.allergenSeverity,
    required this.dietaryRestrictions,
    required this.dislikes,
    required this.preferences,
    required this.avoidIngredients,
    required this.showWarnings,
    required this.autoFilter,
    required this.strictMode,
    required this.alertLevel,
    this.medicalCondition,
    required this.medications,
    this.doctorNotes,
    required this.isVerifiedByDoctor,
    required this.createdAt,
    required this.updatedAt,
    this.lastReviewDate,
  });

  /// Varsayılan profil oluştur
  factory AllergenProfile.defaultProfile(String customerId) {
    final now = DateTime.now();
    return AllergenProfile(
      customerId: customerId,
      allergens: [],
      intolerances: [],
      allergenSeverity: {},
      dietaryRestrictions: [],
      dislikes: [],
      preferences: [],
      avoidIngredients: [],
      showWarnings: true,
      autoFilter: false,
      strictMode: false,
      alertLevel: AllergenAlertLevel.medium,
      medications: [],
      isVerifiedByDoctor: false,
      createdAt: now,
      updatedAt: now,
    );
  }

  /// Firestore'dan oluşturma
  factory AllergenProfile.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    
    // Alerjen şiddetini parse et
    final severityMap = <String, AllergenSeverity>{};
    final severityData = data['allergenSeverity'] as Map<String, dynamic>? ?? {};
    for (final entry in severityData.entries) {
      severityMap[entry.key] = AllergenSeverity.values.firstWhere(
        (s) => s.toString() == entry.value,
        orElse: () => AllergenSeverity.medium,
      );
    }
    
    return AllergenProfile(
      customerId: doc.id,
      allergens: List<String>.from(data['allergens'] ?? []),
      intolerances: List<String>.from(data['intolerances'] ?? []),
      allergenSeverity: severityMap,
      dietaryRestrictions: List<String>.from(data['dietaryRestrictions'] ?? []),
      dislikes: List<String>.from(data['dislikes'] ?? []),
      preferences: List<String>.from(data['preferences'] ?? []),
      avoidIngredients: List<String>.from(data['avoidIngredients'] ?? []),
      showWarnings: data['showWarnings'] ?? true,
      autoFilter: data['autoFilter'] ?? false,
      strictMode: data['strictMode'] ?? false,
      alertLevel: AllergenAlertLevel.values.firstWhere(
        (level) => level.toString() == data['alertLevel'],
        orElse: () => AllergenAlertLevel.medium,
      ),
      medicalCondition: data['medicalCondition'],
      medications: List<String>.from(data['medications'] ?? []),
      doctorNotes: data['doctorNotes'],
      isVerifiedByDoctor: data['isVerifiedByDoctor'] ?? false,
      createdAt: (data['createdAt'] as Timestamp).toDate(),
      updatedAt: (data['updatedAt'] as Timestamp).toDate(),
      lastReviewDate: data['lastReviewDate'] != null
          ? (data['lastReviewDate'] as Timestamp).toDate()
          : null,
    );
  }

  /// Firestore'a dönüştürme
  Map<String, dynamic> toFirestore() {
    // Alerjen şiddetini string'e çevir
    final severityData = <String, String>{};
    for (final entry in allergenSeverity.entries) {
      severityData[entry.key] = entry.value.toString();
    }
    
    return {
      'allergens': allergens,
      'intolerances': intolerances,
      'allergenSeverity': severityData,
      'dietaryRestrictions': dietaryRestrictions,
      'dislikes': dislikes,
      'preferences': preferences,
      'avoidIngredients': avoidIngredients,
      'showWarnings': showWarnings,
      'autoFilter': autoFilter,
      'strictMode': strictMode,
      'alertLevel': alertLevel.toString(),
      'medicalCondition': medicalCondition,
      'medications': medications,
      'doctorNotes': doctorNotes,
      'isVerifiedByDoctor': isVerifiedByDoctor,
      'createdAt': Timestamp.fromDate(createdAt),
      'updatedAt': Timestamp.fromDate(updatedAt),
      'lastReviewDate': lastReviewDate != null 
          ? Timestamp.fromDate(lastReviewDate!) 
          : null,
    };
  }

  /// Kopya oluşturma
  AllergenProfile copyWith({
    List<String>? allergens,
    List<String>? intolerances,
    Map<String, AllergenSeverity>? allergenSeverity,
    List<String>? dietaryRestrictions,
    List<String>? dislikes,
    List<String>? preferences,
    List<String>? avoidIngredients,
    bool? showWarnings,
    bool? autoFilter,
    bool? strictMode,
    AllergenAlertLevel? alertLevel,
    String? medicalCondition,
    List<String>? medications,
    String? doctorNotes,
    bool? isVerifiedByDoctor,
    DateTime? updatedAt,
    DateTime? lastReviewDate,
  }) {
    return AllergenProfile(
      customerId: customerId,
      allergens: allergens ?? this.allergens,
      intolerances: intolerances ?? this.intolerances,
      allergenSeverity: allergenSeverity ?? this.allergenSeverity,
      dietaryRestrictions: dietaryRestrictions ?? this.dietaryRestrictions,
      dislikes: dislikes ?? this.dislikes,
      preferences: preferences ?? this.preferences,
      avoidIngredients: avoidIngredients ?? this.avoidIngredients,
      showWarnings: showWarnings ?? this.showWarnings,
      autoFilter: autoFilter ?? this.autoFilter,
      strictMode: strictMode ?? this.strictMode,
      alertLevel: alertLevel ?? this.alertLevel,
      medicalCondition: medicalCondition ?? this.medicalCondition,
      medications: medications ?? this.medications,
      doctorNotes: doctorNotes ?? this.doctorNotes,
      isVerifiedByDoctor: isVerifiedByDoctor ?? this.isVerifiedByDoctor,
      createdAt: createdAt,
      updatedAt: updatedAt ?? DateTime.now(),
      lastReviewDate: lastReviewDate ?? this.lastReviewDate,
    );
  }

  // ============================================================================
  // HELPER METHODS
  // ============================================================================

  /// Alerjen ekle
  AllergenProfile addAllergen(String allergen, {AllergenSeverity? severity}) {
    if (allergens.contains(allergen)) return this;
    
    final newAllergens = List<String>.from(allergens)..add(allergen);
    final newSeverity = Map<String, AllergenSeverity>.from(allergenSeverity);
    
    if (severity != null) {
      newSeverity[allergen] = severity;
    }
    
    return copyWith(
      allergens: newAllergens,
      allergenSeverity: newSeverity,
      updatedAt: DateTime.now(),
    );
  }

  /// Alerjen çıkar
  AllergenProfile removeAllergen(String allergen) {
    final newAllergens = List<String>.from(allergens)..remove(allergen);
    final newSeverity = Map<String, AllergenSeverity>.from(allergenSeverity);
    newSeverity.remove(allergen);
    
    return copyWith(
      allergens: newAllergens,
      allergenSeverity: newSeverity,
      updatedAt: DateTime.now(),
    );
  }

  /// Diyet kısıtlaması ekle
  AllergenProfile addDietaryRestriction(String restriction) {
    if (dietaryRestrictions.contains(restriction)) return this;
    
    final newRestrictions = List<String>.from(dietaryRestrictions)..add(restriction);
    return copyWith(
      dietaryRestrictions: newRestrictions,
      updatedAt: DateTime.now(),
    );
  }

  /// Diyet kısıtlaması çıkar
  AllergenProfile removeDietaryRestriction(String restriction) {
    final newRestrictions = List<String>.from(dietaryRestrictions)..remove(restriction);
    return copyWith(
      dietaryRestrictions: newRestrictions,
      updatedAt: DateTime.now(),
    );
  }

  /// Sevmediği yemek ekle
  AllergenProfile addDislike(String food) {
    if (dislikes.contains(food)) return this;
    
    final newDislikes = List<String>.from(dislikes)..add(food);
    return copyWith(
      dislikes: newDislikes,
      updatedAt: DateTime.now(),
    );
  }

  /// Alerjen şiddetini güncelle
  AllergenProfile updateAllergenSeverity(String allergen, AllergenSeverity severity) {
    final newSeverity = Map<String, AllergenSeverity>.from(allergenSeverity);
    newSeverity[allergen] = severity;
    
    return copyWith(
      allergenSeverity: newSeverity,
      updatedAt: DateTime.now(),
    );
  }

  /// Ürün güvenli mi kontrol et
  ProductSafetyResult checkProductSafety(
    List<String> productAllergens,
    List<String> productMayContain,
    List<String> productIngredients,
    List<String> productSpecialDiets,
  ) {
    final warnings = <String>[];
    final blocks = <String>[];
    var riskLevel = RiskLevel.safe;

    // Ana allerjenler kontrol
    for (final allergen in allergens) {
      if (productAllergens.any((pa) => pa.toLowerCase() == allergen.toLowerCase())) {
        final severity = allergenSeverity[allergen] ?? AllergenSeverity.medium;
        blocks.add('İçerir: $allergen (${severity.displayName})');
        riskLevel = RiskLevel.dangerous;
      }
    }

    // "Bulunabilir" uyarıları (sıkı modda)
    if (strictMode) {
      for (final allergen in allergens) {
        if (productMayContain.any((pa) => pa.toLowerCase() == allergen.toLowerCase())) {
          warnings.add('Bulunabilir: $allergen');
          if (riskLevel == RiskLevel.safe) riskLevel = RiskLevel.warning;
        }
      }
    }

    // Hoşgörüsüzlükler kontrol
    for (final intolerance in intolerances) {
      if (productAllergens.any((pa) => pa.toLowerCase() == intolerance.toLowerCase()) ||
          productIngredients.any((pi) => pi.toLowerCase().contains(intolerance.toLowerCase()))) {
        warnings.add('Hoşgörüsüzlük: $intolerance');
        if (riskLevel == RiskLevel.safe) riskLevel = RiskLevel.warning;
      }
    }

    // Diyet kısıtlamaları kontrol
    for (final restriction in dietaryRestrictions) {
      if (!productSpecialDiets.contains(restriction)) {
        final compatibilityCheck = _checkDietCompatibility(restriction, productIngredients);
        if (!compatibilityCheck.isCompatible) {
          warnings.add('Diyet uyumsuzluğu: ${compatibilityCheck.reason}');
          if (riskLevel == RiskLevel.safe) riskLevel = RiskLevel.warning;
        }
      }
    }

    // Kaçınılacak içerikler kontrol
    for (final avoid in avoidIngredients) {
      if (productIngredients.any((pi) => pi.toLowerCase().contains(avoid.toLowerCase()))) {
        warnings.add('Kaçınılacak içerik: $avoid');
        if (riskLevel == RiskLevel.safe) riskLevel = RiskLevel.warning;
      }
    }

    // Sevmediği yemekler kontrol
    for (final dislike in dislikes) {
      if (productIngredients.any((pi) => pi.toLowerCase().contains(dislike.toLowerCase()))) {
        warnings.add('Sevmediğiniz: $dislike');
      }
    }

    return ProductSafetyResult(
      riskLevel: riskLevel,
      warnings: warnings,
      blocks: blocks,
      canConsume: riskLevel != RiskLevel.dangerous,
      shouldShowWarning: warnings.isNotEmpty || blocks.isNotEmpty,
    );
  }

  /// Diyet uyumluluğu kontrol
  DietCompatibilityResult _checkDietCompatibility(String diet, List<String> ingredients) {
    switch (diet.toLowerCase()) {
      case 'vegetarian':
        final meatIngredients = ['et', 'tavuk', 'balık', 'hindi', 'kuzu', 'dana'];
        for (final meat in meatIngredients) {
          if (ingredients.any((ing) => ing.toLowerCase().contains(meat))) {
            return DietCompatibilityResult(false, 'Et ürünü içerir');
          }
        }
        return DietCompatibilityResult(true, '');
        
      case 'vegan':
        final animalProducts = ['et', 'tavuk', 'balık', 'süt', 'peynir', 'yumurta', 'bal'];
        for (final animal in animalProducts) {
          if (ingredients.any((ing) => ing.toLowerCase().contains(animal))) {
            return DietCompatibilityResult(false, 'Hayvansal ürün içerir');
          }
        }
        return DietCompatibilityResult(true, '');
        
      case 'halal':
        final haram = ['domuz', 'alkol', 'şarap'];
        for (final h in haram) {
          if (ingredients.any((ing) => ing.toLowerCase().contains(h))) {
            return DietCompatibilityResult(false, 'Haram madde içerir');
          }
        }
        return DietCompatibilityResult(true, '');
        
      case 'keto':
        // Yüksek karbonhidrat kontrolü gerekli (başka sistemde)
        return DietCompatibilityResult(true, '');
        
      default:
        return DietCompatibilityResult(true, '');
    }
  }

  /// Profil tamamlık yüzdesi
  double get completenessPercentage {
    int completedFields = 0;
    const totalFields = 6;

    if (allergens.isNotEmpty) completedFields++;
    if (dietaryRestrictions.isNotEmpty) completedFields++;
    if (preferences.isNotEmpty) completedFields++;
    if (medicalCondition != null) completedFields++;
    if (isVerifiedByDoctor) completedFields++;
    if (lastReviewDate != null) completedFields++;

    return (completedFields / totalFields) * 100;
  }

  /// Risk seviyesi hesapla
  RiskLevel get overallRiskLevel {
    if (allergens.isEmpty) return RiskLevel.safe;
    
    final highRiskCount = allergenSeverity.values
        .where((severity) => severity == AllergenSeverity.severe || severity == AllergenSeverity.lifeThreatening)
        .length;
    
    if (highRiskCount > 0) return RiskLevel.dangerous;
    if (allergens.length > 3) return RiskLevel.warning;
    return RiskLevel.moderate;
  }

  /// Gözden geçirme gerekli mi?
  bool get needsReview {
    if (lastReviewDate == null) return true;
    
    final daysSinceReview = DateTime.now().difference(lastReviewDate!).inDays;
    return daysSinceReview > 90; // 3 ayda bir gözden geçirme
  }

  @override
  String toString() {
    return 'AllergenProfile(customerId: $customerId, allergens: ${allergens.length}, restrictions: ${dietaryRestrictions.length})';
  }
}

/// Alerjen şiddeti seviyeleri
enum AllergenSeverity {
  mild('Hafif'),
  medium('Orta'),
  severe('Şiddetli'),
  lifeThreatening('Yaşamı Tehdit Edici');

  const AllergenSeverity(this.displayName);
  final String displayName;
}

/// Alerjen uyarı seviyesi
enum AllergenAlertLevel {
  low('Düşük'),
  medium('Orta'),
  high('Yüksek'),
  maximum('Maksimum');

  const AllergenAlertLevel(this.displayName);
  final String displayName;
}

/// Risk seviyesi
enum RiskLevel {
  safe('Güvenli'),
  moderate('Dikkatli'),
  warning('Uyarı'),
  dangerous('Tehlikeli');

  const RiskLevel(this.displayName);
  final String displayName;
}

/// Ürün güvenlik sonucu
class ProductSafetyResult {
  final RiskLevel riskLevel;
  final List<String> warnings;
  final List<String> blocks;
  final bool canConsume;
  final bool shouldShowWarning;

  const ProductSafetyResult({
    required this.riskLevel,
    required this.warnings,
    required this.blocks,
    required this.canConsume,
    required this.shouldShowWarning,
  });
}

/// Diyet uyumluluk sonucu
class DietCompatibilityResult {
  final bool isCompatible;
  final String reason;

  const DietCompatibilityResult(this.isCompatible, this.reason);
}

/// Yaygın allerjenler
class CommonAllergens {
  static const List<String> main = [
    'Süt ve süt ürünleri',
    'Yumurta',
    'Balık',
    'Kabuklu deniz hayvanları',
    'Fındık, badem vb. kabuklu yemişler',
    'Yer fıstığı',
    'Soya',
    'Buğday (gluten)',
  ];

  static const List<String> additional = [
    'Susam',
    'Kükürt dioksit',
    'Selderya',
    'Hardal',
    'Lupin',
    'Yumuşakçalar',
  ];

  static const List<String> common = [
    'Laktoz',
    'Gluten',
    'Fruktoz',
    'Histamin',
    'Kafein',
  ];
} 