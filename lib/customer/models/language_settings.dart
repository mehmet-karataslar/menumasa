import 'package:cloud_firestore/cloud_firestore.dart';

/// Müşteri dil ayarları modeli
class LanguageSettings {
  final String customerId;
  final String preferredLanguage; // 'tr', 'en', 'ar', 'de', 'ru', 'fr'
  final bool autoDetectLanguage;
  final bool translateMenuAutomatically;
  final Map<String, String> customTranslations;
  final String fallbackLanguage; // Tercih edilen dil mevcut değilse
  final DateTime createdAt;
  final DateTime updatedAt;

  const LanguageSettings({
    required this.customerId,
    required this.preferredLanguage,
    required this.autoDetectLanguage,
    required this.translateMenuAutomatically,
    required this.customTranslations,
    required this.fallbackLanguage,
    required this.createdAt,
    required this.updatedAt,
  });

  /// Varsayılan dil ayarları
  factory LanguageSettings.defaultSettings(String customerId) {
    final now = DateTime.now();
    return LanguageSettings(
      customerId: customerId,
      preferredLanguage: 'tr', // Türkçe varsayılan
      autoDetectLanguage: true,
      translateMenuAutomatically: false,
      customTranslations: {},
      fallbackLanguage: 'en',
      createdAt: now,
      updatedAt: now,
    );
  }

  /// Firestore'dan oluşturma
  factory LanguageSettings.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    
    return LanguageSettings(
      customerId: doc.id,
      preferredLanguage: data['preferredLanguage'] ?? 'tr',
      autoDetectLanguage: data['autoDetectLanguage'] ?? true,
      translateMenuAutomatically: data['translateMenuAutomatically'] ?? false,
      customTranslations: Map<String, String>.from(data['customTranslations'] ?? {}),
      fallbackLanguage: data['fallbackLanguage'] ?? 'en',
      createdAt: (data['createdAt'] as Timestamp).toDate(),
      updatedAt: (data['updatedAt'] as Timestamp).toDate(),
    );
  }

  /// Firestore'a dönüştürme
  Map<String, dynamic> toFirestore() {
    return {
      'preferredLanguage': preferredLanguage,
      'autoDetectLanguage': autoDetectLanguage,
      'translateMenuAutomatically': translateMenuAutomatically,
      'customTranslations': customTranslations,
      'fallbackLanguage': fallbackLanguage,
      'createdAt': Timestamp.fromDate(createdAt),
      'updatedAt': Timestamp.fromDate(updatedAt),
    };
  }

  /// Kopya oluşturma
  LanguageSettings copyWith({
    String? preferredLanguage,
    bool? autoDetectLanguage,
    bool? translateMenuAutomatically,
    Map<String, String>? customTranslations,
    String? fallbackLanguage,
    DateTime? updatedAt,
  }) {
    return LanguageSettings(
      customerId: customerId,
      preferredLanguage: preferredLanguage ?? this.preferredLanguage,
      autoDetectLanguage: autoDetectLanguage ?? this.autoDetectLanguage,
      translateMenuAutomatically: translateMenuAutomatically ?? this.translateMenuAutomatically,
      customTranslations: customTranslations ?? this.customTranslations,
      fallbackLanguage: fallbackLanguage ?? this.fallbackLanguage,
      createdAt: createdAt,
      updatedAt: updatedAt ?? DateTime.now(),
    );
  }

  /// Desteklenen diller
  static const List<SupportedLanguage> supportedLanguages = [
    SupportedLanguage('tr', 'Türkçe', '🇹🇷'),
    SupportedLanguage('en', 'English', '🇺🇸'),
    SupportedLanguage('ar', 'العربية', '🇸🇦'),
    SupportedLanguage('de', 'Deutsch', '🇩🇪'),
    SupportedLanguage('ru', 'Русский', '🇷🇺'),
    SupportedLanguage('fr', 'Français', '🇫🇷'),
  ];

  /// Dil kodundan dil bilgisi al
  static SupportedLanguage? getLanguageInfo(String languageCode) {
    try {
      return supportedLanguages.firstWhere((lang) => lang.code == languageCode);
    } catch (e) {
      return null;
    }
  }

  /// Sistem dilini algıla
  static String detectSystemLanguage() {
    // Platform'dan sistem dili alınacak
    // Şimdilik Türkçe döndürüyoruz
    return 'tr';
  }

  @override
  String toString() {
    return 'LanguageSettings(customerId: $customerId, preferredLanguage: $preferredLanguage)';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    
    return other is LanguageSettings &&
        other.customerId == customerId &&
        other.preferredLanguage == preferredLanguage;
  }

  @override
  int get hashCode {
    return customerId.hashCode ^ preferredLanguage.hashCode;
  }
}

/// Desteklenen dil bilgisi
class SupportedLanguage {
  final String code;
  final String name;
  final String flag;

  const SupportedLanguage(this.code, this.name, this.flag);

  @override
  String toString() => '$flag $name';
} 