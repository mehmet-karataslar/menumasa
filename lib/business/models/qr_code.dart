import 'package:cloud_firestore/cloud_firestore.dart';

// =============================================================================
// QR CODE MODELS
// =============================================================================

class QRCode {
  final String qrCodeId;
  final String businessId;
  final QRCodeType type;
  final String title;
  final String description;
  final String url;
  final QRCodeData data;
  final QRCodeStyle style;
  final QRCodeStats stats;
  final bool isActive;
  final DateTime createdAt;
  final DateTime updatedAt;
  final DateTime? expiresAt;
  final String? createdBy;

  QRCode({
    required this.qrCodeId,
    required this.businessId,
    required this.type,
    required this.title,
    required this.description,
    required this.url,
    required this.data,
    required this.style,
    required this.stats,
    required this.isActive,
    required this.createdAt,
    required this.updatedAt,
    this.expiresAt,
    this.createdBy,
  });

  factory QRCode.businessQR({
    required String businessId,
    required String businessName,
    String? customTitle,
    String? customDescription,
    QRCodeStyle? style,
    String? createdBy,
    String? customUrl, // QR Service'ten URL geçirebilmek için
  }) {
    final qrId = 'qr_business_${businessId}_${DateTime.now().millisecondsSinceEpoch}';
    final url = customUrl ?? 'https://menumebak.web.app/menu/$businessId'; // Fallback URL
    
    return QRCode(
      qrCodeId: qrId,
      businessId: businessId,
      type: QRCodeType.business,
      title: customTitle ?? '$businessName - Menü',
      description: customDescription ?? 'İşletme menüsünü görüntülemek için QR kodu tarayın',
      url: url,
      data: QRCodeData.business(
        businessId: businessId,
        businessName: businessName,
      ),
      style: style ?? QRCodeStyle.defaultStyle(),
      stats: QRCodeStats.empty(),
      isActive: true,
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
      createdBy: createdBy,
    );
  }

  factory QRCode.tableQR({
    required String businessId,
    required String businessName,
    required int tableNumber,
    String? tableName,
    QRCodeStyle? style,
    String? createdBy,
    String? customUrl, // QR Service'ten URL geçirebilmek için
  }) {
    final qrId = 'qr_table_${businessId}_$tableNumber${DateTime.now().millisecondsSinceEpoch}';
    final url = customUrl ?? 'https://menumebak.web.app/menu/$businessId?table=$tableNumber'; // Fallback URL
    final displayName = tableName ?? 'Masa $tableNumber';
    
    return QRCode(
      qrCodeId: qrId,
      businessId: businessId,
      type: QRCodeType.table,
      title: '$businessName - $displayName',
      description: '$displayName için menüyü görüntülemek için QR kodu tarayın',
      url: url,
      data: QRCodeData.table(
        businessId: businessId,
        businessName: businessName,
        tableNumber: tableNumber,
        tableName: tableName,
      ),
      style: style ?? QRCodeStyle.defaultStyle(),
      stats: QRCodeStats.empty(),
      isActive: true,
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
      createdBy: createdBy,
    );
  }

  factory QRCode.fromJson(Map<String, dynamic> data, {String? id}) {
    return QRCode(
      qrCodeId: id ?? data['qrCodeId'] ?? '',
      businessId: data['businessId'] ?? '',
      type: QRCodeType.fromString(data['type'] ?? 'business'),
      title: data['title'] ?? '',
      description: data['description'] ?? '',
      url: data['url'] ?? '',
      data: QRCodeData.fromJson(data['data'] ?? {}),
      style: QRCodeStyle.fromJson(data['style'] ?? {}),
      stats: QRCodeStats.fromJson(data['stats'] ?? {}),
      isActive: data['isActive'] ?? true,
      createdAt: _parseDateTime(data['createdAt']),
      updatedAt: _parseDateTime(data['updatedAt']),
      expiresAt: data['expiresAt'] != null ? _parseDateTime(data['expiresAt']) : null,
      createdBy: data['createdBy'],
    );
  }

  factory QRCode.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return QRCode.fromJson({...data, 'qrCodeId': doc.id});
  }

  Map<String, dynamic> toJson() {
    return {
      'qrCodeId': qrCodeId,
      'businessId': businessId,
      'type': type.value,
      'title': title,
      'description': description,
      'url': url,
      'data': data.toJson(),
      'style': style.toJson(),
      'stats': stats.toJson(),
      'isActive': isActive,
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt.toIso8601String(),
      'expiresAt': expiresAt?.toIso8601String(),
      'createdBy': createdBy,
    };
  }

  Map<String, dynamic> toFirestore() {
    final data = toJson();
    data.remove('qrCodeId');
    data['createdAt'] = Timestamp.fromDate(createdAt);
    data['updatedAt'] = Timestamp.fromDate(updatedAt);
    if (expiresAt != null) {
      data['expiresAt'] = Timestamp.fromDate(expiresAt!);
    }
    return data;
  }

  QRCode copyWith({
    String? qrCodeId,
    String? businessId,
    QRCodeType? type,
    String? title,
    String? description,
    String? url,
    QRCodeData? data,
    QRCodeStyle? style,
    QRCodeStats? stats,
    bool? isActive,
    DateTime? createdAt,
    DateTime? updatedAt,
    DateTime? expiresAt,
    String? createdBy,
  }) {
    return QRCode(
      qrCodeId: qrCodeId ?? this.qrCodeId,
      businessId: businessId ?? this.businessId,
      type: type ?? this.type,
      title: title ?? this.title,
      description: description ?? this.description,
      url: url ?? this.url,
      data: data ?? this.data,
      style: style ?? this.style,
      stats: stats ?? this.stats,
      isActive: isActive ?? this.isActive,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      expiresAt: expiresAt ?? this.expiresAt,
      createdBy: createdBy ?? this.createdBy,
    );
  }

  static DateTime _parseDateTime(dynamic value) {
    if (value == null) return DateTime.now();
    
    if (value is Timestamp) {
      return value.toDate();
    } else if (value is String) {
      return DateTime.parse(value);
    } else if (value is DateTime) {
      return value;
    }
    
    return DateTime.now();
  }

  @override
  String toString() {
    return 'QRCode(qrCodeId: $qrCodeId, businessId: $businessId, type: ${type.value}, title: $title)';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is QRCode && other.qrCodeId == qrCodeId;
  }

  @override
  int get hashCode => qrCodeId.hashCode;
}

// =============================================================================
// QR CODE TYPE ENUM
// =============================================================================

enum QRCodeType {
  business('business', 'İşletme QR Kodu', 'Genel menü erişimi'),
  table('table', 'Masa QR Kodu', 'Masa bazlı menü erişimi'),
  category('category', 'Kategori QR Kodu', 'Belirli kategori erişimi'),
  product('product', 'Ürün QR Kodu', 'Belirli ürün erişimi'),
  promotion('promotion', 'Promosyon QR Kodu', 'Özel kampanya erişimi');

  const QRCodeType(this.value, this.displayName, this.description);
  final String value;
  final String displayName;
  final String description;

  static QRCodeType fromString(String value) {
    return QRCodeType.values.firstWhere(
      (type) => type.value == value,
      orElse: () => QRCodeType.business,
    );
  }
}

// =============================================================================
// QR CODE DATA
// =============================================================================

class QRCodeData {
  final Map<String, dynamic> parameters;

  QRCodeData({required this.parameters});

  factory QRCodeData.business({
    required String businessId,
    required String businessName,
    Map<String, dynamic>? additionalParams,
  }) {
    return QRCodeData(
      parameters: {
        'businessId': businessId,
        'businessName': businessName,
        'type': 'business',
        ...?additionalParams,
      },
    );
  }

  factory QRCodeData.table({
    required String businessId,
    required String businessName,
    required int tableNumber,
    String? tableName,
    String? waiterCode,
    Map<String, dynamic>? additionalParams,
  }) {
    return QRCodeData(
      parameters: {
        'businessId': businessId,
        'businessName': businessName,
        'tableNumber': tableNumber,
        'tableName': tableName,
        'waiterCode': waiterCode,
        'type': 'table',
        ...?additionalParams,
      },
    );
  }

  factory QRCodeData.fromJson(Map<String, dynamic> json) {
    return QRCodeData(
      parameters: Map<String, dynamic>.from(json),
    );
  }

  Map<String, dynamic> toJson() {
    return Map<String, dynamic>.from(parameters);
  }

  // Getters for common parameters
  String? get businessId => parameters['businessId'];
  String? get businessName => parameters['businessName'];
  int? get tableNumber => parameters['tableNumber'];
  String? get tableName => parameters['tableName'];
  String? get waiterCode => parameters['waiterCode'];
  String? get type => parameters['type'];
}

// =============================================================================
// QR CODE STYLE
// =============================================================================

class QRCodeStyle {
  final String backgroundColor;
  final String foregroundColor;
  final double size;
  final String logoUrl;
  final bool showLogo;
  final bool showBusinessName;
  final bool showTableInfo;
  final String fontFamily;
  final double fontSize;
  final String borderStyle;
  final double borderWidth;
  final String borderColor;

  QRCodeStyle({
    required this.backgroundColor,
    required this.foregroundColor,
    required this.size,
    required this.logoUrl,
    required this.showLogo,
    required this.showBusinessName,
    required this.showTableInfo,
    required this.fontFamily,
    required this.fontSize,
    required this.borderStyle,
    required this.borderWidth,
    required this.borderColor,
  });

  factory QRCodeStyle.defaultStyle() {
    return QRCodeStyle(
      backgroundColor: '#FFFFFF',
      foregroundColor: '#000000',
      size: 200.0,
      logoUrl: '',
      showLogo: false,
      showBusinessName: true,
      showTableInfo: true,
      fontFamily: 'Roboto',
      fontSize: 14.0,
      borderStyle: 'none',
      borderWidth: 0.0,
      borderColor: '#000000',
    );
  }

  factory QRCodeStyle.fromJson(Map<String, dynamic> json) {
    return QRCodeStyle(
      backgroundColor: json['backgroundColor'] ?? '#FFFFFF',
      foregroundColor: json['foregroundColor'] ?? '#000000',
      size: (json['size'] ?? 200.0).toDouble(),
      logoUrl: json['logoUrl'] ?? '',
      showLogo: json['showLogo'] ?? false,
      showBusinessName: json['showBusinessName'] ?? true,
      showTableInfo: json['showTableInfo'] ?? true,
      fontFamily: json['fontFamily'] ?? 'Roboto',
      fontSize: (json['fontSize'] ?? 14.0).toDouble(),
      borderStyle: json['borderStyle'] ?? 'none',
      borderWidth: (json['borderWidth'] ?? 0.0).toDouble(),
      borderColor: json['borderColor'] ?? '#000000',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'backgroundColor': backgroundColor,
      'foregroundColor': foregroundColor,
      'size': size,
      'logoUrl': logoUrl,
      'showLogo': showLogo,
      'showBusinessName': showBusinessName,
      'showTableInfo': showTableInfo,
      'fontFamily': fontFamily,
      'fontSize': fontSize,
      'borderStyle': borderStyle,
      'borderWidth': borderWidth,
      'borderColor': borderColor,
    };
  }

  QRCodeStyle copyWith({
    String? backgroundColor,
    String? foregroundColor,
    double? size,
    String? logoUrl,
    bool? showLogo,
    bool? showBusinessName,
    bool? showTableInfo,
    String? fontFamily,
    double? fontSize,
    String? borderStyle,
    double? borderWidth,
    String? borderColor,
  }) {
    return QRCodeStyle(
      backgroundColor: backgroundColor ?? this.backgroundColor,
      foregroundColor: foregroundColor ?? this.foregroundColor,
      size: size ?? this.size,
      logoUrl: logoUrl ?? this.logoUrl,
      showLogo: showLogo ?? this.showLogo,
      showBusinessName: showBusinessName ?? this.showBusinessName,
      showTableInfo: showTableInfo ?? this.showTableInfo,
      fontFamily: fontFamily ?? this.fontFamily,
      fontSize: fontSize ?? this.fontSize,
      borderStyle: borderStyle ?? this.borderStyle,
      borderWidth: borderWidth ?? this.borderWidth,
      borderColor: borderColor ?? this.borderColor,
    );
  }
}

// =============================================================================
// QR CODE STATISTICS
// =============================================================================

class QRCodeStats {
  final int totalScans;
  final int todayScans;
  final int weeklyScans;
  final int monthlyScans;
  final DateTime? firstScanAt;
  final DateTime? lastScanAt;
  final Map<String, int> dailyScans;
  final Map<String, int> deviceTypes;
  final Map<String, int> locations;

  QRCodeStats({
    required this.totalScans,
    required this.todayScans,
    required this.weeklyScans,
    required this.monthlyScans,
    this.firstScanAt,
    this.lastScanAt,
    required this.dailyScans,
    required this.deviceTypes,
    required this.locations,
  });

  factory QRCodeStats.empty() {
    return QRCodeStats(
      totalScans: 0,
      todayScans: 0,
      weeklyScans: 0,
      monthlyScans: 0,
      dailyScans: {},
      deviceTypes: {},
      locations: {},
    );
  }

  factory QRCodeStats.fromJson(Map<String, dynamic> json) {
    return QRCodeStats(
      totalScans: json['totalScans'] ?? 0,
      todayScans: json['todayScans'] ?? 0,
      weeklyScans: json['weeklyScans'] ?? 0,
      monthlyScans: json['monthlyScans'] ?? 0,
      firstScanAt: json['firstScanAt'] != null 
          ? DateTime.parse(json['firstScanAt']) 
          : null,
      lastScanAt: json['lastScanAt'] != null 
          ? DateTime.parse(json['lastScanAt']) 
          : null,
      dailyScans: Map<String, int>.from(json['dailyScans'] ?? {}),
      deviceTypes: Map<String, int>.from(json['deviceTypes'] ?? {}),
      locations: Map<String, int>.from(json['locations'] ?? {}),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'totalScans': totalScans,
      'todayScans': todayScans,
      'weeklyScans': weeklyScans,
      'monthlyScans': monthlyScans,
      'firstScanAt': firstScanAt?.toIso8601String(),
      'lastScanAt': lastScanAt?.toIso8601String(),
      'dailyScans': dailyScans,
      'deviceTypes': deviceTypes,
      'locations': locations,
    };
  }

  QRCodeStats incrementScan({
    String? deviceType,
    String? location,
  }) {
    final now = DateTime.now();
    final today = '${now.year}-${now.month.toString().padLeft(2, '0')}-${now.day.toString().padLeft(2, '0')}';
    
    final newDailyScans = Map<String, int>.from(dailyScans);
    newDailyScans[today] = (newDailyScans[today] ?? 0) + 1;
    
    final newDeviceTypes = Map<String, int>.from(deviceTypes);
    if (deviceType != null) {
      newDeviceTypes[deviceType] = (newDeviceTypes[deviceType] ?? 0) + 1;
    }
    
    final newLocations = Map<String, int>.from(locations);
    if (location != null) {
      newLocations[location] = (newLocations[location] ?? 0) + 1;
    }
    
    return QRCodeStats(
      totalScans: totalScans + 1,
      todayScans: todayScans + 1,
      weeklyScans: weeklyScans + 1,
      monthlyScans: monthlyScans + 1,
      firstScanAt: firstScanAt ?? now,
      lastScanAt: now,
      dailyScans: newDailyScans,
      deviceTypes: newDeviceTypes,
      locations: newLocations,
    );
  }
}

// =============================================================================
// QR CODE PACKAGE (for bulk operations)
// =============================================================================

class QRCodePackage {
  final String businessId;
  final String businessName;
  final QRCode businessQR;
  final List<QRCode> tableQRs;
  final DateTime createdAt;
  final String? createdBy;

  QRCodePackage({
    required this.businessId,
    required this.businessName,
    required this.businessQR,
    required this.tableQRs,
    required this.createdAt,
    this.createdBy,
  });

  int get totalQRCodes => 1 + tableQRs.length;

  factory QRCodePackage.create({
    required String businessId,
    required String businessName,
    required int tableCount,
    QRCodeStyle? style,
    String? createdBy,
  }) {
    final businessQR = QRCode.businessQR(
      businessId: businessId,
      businessName: businessName,
      style: style,
      createdBy: createdBy,
    );

    final tableQRs = List.generate(
      tableCount,
      (index) => QRCode.tableQR(
        businessId: businessId,
        businessName: businessName,
        tableNumber: index + 1,
        style: style,
        createdBy: createdBy,
      ),
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

  List<QRCode> get allQRCodes => [businessQR, ...tableQRs];
} 