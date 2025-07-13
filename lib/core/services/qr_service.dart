import 'dart:math';
import 'package:qr_flutter/qr_flutter.dart';
import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:share_plus/share_plus.dart';
import '../../data/models/business.dart';
import 'data_service.dart';

class QRService {
  static final QRService _instance = QRService._internal();
  factory QRService() => _instance;
  QRService._internal();

  final DataService _dataService = DataService();

  // Base URL for QR codes - updated to actual deployment URL
  static const String baseUrl = 'https://masamenu21.web.app';

  /// Generates a unique QR code URL for a business
  String generateBusinessQRUrl(String businessId) {
    return '$baseUrl/menu/$businessId';
  }

  /// Generates a QR code URL for a specific table
  String generateTableQRUrl(String businessId, String tableNumber) {
    return '$baseUrl/menu/$businessId?table=$tableNumber';
  }

  /// Generates a unique QR code URL for a specific business with custom path
  String generateCustomBusinessQRUrl(String businessId, String customPath) {
    return '$baseUrl/menu/$businessId/$customPath';
  }

  /// Generates a QR code URL for a specific table with additional parameters
  String generateAdvancedTableQRUrl(
    String businessId,
    String tableNumber, {
    String? waiterCode,
    String? sessionId,
    Map<String, String>? extraParams,
  }) {
    final uri = Uri.parse('$baseUrl/menu/$businessId');
    final queryParams = <String, String>{'table': tableNumber};

    if (waiterCode != null) queryParams['waiter'] = waiterCode;
    if (sessionId != null) queryParams['session'] = sessionId;
    if (extraParams != null) queryParams.addAll(extraParams);

    return uri.replace(queryParameters: queryParams).toString();
  }

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
    required String tableNumber,
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

  /// Creates a complete QR code widget with business branding
  Widget createBrandedQRWidget({
    required String businessId,
    required String businessName,
    String? tableNumber,
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

  /// Generates QR codes for multiple tables
  List<QRCodeData> generateTableQRCodes(String businessId, int tableCount) {
    final qrCodes = <QRCodeData>[];

    for (int i = 1; i <= tableCount; i++) {
      final tableNumber = i.toString().padLeft(2, '0');
      qrCodes.add(
        QRCodeData(
          businessId: businessId,
          tableNumber: tableNumber,
          qrUrl: generateTableQRUrl(businessId, tableNumber),
          displayName: 'Masa $tableNumber',
        ),
      );
    }

    return qrCodes;
  }

  /// Shares business QR code
  Future<void> shareBusinessQR(String businessId) async {
    final business = await _dataService.getBusiness(businessId);
    if (business != null) {
      final qrUrl = generateBusinessQRUrl(businessId);
      final shareText =
          '''
🍽️ ${business.businessName} Dijital Menü

Menümüzü görmek için QR kodu tarayın veya linke tıklayın:
$qrUrl

📱 Kolay, hızlı, güvenli!
      ''';

      await Share.share(
        shareText,
        subject: '${business.businessName} - Dijital Menü',
      );
    }
  }

  /// Shares table QR code
  Future<void> shareTableQR(String businessId, String tableNumber) async {
    final business = await _dataService.getBusiness(businessId);
    if (business != null) {
      final qrUrl = generateTableQRUrl(businessId, tableNumber);
      final shareText =
          '''
🍽️ ${business.businessName} - Masa $tableNumber

Menümüzü görmek için QR kodu tarayın veya linke tıklayın:
$qrUrl

📱 Kolay, hızlı, güvenli!
      ''';

      await Share.share(
        shareText,
        subject: '${business.businessName} - Masa $tableNumber',
      );
    }
  }

  /// Opens QR URL in browser for testing
  Future<void> openQRUrl(String qrUrl) async {
    final uri = Uri.parse(qrUrl);
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri);
    }
  }

  /// Parses QR code data to extract business and table info
  QRScanResult? parseQRCode(String qrData) {
    try {
      final uri = Uri.parse(qrData);

      // Check if it's our QR code format
      if (!qrData.startsWith(baseUrl)) {
        return null;
      }

      // Extract business ID from path
      final pathSegments = uri.pathSegments;
      if (pathSegments.length >= 2 && pathSegments[0] == 'menu') {
        final businessId = pathSegments[1];
        final tableNumber = uri.queryParameters['table'];

        return QRScanResult(
          businessId: businessId,
          tableNumber: tableNumber,
          originalUrl: qrData,
        );
      }

      return null;
    } catch (e) {
      return null;
    }
  }

  /// Generates random business ID for new businesses
  String generateBusinessId() {
    const chars = 'abcdefghijklmnopqrstuvwxyz0123456789';
    final random = Random();
    return 'biz_${List.generate(8, (index) => chars[random.nextInt(chars.length)]).join()}';
  }

  /// Updates business with QR code URL
  Future<void> updateBusinessQRCode(String businessId) async {
    final business = await _dataService.getBusiness(businessId);
    if (business != null) {
      final qrUrl = generateBusinessQRUrl(businessId);
      final updatedBusiness = business.copyWith(qrCodeUrl: qrUrl);
      await _dataService.saveBusiness(updatedBusiness);
    }
  }

  /// Creates a comprehensive QR code package for printing
  QRCodePackage createPrintableQRPackage(
    String businessId, {
    int tableCount = 20,
  }) {
    final businessQR = QRCodeData(
      businessId: businessId,
      tableNumber: null,
      qrUrl: generateBusinessQRUrl(businessId),
      displayName: 'Genel Menü',
    );

    final tableQRs = generateTableQRCodes(businessId, tableCount);

    return QRCodePackage(
      businessQR: businessQR,
      tableQRs: tableQRs,
      createdAt: DateTime.now(),
    );
  }
}

/// QR code data model
class QRCodeData {
  final String businessId;
  final String? tableNumber;
  final String qrUrl;
  final String displayName;

  QRCodeData({
    required this.businessId,
    this.tableNumber,
    required this.qrUrl,
    required this.displayName,
  });

  Map<String, dynamic> toJson() {
    return {
      'businessId': businessId,
      'tableNumber': tableNumber,
      'qrUrl': qrUrl,
      'displayName': displayName,
    };
  }

  factory QRCodeData.fromJson(Map<String, dynamic> json) {
    return QRCodeData(
      businessId: json['businessId'],
      tableNumber: json['tableNumber'],
      qrUrl: json['qrUrl'],
      displayName: json['displayName'],
    );
  }
}

/// QR scan result model
class QRScanResult {
  final String businessId;
  final String? tableNumber;
  final String originalUrl;

  QRScanResult({
    required this.businessId,
    this.tableNumber,
    required this.originalUrl,
  });
}

/// QR code package for printing
class QRCodePackage {
  final QRCodeData businessQR;
  final List<QRCodeData> tableQRs;
  final DateTime createdAt;

  QRCodePackage({
    required this.businessQR,
    required this.tableQRs,
    required this.createdAt,
  });

  int get totalQRCodes => tableQRs.length + 1;
}
