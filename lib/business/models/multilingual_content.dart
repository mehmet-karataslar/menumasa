import 'package:cloud_firestore/cloud_firestore.dart';

/// Çok dilli içerik modeli - İşletme ürün ve kategori adları için
class MultilingualContent {
  final String id;
  final String entityId; // Product ID, Category ID, Business ID
  final String entityType; // 'product', 'category', 'business'
  final String fieldName; // 'name', 'description', 'address'
  final Map<String, String> translations; // languageCode -> content
  final String defaultLanguage;
  final DateTime createdAt;
  final DateTime updatedAt;

  const MultilingualContent({
    required this.id,
    required this.entityId,
    required this.entityType,
    required this.fieldName,
    required this.translations,
    required this.defaultLanguage,
    required this.createdAt,
    required this.updatedAt,
  });

  /// Yeni çok dilli içerik oluştur
  factory MultilingualContent.create({
    required String entityId,
    required String entityType,
    required String fieldName,
    required String defaultLanguage,
    required String defaultContent,
  }) {
    final now = DateTime.now();
    return MultilingualContent(
      id: '${entityType}_${entityId}_${fieldName}_${now.millisecondsSinceEpoch}',
      entityId: entityId,
      entityType: entityType,
      fieldName: fieldName,
      translations: {defaultLanguage: defaultContent},
      defaultLanguage: defaultLanguage,
      createdAt: now,
      updatedAt: now,
    );
  }

  /// Firestore'dan oluşturma
  factory MultilingualContent.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    
    return MultilingualContent(
      id: doc.id,
      entityId: data['entityId'] ?? '',
      entityType: data['entityType'] ?? '',
      fieldName: data['fieldName'] ?? '',
      translations: Map<String, String>.from(data['translations'] ?? {}),
      defaultLanguage: data['defaultLanguage'] ?? 'tr',
      createdAt: (data['createdAt'] as Timestamp).toDate(),
      updatedAt: (data['updatedAt'] as Timestamp).toDate(),
    );
  }

  /// Firestore'a dönüştürme
  Map<String, dynamic> toFirestore() {
    return {
      'entityId': entityId,
      'entityType': entityType,
      'fieldName': fieldName,
      'translations': translations,
      'defaultLanguage': defaultLanguage,
      'createdAt': Timestamp.fromDate(createdAt),
      'updatedAt': Timestamp.fromDate(updatedAt),
    };
  }

  /// Kopya oluşturma
  MultilingualContent copyWith({
    Map<String, String>? translations,
    String? defaultLanguage,
    DateTime? updatedAt,
  }) {
    return MultilingualContent(
      id: id,
      entityId: entityId,
      entityType: entityType,
      fieldName: fieldName,
      translations: translations ?? this.translations,
      defaultLanguage: defaultLanguage ?? this.defaultLanguage,
      createdAt: createdAt,
      updatedAt: updatedAt ?? DateTime.now(),
    );
  }

  /// Belirtilen dilde içeriği al
  String getTranslation(String languageCode) {
    // İstenen dildeki çeviriyi döndür
    if (translations.containsKey(languageCode)) {
      return translations[languageCode]!;
    }
    
    // İstenen dil yoksa varsayılan dili döndür
    if (translations.containsKey(defaultLanguage)) {
      return translations[defaultLanguage]!;
    }
    
    // Varsayılan dil de yoksa ilk bulunan çeviriyi döndür
    if (translations.isNotEmpty) {
      return translations.values.first;
    }
    
    // Hiçbir çeviri yoksa boş string
    return '';
  }

  /// Çeviri ekle veya güncelle
  MultilingualContent addTranslation(String languageCode, String content) {
    final updatedTranslations = Map<String, String>.from(translations);
    updatedTranslations[languageCode] = content;
    
    return copyWith(
      translations: updatedTranslations,
      updatedAt: DateTime.now(),
    );
  }

  /// Çeviriyi sil
  MultilingualContent removeTranslation(String languageCode) {
    if (languageCode == defaultLanguage) {
      throw ArgumentError('Varsayılan dil çevirisi silinemez');
    }
    
    final updatedTranslations = Map<String, String>.from(translations);
    updatedTranslations.remove(languageCode);
    
    return copyWith(
      translations: updatedTranslations,
      updatedAt: DateTime.now(),
    );
  }

  /// Mevcut çevirilerin listesi
  List<String> get availableLanguages => translations.keys.toList();

  /// Eksik çevirilerin listesi
  List<String> getMissingTranslations(List<String> requiredLanguages) {
    return requiredLanguages.where((lang) => !translations.containsKey(lang)).toList();
  }

  /// Çeviri tamamlanma yüzdesi
  double getCompletionPercentage(List<String> targetLanguages) {
    if (targetLanguages.isEmpty) return 100.0;
    
    final availableCount = targetLanguages.where((lang) => translations.containsKey(lang)).length;
    return (availableCount / targetLanguages.length) * 100.0;
  }

  /// Otomatik çeviri için hazır mı?
  bool get isReadyForAutoTranslation {
    return translations.containsKey(defaultLanguage) && 
           translations[defaultLanguage]!.isNotEmpty;
  }

  @override
  String toString() {
    return 'MultilingualContent(id: $id, entityType: $entityType, fieldName: $fieldName, languages: ${availableLanguages.join(', ')})';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    
    return other is MultilingualContent &&
        other.id == id &&
        other.entityId == entityId &&
        other.fieldName == fieldName;
  }

  @override
  int get hashCode {
    return id.hashCode ^ entityId.hashCode ^ fieldName.hashCode;
  }
}

/// Çok dilli içerik yardımcı sınıfı
class MultilingualContentHelper {
  /// Entity için tüm çok dilli içerikleri al
  static String generateContentId({
    required String entityId,
    required String entityType,
    required String fieldName,
  }) {
    return '${entityType}_${entityId}_$fieldName';
  }

  /// Desteklenen entity türleri
  static const List<String> supportedEntityTypes = [
    'product',
    'category',
    'business',
    'discount',
  ];

  /// Desteklenen alan adları
  static const Map<String, List<String>> supportedFields = {
    'product': ['name', 'description', 'shortDescription'],
    'category': ['name', 'description'],
    'business': ['businessName', 'description', 'businessAddress'],
    'discount': ['title', 'description'],
  };

  /// Entity türü için desteklenen alanları al
  static List<String> getSupportedFields(String entityType) {
    return supportedFields[entityType] ?? [];
  }

  /// Alan adının desteklenip desteklenmediğini kontrol et
  static bool isFieldSupported(String entityType, String fieldName) {
    return getSupportedFields(entityType).contains(fieldName);
  }
} 