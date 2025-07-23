import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:crypto/crypto.dart';
import 'dart:convert';
import '../../business/models/business.dart';
import '../../business/services/business_firestore_service.dart';

/// QR Kod Doğrulama ve Analitik Takip Servisi
class QRValidationService {
  static final QRValidationService _instance = QRValidationService._internal();
  factory QRValidationService() => _instance;
  QRValidationService._internal();

  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final BusinessFirestoreService _businessService = BusinessFirestoreService();

  // =============================================================================
  // QR KOD DOĞRULAMA ve GÜVENLİK
  // =============================================================================

  /// QR kod URL'sini parse eder ve parametreleri doğrular
  Future<QRCodeValidationResult> validateQRCodeUrl(String url) async {
    try {
      print('🔍 QR Validation: Starting validation for URL: $url');

      // URL parsing
      final uri = Uri.tryParse(url);
      if (uri == null) {
        return QRCodeValidationResult.error('Geçersiz URL formatı');
      }

      // Business ID çıkarma
      final businessId = _extractBusinessId(uri);
      if (businessId == null || businessId.isEmpty) {
        return QRCodeValidationResult.error('İşletme ID\'si bulunamadı');
      }

      // Table number çıkarma (opsiyonel)
      final tableNumber = _extractTableNumber(uri);

      print('✅ QR Validation: Extracted - Business ID: $businessId, Table: $tableNumber');

      // Business validation
      final businessValidation = await _validateBusinessExists(businessId);
      if (!businessValidation.isValid) {
        return businessValidation;
      }

      // Analitik kaydet
      await _logQRCodeAccess(businessId, tableNumber, url);

      return QRCodeValidationResult.success(
        businessId: businessId,
        tableNumber: tableNumber,
        business: businessValidation.business,
      );

    } catch (e) {
      print('❌ QR Validation Error: $e');
      return QRCodeValidationResult.error('QR kod doğrulama hatası: $e');
    }
  }

  /// Business ID'yi URL'den çıkarır
  String? _extractBusinessId(Uri uri) {
    // Query parametrelerinden
    String? businessId = uri.queryParameters['business'] ?? 
                        uri.queryParameters['businessId'] ?? 
                        uri.queryParameters['business_id'];

    // Path'den çıkarma (/qr-menu/{businessId} formatı)
    if (businessId == null && uri.pathSegments.isNotEmpty) {
      if (uri.pathSegments.contains('qr-menu') && uri.pathSegments.length > 1) {
        final index = uri.pathSegments.indexOf('qr-menu');
        if (index + 1 < uri.pathSegments.length) {
          businessId = uri.pathSegments[index + 1];
        }
      }
    }

    return businessId;
  }

  /// Table number'ı URL'den çıkarır
  int? _extractTableNumber(Uri uri) {
    final tableString = uri.queryParameters['table'] ?? 
                       uri.queryParameters['tableNumber'] ?? 
                       uri.queryParameters['table_number'];
    
    if (tableString != null) {
      return int.tryParse(tableString);
    }
    return null;
  }

  /// Business'ın veritabanında var olup olmadığını kontrol eder
  Future<QRCodeValidationResult> _validateBusinessExists(String businessId) async {
    try {
      print('🔍 Business Validation: Checking business ID: $businessId');

      // Önce cache'den kontrol et
      final cachedBusiness = await _getCachedBusiness(businessId);
      if (cachedBusiness != null) {
        print('✅ Business found in cache: ${cachedBusiness.businessName}');
        return QRCodeValidationResult.success(
          businessId: businessId,
          business: cachedBusiness,
        );
      }

      // Veritabanından kontrol et
      final business = await _businessService.getBusiness(businessId);
      
      if (business == null) {
        print('❌ Business not found in database: $businessId');
        return QRCodeValidationResult.error(
          'İşletme bulunamadı (ID: $businessId)',
          errorCode: 'BUSINESS_NOT_FOUND',
        );
      }

      if (!business.isActive) {
        print('❌ Business is not active: $businessId');
        return QRCodeValidationResult.error(
          'İşletme şu anda hizmet vermiyor',
          errorCode: 'BUSINESS_INACTIVE',
        );
      }

      // Cache'e kaydet
      await _cacheBusiness(business);

      print('✅ Business validation successful: ${business.businessName}');
      return QRCodeValidationResult.success(
        businessId: businessId,
        business: business,
      );

    } catch (e) {
      print('❌ Business validation error: $e');
      return QRCodeValidationResult.error(
        'İşletme doğrulama hatası: $e',
        errorCode: 'VALIDATION_ERROR',
      );
    }
  }

  // =============================================================================
  // ANALİTİK ve LOGLama
  // =============================================================================

  /// QR kod erişimini loglar (analitik için)
  Future<void> _logQRCodeAccess(String businessId, int? tableNumber, String url) async {
    try {
      final logData = {
        'businessId': businessId,
        'tableNumber': tableNumber,
        'url': url,
        'timestamp': FieldValue.serverTimestamp(),
        'userAgent': 'mobile_app', // Mobil uygulama
        'accessType': 'qr_scan',
        'platform': 'flutter',
      };

      // Asenkron olarak kaydet (UI'yi bloklamasın)
      _firestore.collection('qr_access_logs').add(logData).catchError((e) {
        print('⚠️ QR Access log error (non-critical): $e');
      });

      print('📊 QR Access logged: Business $businessId, Table: $tableNumber');
    } catch (e) {
      print('⚠️ QR Access logging failed (non-critical): $e');
    }
  }

  /// QR kod hata durumunu loglar
  Future<void> logQRCodeError(String url, String errorMessage, String? errorCode) async {
    try {
      final errorLog = {
        'url': url,
        'errorMessage': errorMessage,
        'errorCode': errorCode,
        'timestamp': FieldValue.serverTimestamp(),
        'userAgent': 'mobile_app',
        'platform': 'flutter',
      };

      _firestore.collection('qr_error_logs').add(errorLog).catchError((e) {
        print('⚠️ QR Error log failed (non-critical): $e');
      });

      print('🚨 QR Error logged: $errorMessage');
    } catch (e) {
      print('⚠️ QR Error logging failed (non-critical): $e');
    }
  }

  // =============================================================================
  // CACHE YÖNETİMİ
  // =============================================================================

  /// Business bilgilerini cache'e kaydet (5 dakika süre ile)
  Future<void> _cacheBusiness(Business business) async {
    try {
      final cacheData = {
        ...business.toFirestore(),
        'cachedAt': FieldValue.serverTimestamp(),
        'expiresAt': Timestamp.fromDate(DateTime.now().add(Duration(minutes: 5))),
      };

      await _firestore
          .collection('business_cache')
          .doc(business.id)
          .set(cacheData, SetOptions(merge: true));

    } catch (e) {
      print('⚠️ Business cache failed (non-critical): $e');
    }
  }

  /// Cache'den business bilgilerini al
  Future<Business?> _getCachedBusiness(String businessId) async {
    try {
      final cacheDoc = await _firestore
          .collection('business_cache')
          .doc(businessId)
          .get();

      if (!cacheDoc.exists) return null;

      final data = cacheDoc.data()!;
      final expiresAt = (data['expiresAt'] as Timestamp?)?.toDate();
      
      // Cache süresi dolmuş mu?
      if (expiresAt == null || DateTime.now().isAfter(expiresAt)) {
        // Expired cache'i sil
        cacheDoc.reference.delete().catchError((e) {});
        return null;
      }

      return Business.fromFirestore(cacheDoc);
    } catch (e) {
      print('⚠️ Cache read failed (non-critical): $e');
      return null;
    }
  }

  // =============================================================================
  // ANALİTİK RAPORLAMA
  // =============================================================================

  /// İşletme için QR kod kullanım istatistikleri
  Future<QRCodeAnalytics> getQRCodeAnalytics(String businessId, {
    DateTime? startDate,
    DateTime? endDate,
  }) async {
    try {
      startDate ??= DateTime.now().subtract(Duration(days: 7));
      endDate ??= DateTime.now();

      final query = _firestore
          .collection('qr_access_logs')
          .where('businessId', isEqualTo: businessId)
          .where('timestamp', isGreaterThanOrEqualTo: Timestamp.fromDate(startDate))
          .where('timestamp', isLessThanOrEqualTo: Timestamp.fromDate(endDate));

      final snapshot = await query.get();
      
      int totalScans = snapshot.docs.length;
      Map<int, int> tableScans = {};
      Map<String, int> dailyScans = {};

      for (final doc in snapshot.docs) {
        final data = doc.data();
        final tableNumber = data['tableNumber'] as int?;
        final timestamp = (data['timestamp'] as Timestamp).toDate();
        final dayKey = '${timestamp.year}-${timestamp.month.toString().padLeft(2, '0')}-${timestamp.day.toString().padLeft(2, '0')}';

        if (tableNumber != null) {
          tableScans[tableNumber] = (tableScans[tableNumber] ?? 0) + 1;
        }
        
        dailyScans[dayKey] = (dailyScans[dayKey] ?? 0) + 1;
      }

      return QRCodeAnalytics(
        businessId: businessId,
        totalScans: totalScans,
        tableScans: tableScans,
        dailyScans: dailyScans,
        startDate: startDate,
        endDate: endDate,
      );

    } catch (e) {
      print('❌ Analytics error: $e');
      return QRCodeAnalytics.empty(businessId);
    }
  }
}

// =============================================================================
// DATA MODELS
// =============================================================================

/// QR kod doğrulama sonucu
class QRCodeValidationResult {
  final bool isValid;
  final String? errorMessage;
  final String? errorCode;
  final String? businessId;
  final int? tableNumber;
  final Business? business;

  QRCodeValidationResult.success({
    required this.businessId,
    this.tableNumber,
    this.business,
  }) : isValid = true, errorMessage = null, errorCode = null;

  QRCodeValidationResult.error(
    this.errorMessage, {
    this.errorCode,
  }) : isValid = false, businessId = null, tableNumber = null, business = null;

  bool get hasTableNumber => tableNumber != null && tableNumber! > 0;
}

/// QR kod analitik verileri
class QRCodeAnalytics {
  final String businessId;
  final int totalScans;
  final Map<int, int> tableScans;
  final Map<String, int> dailyScans;
  final DateTime startDate;
  final DateTime endDate;

  QRCodeAnalytics({
    required this.businessId,
    required this.totalScans,
    required this.tableScans,
    required this.dailyScans,
    required this.startDate,
    required this.endDate,
  });

  QRCodeAnalytics.empty(this.businessId)
      : totalScans = 0,
        tableScans = {},
        dailyScans = {},
        startDate = DateTime.now(),
        endDate = DateTime.now();

  /// En çok kullanılan masa
  int? get mostUsedTable {
    if (tableScans.isEmpty) return null;
    return tableScans.entries
        .reduce((a, b) => a.value > b.value ? a : b)
        .key;
  }

  /// Günlük ortalama tarama
  double get averageDailyScans {
    if (dailyScans.isEmpty) return 0.0;
    return totalScans / dailyScans.length;
  }
} 