import 'package:cloud_firestore/cloud_firestore.dart';
import '../../business/models/multilingual_content.dart';
import '../../customer/models/language_settings.dart';

/// Çok dilli içerik yönetim servisi
class MultilingualService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  
  static const String _multilingualCollection = 'multilingual_content';
  static const String _languageSettingsCollection = 'language_settings';

  // ============================================================================
  // LANGUAGE SETTINGS METHODS
  // ============================================================================

  /// Müşteri dil ayarlarını al
  Future<LanguageSettings?> getLanguageSettings(String customerId) async {
    try {
      final doc = await _firestore
          .collection(_languageSettingsCollection)
          .doc(customerId)
          .get();
      
      if (doc.exists) {
        return LanguageSettings.fromFirestore(doc);
      }
      
      // Ayar yoksa varsayılan ayarları oluştur
      final defaultSettings = LanguageSettings.defaultSettings(customerId);
      await saveLanguageSettings(defaultSettings);
      return defaultSettings;
    } catch (e) {
      print('Dil ayarları alınırken hata: $e');
      return null;
    }
  }

  /// Müşteri dil ayarlarını kaydet
  Future<void> saveLanguageSettings(LanguageSettings settings) async {
    try {
      await _firestore
          .collection(_languageSettingsCollection)
          .doc(settings.customerId)
          .set(settings.toFirestore());
    } catch (e) {
      print('Dil ayarları kaydedilirken hata: $e');
      rethrow;
    }
  }

  /// Müşteri dil ayarlarını güncelle
  Future<void> updateLanguageSettings(
    String customerId, {
    String? preferredLanguage,
    bool? autoDetectLanguage,
    bool? translateMenuAutomatically,
    Map<String, String>? customTranslations,
    String? fallbackLanguage,
  }) async {
    try {
      final currentSettings = await getLanguageSettings(customerId);
      if (currentSettings == null) return;

      final updatedSettings = currentSettings.copyWith(
        preferredLanguage: preferredLanguage,
        autoDetectLanguage: autoDetectLanguage,
        translateMenuAutomatically: translateMenuAutomatically,
        customTranslations: customTranslations,
        fallbackLanguage: fallbackLanguage,
        updatedAt: DateTime.now(),
      );

      await saveLanguageSettings(updatedSettings);
    } catch (e) {
      print('Dil ayarları güncellenirken hata: $e');
      rethrow;
    }
  }

  // ============================================================================
  // MULTILINGUAL CONTENT METHODS
  // ============================================================================

  /// Çok dilli içerik kaydet
  Future<void> saveMultilingualContent(MultilingualContent content) async {
    try {
      await _firestore
          .collection(_multilingualCollection)
          .doc(content.id)
          .set(content.toFirestore());
    } catch (e) {
      print('Çok dilli içerik kaydedilirken hata: $e');
      rethrow;
    }
  }

  /// Entity için çok dilli içerikleri al
  Future<List<MultilingualContent>> getMultilingualContent({
    required String entityId,
    String? entityType,
    String? fieldName,
  }) async {
    try {
      Query query = _firestore
          .collection(_multilingualCollection)
          .where('entityId', isEqualTo: entityId);
      
      if (entityType != null) {
        query = query.where('entityType', isEqualTo: entityType);
      }
      
      if (fieldName != null) {
        query = query.where('fieldName', isEqualTo: fieldName);
      }

      final snapshot = await query.get();
      
      return snapshot.docs
          .map((doc) => MultilingualContent.fromFirestore(doc))
          .toList();
    } catch (e) {
      print('Çok dilli içerik alınırken hata: $e');
      return [];
    }
  }

  /// Belirli bir alan için çeviri al
  Future<String> getTranslation({
    required String entityId,
    required String entityType,
    required String fieldName,
    required String languageCode,
    required String fallbackContent,
  }) async {
    try {
      final contentId = MultilingualContentHelper.generateContentId(
        entityId: entityId,
        entityType: entityType,
        fieldName: fieldName,
      );

      final doc = await _firestore
          .collection(_multilingualCollection)
          .doc(contentId)
          .get();

      if (doc.exists) {
        final content = MultilingualContent.fromFirestore(doc);
        final translation = content.getTranslation(languageCode);
        return translation.isNotEmpty ? translation : fallbackContent;
      }

      return fallbackContent;
    } catch (e) {
      print('Çeviri alınırken hata: $e');
      return fallbackContent;
    }
  }

  /// Çeviri ekle veya güncelle
  Future<void> addOrUpdateTranslation({
    required String entityId,
    required String entityType,
    required String fieldName,
    required String languageCode,
    required String content,
    String defaultLanguage = 'tr',
  }) async {
    try {
      final contentId = MultilingualContentHelper.generateContentId(
        entityId: entityId,
        entityType: entityType,
        fieldName: fieldName,
      );

      final doc = await _firestore
          .collection(_multilingualCollection)
          .doc(contentId)
          .get();

      MultilingualContent multilingualContent;

      if (doc.exists) {
        // Mevcut içeriği güncelle
        multilingualContent = MultilingualContent.fromFirestore(doc);
        multilingualContent = multilingualContent.addTranslation(languageCode, content);
      } else {
        // Yeni içerik oluştur
        multilingualContent = MultilingualContent.create(
          entityId: entityId,
          entityType: entityType,
          fieldName: fieldName,
          defaultLanguage: defaultLanguage,
          defaultContent: content,
        );
      }

      await saveMultilingualContent(multilingualContent);
    } catch (e) {
      print('Çeviri eklenirken/güncellenirken hata: $e');
      rethrow;
    }
  }

  /// Çeviriyi sil
  Future<void> removeTranslation({
    required String entityId,
    required String entityType,
    required String fieldName,
    required String languageCode,
  }) async {
    try {
      final contentId = MultilingualContentHelper.generateContentId(
        entityId: entityId,
        entityType: entityType,
        fieldName: fieldName,
      );

      final doc = await _firestore
          .collection(_multilingualCollection)
          .doc(contentId)
          .get();

      if (doc.exists) {
        final content = MultilingualContent.fromFirestore(doc);
        final updatedContent = content.removeTranslation(languageCode);
        await saveMultilingualContent(updatedContent);
      }
    } catch (e) {
      print('Çeviri silinirken hata: $e');
      rethrow;
    }
  }

  /// Entity'nin tüm çevirilerini sil
  Future<void> deleteEntityTranslations({
    required String entityId,
    String? entityType,
  }) async {
    try {
      Query query = _firestore
          .collection(_multilingualCollection)
          .where('entityId', isEqualTo: entityId);
      
      if (entityType != null) {
        query = query.where('entityType', isEqualTo: entityType);
      }

      final snapshot = await query.get();
      
      final batch = _firestore.batch();
      for (final doc in snapshot.docs) {
        batch.delete(doc.reference);
      }
      
      await batch.commit();
    } catch (e) {
      print('Entity çevirileri silinirken hata: $e');
      rethrow;
    }
  }

  // ============================================================================
  // BATCH OPERATIONS
  // ============================================================================

  /// Toplu çeviri ekleme
  Future<void> batchAddTranslations(List<Map<String, dynamic>> translations) async {
    try {
      final batch = _firestore.batch();
      
      for (final translation in translations) {
        final contentId = MultilingualContentHelper.generateContentId(
          entityId: translation['entityId'],
          entityType: translation['entityType'],
          fieldName: translation['fieldName'],
        );
        
        final content = MultilingualContent.create(
          entityId: translation['entityId'],
          entityType: translation['entityType'],
          fieldName: translation['fieldName'],
          defaultLanguage: translation['defaultLanguage'] ?? 'tr',
          defaultContent: translation['content'],
        );
        
        batch.set(
          _firestore.collection(_multilingualCollection).doc(contentId),
          content.toFirestore(),
        );
      }
      
      await batch.commit();
    } catch (e) {
      print('Toplu çeviri eklenirken hata: $e');
      rethrow;
    }
  }

  // ============================================================================
  // UTILITY METHODS
  // ============================================================================

  /// Müşteri için en uygun dili belirle
  Future<String> determineUserLanguage(String? customerId) async {
    try {
      if (customerId != null) {
        final settings = await getLanguageSettings(customerId);
        if (settings != null) {
          if (settings.autoDetectLanguage) {
            // Sistem dilini algıla veya tercih edilen dili kullan
            final systemLang = LanguageSettings.detectSystemLanguage();
            return _isSupportedLanguage(systemLang) ? systemLang : settings.preferredLanguage;
          }
          return settings.preferredLanguage;
        }
      }
      
      // Varsayılan olarak sistem dilini algıla
      final systemLang = LanguageSettings.detectSystemLanguage();
      return _isSupportedLanguage(systemLang) ? systemLang : 'tr';
    } catch (e) {
      print('Kullanıcı dili belirlenirken hata: $e');
      return 'tr';
    }
  }

  /// Dil kodunun desteklenip desteklenmediğini kontrol et
  bool _isSupportedLanguage(String languageCode) {
    return LanguageSettings.supportedLanguages
        .any((lang) => lang.code == languageCode);
  }

  /// Çeviri tamamlanma istatistikleri
  Future<Map<String, dynamic>> getTranslationStats({
    required String entityType,
    List<String>? targetLanguages,
  }) async {
    try {
      final snapshot = await _firestore
          .collection(_multilingualCollection)
          .where('entityType', isEqualTo: entityType)
          .get();

      final contents = snapshot.docs
          .map((doc) => MultilingualContent.fromFirestore(doc))
          .toList();

      final targets = targetLanguages ?? 
          LanguageSettings.supportedLanguages.map((l) => l.code).toList();

      final stats = <String, dynamic>{
        'totalEntities': contents.length,
        'targetLanguages': targets,
        'completionByLanguage': <String, double>{},
        'overallCompletion': 0.0,
      };

      if (contents.isNotEmpty) {
        for (final lang in targets) {
          final completedCount = contents
              .where((content) => content.translations.containsKey(lang))
              .length;
          stats['completionByLanguage'][lang] = (completedCount / contents.length) * 100.0;
        }

        final totalCompletion = (stats['completionByLanguage'] as Map<String, double>)
            .values
            .fold(0.0, (sum, value) => sum + value) / targets.length;
        stats['overallCompletion'] = totalCompletion;
      }

      return stats;
    } catch (e) {
      print('Çeviri istatistikleri alınırken hata: $e');
      return {};
    }
  }
} 