import 'package:cloud_firestore/cloud_firestore.dart';

class CustomerProfile {
  final String customerId;
  final String? firstName;
  final String? lastName;
  final String? email;
  final String? phone;
  final DateTime? birthDate;
  final String? profileImageUrl;
  final String? gender; // 'male', 'female', 'other', 'prefer_not_to_say'
  final List<CustomerAddress> addresses;
  final CustomerAddress? defaultAddress;
  final LocationSettings locationSettings;
  final NotificationSettings notificationSettings;
  final PrivacySettings privacySettings;
  final CustomerStatistics statistics;
  final DateTime createdAt;
  final DateTime updatedAt;

  CustomerProfile({
    required this.customerId,
    this.firstName,
    this.lastName,
    this.email,
    this.phone,
    this.birthDate,
    this.profileImageUrl,
    this.gender,
    required this.addresses,
    this.defaultAddress,
    required this.locationSettings,
    required this.notificationSettings,
    required this.privacySettings,
    required this.statistics,
    required this.createdAt,
    required this.updatedAt,
  });

  // Computed properties
  String get fullName {
    if (firstName != null && lastName != null) {
      return '$firstName $lastName';
    } else if (firstName != null) {
      return firstName!;
    } else if (lastName != null) {
      return lastName!;
    }
    return 'Kullanıcı';
  }

  String get displayName {
    if (fullName != 'Kullanıcı') return fullName;
    if (phone != null && phone!.isNotEmpty) return phone!;
    if (email != null && email!.isNotEmpty) return email!;
    return 'Misafir Kullanıcı';
  }

  int get age {
    if (birthDate == null) return 0;
    final now = DateTime.now();
    int age = now.year - birthDate!.year;
    if (now.month < birthDate!.month || 
        (now.month == birthDate!.month && now.day < birthDate!.day)) {
      age--;
    }
    return age;
  }

  bool get hasProfileImage => profileImageUrl != null && profileImageUrl!.isNotEmpty;
  bool get hasCompleteProfile => firstName != null && lastName != null && 
                                email != null && phone != null && birthDate != null;

  // Factory constructor for new customer
  factory CustomerProfile.newCustomer(String customerId) {
    final now = DateTime.now();
    return CustomerProfile(
      customerId: customerId,
      addresses: [],
      locationSettings: LocationSettings.defaultSettings(),
      notificationSettings: NotificationSettings.defaultSettings(),
      privacySettings: PrivacySettings.defaultSettings(),
      statistics: CustomerStatistics.empty(customerId),
      createdAt: now,
      updatedAt: now,
    );
  }

  // Factory constructor from Firestore
  factory CustomerProfile.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    
    return CustomerProfile(
      customerId: doc.id,
      firstName: data['firstName'],
      lastName: data['lastName'],
      email: data['email'],
      phone: data['phone'],
      birthDate: data['birthDate'] != null 
          ? (data['birthDate'] as Timestamp).toDate()
          : null,
      profileImageUrl: data['profileImageUrl'],
      gender: data['gender'],
      addresses: (data['addresses'] as List?)
          ?.map((addr) => CustomerAddress.fromMap(addr))
          .toList() ?? [],
      defaultAddress: data['defaultAddress'] != null
          ? CustomerAddress.fromMap(data['defaultAddress'])
          : null,
      locationSettings: LocationSettings.fromMap(data['locationSettings'] ?? {}),
      notificationSettings: NotificationSettings.fromMap(data['notificationSettings'] ?? {}),
      privacySettings: PrivacySettings.fromMap(data['privacySettings'] ?? {}),
      statistics: CustomerStatistics.fromMap(data['statistics'] ?? {}),
      createdAt: (data['createdAt'] as Timestamp).toDate(),
      updatedAt: (data['updatedAt'] as Timestamp).toDate(),
    );
  }

  // Convert to Firestore
  Map<String, dynamic> toFirestore() {
    return {
      'firstName': firstName,
      'lastName': lastName,
      'email': email,
      'phone': phone,
      'birthDate': birthDate != null ? Timestamp.fromDate(birthDate!) : null,
      'profileImageUrl': profileImageUrl,
      'gender': gender,
      'addresses': addresses.map((addr) => addr.toMap()).toList(),
      'defaultAddress': defaultAddress?.toMap(),
      'locationSettings': locationSettings.toMap(),
      'notificationSettings': notificationSettings.toMap(),
      'privacySettings': privacySettings.toMap(),
      'statistics': statistics.toMap(),
      'createdAt': Timestamp.fromDate(createdAt),
      'updatedAt': Timestamp.fromDate(updatedAt),
    };
  }

  // Copy with method
  CustomerProfile copyWith({
    String? firstName,
    String? lastName,
    String? email,
    String? phone,
    DateTime? birthDate,
    String? profileImageUrl,
    String? gender,
    List<CustomerAddress>? addresses,
    CustomerAddress? defaultAddress,
    LocationSettings? locationSettings,
    NotificationSettings? notificationSettings,
    PrivacySettings? privacySettings,
    CustomerStatistics? statistics,
    DateTime? updatedAt,
  }) {
    return CustomerProfile(
      customerId: customerId,
      firstName: firstName ?? this.firstName,
      lastName: lastName ?? this.lastName,
      email: email ?? this.email,
      phone: phone ?? this.phone,
      birthDate: birthDate ?? this.birthDate,
      profileImageUrl: profileImageUrl ?? this.profileImageUrl,
      gender: gender ?? this.gender,
      addresses: addresses ?? this.addresses,
      defaultAddress: defaultAddress ?? this.defaultAddress,
      locationSettings: locationSettings ?? this.locationSettings,
      notificationSettings: notificationSettings ?? this.notificationSettings,
      privacySettings: privacySettings ?? this.privacySettings,
      statistics: statistics ?? this.statistics,
      createdAt: createdAt,
      updatedAt: updatedAt ?? DateTime.now(),
    );
  }

  @override
  String toString() {
    return 'CustomerProfile(customerId: $customerId, fullName: $fullName, email: $email)';
  }
}

// Müşteri adresi modeli (daha detaylı)
class CustomerAddress {
  final String addressId;
  final String title; // "Ev", "İş", "Diğer" vb.
  final String? firstName;
  final String? lastName;
  final String? phoneNumber;
  final String addressLine1;
  final String? addressLine2;
  final String city;
  final String district;
  final String? neighborhood;
  final String postalCode;
  final String country;
  final double? latitude;
  final double? longitude;
  final bool isDefault;
  final DateTime createdAt;
  final DateTime updatedAt;

  CustomerAddress({
    required this.addressId,
    required this.title,
    this.firstName,
    this.lastName,
    this.phoneNumber,
    required this.addressLine1,
    this.addressLine2,
    required this.city,
    required this.district,
    this.neighborhood,
    required this.postalCode,
    required this.country,
    this.latitude,
    this.longitude,
    required this.isDefault,
    required this.createdAt,
    required this.updatedAt,
  });

  String get fullAddress {
    String address = addressLine1;
    if (addressLine2 != null && addressLine2!.isNotEmpty) {
      address += ', $addressLine2';
    }
    if (neighborhood != null && neighborhood!.isNotEmpty) {
      address += ', $neighborhood';
    }
    address += ', $district, $city';
    return address;
  }

  String get coordinates => latitude != null && longitude != null 
      ? '$latitude,$longitude' 
      : '';

  factory CustomerAddress.fromMap(Map<String, dynamic> map) {
    return CustomerAddress(
      addressId: map['addressId'] ?? '',
      title: map['title'] ?? '',
      firstName: map['firstName'],
      lastName: map['lastName'],
      phoneNumber: map['phoneNumber'],
      addressLine1: map['addressLine1'] ?? '',
      addressLine2: map['addressLine2'],
      city: map['city'] ?? '',
      district: map['district'] ?? '',
      neighborhood: map['neighborhood'],
      postalCode: map['postalCode'] ?? '',
      country: map['country'] ?? 'Turkey',
      latitude: map['latitude']?.toDouble(),
      longitude: map['longitude']?.toDouble(),
      isDefault: map['isDefault'] ?? false,
      createdAt: DateTime.fromMillisecondsSinceEpoch(
        map['createdAt'] ?? DateTime.now().millisecondsSinceEpoch
      ),
      updatedAt: DateTime.fromMillisecondsSinceEpoch(
        map['updatedAt'] ?? DateTime.now().millisecondsSinceEpoch
      ),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'addressId': addressId,
      'title': title,
      'firstName': firstName,
      'lastName': lastName,
      'phoneNumber': phoneNumber,
      'addressLine1': addressLine1,
      'addressLine2': addressLine2,
      'city': city,
      'district': district,
      'neighborhood': neighborhood,
      'postalCode': postalCode,
      'country': country,
      'latitude': latitude,
      'longitude': longitude,
      'isDefault': isDefault,
      'createdAt': createdAt.millisecondsSinceEpoch,
      'updatedAt': updatedAt.millisecondsSinceEpoch,
    };
  }
}

// Konum ayarları modeli
class LocationSettings {
  final bool isLocationEnabled;
  final bool allowLocationTracking;
  final bool showNearbyBusinesses;
  final bool showLocationBasedOffers;
  final int locationUpdateInterval; // dakika cinsinden
  final double searchRadius; // kilometre cinsinden

  const LocationSettings({
    required this.isLocationEnabled,
    required this.allowLocationTracking,
    required this.showNearbyBusinesses,
    required this.showLocationBasedOffers,
    required this.locationUpdateInterval,
    required this.searchRadius,
  });

  factory LocationSettings.defaultSettings() {
    return const LocationSettings(
      isLocationEnabled: false,
      allowLocationTracking: false,
      showNearbyBusinesses: true,
      showLocationBasedOffers: true,
      locationUpdateInterval: 15,
      searchRadius: 5.0,
    );
  }

  factory LocationSettings.fromMap(Map<String, dynamic> map) {
    return LocationSettings(
      isLocationEnabled: map['isLocationEnabled'] ?? false,
      allowLocationTracking: map['allowLocationTracking'] ?? false,
      showNearbyBusinesses: map['showNearbyBusinesses'] ?? true,
      showLocationBasedOffers: map['showLocationBasedOffers'] ?? true,
      locationUpdateInterval: map['locationUpdateInterval'] ?? 15,
      searchRadius: (map['searchRadius'] ?? 5.0).toDouble(),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'isLocationEnabled': isLocationEnabled,
      'allowLocationTracking': allowLocationTracking,
      'showNearbyBusinesses': showNearbyBusinesses,
      'showLocationBasedOffers': showLocationBasedOffers,
      'locationUpdateInterval': locationUpdateInterval,
      'searchRadius': searchRadius,
    };
  }

  LocationSettings copyWith({
    bool? isLocationEnabled,
    bool? allowLocationTracking,
    bool? showNearbyBusinesses,
    bool? showLocationBasedOffers,
    int? locationUpdateInterval,
    double? searchRadius,
  }) {
    return LocationSettings(
      isLocationEnabled: isLocationEnabled ?? this.isLocationEnabled,
      allowLocationTracking: allowLocationTracking ?? this.allowLocationTracking,
      showNearbyBusinesses: showNearbyBusinesses ?? this.showNearbyBusinesses,
      showLocationBasedOffers: showLocationBasedOffers ?? this.showLocationBasedOffers,
      locationUpdateInterval: locationUpdateInterval ?? this.locationUpdateInterval,
      searchRadius: searchRadius ?? this.searchRadius,
    );
  }
}

// Bildirim ayarları modeli
class NotificationSettings {
  final bool isNotificationsEnabled;
  final bool orderNotifications;
  final bool campaignNotifications;
  final bool systemNotifications;
  final bool businessUpdates;
  final bool promotionalOffers;
  final bool loyaltyProgram;
  final bool securityAlerts;
  final TimeRange quietHours;
  final List<String> blockedBusinessIds;

  const NotificationSettings({
    required this.isNotificationsEnabled,
    required this.orderNotifications,
    required this.campaignNotifications,
    required this.systemNotifications,
    required this.businessUpdates,
    required this.promotionalOffers,
    required this.loyaltyProgram,
    required this.securityAlerts,
    required this.quietHours,
    required this.blockedBusinessIds,
  });

  factory NotificationSettings.defaultSettings() {
    return NotificationSettings(
      isNotificationsEnabled: true,
      orderNotifications: true,
      campaignNotifications: true,
      systemNotifications: true,
      businessUpdates: false,
      promotionalOffers: false,
      loyaltyProgram: true,
      securityAlerts: true,
      quietHours: TimeRange(startHour: 22, endHour: 8), // 22:00 - 08:00
      blockedBusinessIds: [],
    );
  }

  factory NotificationSettings.fromMap(Map<String, dynamic> map) {
    return NotificationSettings(
      isNotificationsEnabled: map['isNotificationsEnabled'] ?? true,
      orderNotifications: map['orderNotifications'] ?? true,
      campaignNotifications: map['campaignNotifications'] ?? true,
      systemNotifications: map['systemNotifications'] ?? true,
      businessUpdates: map['businessUpdates'] ?? false,
      promotionalOffers: map['promotionalOffers'] ?? false,
      loyaltyProgram: map['loyaltyProgram'] ?? true,
      securityAlerts: map['securityAlerts'] ?? true,
      quietHours: TimeRange.fromMap(map['quietHours'] ?? {}),
      blockedBusinessIds: List<String>.from(map['blockedBusinessIds'] ?? []),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'isNotificationsEnabled': isNotificationsEnabled,
      'orderNotifications': orderNotifications,
      'campaignNotifications': campaignNotifications,
      'systemNotifications': systemNotifications,
      'businessUpdates': businessUpdates,
      'promotionalOffers': promotionalOffers,
      'loyaltyProgram': loyaltyProgram,
      'securityAlerts': securityAlerts,
      'quietHours': quietHours.toMap(),
      'blockedBusinessIds': blockedBusinessIds,
    };
  }

  NotificationSettings copyWith({
    bool? isNotificationsEnabled,
    bool? orderNotifications,
    bool? campaignNotifications,
    bool? systemNotifications,
    bool? businessUpdates,
    bool? promotionalOffers,
    bool? loyaltyProgram,
    bool? securityAlerts,
    TimeRange? quietHours,
    List<String>? blockedBusinessIds,
  }) {
    return NotificationSettings(
      isNotificationsEnabled: isNotificationsEnabled ?? this.isNotificationsEnabled,
      orderNotifications: orderNotifications ?? this.orderNotifications,
      campaignNotifications: campaignNotifications ?? this.campaignNotifications,
      systemNotifications: systemNotifications ?? this.systemNotifications,
      businessUpdates: businessUpdates ?? this.businessUpdates,
      promotionalOffers: promotionalOffers ?? this.promotionalOffers,
      loyaltyProgram: loyaltyProgram ?? this.loyaltyProgram,
      securityAlerts: securityAlerts ?? this.securityAlerts,
      quietHours: quietHours ?? this.quietHours,
      blockedBusinessIds: blockedBusinessIds ?? this.blockedBusinessIds,
    );
  }
}

// Zaman aralığı modeli
class TimeRange {
  final int startHour; // 0-23
  final int endHour;   // 0-23

  const TimeRange({
    required this.startHour,
    required this.endHour,
  });

  factory TimeRange.fromMap(Map<String, dynamic> map) {
    return TimeRange(
      startHour: map['startHour'] ?? 22,
      endHour: map['endHour'] ?? 8,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'startHour': startHour,
      'endHour': endHour,
    };
  }

  String get displayText {
    return '${startHour.toString().padLeft(2, '0')}:00 - ${endHour.toString().padLeft(2, '0')}:00';
  }

  bool isInQuietHours(DateTime time) {
    final hour = time.hour;
    if (startHour <= endHour) {
      return hour >= startHour && hour < endHour;
    } else {
      return hour >= startHour || hour < endHour;
    }
  }
}

// Gizlilik ayarları modeli
class PrivacySettings {
  final bool profileVisibility; // Profilin diğer kullanıcılara görünürlüğü
  final bool showOnlineStatus;
  final bool allowDataCollection;
  final bool shareAnalytics;
  final bool personalizedAds;
  final bool locationSharing;

  const PrivacySettings({
    required this.profileVisibility,
    required this.showOnlineStatus,
    required this.allowDataCollection,
    required this.shareAnalytics,
    required this.personalizedAds,
    required this.locationSharing,
  });

  factory PrivacySettings.defaultSettings() {
    return const PrivacySettings(
      profileVisibility: true,
      showOnlineStatus: false,
      allowDataCollection: true,
      shareAnalytics: false,
      personalizedAds: false,
      locationSharing: false,
    );
  }

  factory PrivacySettings.fromMap(Map<String, dynamic> map) {
    return PrivacySettings(
      profileVisibility: map['profileVisibility'] ?? true,
      showOnlineStatus: map['showOnlineStatus'] ?? false,
      allowDataCollection: map['allowDataCollection'] ?? true,
      shareAnalytics: map['shareAnalytics'] ?? false,
      personalizedAds: map['personalizedAds'] ?? false,
      locationSharing: map['locationSharing'] ?? false,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'profileVisibility': profileVisibility,
      'showOnlineStatus': showOnlineStatus,
      'allowDataCollection': allowDataCollection,
      'shareAnalytics': shareAnalytics,
      'personalizedAds': personalizedAds,
      'locationSharing': locationSharing,
    };
  }

  PrivacySettings copyWith({
    bool? profileVisibility,
    bool? showOnlineStatus,
    bool? allowDataCollection,
    bool? shareAnalytics,
    bool? personalizedAds,
    bool? locationSharing,
  }) {
    return PrivacySettings(
      profileVisibility: profileVisibility ?? this.profileVisibility,
      showOnlineStatus: showOnlineStatus ?? this.showOnlineStatus,
      allowDataCollection: allowDataCollection ?? this.allowDataCollection,
      shareAnalytics: shareAnalytics ?? this.shareAnalytics,
      personalizedAds: personalizedAds ?? this.personalizedAds,
      locationSharing: locationSharing ?? this.locationSharing,
    );
  }
}

// Müşteri istatistikleri modeli
class CustomerStatistics {
  final String customerId;
  final int totalOrders;
  final double totalSpent;
  final int totalVisits;
  final List<String> favoriteBusinessIds;
  final Map<String, int> businessVisitCounts;
  final Map<String, double> categorySpending;
  final Map<String, int> monthlyOrderCounts;
  final String? mostOrderedCategory;
  final String? favoriteBusinessId;
  final double averageOrderValue;
  final int loyaltyPoints;
  final DateTime lastOrderDate;
  final DateTime createdAt;
  final DateTime updatedAt;

  const CustomerStatistics({
    required this.customerId,
    required this.totalOrders,
    required this.totalSpent,
    required this.totalVisits,
    required this.favoriteBusinessIds,
    required this.businessVisitCounts,
    required this.categorySpending,
    required this.monthlyOrderCounts,
    this.mostOrderedCategory,
    this.favoriteBusinessId,
    required this.averageOrderValue,
    required this.loyaltyPoints,
    required this.lastOrderDate,
    required this.createdAt,
    required this.updatedAt,
  });

  factory CustomerStatistics.empty(String customerId) {
    final now = DateTime.now();
    return CustomerStatistics(
      customerId: customerId,
      totalOrders: 0,
      totalSpent: 0.0,
      totalVisits: 0,
      favoriteBusinessIds: [],
      businessVisitCounts: {},
      categorySpending: {},
      monthlyOrderCounts: {},
      averageOrderValue: 0.0,
      loyaltyPoints: 0,
      lastOrderDate: now,
      createdAt: now,
      updatedAt: now,
    );
  }

  factory CustomerStatistics.fromMap(Map<String, dynamic> map) {
    return CustomerStatistics(
      customerId: map['customerId'] ?? '',
      totalOrders: map['totalOrders'] ?? 0,
      totalSpent: (map['totalSpent'] ?? 0.0).toDouble(),
      totalVisits: map['totalVisits'] ?? 0,
      favoriteBusinessIds: List<String>.from(map['favoriteBusinessIds'] ?? []),
      businessVisitCounts: Map<String, int>.from(map['businessVisitCounts'] ?? {}),
      categorySpending: Map<String, double>.from(map['categorySpending'] ?? {}),
      monthlyOrderCounts: Map<String, int>.from(map['monthlyOrderCounts'] ?? {}),
      mostOrderedCategory: map['mostOrderedCategory'],
      favoriteBusinessId: map['favoriteBusinessId'],
      averageOrderValue: (map['averageOrderValue'] ?? 0.0).toDouble(),
      loyaltyPoints: map['loyaltyPoints'] ?? 0,
      lastOrderDate: DateTime.fromMillisecondsSinceEpoch(
        map['lastOrderDate'] ?? DateTime.now().millisecondsSinceEpoch
      ),
      createdAt: DateTime.fromMillisecondsSinceEpoch(
        map['createdAt'] ?? DateTime.now().millisecondsSinceEpoch
      ),
      updatedAt: DateTime.fromMillisecondsSinceEpoch(
        map['updatedAt'] ?? DateTime.now().millisecondsSinceEpoch
      ),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'customerId': customerId,
      'totalOrders': totalOrders,
      'totalSpent': totalSpent,
      'totalVisits': totalVisits,
      'favoriteBusinessIds': favoriteBusinessIds,
      'businessVisitCounts': businessVisitCounts,
      'categorySpending': categorySpending,
      'monthlyOrderCounts': monthlyOrderCounts,
      'mostOrderedCategory': mostOrderedCategory,
      'favoriteBusinessId': favoriteBusinessId,
      'averageOrderValue': averageOrderValue,
      'loyaltyPoints': loyaltyPoints,
      'lastOrderDate': lastOrderDate.millisecondsSinceEpoch,
      'createdAt': createdAt.millisecondsSinceEpoch,
      'updatedAt': updatedAt.millisecondsSinceEpoch,
    };
  }

  CustomerStatistics copyWith({
    int? totalOrders,
    double? totalSpent,
    int? totalVisits,
    List<String>? favoriteBusinessIds,
    Map<String, int>? businessVisitCounts,
    Map<String, double>? categorySpending,
    Map<String, int>? monthlyOrderCounts,
    String? mostOrderedCategory,
    String? favoriteBusinessId,
    double? averageOrderValue,
    int? loyaltyPoints,
    DateTime? lastOrderDate,
    DateTime? updatedAt,
  }) {
    return CustomerStatistics(
      customerId: customerId,
      totalOrders: totalOrders ?? this.totalOrders,
      totalSpent: totalSpent ?? this.totalSpent,
      totalVisits: totalVisits ?? this.totalVisits,
      favoriteBusinessIds: favoriteBusinessIds ?? this.favoriteBusinessIds,
      businessVisitCounts: businessVisitCounts ?? this.businessVisitCounts,
      categorySpending: categorySpending ?? this.categorySpending,
      monthlyOrderCounts: monthlyOrderCounts ?? this.monthlyOrderCounts,
      mostOrderedCategory: mostOrderedCategory ?? this.mostOrderedCategory,
      favoriteBusinessId: favoriteBusinessId ?? this.favoriteBusinessId,
      averageOrderValue: averageOrderValue ?? this.averageOrderValue,
      loyaltyPoints: loyaltyPoints ?? this.loyaltyPoints,
      lastOrderDate: lastOrderDate ?? this.lastOrderDate,
      createdAt: createdAt,
      updatedAt: updatedAt ?? DateTime.now(),
    );
  }
} 