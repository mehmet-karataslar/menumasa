import 'package:cloud_firestore/cloud_firestore.dart';

class Business {
  final String businessId;
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
  final bool isActive;
  final bool isOpen;
  final DateTime createdAt;
  final DateTime updatedAt;

  Business({
    required this.businessId,
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
    required this.isActive,
    required this.isOpen,
    required this.createdAt,
    required this.updatedAt,
  });

  factory Business.fromJson(Map<String, dynamic> data, {String? id}) {
    return Business(
      businessId: id ?? data['businessId'] ?? '',
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
      isActive: data['isActive'] ?? true,
      isOpen: data['isOpen'] ?? true,
      createdAt: _parseDateTime(data['createdAt']),
      updatedAt: _parseDateTime(data['updatedAt']),
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

  Map<String, dynamic> toJson() {
    return {
      'businessId': businessId,
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
      'isActive': isActive,
      'isOpen': isOpen,
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt.toIso8601String(),
    };
  }

  Business copyWith({
    String? businessId,
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
    bool? isActive,
    bool? isOpen,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return Business(
      businessId: businessId ?? this.businessId,
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
      isActive: isActive ?? this.isActive,
      isOpen: isOpen ?? this.isOpen,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  @override
  String toString() {
    return 'Business(businessId: $businessId, businessName: $businessName, ownerId: $ownerId, isActive: $isActive)';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is Business && other.businessId == businessId;
  }

  @override
  int get hashCode => businessId.hashCode;
}

class Address {
  final String street;
  final String city;
  final String district;
  final String postalCode;
  final Coordinates? coordinates;

  Address({
    required this.street,
    required this.city,
    required this.district,
    required this.postalCode,
    this.coordinates,
  });

  factory Address.fromMap(Map<String, dynamic> map) {
    return Address(
      street: map['street'] ?? '',
      city: map['city'] ?? '',
      district: map['district'] ?? '',
      postalCode: map['postalCode'] ?? '',
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
      'coordinates': coordinates?.toMap(),
    };
  }

  Address copyWith({
    String? street,
    String? city,
    String? district,
    String? postalCode,
    Coordinates? coordinates,
  }) {
    return Address(
      street: street ?? this.street,
      city: city ?? this.city,
      district: district ?? this.district,
      postalCode: postalCode ?? this.postalCode,
      coordinates: coordinates ?? this.coordinates,
    );
  }

  @override
  String toString() {
    return '$street, $district, $city $postalCode';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is Address &&
        other.street == street &&
        other.city == city &&
        other.district == district &&
        other.postalCode == postalCode;
  }

  @override
  int get hashCode {
    return street.hashCode ^
        city.hashCode ^
        district.hashCode ^
        postalCode.hashCode;
  }
}

class Coordinates {
  final double lat;
  final double lng;

  Coordinates({required this.lat, required this.lng});

  factory Coordinates.fromMap(Map<String, dynamic> map) {
    return Coordinates(
      lat: (map['lat'] ?? 0.0).toDouble(),
      lng: (map['lng'] ?? 0.0).toDouble(),
    );
  }

  Map<String, dynamic> toMap() {
    return {'lat': lat, 'lng': lng};
  }

  Coordinates copyWith({double? lat, double? lng}) {
    return Coordinates(lat: lat ?? this.lat, lng: lng ?? this.lng);
  }

  @override
  String toString() => 'Coordinates(lat: $lat, lng: $lng)';

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is Coordinates && other.lat == lat && other.lng == lng;
  }

  @override
  int get hashCode => lat.hashCode ^ lng.hashCode;
}

class ContactInfo {
  final String phone;
  final String email;
  final String? website;
  final SocialMedia? socialMedia;

  ContactInfo({
    required this.phone,
    required this.email,
    this.website,
    this.socialMedia,
  });

  factory ContactInfo.fromMap(Map<String, dynamic> map) {
    return ContactInfo(
      phone: map['phone'] ?? '',
      email: map['email'] ?? '',
      website: map['website'],
      socialMedia: map['socialMedia'] != null
          ? SocialMedia.fromMap(map['socialMedia'])
          : null,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'phone': phone,
      'email': email,
      'website': website,
      'socialMedia': socialMedia?.toMap(),
    };
  }

  ContactInfo copyWith({
    String? phone,
    String? email,
    String? website,
    SocialMedia? socialMedia,
  }) {
    return ContactInfo(
      phone: phone ?? this.phone,
      email: email ?? this.email,
      website: website ?? this.website,
      socialMedia: socialMedia ?? this.socialMedia,
    );
  }

  @override
  String toString() => 'ContactInfo(phone: $phone, email: $email)';

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is ContactInfo && other.phone == phone && other.email == email;
  }

  @override
  int get hashCode => phone.hashCode ^ email.hashCode;
}

class SocialMedia {
  final String? instagram;
  final String? facebook;
  final String? twitter;
  final String? youtube;

  SocialMedia({this.instagram, this.facebook, this.twitter, this.youtube});

  factory SocialMedia.fromMap(Map<String, dynamic> map) {
    return SocialMedia(
      instagram: map['instagram'],
      facebook: map['facebook'],
      twitter: map['twitter'],
      youtube: map['youtube'],
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'instagram': instagram,
      'facebook': facebook,
      'twitter': twitter,
      'youtube': youtube,
    };
  }

  SocialMedia copyWith({
    String? instagram,
    String? facebook,
    String? twitter,
    String? youtube,
  }) {
    return SocialMedia(
      instagram: instagram ?? this.instagram,
      facebook: facebook ?? this.facebook,
      twitter: twitter ?? this.twitter,
      youtube: youtube ?? this.youtube,
    );
  }

  @override
  String toString() =>
      'SocialMedia(instagram: $instagram, facebook: $facebook)';

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is SocialMedia &&
        other.instagram == instagram &&
        other.facebook == facebook;
  }

  @override
  int get hashCode => instagram.hashCode ^ facebook.hashCode;
}

class MenuSettings {
  final String theme;
  final String primaryColor;
  final String fontFamily;
  final double fontSize;
  final bool showPrices;
  final bool showImages;
  final String imageSize;
  final String language;
  final bool? showDescriptions;
  final bool? showCategories;
  final bool? showAllergens;
  final bool? showRatings;
  final String? layoutStyle;
  final bool? showNutritionInfo;
  final bool? showBadges;
  final bool? showAvailability;

  MenuSettings({
    required this.theme,
    required this.primaryColor,
    required this.fontFamily,
    required this.fontSize,
    required this.showPrices,
    required this.showImages,
    required this.imageSize,
    required this.language,
    this.showDescriptions,
    this.showCategories,
    this.showAllergens,
    this.showRatings,
    this.layoutStyle,
    this.showNutritionInfo,
    this.showBadges,
    this.showAvailability,
  });

  factory MenuSettings.fromMap(Map<String, dynamic> map) {
    return MenuSettings(
      theme: map['theme'] ?? 'default',
      primaryColor: map['primaryColor'] ?? '#2C1810',
      fontFamily: map['fontFamily'] ?? 'Poppins',
      fontSize: (map['fontSize'] ?? 16.0).toDouble(),
      showPrices: map['showPrices'] ?? true,
      showImages: map['showImages'] ?? true,
      imageSize: map['imageSize'] ?? 'medium',
      language: map['language'] ?? 'tr',
      showDescriptions: map['showDescriptions'],
      showCategories: map['showCategories'],
      showAllergens: map['showAllergens'],
      showRatings: map['showRatings'],
      layoutStyle: map['layoutStyle'],
      showNutritionInfo: map['showNutritionInfo'],
      showBadges: map['showBadges'],
      showAvailability: map['showAvailability'],
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'theme': theme,
      'primaryColor': primaryColor,
      'fontFamily': fontFamily,
      'fontSize': fontSize,
      'showPrices': showPrices,
      'showImages': showImages,
      'imageSize': imageSize,
      'language': language,
      'showDescriptions': showDescriptions,
      'showCategories': showCategories,
      'showAllergens': showAllergens,
      'showRatings': showRatings,
      'layoutStyle': layoutStyle,
      'showNutritionInfo': showNutritionInfo,
      'showBadges': showBadges,
      'showAvailability': showAvailability,
    };
  }

  MenuSettings copyWith({
    String? theme,
    String? primaryColor,
    String? fontFamily,
    double? fontSize,
    bool? showPrices,
    bool? showImages,
    String? imageSize,
    String? language,
    bool? showDescriptions,
    bool? showCategories,
    bool? showAllergens,
    bool? showRatings,
    String? layoutStyle,
    bool? showNutritionInfo,
    bool? showBadges,
    bool? showAvailability,
  }) {
    return MenuSettings(
      theme: theme ?? this.theme,
      primaryColor: primaryColor ?? this.primaryColor,
      fontFamily: fontFamily ?? this.fontFamily,
      fontSize: fontSize ?? this.fontSize,
      showPrices: showPrices ?? this.showPrices,
      showImages: showImages ?? this.showImages,
      imageSize: imageSize ?? this.imageSize,
      language: language ?? this.language,
      showDescriptions: showDescriptions ?? this.showDescriptions,
      showCategories: showCategories ?? this.showCategories,
      showAllergens: showAllergens ?? this.showAllergens,
      showRatings: showRatings ?? this.showRatings,
      layoutStyle: layoutStyle ?? this.layoutStyle,
      showNutritionInfo: showNutritionInfo ?? this.showNutritionInfo,
      showBadges: showBadges ?? this.showBadges,
      showAvailability: showAvailability ?? this.showAvailability,
    );
  }

  @override
  String toString() =>
      'MenuSettings(theme: $theme, primaryColor: $primaryColor)';

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is MenuSettings &&
        other.theme == theme &&
        other.primaryColor == primaryColor;
  }

  @override
  int get hashCode => theme.hashCode ^ primaryColor.hashCode;
}

// Default instances for creating new businesses
class BusinessDefaults {
  static Address get defaultAddress =>
      Address(street: '', city: '', district: '', postalCode: '');

  static ContactInfo get defaultContactInfo =>
      ContactInfo(phone: '', email: '');

  static MenuSettings get defaultMenuSettings => MenuSettings(
    theme: 'default',
    primaryColor: '#2C1810',
    fontFamily: 'Poppins',
    fontSize: 16.0,
    showPrices: true,
    showImages: true,
    imageSize: 'medium',
    language: 'tr',
    showDescriptions: true,
    showCategories: true,
    showAllergens: true,
    showRatings: false,
    layoutStyle: 'card',
  );

  static Business createDefault({
    required String businessId,
    required String ownerId,
    required String businessName,
    required String businessDescription,
  }) {
    return Business(
      businessId: businessId,
      ownerId: ownerId,
      businessName: businessName,
      businessDescription: businessDescription,
      businessType: 'Restoran',
      businessAddress: '',
      address: defaultAddress,
      contactInfo: defaultContactInfo,
      menuSettings: defaultMenuSettings,
      isActive: true,
      isOpen: true,
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
    );
  }
}
