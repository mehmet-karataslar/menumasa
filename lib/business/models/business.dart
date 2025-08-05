import 'package:cloud_firestore/cloud_firestore.dart';

// =============================================================================
// BUSINESS MODEL
// =============================================================================

class Business {
  final String id;
  final String ownerId;
  final String businessName;
  final String businessDescription;
  final String businessType;
  final String businessAddress;
  final String? logoUrl;
  final String? phone;
  final String? email;
  final Address address;
  final ContactInfo contactInfo;
  final String? qrCodeUrl;
  final MenuSettings menuSettings;
  final BusinessSettings settings;
  final BusinessStats stats;
  final bool isActive;
  final bool isOpen;
  final bool isApproved;
  final BusinessStatus status;
  final DateTime createdAt;
  final DateTime updatedAt;
  final DateTime? approvedAt;
  final String? approvedBy;
  final List<String> staffIds;
  final List<String> categoryIds;
  final Map<String, dynamic>? metadata;

  Business({
    required this.id,
    required this.ownerId,
    required this.businessName,
    required this.businessDescription,
    required this.businessType,
    required this.businessAddress,
    this.logoUrl,
    this.phone,
    this.email,
    required this.address,
    required this.contactInfo,
    this.qrCodeUrl,
    required this.menuSettings,
    required this.settings,
    required this.stats,
    required this.isActive,
    required this.isOpen,
    required this.isApproved,
    required this.status,
    required this.createdAt,
    required this.updatedAt,
    this.approvedAt,
    this.approvedBy,
    this.staffIds = const [],
    this.categoryIds = const [],
    this.metadata,
  });

  // Factory methods for different business types
  factory Business.restaurant({
    required String id,
    required String ownerId,
    required String businessName,
    String businessDescription = '',
    String businessAddress = '',
    String? logoUrl,
    String? phone,
    String? email,
    Address? address,
    ContactInfo? contactInfo,
    String? qrCodeUrl,
    MenuSettings? menuSettings,
    BusinessSettings? settings,
    BusinessStats? stats,
    bool isActive = true,
    bool isOpen = true,
    bool isApproved = false,
    BusinessStatus status = BusinessStatus.pending,
    DateTime? createdAt,
    DateTime? updatedAt,
    DateTime? approvedAt,
    String? approvedBy,
    List<String> staffIds = const [],
    List<String> categoryIds = const [],
    Map<String, dynamic>? metadata,
  }) {
    return Business(
      id: id,
      ownerId: ownerId,
      businessName: businessName,
      businessDescription: businessDescription,
      businessType: 'Restoran',
      businessAddress: businessAddress,
      logoUrl: logoUrl,
      phone: phone,
      email: email,
      address: address ?? Address.empty(),
      contactInfo: contactInfo ?? ContactInfo.empty(),
      qrCodeUrl: qrCodeUrl,
      menuSettings: menuSettings ?? MenuSettings.defaultRestaurant(),
      settings: settings ?? BusinessSettings.defaultRestaurant(),
      stats: stats ?? BusinessStats.empty(),
      isActive: isActive,
      isOpen: isOpen,
      isApproved: isApproved,
      status: status,
      createdAt: createdAt ?? DateTime.now(),
      updatedAt: updatedAt ?? DateTime.now(),
      approvedAt: approvedAt,
      approvedBy: approvedBy,
      staffIds: staffIds,
      categoryIds: categoryIds,
      metadata: metadata,
    );
  }

  factory Business.cafe({
    required String id,
    required String ownerId,
    required String businessName,
    String businessDescription = '',
    String businessAddress = '',
    String? logoUrl,
    String? phone,
    String? email,
    Address? address,
    ContactInfo? contactInfo,
    String? qrCodeUrl,
    MenuSettings? menuSettings,
    BusinessSettings? settings,
    BusinessStats? stats,
    bool isActive = true,
    bool isOpen = true,
    bool isApproved = false,
    BusinessStatus status = BusinessStatus.pending,
    DateTime? createdAt,
    DateTime? updatedAt,
    DateTime? approvedAt,
    String? approvedBy,
    List<String> staffIds = const [],
    List<String> categoryIds = const [],
    Map<String, dynamic>? metadata,
  }) {
    return Business(
      id: id,
      ownerId: ownerId,
      businessName: businessName,
      businessDescription: businessDescription,
      businessType: 'Kafe',
      businessAddress: businessAddress,
      logoUrl: logoUrl,
      phone: phone,
      email: email,
      address: address ?? Address.empty(),
      contactInfo: contactInfo ?? ContactInfo.empty(),
      qrCodeUrl: qrCodeUrl,
      menuSettings: menuSettings ?? MenuSettings.defaultCafe(),
      settings: settings ?? BusinessSettings.defaultCafe(),
      stats: stats ?? BusinessStats.empty(),
      isActive: isActive,
      isOpen: isOpen,
      isApproved: isApproved,
      status: status,
      createdAt: createdAt ?? DateTime.now(),
      updatedAt: updatedAt ?? DateTime.now(),
      approvedAt: approvedAt,
      approvedBy: approvedBy,
      staffIds: staffIds,
      categoryIds: categoryIds,
      metadata: metadata,
    );
  }

  factory Business.fromJson(Map<String, dynamic> data, {String? id}) {
    return Business(
      id: id ?? data['id'] ?? '',
      ownerId: data['ownerId'] ?? '',
      businessName: data['businessName'] ?? '',
      businessDescription: data['businessDescription'] ?? '',
      businessType: data['businessType'] ?? 'Restoran',
      businessAddress: data['businessAddress'] ?? '',
      logoUrl: data['logoUrl'],
      phone: data['phone'],
      email: data['email'],
      address: Address.fromMap(data['address'] ?? {}),
      contactInfo: ContactInfo.fromMap(data['contactInfo'] ?? {}),
      qrCodeUrl: data['qrCodeUrl'],
      menuSettings: MenuSettings.fromMap(data['menuSettings'] ?? {}),
      settings: BusinessSettings.fromMap(data['settings'] ?? {}),
      stats: BusinessStats.fromMap(data['stats'] ?? {}),
      isActive: data['isActive'] ?? true,
      isOpen: data['isOpen'] ?? true,
      isApproved: data['isApproved'] ?? false,
      status: BusinessStatus.fromString(data['status'] ?? 'pending'),
      createdAt: _parseDateTime(data['createdAt']),
      updatedAt: _parseDateTime(data['updatedAt']),
      approvedAt: data['approvedAt'] != null
          ? _parseDateTime(data['approvedAt'])
          : null,
      approvedBy: data['approvedBy'],
      staffIds: List<String>.from(data['staffIds'] ?? []),
      categoryIds: List<String>.from(data['categoryIds'] ?? []),
      metadata: _parseMetadata(data['metadata']),
    );
  }

  factory Business.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return Business.fromJson({...data, 'id': doc.id});
  }

  /// Map'ten Business objesi oluştur (fromJson'un alias'ı)
  factory Business.fromMap(Map<String, dynamic> data, {String? id}) {
    return Business.fromJson(data, id: id);
  }

  factory Business.empty() {
    return Business(
      id: '',
      ownerId: '',
      businessName: '',
      businessDescription: '',
      businessType: '',
      businessAddress: '',
      address: Address.empty(),
      contactInfo: ContactInfo.empty(),
      menuSettings: MenuSettings.defaults(),
      settings: BusinessSettings.defaults(),
      stats: BusinessStats.empty(),
      isActive: false,
      isOpen: false,
      isApproved: false,
      status: BusinessStatus.pending,
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
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

  /// Metadata'yı parse eder (String, Map veya null olabilir)
  static Map<String, dynamic>? _parseMetadata(dynamic metadata) {
    if (metadata == null) return null;

    if (metadata is Map<String, dynamic>) {
      return metadata;
    } else if (metadata is Map) {
      // Map ama String, dynamic değil - dönüştür
      return Map<String, dynamic>.from(metadata);
    } else if (metadata is String) {
      // String ise null döndür (geçersiz format)
      return null;
    } else {
      return null; // Fallback
    }
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'ownerId': ownerId,
      'businessName': businessName,
      'businessDescription': businessDescription,
      'businessType': businessType,
      'businessAddress': businessAddress,
      'logoUrl': logoUrl,
      'phone': phone,
      'email': email,
      'address': address.toMap(),
      'contactInfo': contactInfo.toMap(),
      'qrCodeUrl': qrCodeUrl,
      'menuSettings': menuSettings.toMap(),
      'settings': settings.toMap(),
      'stats': stats.toMap(),
      'isActive': isActive,
      'isOpen': isOpen,
      'isApproved': isApproved,
      'status': status.value,
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt.toIso8601String(),
      'approvedAt': approvedAt?.toIso8601String(),
      'approvedBy': approvedBy,
      'staffIds': staffIds,
      'categoryIds': categoryIds,
      'metadata': metadata,
    };
  }

  Map<String, dynamic> toFirestore() {
    final data = toJson();
    data.remove('id');
    data['createdAt'] = Timestamp.fromDate(createdAt);
    data['updatedAt'] = Timestamp.fromDate(updatedAt);
    if (approvedAt != null) {
      data['approvedAt'] = Timestamp.fromDate(approvedAt!);
    }
    return data;
  }

  // Helper methods
  bool get isFullyOperational =>
      isActive && isOpen && isApproved && status == BusinessStatus.active;
  bool get needsApproval => !isApproved && status == BusinessStatus.pending;
  bool get isSuspended => status == BusinessStatus.suspended;
  bool get isClosed => status == BusinessStatus.closed;
  String get statusDisplayName => status.displayName;
  String get businessTypeDisplayName =>
      _getBusinessTypeDisplayName(businessType);

  String _getBusinessTypeDisplayName(String type) {
    switch (type.toLowerCase()) {
      case 'restoran':
        return 'Restoran';
      case 'kafe':
        return 'Kafe';
      case 'bar':
        return 'Bar';
      case 'pastane':
        return 'Pastane';
      case 'market':
        return 'Market';
      case 'eczane':
        return 'Eczane';
      default:
        return type;
    }
  }

  Business copyWith({
    String? id,
    String? ownerId,
    String? businessName,
    String? businessDescription,
    String? businessType,
    String? businessAddress,
    String? logoUrl,
    String? phone,
    String? email,
    Address? address,
    ContactInfo? contactInfo,
    String? qrCodeUrl,
    MenuSettings? menuSettings,
    BusinessSettings? settings,
    BusinessStats? stats,
    bool? isActive,
    bool? isOpen,
    bool? isApproved,
    BusinessStatus? status,
    DateTime? createdAt,
    DateTime? updatedAt,
    DateTime? approvedAt,
    String? approvedBy,
    List<String>? staffIds,
    List<String>? categoryIds,
    Map<String, dynamic>? metadata,
  }) {
    return Business(
      id: id ?? this.id,
      ownerId: ownerId ?? this.ownerId,
      businessName: businessName ?? this.businessName,
      businessDescription: businessDescription ?? this.businessDescription,
      businessType: businessType ?? this.businessType,
      businessAddress: businessAddress ?? this.businessAddress,
      logoUrl: logoUrl ?? this.logoUrl,
      phone: phone ?? this.phone,
      email: email ?? this.email,
      address: address ?? this.address,
      contactInfo: contactInfo ?? this.contactInfo,
      qrCodeUrl: qrCodeUrl ?? this.qrCodeUrl,
      menuSettings: menuSettings ?? this.menuSettings,
      settings: settings ?? this.settings,
      stats: stats ?? this.stats,
      isActive: isActive ?? this.isActive,
      isOpen: isOpen ?? this.isOpen,
      isApproved: isApproved ?? this.isApproved,
      status: status ?? this.status,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      approvedAt: approvedAt ?? this.approvedAt,
      approvedBy: approvedBy ?? this.approvedBy,
      staffIds: staffIds ?? this.staffIds,
      categoryIds: categoryIds ?? this.categoryIds,
      metadata: metadata ?? this.metadata,
    );
  }

  @override
  String toString() {
    return 'Business(id: $id, businessName: $businessName, ownerId: $ownerId, status: $status, isActive: $isActive)';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is Business && other.id == id;
  }

  @override
  int get hashCode => id.hashCode;
}

// =============================================================================
// BUSINESS STATUS
// =============================================================================

enum BusinessStatus {
  pending('pending', 'Beklemede', 'Onay bekliyor'),
  active('active', 'Aktif', 'Aktif ve çalışıyor'),
  suspended('suspended', 'Askıya Alındı', 'Geçici olarak askıya alındı'),
  closed('closed', 'Kapalı', 'Kalıcı olarak kapalı'),
  rejected('rejected', 'Reddedildi', 'Onay reddedildi');

  const BusinessStatus(this.value, this.displayName, this.description);
  final String value;
  final String displayName;
  final String description;

  static BusinessStatus fromString(String value) {
    return BusinessStatus.values.firstWhere(
      (status) => status.value == value,
      orElse: () => BusinessStatus.pending,
    );
  }
}

// =============================================================================
// ADDRESS MODEL
// =============================================================================

class Address {
  final String street;
  final String city;
  final String district;
  final String postalCode;
  final String country;
  final Coordinates? coordinates;

  Address({
    required this.street,
    required this.city,
    required this.district,
    required this.postalCode,
    this.country = 'Türkiye',
    this.coordinates,
  });

  factory Address.empty() {
    return Address(
      street: '',
      city: '',
      district: '',
      postalCode: '',
      country: 'Türkiye',
    );
  }

  factory Address.fromMap(Map<String, dynamic> map) {
    return Address(
      street: map['street'] ?? '',
      city: map['city'] ?? '',
      district: map['district'] ?? '',
      postalCode: map['postalCode'] ?? '',
      country: map['country'] ?? 'Türkiye',
      coordinates: map['coordinates'] != null
          ? Coordinates.fromMap(map['coordinates'])
          : null,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'street': street,
      'city': city,
      'district': district,
      'postalCode': postalCode,
      'country': country,
      'coordinates': coordinates?.toMap(),
    };
  }

  String get fullAddress {
    final parts = [street, district, city, postalCode, country];
    return parts.where((part) => part.isNotEmpty).join(', ');
  }

  Address copyWith({
    String? street,
    String? city,
    String? district,
    String? postalCode,
    String? country,
    Coordinates? coordinates,
  }) {
    return Address(
      street: street ?? this.street,
      city: city ?? this.city,
      district: district ?? this.district,
      postalCode: postalCode ?? this.postalCode,
      country: country ?? this.country,
      coordinates: coordinates ?? this.coordinates,
    );
  }
}

// =============================================================================
// CONTACT INFO MODEL
// =============================================================================

class ContactInfo {
  final String? phone;
  final String? email;
  final String? website;
  final String? facebook;
  final String? instagram;
  final String? twitter;
  final String? whatsapp;

  ContactInfo({
    this.phone,
    this.email,
    this.website,
    this.facebook,
    this.instagram,
    this.twitter,
    this.whatsapp,
  });

  factory ContactInfo.empty() {
    return ContactInfo();
  }

  // Getter for social media links
  Map<String, String?> get socialMedia => {
        'facebook': facebook,
        'instagram': instagram,
        'twitter': twitter,
        'whatsapp': whatsapp,
      };

  factory ContactInfo.fromMap(Map<String, dynamic> map) {
    return ContactInfo(
      phone: map['phone'],
      email: map['email'],
      website: map['website'],
      facebook: map['facebook'],
      instagram: map['instagram'],
      twitter: map['twitter'],
      whatsapp: map['whatsapp'],
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'phone': phone,
      'email': email,
      'website': website,
      'facebook': facebook,
      'instagram': instagram,
      'twitter': twitter,
      'whatsapp': whatsapp,
    };
  }

  ContactInfo copyWith({
    String? phone,
    String? email,
    String? website,
    String? facebook,
    String? instagram,
    String? twitter,
    String? whatsapp,
  }) {
    return ContactInfo(
      phone: phone ?? this.phone,
      email: email ?? this.email,
      website: website ?? this.website,
      facebook: facebook ?? this.facebook,
      instagram: instagram ?? this.instagram,
      twitter: twitter ?? this.twitter,
      whatsapp: whatsapp ?? this.whatsapp,
    );
  }
}

// =============================================================================
// MENU DESIGN MODELS
// =============================================================================

enum MenuThemeType {
  modern('modern', 'Modern', 'Temiz ve minimalist görünüm'),
  classic('classic', 'Klasik', 'Geleneksel ve zarif tasarım'),
  grid('grid', 'Izgara', 'Kart tabanlı ızgara düzeni'),
  magazine('magazine', 'Dergi', 'Dergi tarzı görsel yoğun tasarım'),
  dark('dark', 'Koyu', 'Karanlık tema ve koyu renkler');

  const MenuThemeType(this.value, this.displayName, this.description);
  final String value;
  final String displayName;
  final String description;

  static MenuThemeType fromString(String value) {
    return MenuThemeType.values.firstWhere(
      (theme) => theme.value == value,
      orElse: () => MenuThemeType.modern,
    );
  }
}

enum MenuLayoutType {
  list('list', 'Liste', 'Dikey liste düzeni'),
  grid('grid', 'Izgara', '2-3 sütunlu ızgara'),
  masonry('masonry', 'Karma', 'Değişken yükseklik düzeni'),
  carousel('carousel', 'Kaydırmalı', 'Yatay kaydırma düzeni'),
  staggered('staggered', 'Zigzag', 'Zigzag layout düzeni'),
  waterfall('waterfall', 'Şelale', 'Pinterest tarzı şelale'),
  magazine('magazine', 'Dergi', 'Dergi sayfa düzeni');

  const MenuLayoutType(this.value, this.displayName, this.description);
  final String value;
  final String displayName;
  final String description;

  static MenuLayoutType fromString(String value) {
    return MenuLayoutType.values.firstWhere(
      (layout) => layout.value == value,
      orElse: () => MenuLayoutType.grid,
    );
  }
}

enum MenuCardSize {
  small('small', 'Küçük', 0.6),
  medium('medium', 'Orta', 0.8),
  large('large', 'Büyük', 1.0),
  extraLarge('extraLarge', 'Çok Büyük', 1.2);

  const MenuCardSize(this.value, this.displayName, this.scale);
  final String value;
  final String displayName;
  final double scale;

  static MenuCardSize fromString(String value) {
    return MenuCardSize.values.firstWhere(
      (size) => size.value == value,
      orElse: () => MenuCardSize.medium,
    );
  }
}

class MenuDesignTheme {
  final MenuThemeType themeType;
  final String name;
  final String description;
  final bool isCustom;
  final Map<String, dynamic>? customProperties;

  const MenuDesignTheme({
    required this.themeType,
    required this.name,
    required this.description,
    this.isCustom = false,
    this.customProperties,
  });

  factory MenuDesignTheme.modern() {
    return const MenuDesignTheme(
      themeType: MenuThemeType.modern,
      name: 'Modern',
      description: 'Temiz, minimalist ve çağdaş görünüm',
    );
  }

  factory MenuDesignTheme.classic() {
    return const MenuDesignTheme(
      themeType: MenuThemeType.classic,
      name: 'Klasik',
      description: 'Geleneksel ve zarif tasarım',
    );
  }

  factory MenuDesignTheme.grid() {
    return const MenuDesignTheme(
      themeType: MenuThemeType.grid,
      name: 'Izgara',
      description: 'Kart tabanlı ızgara düzeni',
    );
  }

  factory MenuDesignTheme.magazine() {
    return const MenuDesignTheme(
      themeType: MenuThemeType.magazine,
      name: 'Dergi',
      description: 'Görsel yoğun dergi tarzı tasarım',
    );
  }

  factory MenuDesignTheme.dark() {
    return const MenuDesignTheme(
      themeType: MenuThemeType.dark,
      name: 'Koyu',
      description: 'Karanlık tema ve koyu renkler',
    );
  }

  factory MenuDesignTheme.fromMap(Map<String, dynamic> map) {
    return MenuDesignTheme(
      themeType: MenuThemeType.fromString(map['themeType'] ?? 'modern'),
      name: map['name'] ?? 'Modern',
      description: map['description'] ?? '',
      isCustom: map['isCustom'] ?? false,
      customProperties: _parseCustomProperties(map['customProperties']),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'themeType': themeType.value,
      'name': name,
      'description': description,
      'isCustom': isCustom,
      'customProperties': customProperties,
    };
  }

  MenuDesignTheme copyWith({
    MenuThemeType? themeType,
    String? name,
    String? description,
    bool? isCustom,
    Map<String, dynamic>? customProperties,
  }) {
    return MenuDesignTheme(
      themeType: themeType ?? this.themeType,
      name: name ?? this.name,
      description: description ?? this.description,
      isCustom: isCustom ?? this.isCustom,
      customProperties: customProperties ?? this.customProperties,
    );
  }

  /// Custom properties'i parse eder (String, Map veya null olabilir)
  static Map<String, dynamic>? _parseCustomProperties(dynamic properties) {
    if (properties == null) return null;

    if (properties is Map<String, dynamic>) {
      return properties;
    } else if (properties is Map) {
      // Map ama String, dynamic değil - dönüştür
      return Map<String, dynamic>.from(properties);
    } else if (properties is String) {
      // String ise null döndür (geçersiz format)
      return null;
    } else {
      return null; // Fallback
    }
  }
}

class MenuLayoutStyle {
  final MenuLayoutType layoutType;
  final int columnsCount;
  final double itemSpacing;
  final double categorySpacing;
  final bool showCategoryHeaders;
  final bool stickyHeaders;
  final double itemHeight;
  final bool autoHeight;
  final double padding;
  final double sectionSpacing;
  final MenuCardSize cardSize;
  final double cardAspectRatio;

  const MenuLayoutStyle({
    this.layoutType = MenuLayoutType.grid,
    this.columnsCount = 2,
    this.itemSpacing = 16.0,
    this.categorySpacing = 24.0,
    this.showCategoryHeaders = true,
    this.stickyHeaders = false,
    this.itemHeight = 200.0,
    this.autoHeight = true,
    this.padding = 16.0,
    this.sectionSpacing = 32.0,
    this.cardSize = MenuCardSize.medium,
    this.cardAspectRatio = 0.75,
  });

  factory MenuLayoutStyle.fromMap(Map<String, dynamic> map) {
    return MenuLayoutStyle(
      layoutType: MenuLayoutType.fromString(map['layoutType'] ?? 'grid'),
      columnsCount: map['columnsCount'] ?? 2,
      itemSpacing: (map['itemSpacing'] ?? 16.0).toDouble(),
      categorySpacing: (map['categorySpacing'] ?? 24.0).toDouble(),
      showCategoryHeaders: map['showCategoryHeaders'] ?? true,
      stickyHeaders: map['stickyHeaders'] ?? false,
      itemHeight: (map['itemHeight'] ?? 200.0).toDouble(),
      autoHeight: map['autoHeight'] ?? true,
      padding: (map['padding'] ?? 16.0).toDouble(),
      sectionSpacing: (map['sectionSpacing'] ?? 32.0).toDouble(),
      cardSize: MenuCardSize.fromString(map['cardSize'] ?? 'medium'),
      cardAspectRatio: (map['cardAspectRatio'] ?? 0.75).toDouble(),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'layoutType': layoutType.value,
      'columnsCount': columnsCount,
      'itemSpacing': itemSpacing,
      'categorySpacing': categorySpacing,
      'showCategoryHeaders': showCategoryHeaders,
      'stickyHeaders': stickyHeaders,
      'itemHeight': itemHeight,
      'autoHeight': autoHeight,
      'padding': padding,
      'sectionSpacing': sectionSpacing,
      'cardSize': cardSize.value,
      'cardAspectRatio': cardAspectRatio,
    };
  }

  MenuLayoutStyle copyWith({
    MenuLayoutType? layoutType,
    int? columnsCount,
    double? itemSpacing,
    double? categorySpacing,
    bool? showCategoryHeaders,
    bool? stickyHeaders,
    double? itemHeight,
    bool? autoHeight,
    double? padding,
    double? sectionSpacing,
    MenuCardSize? cardSize,
    double? cardAspectRatio,
  }) {
    return MenuLayoutStyle(
      layoutType: layoutType ?? this.layoutType,
      columnsCount: columnsCount ?? this.columnsCount,
      itemSpacing: itemSpacing ?? this.itemSpacing,
      categorySpacing: categorySpacing ?? this.categorySpacing,
      showCategoryHeaders: showCategoryHeaders ?? this.showCategoryHeaders,
      stickyHeaders: stickyHeaders ?? this.stickyHeaders,
      itemHeight: itemHeight ?? this.itemHeight,
      autoHeight: autoHeight ?? this.autoHeight,
      padding: padding ?? this.padding,
      sectionSpacing: sectionSpacing ?? this.sectionSpacing,
      cardSize: cardSize ?? this.cardSize,
      cardAspectRatio: cardAspectRatio ?? this.cardAspectRatio,
    );
  }
}

class MenuColorScheme {
  final String primaryColor;
  final String secondaryColor;
  final String backgroundColor;
  final String surfaceColor;
  final String textPrimaryColor;
  final String textSecondaryColor;
  final String accentColor;
  final String cardColor;
  final String borderColor;
  final String shadowColor;
  final double opacity;
  final bool isDark;

  const MenuColorScheme({
    this.primaryColor = '#FF6B35',
    this.secondaryColor = '#FFB86C',
    this.backgroundColor = '#FFFFFF',
    this.surfaceColor = '#F8F9FA',
    this.textPrimaryColor = '#2C3E50',
    this.textSecondaryColor = '#7F8C8D',
    this.accentColor = '#E74C3C',
    this.cardColor = '#FFFFFF',
    this.borderColor = '#E9ECEF',
    this.shadowColor = '#00000010',
    this.opacity = 1.0,
    this.isDark = false,
  });

  factory MenuColorScheme.fromMap(Map<String, dynamic> map) {
    return MenuColorScheme(
      primaryColor: map['primaryColor'] ?? '#FF6B35',
      secondaryColor: map['secondaryColor'] ?? '#FFB86C',
      backgroundColor: map['backgroundColor'] ?? '#FFFFFF',
      surfaceColor: map['surfaceColor'] ?? '#F8F9FA',
      textPrimaryColor: map['textPrimaryColor'] ?? '#2C3E50',
      textSecondaryColor: map['textSecondaryColor'] ?? '#7F8C8D',
      accentColor: map['accentColor'] ?? '#E74C3C',
      cardColor: map['cardColor'] ?? '#FFFFFF',
      borderColor: map['borderColor'] ?? '#E9ECEF',
      shadowColor: map['shadowColor'] ?? '#00000010',
      opacity: (map['opacity'] ?? 1.0).toDouble(),
      isDark: map['isDark'] ?? false,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'primaryColor': primaryColor,
      'secondaryColor': secondaryColor,
      'backgroundColor': backgroundColor,
      'surfaceColor': surfaceColor,
      'textPrimaryColor': textPrimaryColor,
      'textSecondaryColor': textSecondaryColor,
      'accentColor': accentColor,
      'cardColor': cardColor,
      'borderColor': borderColor,
      'shadowColor': shadowColor,
      'opacity': opacity,
      'isDark': isDark,
    };
  }

  MenuColorScheme copyWith({
    String? primaryColor,
    String? secondaryColor,
    String? backgroundColor,
    String? surfaceColor,
    String? textPrimaryColor,
    String? textSecondaryColor,
    String? accentColor,
    String? cardColor,
    String? borderColor,
    String? shadowColor,
    double? opacity,
    bool? isDark,
  }) {
    return MenuColorScheme(
      primaryColor: primaryColor ?? this.primaryColor,
      secondaryColor: secondaryColor ?? this.secondaryColor,
      backgroundColor: backgroundColor ?? this.backgroundColor,
      surfaceColor: surfaceColor ?? this.surfaceColor,
      textPrimaryColor: textPrimaryColor ?? this.textPrimaryColor,
      textSecondaryColor: textSecondaryColor ?? this.textSecondaryColor,
      accentColor: accentColor ?? this.accentColor,
      cardColor: cardColor ?? this.cardColor,
      borderColor: borderColor ?? this.borderColor,
      shadowColor: shadowColor ?? this.shadowColor,
      opacity: opacity ?? this.opacity,
      isDark: isDark ?? this.isDark,
    );
  }
}

class MenuBackgroundSettings {
  final String type; // 'color', 'pattern', 'gradient', 'image'
  final String backgroundImage; // URL or pattern name
  final String primaryColor;
  final String secondaryColor;
  final double opacity;
  final String blendMode; // 'normal', 'multiply', 'overlay', etc.
  final bool isRepeating;

  const MenuBackgroundSettings({
    this.type = 'color',
    this.backgroundImage = '',
    this.primaryColor = '#FFFFFF',
    this.secondaryColor = '#F8F9FA',
    this.opacity = 1.0,
    this.blendMode = 'normal',
    this.isRepeating = true,
  });

  factory MenuBackgroundSettings.fromMap(Map<String, dynamic> map) {
    return MenuBackgroundSettings(
      type: map['type'] ?? 'color',
      backgroundImage: map['backgroundImage'] ?? '',
      primaryColor: map['primaryColor'] ?? '#FFFFFF',
      secondaryColor: map['secondaryColor'] ?? '#F8F9FA',
      opacity: (map['opacity'] ?? 1.0).toDouble(),
      blendMode: map['blendMode'] ?? 'normal',
      isRepeating: map['isRepeating'] ?? true,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'type': type,
      'backgroundImage': backgroundImage,
      'primaryColor': primaryColor,
      'secondaryColor': secondaryColor,
      'opacity': opacity,
      'blendMode': blendMode,
      'isRepeating': isRepeating,
    };
  }

  MenuBackgroundSettings copyWith({
    String? type,
    String? backgroundImage,
    String? primaryColor,
    String? secondaryColor,
    double? opacity,
    String? blendMode,
    bool? isRepeating,
  }) {
    return MenuBackgroundSettings(
      type: type ?? this.type,
      backgroundImage: backgroundImage ?? this.backgroundImage,
      primaryColor: primaryColor ?? this.primaryColor,
      secondaryColor: secondaryColor ?? this.secondaryColor,
      opacity: opacity ?? this.opacity,
      blendMode: blendMode ?? this.blendMode,
      isRepeating: isRepeating ?? this.isRepeating,
    );
  }
}

class MenuTypography {
  final String fontFamily;
  final double titleFontSize;
  final double headingFontSize;
  final double bodyFontSize;
  final double captionFontSize;
  final String titleFontWeight;
  final String headingFontWeight;
  final String bodyFontWeight;
  final double lineHeight;
  final double letterSpacing;

  // Kategori Stil Ayarları
  final double categoryFontSize;
  final String categoryFontWeight;
  final String categoryTextColor;
  final String categorySelectedTextColor;
  final bool showCategoryImages;
  final double categoryImageSize;
  final String categoryLayout; // 'horizontal', 'vertical', 'story'

  const MenuTypography({
    this.fontFamily = 'Poppins',
    this.titleFontSize = 24.0,
    this.headingFontSize = 18.0,
    this.bodyFontSize = 14.0,
    this.captionFontSize = 12.0,
    this.titleFontWeight = '600',
    this.headingFontWeight = '500',
    this.bodyFontWeight = '400',
    this.lineHeight = 1.4,
    this.letterSpacing = 0.0,
    // Kategori varsayılanları
    this.categoryFontSize = 12.0,
    this.categoryFontWeight = '500',
    this.categoryTextColor = '#333333',
    this.categorySelectedTextColor = '#FF6B35',
    this.showCategoryImages = true,
    this.categoryImageSize = 70.0,
    this.categoryLayout = 'story',
  });

  factory MenuTypography.fromMap(Map<String, dynamic> map) {
    return MenuTypography(
      fontFamily: map['fontFamily'] ?? 'Poppins',
      titleFontSize: (map['titleFontSize'] ?? 24.0).toDouble(),
      headingFontSize: (map['headingFontSize'] ?? 18.0).toDouble(),
      bodyFontSize: (map['bodyFontSize'] ?? 14.0).toDouble(),
      captionFontSize: (map['captionFontSize'] ?? 12.0).toDouble(),
      titleFontWeight: map['titleFontWeight'] ?? '600',
      headingFontWeight: map['headingFontWeight'] ?? '500',
      bodyFontWeight: map['bodyFontWeight'] ?? '400',
      lineHeight: (map['lineHeight'] ?? 1.4).toDouble(),
      letterSpacing: (map['letterSpacing'] ?? 0.0).toDouble(),
      // Kategori ayarları
      categoryFontSize: (map['categoryFontSize'] ?? 12.0).toDouble(),
      categoryFontWeight: map['categoryFontWeight'] ?? '500',
      categoryTextColor: map['categoryTextColor'] ?? '#333333',
      categorySelectedTextColor: map['categorySelectedTextColor'] ?? '#FF6B35',
      showCategoryImages: map['showCategoryImages'] ?? true,
      categoryImageSize: (map['categoryImageSize'] ?? 70.0).toDouble(),
      categoryLayout: map['categoryLayout'] ?? 'story',
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'fontFamily': fontFamily,
      'titleFontSize': titleFontSize,
      'headingFontSize': headingFontSize,
      'bodyFontSize': bodyFontSize,
      'captionFontSize': captionFontSize,
      'titleFontWeight': titleFontWeight,
      'headingFontWeight': headingFontWeight,
      'bodyFontWeight': bodyFontWeight,
      'lineHeight': lineHeight,
      'letterSpacing': letterSpacing,
      // Kategori ayarları
      'categoryFontSize': categoryFontSize,
      'categoryFontWeight': categoryFontWeight,
      'categoryTextColor': categoryTextColor,
      'categorySelectedTextColor': categorySelectedTextColor,
      'showCategoryImages': showCategoryImages,
      'categoryImageSize': categoryImageSize,
      'categoryLayout': categoryLayout,
    };
  }

  MenuTypography copyWith({
    String? fontFamily,
    double? titleFontSize,
    double? headingFontSize,
    double? bodyFontSize,
    double? captionFontSize,
    String? titleFontWeight,
    String? headingFontWeight,
    String? bodyFontWeight,
    double? lineHeight,
    double? letterSpacing,
    // Kategori ayarları
    double? categoryFontSize,
    String? categoryFontWeight,
    String? categoryTextColor,
    String? categorySelectedTextColor,
    bool? showCategoryImages,
    double? categoryImageSize,
    String? categoryLayout,
  }) {
    return MenuTypography(
      fontFamily: fontFamily ?? this.fontFamily,
      titleFontSize: titleFontSize ?? this.titleFontSize,
      headingFontSize: headingFontSize ?? this.headingFontSize,
      bodyFontSize: bodyFontSize ?? this.bodyFontSize,
      captionFontSize: captionFontSize ?? this.captionFontSize,
      titleFontWeight: titleFontWeight ?? this.titleFontWeight,
      headingFontWeight: headingFontWeight ?? this.headingFontWeight,
      bodyFontWeight: bodyFontWeight ?? this.bodyFontWeight,
      lineHeight: lineHeight ?? this.lineHeight,
      letterSpacing: letterSpacing ?? this.letterSpacing,
      // Kategori ayarları
      categoryFontSize: categoryFontSize ?? this.categoryFontSize,
      categoryFontWeight: categoryFontWeight ?? this.categoryFontWeight,
      categoryTextColor: categoryTextColor ?? this.categoryTextColor,
      categorySelectedTextColor:
          categorySelectedTextColor ?? this.categorySelectedTextColor,
      showCategoryImages: showCategoryImages ?? this.showCategoryImages,
      categoryImageSize: categoryImageSize ?? this.categoryImageSize,
      categoryLayout: categoryLayout ?? this.categoryLayout,
    );
  }
}

class MenuVisualStyle {
  final double borderRadius;
  final double cardElevation;
  final bool showShadows;
  final bool showBorders;
  final double imageAspectRatio;
  final String imageShape; // 'rectangle', 'rounded', 'circle'
  final bool showImageOverlay;
  final double imageOpacity;
  final bool enableAnimations;
  final bool showDividers;
  final double buttonRadius;
  final String buttonStyle; // 'filled', 'outlined', 'text'

  const MenuVisualStyle({
    this.borderRadius = 12.0,
    this.cardElevation = 2.0,
    this.showShadows = true,
    this.showBorders = false,
    this.imageAspectRatio = 1.5,
    this.imageShape = 'rounded',
    this.showImageOverlay = false,
    this.imageOpacity = 1.0,
    this.enableAnimations = true,
    this.showDividers = true,
    this.buttonRadius = 8.0,
    this.buttonStyle = 'filled',
  });

  factory MenuVisualStyle.fromMap(Map<String, dynamic> map) {
    return MenuVisualStyle(
      borderRadius: (map['borderRadius'] ?? 12.0).toDouble(),
      cardElevation: (map['cardElevation'] ?? 2.0).toDouble(),
      showShadows: map['showShadows'] ?? true,
      showBorders: map['showBorders'] ?? false,
      imageAspectRatio: (map['imageAspectRatio'] ?? 1.5).toDouble(),
      imageShape: map['imageShape'] ?? 'rounded',
      showImageOverlay: map['showImageOverlay'] ?? false,
      imageOpacity: (map['imageOpacity'] ?? 1.0).toDouble(),
      enableAnimations: map['enableAnimations'] ?? true,
      showDividers: map['showDividers'] ?? true,
      buttonRadius: (map['buttonRadius'] ?? 8.0).toDouble(),
      buttonStyle: map['buttonStyle'] ?? 'filled',
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'borderRadius': borderRadius,
      'cardElevation': cardElevation,
      'showShadows': showShadows,
      'showBorders': showBorders,
      'imageAspectRatio': imageAspectRatio,
      'imageShape': imageShape,
      'showImageOverlay': showImageOverlay,
      'imageOpacity': imageOpacity,
      'enableAnimations': enableAnimations,
      'showDividers': showDividers,
      'buttonRadius': buttonRadius,
      'buttonStyle': buttonStyle,
    };
  }

  MenuVisualStyle copyWith({
    double? borderRadius,
    double? cardElevation,
    bool? showShadows,
    bool? showBorders,
    double? imageAspectRatio,
    String? imageShape,
    bool? showImageOverlay,
    double? imageOpacity,
    bool? enableAnimations,
    bool? showDividers,
    double? buttonRadius,
    String? buttonStyle,
  }) {
    return MenuVisualStyle(
      borderRadius: borderRadius ?? this.borderRadius,
      cardElevation: cardElevation ?? this.cardElevation,
      showShadows: showShadows ?? this.showShadows,
      showBorders: showBorders ?? this.showBorders,
      imageAspectRatio: imageAspectRatio ?? this.imageAspectRatio,
      imageShape: imageShape ?? this.imageShape,
      showImageOverlay: showImageOverlay ?? this.showImageOverlay,
      imageOpacity: imageOpacity ?? this.imageOpacity,
      enableAnimations: enableAnimations ?? this.enableAnimations,
      showDividers: showDividers ?? this.showDividers,
      buttonRadius: buttonRadius ?? this.buttonRadius,
      buttonStyle: buttonStyle ?? this.buttonStyle,
    );
  }
}

class MenuInteractionSettings {
  final bool enableHoverEffects;
  final bool enableClickAnimations;
  final bool enableSwipeGestures;
  final bool enableQuickView;
  final bool enableFavorites;
  final bool enableShare;
  final bool enableZoom;
  final double animationDuration;
  final bool hapticFeedback;
  final bool enableDoubleTap;
  final bool enableLongPress;
  final bool enableLazyLoading;
  final bool autoRefresh;
  final double refreshInterval;

  const MenuInteractionSettings({
    this.enableHoverEffects = true,
    this.enableClickAnimations = true,
    this.enableSwipeGestures = true,
    this.enableQuickView = false,
    this.enableFavorites = true,
    this.enableShare = false,
    this.enableZoom = false,
    this.animationDuration = 300.0,
    this.hapticFeedback = true,
    this.enableDoubleTap = false,
    this.enableLongPress = true,
    this.enableLazyLoading = true,
    this.autoRefresh = false,
    this.refreshInterval = 30.0,
  });

  factory MenuInteractionSettings.fromMap(Map<String, dynamic> map) {
    return MenuInteractionSettings(
      enableHoverEffects: map['enableHoverEffects'] ?? true,
      enableClickAnimations: map['enableClickAnimations'] ?? true,
      enableSwipeGestures: map['enableSwipeGestures'] ?? true,
      enableQuickView: map['enableQuickView'] ?? false,
      enableFavorites: map['enableFavorites'] ?? true,
      enableShare: map['enableShare'] ?? false,
      enableZoom: map['enableZoom'] ?? false,
      animationDuration: (map['animationDuration'] ?? 300.0).toDouble(),
      hapticFeedback: map['hapticFeedback'] ?? true,
      enableDoubleTap: map['enableDoubleTap'] ?? false,
      enableLongPress: map['enableLongPress'] ?? true,
      enableLazyLoading: map['enableLazyLoading'] ?? true,
      autoRefresh: map['autoRefresh'] ?? false,
      refreshInterval: (map['refreshInterval'] ?? 30.0).toDouble(),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'enableHoverEffects': enableHoverEffects,
      'enableClickAnimations': enableClickAnimations,
      'enableSwipeGestures': enableSwipeGestures,
      'enableQuickView': enableQuickView,
      'enableFavorites': enableFavorites,
      'enableShare': enableShare,
      'enableZoom': enableZoom,
      'animationDuration': animationDuration,
      'hapticFeedback': hapticFeedback,
      'enableDoubleTap': enableDoubleTap,
      'enableLongPress': enableLongPress,
      'enableLazyLoading': enableLazyLoading,
      'autoRefresh': autoRefresh,
      'refreshInterval': refreshInterval,
    };
  }

  MenuInteractionSettings copyWith({
    bool? enableHoverEffects,
    bool? enableClickAnimations,
    bool? enableSwipeGestures,
    bool? enableQuickView,
    bool? enableFavorites,
    bool? enableShare,
    bool? enableZoom,
    double? animationDuration,
    bool? hapticFeedback,
    bool? enableDoubleTap,
    bool? enableLongPress,
    bool? enableLazyLoading,
    bool? autoRefresh,
    double? refreshInterval,
  }) {
    return MenuInteractionSettings(
      enableHoverEffects: enableHoverEffects ?? this.enableHoverEffects,
      enableClickAnimations:
          enableClickAnimations ?? this.enableClickAnimations,
      enableSwipeGestures: enableSwipeGestures ?? this.enableSwipeGestures,
      enableQuickView: enableQuickView ?? this.enableQuickView,
      enableFavorites: enableFavorites ?? this.enableFavorites,
      enableShare: enableShare ?? this.enableShare,
      enableZoom: enableZoom ?? this.enableZoom,
      animationDuration: animationDuration ?? this.animationDuration,
      hapticFeedback: hapticFeedback ?? this.hapticFeedback,
      enableDoubleTap: enableDoubleTap ?? this.enableDoubleTap,
      enableLongPress: enableLongPress ?? this.enableLongPress,
      enableLazyLoading: enableLazyLoading ?? this.enableLazyLoading,
      autoRefresh: autoRefresh ?? this.autoRefresh,
      refreshInterval: refreshInterval ?? this.refreshInterval,
    );
  }
}

// =============================================================================
// MENU SETTINGS MODEL
// =============================================================================

class MenuSettings {
  final bool showPrices;
  final bool showDescriptions;
  final bool showImages;
  final bool showAllergens;
  final bool showNutritionalInfo;
  final String currency;
  final String language;
  final List<String> allergens;
  final Map<String, String> allergenTranslations;
  final bool enableQRCode;
  final bool enableOnlineOrdering;
  final bool enableTableService;
  final bool enableDelivery;
  final bool enableTakeaway;

  // Gelişmiş Tasarım Ayarları
  final MenuDesignTheme designTheme;
  final MenuLayoutStyle layoutStyle;
  final MenuColorScheme colorScheme;
  final MenuBackgroundSettings backgroundSettings;
  final MenuTypography typography;
  final MenuVisualStyle visualStyle;
  final MenuInteractionSettings interactionSettings;
  final Map<String, String>? workingHours;

  MenuSettings({
    this.showPrices = true,
    this.showDescriptions = true,
    this.showImages = true,
    this.showAllergens = true,
    this.showNutritionalInfo = false,
    this.currency = 'TRY',
    this.language = 'tr',
    this.allergens = const [],
    this.allergenTranslations = const {},
    this.enableQRCode = true,
    this.enableOnlineOrdering = true,
    this.enableTableService = true,
    this.enableDelivery = false,
    this.enableTakeaway = true,
    MenuDesignTheme? designTheme,
    MenuLayoutStyle? layoutStyle,
    MenuColorScheme? colorScheme,
    MenuBackgroundSettings? backgroundSettings,
    MenuTypography? typography,
    MenuVisualStyle? visualStyle,
    MenuInteractionSettings? interactionSettings,
    this.workingHours,
  })  : designTheme = designTheme ?? MenuDesignTheme.modern(),
        layoutStyle = layoutStyle ?? const MenuLayoutStyle(),
        colorScheme = colorScheme ?? const MenuColorScheme(),
        backgroundSettings =
            backgroundSettings ?? const MenuBackgroundSettings(),
        typography = typography ?? const MenuTypography(),
        visualStyle = visualStyle ?? const MenuVisualStyle(),
        interactionSettings =
            interactionSettings ?? const MenuInteractionSettings();

  factory MenuSettings.defaultRestaurant() {
    return MenuSettings(
      showPrices: true,
      showDescriptions: true,
      showImages: true,
      showAllergens: true,
      showNutritionalInfo: false,
      currency: 'TRY',
      language: 'tr',
      allergens: [
        'gluten',
        'lactose',
        'nuts',
        'eggs',
        'fish',
        'shellfish',
        'soy'
      ],
      allergenTranslations: {
        'gluten': 'Gluten',
        'lactose': 'Laktoz',
        'nuts': 'Kuruyemiş',
        'eggs': 'Yumurta',
        'fish': 'Balık',
        'shellfish': 'Kabuklu Deniz Ürünleri',
        'soy': 'Soya',
      },
      enableQRCode: true,
      enableOnlineOrdering: true,
      enableTableService: true,
      enableDelivery: false,
      enableTakeaway: true,
      designTheme: MenuDesignTheme.modern(),
      layoutStyle: const MenuLayoutStyle(layoutType: MenuLayoutType.grid),
      colorScheme: const MenuColorScheme(primaryColor: '#FF6B35'),
      typography: const MenuTypography(fontFamily: 'Poppins'),
      visualStyle: const MenuVisualStyle(),
      interactionSettings: const MenuInteractionSettings(),
    );
  }

  factory MenuSettings.defaultCafe() {
    return MenuSettings(
      showPrices: true,
      showDescriptions: true,
      showImages: true,
      showAllergens: false,
      showNutritionalInfo: false,
      currency: 'TRY',
      language: 'tr',
      allergens: ['lactose'],
      allergenTranslations: {
        'lactose': 'Laktoz',
      },
      enableQRCode: true,
      enableOnlineOrdering: true,
      enableTableService: true,
      enableDelivery: false,
      enableTakeaway: true,
      designTheme: MenuDesignTheme.classic(),
      layoutStyle: const MenuLayoutStyle(layoutType: MenuLayoutType.list),
      colorScheme: const MenuColorScheme(primaryColor: '#8B4513'),
      typography: const MenuTypography(fontFamily: 'Poppins'),
      visualStyle: const MenuVisualStyle(),
      interactionSettings: const MenuInteractionSettings(),
    );
  }

  factory MenuSettings.defaults() {
    return MenuSettings();
  }

  factory MenuSettings.fromMap(Map<String, dynamic> map) {
    // Legacy data detection - eski format'ı detect et
    bool isLegacyFormat = map.containsKey('theme') ||
        map.containsKey('primaryColor') ||
        map.containsKey('fontSize') ||
        !map.containsKey('designTheme');

    if (isLegacyFormat) {
      // Eski format'ı yeni format'a dönüştür
      return _fromLegacyMap(map);
    }

    // Yeni format - normal parsing
    return MenuSettings(
      showPrices: map['showPrices'] ?? true,
      showDescriptions: map['showDescriptions'] ?? true,
      showImages: map['showImages'] ?? true,
      showAllergens: map['showAllergens'] ?? true,
      showNutritionalInfo: map['showNutritionalInfo'] ?? false,
      currency: map['currency'] ?? 'TRY',
      language: map['language'] ?? 'tr',
      allergens: List<String>.from(map['allergens'] ?? []),
      allergenTranslations: _parseStringMap(map['allergenTranslations']),
      enableQRCode: map['enableQRCode'] ?? true,
      enableOnlineOrdering: map['enableOnlineOrdering'] ?? true,
      enableTableService: map['enableTableService'] ?? true,
      enableDelivery: map['enableDelivery'] ?? false,
      enableTakeaway: map['enableTakeaway'] ?? true,
      designTheme: map['designTheme'] != null
          ? MenuDesignTheme.fromMap(map['designTheme'])
          : MenuDesignTheme.modern(),
      layoutStyle: map['layoutStyle'] != null
          ? MenuLayoutStyle.fromMap(map['layoutStyle'])
          : const MenuLayoutStyle(),
      colorScheme: map['colorScheme'] != null
          ? MenuColorScheme.fromMap(map['colorScheme'])
          : const MenuColorScheme(),
      backgroundSettings: map['backgroundSettings'] != null
          ? MenuBackgroundSettings.fromMap(map['backgroundSettings'])
          : const MenuBackgroundSettings(),
      typography: map['typography'] != null
          ? MenuTypography.fromMap(map['typography'])
          : const MenuTypography(),
      visualStyle: map['visualStyle'] != null
          ? MenuVisualStyle.fromMap(map['visualStyle'])
          : const MenuVisualStyle(),
      interactionSettings: map['interactionSettings'] != null
          ? MenuInteractionSettings.fromMap(map['interactionSettings'])
          : const MenuInteractionSettings(),
      workingHours: _parseStringMap(map['workingHours']),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'showPrices': showPrices,
      'showDescriptions': showDescriptions,
      'showImages': showImages,
      'showAllergens': showAllergens,
      'showNutritionalInfo': showNutritionalInfo,
      'currency': currency,
      'language': language,
      'allergens': allergens,
      'allergenTranslations': allergenTranslations,
      'enableQRCode': enableQRCode,
      'enableOnlineOrdering': enableOnlineOrdering,
      'enableTableService': enableTableService,
      'enableDelivery': enableDelivery,
      'enableTakeaway': enableTakeaway,
      'designTheme': designTheme.toMap(),
      'layoutStyle': layoutStyle.toMap(),
      'colorScheme': colorScheme.toMap(),
      'backgroundSettings': backgroundSettings.toMap(),
      'typography': typography.toMap(),
      'visualStyle': visualStyle.toMap(),
      'interactionSettings': interactionSettings.toMap(),
      'workingHours': workingHours,
    };
  }

  MenuSettings copyWith({
    bool? showPrices,
    bool? showDescriptions,
    bool? showImages,
    bool? showAllergens,
    bool? showNutritionalInfo,
    String? currency,
    String? language,
    List<String>? allergens,
    Map<String, String>? allergenTranslations,
    bool? enableQRCode,
    bool? enableOnlineOrdering,
    bool? enableTableService,
    bool? enableDelivery,
    bool? enableTakeaway,
    MenuDesignTheme? designTheme,
    MenuLayoutStyle? layoutStyle,
    MenuColorScheme? colorScheme,
    MenuBackgroundSettings? backgroundSettings,
    MenuTypography? typography,
    MenuVisualStyle? visualStyle,
    MenuInteractionSettings? interactionSettings,
    Map<String, String>? workingHours,
  }) {
    return MenuSettings(
      showPrices: showPrices ?? this.showPrices,
      showDescriptions: showDescriptions ?? this.showDescriptions,
      showImages: showImages ?? this.showImages,
      showAllergens: showAllergens ?? this.showAllergens,
      showNutritionalInfo: showNutritionalInfo ?? this.showNutritionalInfo,
      currency: currency ?? this.currency,
      language: language ?? this.language,
      allergens: allergens ?? this.allergens,
      allergenTranslations: allergenTranslations ?? this.allergenTranslations,
      enableQRCode: enableQRCode ?? this.enableQRCode,
      enableOnlineOrdering: enableOnlineOrdering ?? this.enableOnlineOrdering,
      enableTableService: enableTableService ?? this.enableTableService,
      enableDelivery: enableDelivery ?? this.enableDelivery,
      enableTakeaway: enableTakeaway ?? this.enableTakeaway,
      designTheme: designTheme ?? this.designTheme,
      layoutStyle: layoutStyle ?? this.layoutStyle,
      colorScheme: colorScheme ?? this.colorScheme,
      backgroundSettings: backgroundSettings ?? this.backgroundSettings,
      typography: typography ?? this.typography,
      visualStyle: visualStyle ?? this.visualStyle,
      interactionSettings: interactionSettings ?? this.interactionSettings,
      workingHours: workingHours ?? this.workingHours,
    );
  }

  /// Eski format'tan yeni format'a dönüştürme
  static MenuSettings _fromLegacyMap(Map<String, dynamic> map) {
    // Eski format'taki alanları yeni format'a map et
    String primaryColor = map['primaryColor'] ?? '#FF6B35';
    String theme = map['theme'] ?? 'modern';
    String fontFamily = map['fontFamily'] ?? 'Poppins';
    String layoutStyle = map['layoutStyle'] ?? 'grid';

    // Legacy theme'i yeni MenuThemeType'a map et
    MenuThemeType themeType = MenuThemeType.modern;
    switch (theme.toLowerCase()) {
      case 'classic':
        themeType = MenuThemeType.classic;
        break;
      case 'grid':
        themeType = MenuThemeType.grid;
        break;
      case 'magazine':
        themeType = MenuThemeType.magazine;
        break;
      default:
        themeType = MenuThemeType.modern;
        break;
    }

    // Legacy layout'u yeni MenuLayoutType'a map et
    MenuLayoutType layout = MenuLayoutType.grid;
    switch (layoutStyle.toLowerCase()) {
      case 'list':
        layout = MenuLayoutType.list;
        break;
      case 'card':
      case 'grid':
        layout = MenuLayoutType.grid;
        break;
      case 'masonry':
        layout = MenuLayoutType.masonry;
        break;
      case 'carousel':
        layout = MenuLayoutType.carousel;
        break;
      default:
        layout = MenuLayoutType.grid;
        break;
    }

    return MenuSettings(
      showPrices: map['showPrices'] ?? true,
      showDescriptions: map['showDescriptions'] ?? true,
      showImages: map['showImages'] ?? true,
      showAllergens: map['showAllergens'] ?? true,
      showNutritionalInfo:
          map['showNutritionalInfo'] ?? map['showNutritionInfo'] ?? false,
      currency: map['currency'] ?? 'TRY',
      language: map['language'] ?? 'tr',
      allergens: List<String>.from(map['allergens'] ?? []),
      allergenTranslations: _parseStringMap(map['allergenTranslations']),
      enableQRCode: map['enableQRCode'] ?? true,
      enableOnlineOrdering: map['enableOnlineOrdering'] ?? true,
      enableTableService: map['enableTableService'] ?? true,
      enableDelivery: map['enableDelivery'] ?? false,
      enableTakeaway: map['enableTakeaway'] ?? true,
      // Eski alanlardan yeni nested objects oluştur
      designTheme: MenuDesignTheme(
        themeType: themeType,
        name: themeType.displayName,
        description: themeType.description,
      ),
      layoutStyle: MenuLayoutStyle(
        layoutType: layout,
        columnsCount: layout == MenuLayoutType.grid ? 2 : 1,
      ),
      colorScheme: MenuColorScheme(
        primaryColor: primaryColor,
      ),
      typography: MenuTypography(
        fontFamily: fontFamily,
        titleFontSize: (map['fontSize'] ?? 16).toDouble() + 8,
        headingFontSize: (map['fontSize'] ?? 16).toDouble() + 2,
        bodyFontSize: (map['fontSize'] ?? 16).toDouble(),
      ),
      visualStyle: const MenuVisualStyle(),
      interactionSettings: const MenuInteractionSettings(),
      workingHours: _parseStringMap(map['workingHours']),
    );
  }

  /// String Map'i parse eder (String, Map veya null olabilir)
  static Map<String, String> _parseStringMap(dynamic stringMap) {
    if (stringMap == null) return {};

    if (stringMap is Map<String, String>) {
      return stringMap;
    } else if (stringMap is Map) {
      // Map ama String, String değil - dönüştür
      return Map<String, String>.from(stringMap);
    } else if (stringMap is String) {
      // String ise boş Map döndür (geçersiz format)
      return {};
    } else {
      return {}; // Fallback
    }
  }
}

// =============================================================================
// BUSINESS SETTINGS MODEL
// =============================================================================

class BusinessSettings {
  final bool isOpen;
  final bool autoAcceptOrders;
  final bool requirePaymentConfirmation;
  final double minimumOrderAmount;
  final double deliveryFee;
  final double maxDeliveryDistance;
  final int estimatedPreparationTime;
  final List<String> acceptedPaymentMethods;
  final String currency;
  final String language;
  final bool enableNotifications;
  final bool enableAnalytics;
  final bool enableReviews;
  final bool enableLoyaltyProgram;
  final Map<String, dynamic>? customSettings;

  BusinessSettings({
    this.isOpen = true,
    this.autoAcceptOrders = false,
    this.requirePaymentConfirmation = true,
    this.minimumOrderAmount = 0.0,
    this.deliveryFee = 0.0,
    this.maxDeliveryDistance = 10.0,
    this.estimatedPreparationTime = 30,
    this.acceptedPaymentMethods = const ['cash', 'card'],
    this.currency = 'TRY',
    this.language = 'tr',
    this.enableNotifications = true,
    this.enableAnalytics = true,
    this.enableReviews = true,
    this.enableLoyaltyProgram = false,
    this.customSettings,
  });

  factory BusinessSettings.defaultRestaurant() {
    return BusinessSettings(
      isOpen: true,
      autoAcceptOrders: false,
      requirePaymentConfirmation: true,
      minimumOrderAmount: 50.0,
      deliveryFee: 10.0,
      maxDeliveryDistance: 15.0,
      estimatedPreparationTime: 45,
      acceptedPaymentMethods: ['cash', 'card', 'online'],
      currency: 'TRY',
      language: 'tr',
      enableNotifications: true,
      enableAnalytics: true,
      enableReviews: true,
      enableLoyaltyProgram: true,
    );
  }

  factory BusinessSettings.defaultCafe() {
    return BusinessSettings(
      isOpen: true,
      autoAcceptOrders: true,
      requirePaymentConfirmation: false,
      minimumOrderAmount: 0.0,
      deliveryFee: 5.0,
      maxDeliveryDistance: 8.0,
      estimatedPreparationTime: 15,
      acceptedPaymentMethods: ['cash', 'card'],
      currency: 'TRY',
      language: 'tr',
      enableNotifications: true,
      enableAnalytics: true,
      enableReviews: true,
      enableLoyaltyProgram: false,
    );
  }

  factory BusinessSettings.defaults() {
    return BusinessSettings();
  }

  factory BusinessSettings.fromMap(Map<String, dynamic> map) {
    return BusinessSettings(
      isOpen: map['isOpen'] ?? true,
      autoAcceptOrders: map['autoAcceptOrders'] ?? false,
      requirePaymentConfirmation: map['requirePaymentConfirmation'] ?? true,
      minimumOrderAmount: (map['minimumOrderAmount'] ?? 0.0).toDouble(),
      deliveryFee: (map['deliveryFee'] ?? 0.0).toDouble(),
      maxDeliveryDistance: (map['maxDeliveryDistance'] ?? 10.0).toDouble(),
      estimatedPreparationTime: map['estimatedPreparationTime'] ?? 30,
      acceptedPaymentMethods:
          _parsePaymentMethods(map['acceptedPaymentMethods']),
      currency: map['currency'] ?? 'TRY',
      language: map['language'] ?? 'tr',
      enableNotifications: map['enableNotifications'] ?? true,
      enableAnalytics: map['enableAnalytics'] ?? true,
      enableReviews: map['enableReviews'] ?? true,
      enableLoyaltyProgram: map['enableLoyaltyProgram'] ?? false,
      customSettings: _parseCustomSettings(map['customSettings']),
    );
  }

  // Alias for fromMap to match the expected method name
  factory BusinessSettings.fromJson(Map<String, dynamic> json) =>
      BusinessSettings.fromMap(json);

  /// Ödeme methodlarını parse eder (String veya List<String> olabilir)
  static List<String> _parsePaymentMethods(dynamic methods) {
    if (methods == null) return ['cash', 'card'];

    if (methods is List) {
      return methods.map((e) => e.toString()).toList();
    } else if (methods is String) {
      // Tek string ise liste haline getir
      return [methods];
    } else {
      return ['cash', 'card']; // Fallback
    }
  }

  /// Custom settings'i parse eder (String, Map veya null olabilir)
  static Map<String, dynamic>? _parseCustomSettings(dynamic settings) {
    if (settings == null) return null;

    if (settings is Map<String, dynamic>) {
      return settings;
    } else if (settings is Map) {
      // Map ama String, dynamic değil - dönüştür
      return Map<String, dynamic>.from(settings);
    } else if (settings is String) {
      // String ise null döndür (geçersiz format)
      return null;
    } else {
      return null; // Fallback
    }
  }

  Map<String, dynamic> toMap() {
    return {
      'isOpen': isOpen,
      'autoAcceptOrders': autoAcceptOrders,
      'requirePaymentConfirmation': requirePaymentConfirmation,
      'minimumOrderAmount': minimumOrderAmount,
      'deliveryFee': deliveryFee,
      'maxDeliveryDistance': maxDeliveryDistance,
      'estimatedPreparationTime': estimatedPreparationTime,
      'acceptedPaymentMethods': acceptedPaymentMethods,
      'currency': currency,
      'language': language,
      'enableNotifications': enableNotifications,
      'enableAnalytics': enableAnalytics,
      'enableReviews': enableReviews,
      'enableLoyaltyProgram': enableLoyaltyProgram,
      'customSettings': customSettings,
    };
  }

  // Alias for toMap to match the expected method name
  Map<String, dynamic> toJson() => toMap();

  BusinessSettings copyWith({
    bool? isOpen,
    bool? autoAcceptOrders,
    bool? requirePaymentConfirmation,
    double? minimumOrderAmount,
    double? deliveryFee,
    double? maxDeliveryDistance,
    int? estimatedPreparationTime,
    List<String>? acceptedPaymentMethods,
    String? currency,
    String? language,
    bool? enableNotifications,
    bool? enableAnalytics,
    bool? enableReviews,
    bool? enableLoyaltyProgram,
    Map<String, dynamic>? customSettings,
  }) {
    return BusinessSettings(
      isOpen: isOpen ?? this.isOpen,
      autoAcceptOrders: autoAcceptOrders ?? this.autoAcceptOrders,
      requirePaymentConfirmation:
          requirePaymentConfirmation ?? this.requirePaymentConfirmation,
      minimumOrderAmount: minimumOrderAmount ?? this.minimumOrderAmount,
      deliveryFee: deliveryFee ?? this.deliveryFee,
      maxDeliveryDistance: maxDeliveryDistance ?? this.maxDeliveryDistance,
      estimatedPreparationTime:
          estimatedPreparationTime ?? this.estimatedPreparationTime,
      acceptedPaymentMethods:
          acceptedPaymentMethods ?? this.acceptedPaymentMethods,
      currency: currency ?? this.currency,
      language: language ?? this.language,
      enableNotifications: enableNotifications ?? this.enableNotifications,
      enableAnalytics: enableAnalytics ?? this.enableAnalytics,
      enableReviews: enableReviews ?? this.enableReviews,
      enableLoyaltyProgram: enableLoyaltyProgram ?? this.enableLoyaltyProgram,
      customSettings: customSettings ?? this.customSettings,
    );
  }
}

// =============================================================================
// BUSINESS STATS MODEL
// =============================================================================

class BusinessStats {
  final int totalOrders;
  final double totalRevenue;
  final int totalProducts;
  final int totalCategories;
  final int totalCustomers;
  final double averageRating;
  final int totalReviews;
  final DateTime? lastOrderAt;
  final DateTime? firstOrderAt;
  final Map<String, int> ordersByDay;
  final Map<String, double> revenueByDay;
  final Map<String, int> popularProducts;
  final Map<String, int> popularCategories;

  BusinessStats({
    this.totalOrders = 0,
    this.totalRevenue = 0.0,
    this.totalProducts = 0,
    this.totalCategories = 0,
    this.totalCustomers = 0,
    this.averageRating = 0.0,
    this.totalReviews = 0,
    this.lastOrderAt,
    this.firstOrderAt,
    this.ordersByDay = const {},
    this.revenueByDay = const {},
    this.popularProducts = const {},
    this.popularCategories = const {},
  });

  factory BusinessStats.empty() {
    return BusinessStats();
  }

  factory BusinessStats.fromMap(Map<String, dynamic> map) {
    return BusinessStats(
      totalOrders: map['totalOrders'] ?? 0,
      totalRevenue: (map['totalRevenue'] ?? 0.0).toDouble(),
      totalProducts: map['totalProducts'] ?? 0,
      totalCategories: map['totalCategories'] ?? 0,
      totalCustomers: map['totalCustomers'] ?? 0,
      averageRating: (map['averageRating'] ?? 0.0).toDouble(),
      totalReviews: map['totalReviews'] ?? 0,
      lastOrderAt: map['lastOrderAt'] != null
          ? DateTime.parse(map['lastOrderAt'])
          : null,
      firstOrderAt: map['firstOrderAt'] != null
          ? DateTime.parse(map['firstOrderAt'])
          : null,
      ordersByDay: Map<String, int>.from(map['ordersByDay'] ?? {}),
      revenueByDay: Map<String, double>.from(map['revenueByDay'] ?? {}),
      popularProducts: Map<String, int>.from(map['popularProducts'] ?? {}),
      popularCategories: Map<String, int>.from(map['popularCategories'] ?? {}),
    );
  }

  // Alias for fromMap to match the expected method name
  factory BusinessStats.fromJson(Map<String, dynamic> json) =>
      BusinessStats.fromMap(json);

  Map<String, dynamic> toMap() {
    return {
      'totalOrders': totalOrders,
      'totalRevenue': totalRevenue,
      'totalProducts': totalProducts,
      'totalCategories': totalCategories,
      'totalCustomers': totalCustomers,
      'averageRating': averageRating,
      'totalReviews': totalReviews,
      'lastOrderAt': lastOrderAt?.toIso8601String(),
      'firstOrderAt': firstOrderAt?.toIso8601String(),
      'ordersByDay': ordersByDay,
      'revenueByDay': revenueByDay,
      'popularProducts': popularProducts,
      'popularCategories': popularCategories,
    };
  }

  // Alias for toMap to match the expected method name
  Map<String, dynamic> toJson() => toMap();

  BusinessStats copyWith({
    int? totalOrders,
    double? totalRevenue,
    int? totalProducts,
    int? totalCategories,
    int? totalCustomers,
    double? averageRating,
    int? totalReviews,
    DateTime? lastOrderAt,
    DateTime? firstOrderAt,
    Map<String, int>? ordersByDay,
    Map<String, double>? revenueByDay,
    Map<String, int>? popularProducts,
    Map<String, int>? popularCategories,
  }) {
    return BusinessStats(
      totalOrders: totalOrders ?? this.totalOrders,
      totalRevenue: totalRevenue ?? this.totalRevenue,
      totalProducts: totalProducts ?? this.totalProducts,
      totalCategories: totalCategories ?? this.totalCategories,
      totalCustomers: totalCustomers ?? this.totalCustomers,
      averageRating: averageRating ?? this.averageRating,
      totalReviews: totalReviews ?? this.totalReviews,
      lastOrderAt: lastOrderAt ?? this.lastOrderAt,
      firstOrderAt: firstOrderAt ?? this.firstOrderAt,
      ordersByDay: ordersByDay ?? this.ordersByDay,
      revenueByDay: revenueByDay ?? this.revenueByDay,
      popularProducts: popularProducts ?? this.popularProducts,
      popularCategories: popularCategories ?? this.popularCategories,
    );
  }
}

// =============================================================================
// COORDINATES MODEL
// =============================================================================

class Coordinates {
  final double latitude;
  final double longitude;

  const Coordinates({
    required this.latitude,
    required this.longitude,
  });

  factory Coordinates.fromMap(Map<String, dynamic> map) {
    return Coordinates(
      latitude: (map['latitude'] ?? 0.0).toDouble(),
      longitude: (map['longitude'] ?? 0.0).toDouble(),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'latitude': latitude,
      'longitude': longitude,
    };
  }

  @override
  String toString() {
    return 'Coordinates(lat: $latitude, lng: $longitude)';
  }
}
