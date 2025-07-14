import 'package:cloud_firestore/cloud_firestore.dart';

class User {
  final String uid;
  final String email;
  final String name;
  final String? phone;
  final DateTime createdAt;
  final DateTime updatedAt;
  final bool isActive;
  final SubscriptionType subscriptionType;
  final DateTime? subscriptionExpiry;
  final UserProfile profile;

  User({
    required this.uid,
    required this.email,
    required this.name,
    this.phone,
    required this.createdAt,
    required this.updatedAt,
    required this.isActive,
    required this.subscriptionType,
    this.subscriptionExpiry,
    required this.profile,
  });

  factory User.fromJson(Map<String, dynamic> data, {String? id}) {
    return User(
      uid: id ?? data['uid'] ?? '',
      email: data['email'] ?? '',
      name: data['name'] ?? '',
      phone: data['phone'],
      createdAt: _parseDateTime(data['createdAt']),
      updatedAt: _parseDateTime(data['updatedAt']),
      isActive: data['isActive'] ?? true,
      subscriptionType: SubscriptionType.fromString(
        data['subscriptionType'] ?? 'free',
      ),
      subscriptionExpiry: data['subscriptionExpiry'] != null
          ? _parseDateTime(data['subscriptionExpiry'])
          : null,
      profile: UserProfile.fromMap(data['profile'] ?? {}),
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
      'uid': uid,
      'email': email,
      'name': name,
      'phone': phone,
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt.toIso8601String(),
      'isActive': isActive,
      'subscriptionType': subscriptionType.value,
      'subscriptionExpiry': subscriptionExpiry?.toIso8601String(),
      'profile': profile.toMap(),
    };
  }

  User copyWith({
    String? uid,
    String? email,
    String? name,
    String? phone,
    DateTime? createdAt,
    DateTime? updatedAt,
    bool? isActive,
    SubscriptionType? subscriptionType,
    DateTime? subscriptionExpiry,
    UserProfile? profile,
  }) {
    return User(
      uid: uid ?? this.uid,
      email: email ?? this.email,
      name: name ?? this.name,
      phone: phone ?? this.phone,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      isActive: isActive ?? this.isActive,
      subscriptionType: subscriptionType ?? this.subscriptionType,
      subscriptionExpiry: subscriptionExpiry ?? this.subscriptionExpiry,
      profile: profile ?? this.profile,
    );
  }

  // Helper methods
  bool get hasActiveSubscription {
    if (subscriptionType == SubscriptionType.free) return true;
    if (subscriptionExpiry == null) return false;
    return DateTime.now().isBefore(subscriptionExpiry!);
  }

  bool get isSubscriptionExpired {
    if (subscriptionType == SubscriptionType.free) return false;
    if (subscriptionExpiry == null) return true;
    return DateTime.now().isAfter(subscriptionExpiry!);
  }

  int get daysUntilExpiry {
    if (subscriptionExpiry == null) return 0;
    return subscriptionExpiry!.difference(DateTime.now()).inDays;
  }

  bool get isSubscriptionExpiringSoon {
    return daysUntilExpiry > 0 && daysUntilExpiry <= 7;
  }

  String get displayName {
    return name.isNotEmpty ? name : email.split('@').first;
  }

  String get initials {
    final names = name.split(' ');
    if (names.length >= 2) {
      return '${names[0][0]}${names[1][0]}'.toUpperCase();
    } else if (names.isNotEmpty) {
      return names[0][0].toUpperCase();
    }
    return email[0].toUpperCase();
  }

  @override
  String toString() {
    return 'User(uid: $uid, email: $email, name: $name, subscriptionType: $subscriptionType, isActive: $isActive)';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is User && other.uid == uid;
  }

  @override
  int get hashCode => uid.hashCode;
}

class UserProfile {
  final String? avatarUrl;
  final String? bio;
  final String? company;
  final String? website;
  final String? location;
  final UserPreferences preferences;
  final DateTime? lastLoginAt;
  final int totalBusinesses;
  final int totalProducts;
  final CustomerData? customerData; // Müşteri verileri

  UserProfile({
    this.avatarUrl,
    this.bio,
    this.company,
    this.website,
    this.location,
    required this.preferences,
    this.lastLoginAt,
    required this.totalBusinesses,
    required this.totalProducts,
    this.customerData,
  });

  factory UserProfile.fromMap(Map<String, dynamic> map) {
    return UserProfile(
      avatarUrl: map['avatarUrl'],
      bio: map['bio'],
      company: map['company'],
      website: map['website'],
      location: map['location'],
      preferences: UserPreferences.fromMap(map['preferences'] ?? {}),
      lastLoginAt: map['lastLoginAt'] != null
          ? User._parseDateTime(map['lastLoginAt'])
          : null,
      totalBusinesses: map['totalBusinesses'] ?? 0,
      totalProducts: map['totalProducts'] ?? 0,
      customerData: map['customerData'] != null
          ? CustomerData.fromMap(map['customerData'])
          : null,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'avatarUrl': avatarUrl,
      'bio': bio,
      'company': company,
      'website': website,
      'location': location,
      'preferences': preferences.toMap(),
      'lastLoginAt': lastLoginAt?.toIso8601String(),
      'totalBusinesses': totalBusinesses,
      'totalProducts': totalProducts,
      'customerData': customerData?.toMap(),
    };
  }

  UserProfile copyWith({
    String? avatarUrl,
    String? bio,
    String? company,
    String? website,
    String? location,
    UserPreferences? preferences,
    DateTime? lastLoginAt,
    int? totalBusinesses,
    int? totalProducts,
    CustomerData? customerData,
  }) {
    return UserProfile(
      avatarUrl: avatarUrl ?? this.avatarUrl,
      bio: bio ?? this.bio,
      company: company ?? this.company,
      website: website ?? this.website,
      location: location ?? this.location,
      preferences: preferences ?? this.preferences,
      lastLoginAt: lastLoginAt ?? this.lastLoginAt,
      totalBusinesses: totalBusinesses ?? this.totalBusinesses,
      totalProducts: totalProducts ?? this.totalProducts,
      customerData: customerData ?? this.customerData,
    );
  }

  @override
  String toString() {
    return 'UserProfile(company: $company, totalBusinesses: $totalBusinesses, totalProducts: $totalProducts)';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is UserProfile &&
        other.avatarUrl == avatarUrl &&
        other.company == company;
  }

  @override
  int get hashCode => avatarUrl.hashCode ^ company.hashCode;
}

// Müşteri verileri sınıfı
class CustomerData {
  final List<CustomerOrder> orderHistory;
  final List<CustomerFavorite> favorites;
  final List<CustomerVisit> visitHistory;
  final CustomerStats stats;
  final CustomerPreferences preferences;
  final List<CustomerAddress> addresses;
  final CustomerPaymentInfo? paymentInfo;

  CustomerData({
    required this.orderHistory,
    required this.favorites,
    required this.visitHistory,
    required this.stats,
    required this.preferences,
    required this.addresses,
    this.paymentInfo,
  });

  factory CustomerData.fromMap(Map<String, dynamic> map) {
    return CustomerData(
      orderHistory: (map['orderHistory'] as List<dynamic>?)
              ?.map((e) => CustomerOrder.fromMap(e))
              .toList() ??
          [],
      favorites: (map['favorites'] as List<dynamic>?)
              ?.map((e) => CustomerFavorite.fromMap(e))
              .toList() ??
          [],
      visitHistory: (map['visitHistory'] as List<dynamic>?)
              ?.map((e) => CustomerVisit.fromMap(e))
              .toList() ??
          [],
      stats: CustomerStats.fromMap(map['stats'] ?? {}),
      preferences: CustomerPreferences.fromMap(map['preferences'] ?? {}),
      addresses: (map['addresses'] as List<dynamic>?)
              ?.map((e) => CustomerAddress.fromMap(e))
              .toList() ??
          [],
      paymentInfo: map['paymentInfo'] != null
          ? CustomerPaymentInfo.fromMap(map['paymentInfo'])
          : null,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'orderHistory': orderHistory.map((e) => e.toMap()).toList(),
      'favorites': favorites.map((e) => e.toMap()).toList(),
      'visitHistory': visitHistory.map((e) => e.toMap()).toList(),
      'stats': stats.toMap(),
      'preferences': preferences.toMap(),
      'addresses': addresses.map((e) => e.toMap()).toList(),
      'paymentInfo': paymentInfo?.toMap(),
    };
  }

  CustomerData copyWith({
    List<CustomerOrder>? orderHistory,
    List<CustomerFavorite>? favorites,
    List<CustomerVisit>? visitHistory,
    CustomerStats? stats,
    CustomerPreferences? preferences,
    List<CustomerAddress>? addresses,
    CustomerPaymentInfo? paymentInfo,
  }) {
    return CustomerData(
      orderHistory: orderHistory ?? this.orderHistory,
      favorites: favorites ?? this.favorites,
      visitHistory: visitHistory ?? this.visitHistory,
      stats: stats ?? this.stats,
      preferences: preferences ?? this.preferences,
      addresses: addresses ?? this.addresses,
      paymentInfo: paymentInfo ?? this.paymentInfo,
    );
  }

  @override
  String toString() {
    return 'CustomerData(orderHistory: ${orderHistory.length}, favorites: ${favorites.length}, totalSpent: ${stats.totalSpent})';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is CustomerData &&
        other.orderHistory.length == orderHistory.length &&
        other.favorites.length == favorites.length;
  }

  @override
  int get hashCode => orderHistory.length.hashCode ^ favorites.length.hashCode;
}

// Müşteri sipariş geçmişi
class CustomerOrder {
  final String orderId;
  final String businessId;
  final String businessName;
  final List<CustomerOrderItem> items;
  final double totalAmount;
  final DateTime orderDate;
  final String status;
  final String? notes;
  final String? tableNumber;

  CustomerOrder({
    required this.orderId,
    required this.businessId,
    required this.businessName,
    required this.items,
    required this.totalAmount,
    required this.orderDate,
    required this.status,
    this.notes,
    this.tableNumber,
  });

  factory CustomerOrder.fromMap(Map<String, dynamic> map) {
    return CustomerOrder(
      orderId: map['orderId'] ?? '',
      businessId: map['businessId'] ?? '',
      businessName: map['businessName'] ?? '',
      items: (map['items'] as List<dynamic>?)
              ?.map((e) => CustomerOrderItem.fromMap(e))
              .toList() ??
          [],
      totalAmount: (map['totalAmount'] ?? 0.0).toDouble(),
      orderDate: User._parseDateTime(map['orderDate']),
      status: map['status'] ?? 'completed',
      notes: map['notes'],
      tableNumber: map['tableNumber'],
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'orderId': orderId,
      'businessId': businessId,
      'businessName': businessName,
      'items': items.map((e) => e.toMap()).toList(),
      'totalAmount': totalAmount,
      'orderDate': orderDate.toIso8601String(),
      'status': status,
      'notes': notes,
      'tableNumber': tableNumber,
    };
  }
}

// Müşteri sipariş öğesi
class CustomerOrderItem {
  final String productId;
  final String productName;
  final int quantity;
  final double unitPrice;
  final double totalPrice;
  final String? notes;

  CustomerOrderItem({
    required this.productId,
    required this.productName,
    required this.quantity,
    required this.unitPrice,
    required this.totalPrice,
    this.notes,
  });

  factory CustomerOrderItem.fromMap(Map<String, dynamic> map) {
    return CustomerOrderItem(
      productId: map['productId'] ?? '',
      productName: map['productName'] ?? '',
      quantity: map['quantity'] ?? 1,
      unitPrice: (map['unitPrice'] ?? 0.0).toDouble(),
      totalPrice: (map['totalPrice'] ?? 0.0).toDouble(),
      notes: map['notes'],
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'productId': productId,
      'productName': productName,
      'quantity': quantity,
      'unitPrice': unitPrice,
      'totalPrice': totalPrice,
      'notes': notes,
    };
  }
}

// Müşteri favori işletmeleri
class CustomerFavorite {
  final String businessId;
  final String businessName;
  final String? businessLogo;
  final DateTime addedDate;
  final int visitCount;
  final double totalSpent;

  CustomerFavorite({
    required this.businessId,
    required this.businessName,
    this.businessLogo,
    required this.addedDate,
    required this.visitCount,
    required this.totalSpent,
  });

  factory CustomerFavorite.fromMap(Map<String, dynamic> map) {
    return CustomerFavorite(
      businessId: map['businessId'] ?? '',
      businessName: map['businessName'] ?? '',
      businessLogo: map['businessLogo'],
      addedDate: User._parseDateTime(map['addedDate']),
      visitCount: map['visitCount'] ?? 0,
      totalSpent: (map['totalSpent'] ?? 0.0).toDouble(),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'businessId': businessId,
      'businessName': businessName,
      'businessLogo': businessLogo,
      'addedDate': addedDate.toIso8601String(),
      'visitCount': visitCount,
      'totalSpent': totalSpent,
    };
  }
}

// Müşteri ziyaret geçmişi
class CustomerVisit {
  final String businessId;
  final String businessName;
  final DateTime visitDate;
  final String? tableNumber;
  final int orderCount;
  final double totalSpent;

  CustomerVisit({
    required this.businessId,
    required this.businessName,
    required this.visitDate,
    this.tableNumber,
    required this.orderCount,
    required this.totalSpent,
  });

  factory CustomerVisit.fromMap(Map<String, dynamic> map) {
    return CustomerVisit(
      businessId: map['businessId'] ?? '',
      businessName: map['businessName'] ?? '',
      visitDate: User._parseDateTime(map['visitDate']),
      tableNumber: map['tableNumber'],
      orderCount: map['orderCount'] ?? 0,
      totalSpent: (map['totalSpent'] ?? 0.0).toDouble(),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'businessId': businessId,
      'businessName': businessName,
      'visitDate': visitDate.toIso8601String(),
      'tableNumber': tableNumber,
      'orderCount': orderCount,
      'totalSpent': totalSpent,
    };
  }
}

// Müşteri istatistikleri
class CustomerStats {
  final int totalOrders;
  final double totalSpent;
  final int favoriteBusinessCount;
  final int totalVisits;
  final DateTime? firstOrderDate;
  final DateTime? lastOrderDate;
  final Map<String, int> categoryPreferences;
  final Map<String, double> businessSpending;

  CustomerStats({
    required this.totalOrders,
    required this.totalSpent,
    required this.favoriteBusinessCount,
    required this.totalVisits,
    this.firstOrderDate,
    this.lastOrderDate,
    required this.categoryPreferences,
    required this.businessSpending,
  });

  factory CustomerStats.fromMap(Map<String, dynamic> map) {
    return CustomerStats(
      totalOrders: map['totalOrders'] ?? 0,
      totalSpent: (map['totalSpent'] ?? 0.0).toDouble(),
      favoriteBusinessCount: map['favoriteBusinessCount'] ?? 0,
      totalVisits: map['totalVisits'] ?? 0,
      firstOrderDate: map['firstOrderDate'] != null
          ? User._parseDateTime(map['firstOrderDate'])
          : null,
      lastOrderDate: map['lastOrderDate'] != null
          ? User._parseDateTime(map['lastOrderDate'])
          : null,
      categoryPreferences: Map<String, int>.from(
        map['categoryPreferences'] ?? {},
      ),
      businessSpending: Map<String, double>.from(
        map['businessSpending'] ?? {},
      ),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'totalOrders': totalOrders,
      'totalSpent': totalSpent,
      'favoriteBusinessCount': favoriteBusinessCount,
      'totalVisits': totalVisits,
      'firstOrderDate': firstOrderDate?.toIso8601String(),
      'lastOrderDate': lastOrderDate?.toIso8601String(),
      'categoryPreferences': categoryPreferences,
      'businessSpending': businessSpending,
    };
  }
}

// Müşteri tercihleri
class CustomerPreferences {
  final List<String> favoriteCategories;
  final List<String> dietaryRestrictions;
  final bool allowNotifications;
  final bool allowMarketing;
  final String preferredLanguage;
  final String preferredCurrency;
  final double maxOrderAmount;
  final bool autoSavePaymentInfo;

  CustomerPreferences({
    required this.favoriteCategories,
    required this.dietaryRestrictions,
    required this.allowNotifications,
    required this.allowMarketing,
    required this.preferredLanguage,
    required this.preferredCurrency,
    required this.maxOrderAmount,
    required this.autoSavePaymentInfo,
  });

  factory CustomerPreferences.fromMap(Map<String, dynamic> map) {
    return CustomerPreferences(
      favoriteCategories: List<String>.from(
        map['favoriteCategories'] ?? [],
      ),
      dietaryRestrictions: List<String>.from(
        map['dietaryRestrictions'] ?? [],
      ),
      allowNotifications: map['allowNotifications'] ?? true,
      allowMarketing: map['allowMarketing'] ?? false,
      preferredLanguage: map['preferredLanguage'] ?? 'tr',
      preferredCurrency: map['preferredCurrency'] ?? 'TL',
      maxOrderAmount: (map['maxOrderAmount'] ?? 1000.0).toDouble(),
      autoSavePaymentInfo: map['autoSavePaymentInfo'] ?? false,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'favoriteCategories': favoriteCategories,
      'dietaryRestrictions': dietaryRestrictions,
      'allowNotifications': allowNotifications,
      'allowMarketing': allowMarketing,
      'preferredLanguage': preferredLanguage,
      'preferredCurrency': preferredCurrency,
      'maxOrderAmount': maxOrderAmount,
      'autoSavePaymentInfo': autoSavePaymentInfo,
    };
  }
}

// Müşteri adres bilgileri
class CustomerAddress {
  final String id;
  final String title;
  final String address;
  final String city;
  final String district;
  final String postalCode;
  final bool isDefault;
  final String? notes;

  CustomerAddress({
    required this.id,
    required this.title,
    required this.address,
    required this.city,
    required this.district,
    required this.postalCode,
    required this.isDefault,
    this.notes,
  });

  factory CustomerAddress.fromMap(Map<String, dynamic> map) {
    return CustomerAddress(
      id: map['id'] ?? '',
      title: map['title'] ?? '',
      address: map['address'] ?? '',
      city: map['city'] ?? '',
      district: map['district'] ?? '',
      postalCode: map['postalCode'] ?? '',
      isDefault: map['isDefault'] ?? false,
      notes: map['notes'],
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'title': title,
      'address': address,
      'city': city,
      'district': district,
      'postalCode': postalCode,
      'isDefault': isDefault,
      'notes': notes,
    };
  }
}

// Müşteri ödeme bilgileri
class CustomerPaymentInfo {
  final String cardType;
  final String lastFourDigits;
  final String cardholderName;
  final DateTime expiryDate;
  final bool isDefault;

  CustomerPaymentInfo({
    required this.cardType,
    required this.lastFourDigits,
    required this.cardholderName,
    required this.expiryDate,
    required this.isDefault,
  });

  factory CustomerPaymentInfo.fromMap(Map<String, dynamic> map) {
    return CustomerPaymentInfo(
      cardType: map['cardType'] ?? '',
      lastFourDigits: map['lastFourDigits'] ?? '',
      cardholderName: map['cardholderName'] ?? '',
      expiryDate: User._parseDateTime(map['expiryDate']),
      isDefault: map['isDefault'] ?? false,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'cardType': cardType,
      'lastFourDigits': lastFourDigits,
      'cardholderName': cardholderName,
      'expiryDate': expiryDate.toIso8601String(),
      'isDefault': isDefault,
    };
  }
}

class UserPreferences {
  final String language;
  final String currency;
  final String timezone;
  final bool emailNotifications;
  final bool pushNotifications;
  final bool smsNotifications;
  final String theme;
  final bool analytics;
  final bool marketing;

  UserPreferences({
    required this.language,
    required this.currency,
    required this.timezone,
    required this.emailNotifications,
    required this.pushNotifications,
    required this.smsNotifications,
    required this.theme,
    required this.analytics,
    required this.marketing,
  });

  factory UserPreferences.fromMap(Map<String, dynamic> map) {
    return UserPreferences(
      language: map['language'] ?? 'tr',
      currency: map['currency'] ?? 'TL',
      timezone: map['timezone'] ?? 'Europe/Istanbul',
      emailNotifications: map['emailNotifications'] ?? true,
      pushNotifications: map['pushNotifications'] ?? true,
      smsNotifications: map['smsNotifications'] ?? false,
      theme: map['theme'] ?? 'light',
      analytics: map['analytics'] ?? true,
      marketing: map['marketing'] ?? false,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'language': language,
      'currency': currency,
      'timezone': timezone,
      'emailNotifications': emailNotifications,
      'pushNotifications': pushNotifications,
      'smsNotifications': smsNotifications,
      'theme': theme,
      'analytics': analytics,
      'marketing': marketing,
    };
  }

  UserPreferences copyWith({
    String? language,
    String? currency,
    String? timezone,
    bool? emailNotifications,
    bool? pushNotifications,
    bool? smsNotifications,
    String? theme,
    bool? analytics,
    bool? marketing,
  }) {
    return UserPreferences(
      language: language ?? this.language,
      currency: currency ?? this.currency,
      timezone: timezone ?? this.timezone,
      emailNotifications: emailNotifications ?? this.emailNotifications,
      pushNotifications: pushNotifications ?? this.pushNotifications,
      smsNotifications: smsNotifications ?? this.smsNotifications,
      theme: theme ?? this.theme,
      analytics: analytics ?? this.analytics,
      marketing: marketing ?? this.marketing,
    );
  }

  @override
  String toString() {
    return 'UserPreferences(language: $language, currency: $currency, theme: $theme)';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is UserPreferences &&
        other.language == language &&
        other.currency == currency &&
        other.theme == theme;
  }

  @override
  int get hashCode => language.hashCode ^ currency.hashCode ^ theme.hashCode;
}

enum SubscriptionType {
  free('free', 'Ücretsiz', 1, 50),
  premium('premium', 'Premium', 3, 200),
  business('business', 'İşletme', 10, 1000),
  enterprise('enterprise', 'Kurumsal', -1, -1);

  const SubscriptionType(
    this.value,
    this.displayName,
    this.maxBusinesses,
    this.maxProducts,
  );

  final String value;
  final String displayName;
  final int maxBusinesses; // -1 = unlimited
  final int maxProducts; // -1 = unlimited

  static SubscriptionType fromString(String value) {
    return SubscriptionType.values.firstWhere(
      (type) => type.value == value,
      orElse: () => SubscriptionType.free,
    );
  }

  bool get isUnlimited => maxBusinesses == -1 && maxProducts == -1;

  bool canCreateBusiness(int currentBusinessCount) {
    return isUnlimited || currentBusinessCount < maxBusinesses;
  }

  bool canCreateProduct(int currentProductCount) {
    return isUnlimited || currentProductCount < maxProducts;
  }

  String get businessLimit =>
      isUnlimited ? 'Sınırsız' : '$maxBusinesses işletme';
  String get productLimit => isUnlimited ? 'Sınırsız' : '$maxProducts ürün';
}

// Default instances and helper methods
class UserDefaults {
  static User createDefault({
    required String uid,
    required String email,
    required String name,
    String? phone,
  }) {
    return User(
      uid: uid,
      email: email,
      name: name,
      phone: phone,
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
      isActive: true,
      subscriptionType: SubscriptionType.free,
      profile: defaultUserProfile,
    );
  }

  static UserProfile get defaultUserProfile => UserProfile(
    preferences: defaultUserPreferences,
    totalBusinesses: 0,
    totalProducts: 0,
    customerData: defaultCustomerData,
  );

  static UserPreferences get defaultUserPreferences => UserPreferences(
    language: 'tr',
    currency: 'TL',
    timezone: 'Europe/Istanbul',
    emailNotifications: true,
    pushNotifications: true,
    smsNotifications: false,
    theme: 'light',
    analytics: true,
    marketing: false,
  );

  static CustomerData get defaultCustomerData => CustomerData(
    orderHistory: [],
    favorites: [],
    visitHistory: [],
    stats: defaultCustomerStats,
    preferences: defaultCustomerPreferences,
    addresses: [],
  );

  static CustomerStats get defaultCustomerStats => CustomerStats(
    totalOrders: 0,
    totalSpent: 0.0,
    favoriteBusinessCount: 0,
    totalVisits: 0,
    categoryPreferences: {},
    businessSpending: {},
  );

  static CustomerPreferences get defaultCustomerPreferences => CustomerPreferences(
    favoriteCategories: [],
    dietaryRestrictions: [],
    allowNotifications: true,
    allowMarketing: false,
    preferredLanguage: 'tr',
    preferredCurrency: 'TL',
    maxOrderAmount: 1000.0,
    autoSavePaymentInfo: false,
  );
}

// Extension methods for better usability
extension UserExtensions on User {
  /// Kullanıcının abonelik durumunu kontrol eder
  String getSubscriptionStatus() {
    if (subscriptionType == SubscriptionType.free) {
      return 'Ücretsiz Plan';
    }

    if (hasActiveSubscription) {
      if (isSubscriptionExpiringSoon) {
        return '${subscriptionType.displayName} - ${daysUntilExpiry} gün kaldı';
      }
      return '${subscriptionType.displayName} - Aktif';
    }

    return '${subscriptionType.displayName} - Süresi Dolmuş';
  }

  /// Kullanıcının yeni işletme oluşturup oluşturamayacağını kontrol eder
  bool canCreateNewBusiness() {
    return subscriptionType.canCreateBusiness(profile.totalBusinesses);
  }

  /// Kullanıcının yeni ürün oluşturup oluşturamayacağını kontrol eder
  bool canCreateNewProduct() {
    return subscriptionType.canCreateProduct(profile.totalProducts);
  }

  /// Kullanıcının hesap yaşını döndürür
  int get accountAgeInDays {
    return DateTime.now().difference(createdAt).inDays;
  }

  /// Kullanıcının son giriş tarihini döndürür
  String get lastLoginString {
    if (profile.lastLoginAt == null) return 'Hiç giriş yapmamış';

    final difference = DateTime.now().difference(profile.lastLoginAt!);

    if (difference.inDays > 0) {
      return '${difference.inDays} gün önce';
    } else if (difference.inHours > 0) {
      return '${difference.inHours} saat önce';
    } else if (difference.inMinutes > 0) {
      return '${difference.inMinutes} dakika önce';
    } else {
      return 'Şimdi';
    }
  }

  /// Kullanıcının aktiflik durumunu döndürür
  String get activityStatus {
    if (!isActive) return 'Pasif';

    if (profile.lastLoginAt == null) return 'Yeni Kullanıcı';

    final daysSinceLogin = DateTime.now()
        .difference(profile.lastLoginAt!)
        .inDays;

    if (daysSinceLogin == 0) return 'Aktif';
    if (daysSinceLogin <= 7) return 'Düzenli';
    if (daysSinceLogin <= 30) return 'Ara sıra';
    return 'Pasif';
  }
}
 