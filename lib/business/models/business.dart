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
      approvedAt: data['approvedAt'] != null ? _parseDateTime(data['approvedAt']) : null,
      approvedBy: data['approvedBy'],
      staffIds: List<String>.from(data['staffIds'] ?? []),
      categoryIds: List<String>.from(data['categoryIds'] ?? []),
      metadata: data['metadata'] != null ? Map<String, dynamic>.from(data['metadata']) : null,
    );
  }

  factory Business.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return Business.fromJson({...data, 'id': doc.id});
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
  bool get isFullyOperational => isActive && isOpen && isApproved && status == BusinessStatus.active;
  bool get needsApproval => !isApproved && status == BusinessStatus.pending;
  bool get isSuspended => status == BusinessStatus.suspended;
  bool get isClosed => status == BusinessStatus.closed;
  String get statusDisplayName => status.displayName;
  String get businessTypeDisplayName => _getBusinessTypeDisplayName(businessType);

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

  // Getter for social media links
  Map<String, String?> get socialMedia => {
    'facebook': facebook,
    'instagram': instagram,
    'twitter': twitter,
    'whatsapp': whatsapp,
  };

  factory ContactInfo.empty() {
    return ContactInfo();
  }

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
  
  // UI/Theme properties
  final String theme;
  final String primaryColor;
  final String fontFamily;
  final double fontSize;
  final double imageSize;
  final bool showCategories;
  final bool showRatings;
  final String layoutStyle;
  final bool showNutritionInfo;
  final bool showBadges;
  final bool showAvailability;
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
    this.theme = 'light',
    this.primaryColor = '#FF6B35',
    this.fontFamily = 'Roboto',
    this.fontSize = 14.0,
    this.imageSize = 120.0,
    this.showCategories = true,
    this.showRatings = true,
    this.layoutStyle = 'grid',
    this.showNutritionInfo = false,
    this.showBadges = true,
    this.showAvailability = true,
    this.workingHours,
  });

  factory MenuSettings.defaultRestaurant() {
    return MenuSettings(
      showPrices: true,
      showDescriptions: true,
      showImages: true,
      showAllergens: true,
      showNutritionalInfo: false,
      currency: 'TRY',
      language: 'tr',
      allergens: ['gluten', 'lactose', 'nuts', 'eggs', 'fish', 'shellfish', 'soy'],
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
      theme: 'light',
      primaryColor: '#FF6B35',
      fontFamily: 'Roboto',
      fontSize: 14.0,
      imageSize: 120.0,
      showCategories: true,
      showRatings: true,
      layoutStyle: 'grid',
      showNutritionInfo: false,
      showBadges: true,
      showAvailability: true,
    );
  }

  factory MenuSettings.defaultCafe() {
    return MenuSettings(
      showPrices: true,
      showDescriptions: true,
      showImages: true,
      showAllergens: true,
      showNutritionalInfo: false,
      currency: 'TRY',
      language: 'tr',
      allergens: ['gluten', 'lactose', 'nuts', 'eggs'],
      allergenTranslations: {
        'gluten': 'Gluten',
        'lactose': 'Laktoz',
        'nuts': 'Kuruyemiş',
        'eggs': 'Yumurta',
      },
      enableQRCode: true,
      enableOnlineOrdering: true,
      enableTableService: true,
      enableDelivery: false,
      enableTakeaway: true,
      theme: 'light',
      primaryColor: '#4A90E2',
      fontFamily: 'Roboto',
      fontSize: 14.0,
      imageSize: 120.0,
      showCategories: true,
      showRatings: true,
      layoutStyle: 'grid',
      showNutritionInfo: false,
      showBadges: true,
      showAvailability: true,
    );
  }

  factory MenuSettings.fromMap(Map<String, dynamic> map) {
    return MenuSettings(
      showPrices: map['showPrices'] ?? true,
      showDescriptions: map['showDescriptions'] ?? true,
      showImages: map['showImages'] ?? true,
      showAllergens: map['showAllergens'] ?? true,
      showNutritionalInfo: map['showNutritionalInfo'] ?? false,
      currency: map['currency'] ?? 'TRY',
      language: map['language'] ?? 'tr',
      allergens: List<String>.from(map['allergens'] ?? []),
      allergenTranslations: Map<String, String>.from(map['allergenTranslations'] ?? {}),
      enableQRCode: map['enableQRCode'] ?? true,
      enableOnlineOrdering: map['enableOnlineOrdering'] ?? true,
      enableTableService: map['enableTableService'] ?? true,
      enableDelivery: map['enableDelivery'] ?? false,
      enableTakeaway: map['enableTakeaway'] ?? true,
      theme: map['theme'] ?? 'light',
      primaryColor: map['primaryColor'] ?? '#FF6B35',
      fontFamily: map['fontFamily'] ?? 'Roboto',
      fontSize: (map['fontSize'] ?? 14.0).toDouble(),
      imageSize: (map['imageSize'] ?? 120.0).toDouble(),
      showCategories: map['showCategories'] ?? true,
      showRatings: map['showRatings'] ?? true,
      layoutStyle: map['layoutStyle'] ?? 'grid',
      showNutritionInfo: map['showNutritionInfo'] ?? false,
      showBadges: map['showBadges'] ?? true,
      showAvailability: map['showAvailability'] ?? true,
      workingHours: map['workingHours'] != null ? Map<String, String>.from(map['workingHours']) : null,
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
      'theme': theme,
      'primaryColor': primaryColor,
      'fontFamily': fontFamily,
      'fontSize': fontSize,
      'imageSize': imageSize,
      'showCategories': showCategories,
      'showRatings': showRatings,
      'layoutStyle': layoutStyle,
      'showNutritionInfo': showNutritionInfo,
      'showBadges': showBadges,
      'showAvailability': showAvailability,
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
    String? theme,
    String? primaryColor,
    String? fontFamily,
    double? fontSize,
    double? imageSize,
    bool? showCategories,
    bool? showRatings,
    String? layoutStyle,
    bool? showNutritionInfo,
    bool? showBadges,
    bool? showAvailability,
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
      theme: theme ?? this.theme,
      primaryColor: primaryColor ?? this.primaryColor,
      fontFamily: fontFamily ?? this.fontFamily,
      fontSize: fontSize ?? this.fontSize,
      imageSize: imageSize ?? this.imageSize,
      showCategories: showCategories ?? this.showCategories,
      showRatings: showRatings ?? this.showRatings,
      layoutStyle: layoutStyle ?? this.layoutStyle,
      showNutritionInfo: showNutritionInfo ?? this.showNutritionInfo,
      showBadges: showBadges ?? this.showBadges,
      showAvailability: showAvailability ?? this.showAvailability,
      workingHours: workingHours ?? this.workingHours,
    );
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

  factory BusinessSettings.fromMap(Map<String, dynamic> map) {
    return BusinessSettings(
      isOpen: map['isOpen'] ?? true,
      autoAcceptOrders: map['autoAcceptOrders'] ?? false,
      requirePaymentConfirmation: map['requirePaymentConfirmation'] ?? true,
      minimumOrderAmount: (map['minimumOrderAmount'] ?? 0.0).toDouble(),
      deliveryFee: (map['deliveryFee'] ?? 0.0).toDouble(),
      maxDeliveryDistance: (map['maxDeliveryDistance'] ?? 10.0).toDouble(),
      estimatedPreparationTime: map['estimatedPreparationTime'] ?? 30,
      acceptedPaymentMethods: List<String>.from(map['acceptedPaymentMethods'] ?? ['cash', 'card']),
      currency: map['currency'] ?? 'TRY',
      language: map['language'] ?? 'tr',
      enableNotifications: map['enableNotifications'] ?? true,
      enableAnalytics: map['enableAnalytics'] ?? true,
      enableReviews: map['enableReviews'] ?? true,
      enableLoyaltyProgram: map['enableLoyaltyProgram'] ?? false,
      customSettings: map['customSettings'] != null ? Map<String, dynamic>.from(map['customSettings']) : null,
    );
  }

  // Alias for fromMap to match the expected method name
  factory BusinessSettings.fromJson(Map<String, dynamic> json) => BusinessSettings.fromMap(json);

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
      requirePaymentConfirmation: requirePaymentConfirmation ?? this.requirePaymentConfirmation,
      minimumOrderAmount: minimumOrderAmount ?? this.minimumOrderAmount,
      deliveryFee: deliveryFee ?? this.deliveryFee,
      maxDeliveryDistance: maxDeliveryDistance ?? this.maxDeliveryDistance,
      estimatedPreparationTime: estimatedPreparationTime ?? this.estimatedPreparationTime,
      acceptedPaymentMethods: acceptedPaymentMethods ?? this.acceptedPaymentMethods,
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
      lastOrderAt: map['lastOrderAt'] != null ? DateTime.parse(map['lastOrderAt']) : null,
      firstOrderAt: map['firstOrderAt'] != null ? DateTime.parse(map['firstOrderAt']) : null,
      ordersByDay: Map<String, int>.from(map['ordersByDay'] ?? {}),
      revenueByDay: Map<String, double>.from(map['revenueByDay'] ?? {}),
      popularProducts: Map<String, int>.from(map['popularProducts'] ?? {}),
      popularCategories: Map<String, int>.from(map['popularCategories'] ?? {}),
    );
  }

  // Alias for fromMap to match the expected method name
  factory BusinessStats.fromJson(Map<String, dynamic> json) => BusinessStats.fromMap(json);

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
