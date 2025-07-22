import 'dart:math';
import 'dart:typed_data';
import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:qr_flutter/qr_flutter.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:share_plus/share_plus.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../business/models/business.dart';
import '../../business/models/qr_code.dart';

import '../../business/services/business_firestore_service.dart';

class QRService {
  static final QRService _instance = QRService._internal();
  factory QRService() => _instance;
  QRService._internal();

  final BusinessFirestoreService _businessFirestoreService = BusinessFirestoreService();
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // Base URL for QR codes - updated to actual deployment URL
  static const String baseUrl = 'https://menumebak.web.app';

  // =============================================================================
  // QR CODE CRUD OPERATIONS
  // =============================================================================

  /// Saves a QR code to Firestore
  Future<String> saveQRCode(QRCode qrCode) async {
    final docRef = await _firestore.collection('qr_codes').add(qrCode.toFirestore());
    return docRef.id;
  }

  /// Updates an existing QR code
  Future<void> updateQRCode(QRCode qrCode) async {
    await _firestore
        .collection('qr_codes')
        .doc(qrCode.qrCodeId)
        .update(qrCode.toFirestore());
  }

  /// Deletes a QR code
  Future<void> deleteQRCode(String qrCodeId) async {
    await _firestore.collection('qr_codes').doc(qrCodeId).delete();
  }

  /// Gets all QR codes for a business
  Future<List<QRCode>> getBusinessQRCodes(String businessId) async {
    final snapshot = await _firestore
        .collection('qr_codes')
        .where('businessId', isEqualTo: businessId)
        .where('isActive', isEqualTo: true)
        .orderBy('createdAt', descending: true)
        .get();

    return snapshot.docs
        .map((doc) => QRCode.fromFirestore(doc))
        .toList();
  }

  /// Gets QR codes by type for a business
  Future<List<QRCode>> getQRCodesByType(String businessId, QRCodeType type) async {
    final snapshot = await _firestore
        .collection('qr_codes')
        .where('businessId', isEqualTo: businessId)
        .where('type', isEqualTo: type.value)
        .where('isActive', isEqualTo: true)
        .orderBy('createdAt', descending: true)
        .get();

    return snapshot.docs
        .map((doc) => QRCode.fromFirestore(doc))
        .toList();
  }

  /// Gets table QR codes for a business
  Future<List<QRCode>> getTableQRCodes(String businessId) async {
    return getQRCodesByType(businessId, QRCodeType.table);
  }

  /// Gets business QR code
  Future<QRCode?> getBusinessQRCode(String businessId) async {
    final codes = await getQRCodesByType(businessId, QRCodeType.business);
    return codes.isNotEmpty ? codes.first : null;
  }

  /// Creates or updates business QR code
  Future<QRCode> createBusinessQRCode({
    required String businessId,
    required String businessName,
    QRCodeStyle? style,
    String? createdBy,
  }) async {
    // Check if business QR already exists
    final existingQR = await getBusinessQRCode(businessId);
    
    if (existingQR != null) {
      // Update existing QR code
      final updatedQR = existingQR.copyWith(
        title: '$businessName - Menü',
        updatedAt: DateTime.now(),
        style: style ?? existingQR.style,
      );
      await updateQRCode(updatedQR);
      return updatedQR;
    } else {
      // Create new business QR code
      final newQR = QRCode.businessQR(
        businessId: businessId,
        businessName: businessName,
        style: style,
        createdBy: createdBy,
      );
      final qrId = await saveQRCode(newQR);
      return newQR.copyWith(qrCodeId: qrId);
    }
  }

  /// Creates table QR codes for a business
  Future<List<QRCode>> createTableQRCodes({
    required String businessId,
    required String businessName,
    required int tableCount,
    QRCodeStyle? style,
    String? createdBy,
    bool replaceExisting = false,
  }) async {
    if (replaceExisting) {
      // Delete existing table QR codes
      final existingCodes = await getTableQRCodes(businessId);
      for (final qr in existingCodes) {
        await deleteQRCode(qr.qrCodeId);
      }
    }

    final tableQRs = <QRCode>[];
    
    for (int i = 1; i <= tableCount; i++) {
      final tableQR = QRCode.tableQR(
        businessId: businessId,
        businessName: businessName,
        tableNumber: i,
        style: style,
        createdBy: createdBy,
      );
      
      final qrId = await saveQRCode(tableQR);
      tableQRs.add(tableQR.copyWith(qrCodeId: qrId));
    }

    return tableQRs;
  }

  /// Creates a complete QR package for a business
  Future<QRCodePackage> createBusinessQRPackage({
    required String businessId,
    required String businessName,
    required int tableCount,
    QRCodeStyle? style,
    String? createdBy,
    bool replaceExisting = false,
  }) async {
    // Create or update business QR
    final businessQR = await createBusinessQRCode(
      businessId: businessId,
      businessName: businessName,
      style: style,
      createdBy: createdBy,
    );

    // Create table QR codes
    final tableQRs = await createTableQRCodes(
      businessId: businessId,
      businessName: businessName,
      tableCount: tableCount,
      style: style,
      createdBy: createdBy,
      replaceExisting: replaceExisting,
    );

    return QRCodePackage(
      businessId: businessId,
      businessName: businessName,
      businessQR: businessQR,
      tableQRs: tableQRs,
      createdAt: DateTime.now(),
      createdBy: createdBy,
    );
  }

  // =============================================================================
  // QR CODE URL GENERATION
  // =============================================================================

  /// Generates a unique QR code URL for a business
  String generateBusinessQRUrl(String businessId) {
    return '$baseUrl/qr-menu/$businessId';
  }

  /// Generates a QR code URL for a specific table
  String generateTableQRUrl(String businessId, int tableNumber) {
    return '$baseUrl/qr-menu/$businessId?table=$tableNumber';
  }

  /// Generates a QR code URL for a specific table with additional parameters
  String generateAdvancedTableQRUrl(
    String businessId,
    int tableNumber, {
    String? waiterCode,
    String? sessionId,
    Map<String, String>? extraParams,
  }) {
    final uri = Uri.parse('$baseUrl/qr-menu/$businessId');
    final queryParams = <String, String>{'table': tableNumber.toString()};

    if (waiterCode != null) queryParams['waiter'] = waiterCode;
    if (sessionId != null) queryParams['session'] = sessionId;
    if (extraParams != null) queryParams.addAll(extraParams);

    return uri.replace(queryParameters: queryParams).toString();
  }

  // =============================================================================
  // QR CODE WIDGET CREATION
  // =============================================================================

  /// Creates QR code widget for business
  Widget createBusinessQRWidget({
    required String businessId,
    double size = 200.0,
    Color? foregroundColor,
    Color? backgroundColor,
  }) {
    final qrData = generateBusinessQRUrl(businessId);

    return QrImageView(
      data: qrData,
      version: QrVersions.auto,
      size: size,
      foregroundColor: foregroundColor ?? Colors.black,
      backgroundColor: backgroundColor ?? Colors.white,
      gapless: false,
      errorStateBuilder: (cxt, err) {
        return Container(
          child: Center(
            child: Text('QR Kod Oluşturulamadı', textAlign: TextAlign.center),
          ),
        );
      },
    );
  }

  /// Creates QR code widget for specific table
  Widget createTableQRWidget({
    required String businessId,
    required int tableNumber,
    double size = 200.0,
    Color? foregroundColor,
    Color? backgroundColor,
    String? waiterCode,
    String? sessionId,
    Map<String, String>? extraParams,
  }) {
    final qrData = generateAdvancedTableQRUrl(
      businessId,
      tableNumber,
      waiterCode: waiterCode,
      sessionId: sessionId,
      extraParams: extraParams,
    );

    return QrImageView(
      data: qrData,
      version: QrVersions.auto,
      size: size,
      foregroundColor: foregroundColor ?? Colors.black,
      backgroundColor: backgroundColor ?? Colors.white,
      gapless: false,
      errorStateBuilder: (cxt, err) {
        return Container(
          child: Center(
            child: Text('QR Kod Oluşturulamadı', textAlign: TextAlign.center),
          ),
        );
      },
    );
  }

  /// Creates QR code widget from QRCode model
  Widget createQRWidget(QRCode qrCode, {double? overrideSize}) {
    final size = overrideSize ?? qrCode.style.size;
    
    return QrImageView(
      data: qrCode.url,
      version: QrVersions.auto,
      size: size,
      foregroundColor: _parseColor(qrCode.style.foregroundColor),
      backgroundColor: _parseColor(qrCode.style.backgroundColor),
      gapless: false,
      errorStateBuilder: (cxt, err) {
        return Container(
          width: size,
          height: size,
          child: Center(
            child: Text(
              'QR Kod Oluşturulamadı',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: size * 0.08),
            ),
          ),
        );
      },
    );
  }

  /// Creates a complete branded QR code widget
  Widget createBrandedQRWidget({
    required String businessId,
    required String businessName,
    int? tableNumber,
    double size = 200.0,
    Color? foregroundColor,
    Color? backgroundColor,
    String? logoUrl,
    bool showBusinessName = true,
    bool showTableInfo = true,
  }) {
    final qrData = tableNumber != null
        ? generateTableQRUrl(businessId, tableNumber)
        : generateBusinessQRUrl(businessId);

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: backgroundColor ?? Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 8,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (showBusinessName)
            Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: Text(
                businessName,
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Colors.black87,
                ),
                textAlign: TextAlign.center,
              ),
            ),
          QrImageView(
            data: qrData,
            version: QrVersions.auto,
            size: size,
            foregroundColor: foregroundColor ?? Colors.black,
            backgroundColor: backgroundColor ?? Colors.white,
            gapless: false,
            errorStateBuilder: (cxt, err) {
              return Container(
                child: Center(
                  child: Text(
                    'QR Kod Oluşturulamadı',
                    textAlign: TextAlign.center,
                  ),
                ),
              );
            },
          ),
          if (showTableInfo && tableNumber != null)
            Padding(
              padding: const EdgeInsets.only(top: 12),
              child: Text(
                'Masa $tableNumber',
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: Colors.black87,
                ),
              ),
            ),
          const SizedBox(height: 8),
          const Text(
            'Menümüze ulaşmak için QR kodu tarayın',
            style: TextStyle(fontSize: 12, color: Colors.grey),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  // =============================================================================
  // QR CODE SHARING AND ACTIONS
  // =============================================================================

  /// Shares business QR code
  Future<void> shareBusinessQR(String businessId) async {
    final url = generateBusinessQRUrl(businessId);
    final business = await _businessFirestoreService.getBusiness(businessId);
    final businessName = business?.businessName ?? 'İşletme';
    
    await Share.share(
      '$businessName menüsünü görüntülemek için bu linki kullanın: $url',
      subject: '$businessName - Menü',
    );
  }

  /// Shares table QR code
  Future<void> shareTableQR(String businessId, int tableNumber) async {
    final url = generateTableQRUrl(businessId, tableNumber);
    final business = await _businessFirestoreService.getBusiness(businessId);
    final businessName = business?.businessName ?? 'İşletme';
    
    await Share.share(
      '$businessName - Masa $tableNumber menüsünü görüntülemek için bu linki kullanın: $url',
      subject: '$businessName - Masa $tableNumber',
    );
  }

  /// Opens QR URL in browser
  Future<void> openQRUrl(String url) async {
    final uri = Uri.parse(url);
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri);
    }
  }

  /// Updates business QR code URL
  Future<void> updateBusinessQRCode(String businessId) async {
    // This method can be used to regenerate QR codes if needed
    final business = await _businessFirestoreService.getBusiness(businessId);
    if (business != null) {
      await createBusinessQRCode(
        businessId: businessId,
        businessName: business.businessName,
      );
    }
  }

  // =============================================================================
  // QR CODE STATISTICS
  // =============================================================================

  /// Records a QR code scan
  Future<void> recordQRScan(String qrCodeId, {
    String? deviceType,
    String? location,
    String? userAgent,
  }) async {
    try {
      final qrRef = _firestore.collection('qr_codes').doc(qrCodeId);
      final qrDoc = await qrRef.get();
      
      if (qrDoc.exists) {
        final qrCode = QRCode.fromFirestore(qrDoc);
        final updatedStats = qrCode.stats.incrementScan(
          deviceType: deviceType,
          location: location,
        );
        
        await qrRef.update({
          'stats': updatedStats.toJson(),
          'updatedAt': Timestamp.now(),
        });
      }
    } catch (e) {
      print('Error recording QR scan: $e');
    }
  }

  /// Gets QR code statistics for a business
  Future<Map<String, dynamic>> getBusinessQRStats(String businessId) async {
    final qrCodes = await getBusinessQRCodes(businessId);
    
    int totalScans = 0;
    int todayScans = 0;
    int weeklyScans = 0;
    int monthlyScans = 0;
    
    for (final qr in qrCodes) {
      totalScans += qr.stats.totalScans;
      todayScans += qr.stats.todayScans;
      weeklyScans += qr.stats.weeklyScans;
      monthlyScans += qr.stats.monthlyScans;
    }
    
    return {
      'totalQRCodes': qrCodes.length,
      'totalScans': totalScans,
      'todayScans': todayScans,
      'weeklyScans': weeklyScans,
      'monthlyScans': monthlyScans,
      'businessQRCount': qrCodes.where((qr) => qr.type == QRCodeType.business).length,
      'tableQRCount': qrCodes.where((qr) => qr.type == QRCodeType.table).length,
    };
  }

  // =============================================================================
  // HELPER METHODS
  // =============================================================================

  Color _parseColor(String colorString) {
    try {
      final hex = colorString.replaceAll('#', '');
      return Color(int.parse('FF$hex', radix: 16));
    } catch (e) {
      return Colors.black;
    }
  }

  /// Legacy method for backward compatibility - creates printable QR package
  QRCodePackage createPrintableQRPackage(
    String businessId, {
    required int tableCount,
  }) {
    // This creates a package without saving to database
    // Used for preview purposes
    return QRCodePackage.create(
      businessId: businessId,
      businessName: 'İşletme', // Will be updated with actual name
      tableCount: tableCount,
    );
  }
}
