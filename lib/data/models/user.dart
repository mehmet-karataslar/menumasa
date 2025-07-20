import 'package:cloud_firestore/cloud_firestore.dart';
import '../../business/models/business.dart';

// =============================================================================
// USER TYPES AND ROLES
// =============================================================================

enum UserType {
  customer('customer', 'Müşteri'),
  business('business', 'İşletme'),
  admin('admin', 'Yönetici');

  const UserType(this.value, this.displayName);
  final String value;
  final String displayName;

  static UserType fromString(String value) {
    return UserType.values.firstWhere(
      (type) => type.value == value,
      orElse: () => UserType.customer,
    );
  }
}

enum CustomerRole {
  regular('regular', 'Normal Müşteri'),
  premium('premium', 'Premium Müşteri'),
  vip('vip', 'VIP Müşteri');

  const CustomerRole(this.value, this.displayName);
  final String value;
  final String displayName;

  static CustomerRole fromString(String value) {
    return CustomerRole.values.firstWhere(
      (role) => role.value == value,
      orElse: () => CustomerRole.regular,
    );
  }
}

enum BusinessRole {
  owner('owner', 'İşletme Sahibi', 'Tam işletme kontrolü'),
  manager('manager', 'Yönetici', 'Genel yönetim yetkileri'),
  staff('staff', 'Personel', 'Temel işlemler'),
  cashier('cashier', 'Kasiyer', 'Sipariş ve ödeme işlemleri');

  const BusinessRole(this.value, this.displayName, this.description);
  final String value;
  final String displayName;
  final String description;

  static BusinessRole fromString(String value) {
    return BusinessRole.values.firstWhere(
      (role) => role.value == value,
      orElse: () => BusinessRole.staff,
    );
  }
}

enum AdminRole {
  superAdmin('super_admin', 'Süper Admin', 'Tam sistem kontrolü'),
  systemAdmin('system_admin', 'Sistem Admin', 'Sistem yönetimi'),
  admin('admin', 'Admin', 'Genel yönetim'),
  moderator('moderator', 'Moderatör', 'İçerik moderasyonu'),
  support('support', 'Destek', 'Müşteri desteği');

  const AdminRole(this.value, this.displayName, this.description);
  final String value;
  final String displayName;
  final String description;

  static AdminRole fromString(String value) {
    return AdminRole.values.firstWhere(
      (role) => role.value == value,
      orElse: () => AdminRole.support,
    );
  }
}

// =============================================================================
// PERMISSIONS
// =============================================================================

enum BusinessPermission {
  // Menu Management
  viewMenu('view_menu', 'Menüyü Görüntüle'),
  editMenu('edit_menu', 'Menüyü Düzenle'),
  addProducts('add_products', 'Ürün Ekle'),
  editProducts('edit_products', 'Ürün Düzenle'),
  deleteProducts('delete_products', 'Ürün Sil'),
  manageCategories('manage_categories', 'Kategorileri Yönet'),
  
  // Order Management
  viewOrders('view_orders', 'Siparişleri Görüntüle'),
  editOrders('edit_orders', 'Siparişleri Düzenle'),
  cancelOrders('cancel_orders', 'Siparişleri İptal Et'),
  managePayments('manage_payments', 'Ödemeleri Yönet'),
  
  // Business Management
  viewAnalytics('view_analytics', 'Analitikleri Görüntüle'),
  manageSettings('manage_settings', 'Ayarları Yönet'),
  manageStaff('manage_staff', 'Personeli Yönet'),
  manageDiscounts('manage_discounts', 'İndirimleri Yönet'),
  manageQrCodes('manage_qr_codes', 'QR Kodları Yönet'),
  
  // Customer Management
  viewCustomers('view_customers', 'Müşterileri Görüntüle'),
  manageCustomers('manage_customers', 'Müşterileri Yönet'),
  
  // Reports
  viewReports('view_reports', 'Raporları Görüntüle'),
  exportData('export_data', 'Veri Dışa Aktar');

  const BusinessPermission(this.value, this.displayName);
  final String value;
  final String displayName;

  static BusinessPermission fromString(String value) {
    return BusinessPermission.values.firstWhere(
      (perm) => perm.value == value,
      orElse: () => BusinessPermission.viewMenu,
    );
  }
}

enum AdminPermission {
  // User Management
  viewUsers('view_users', 'Kullanıcıları Görüntüle'),
  createUsers('create_users', 'Kullanıcı Oluştur'),
  editUsers('edit_users', 'Kullanıcı Düzenle'),
  deleteUsers('delete_users', 'Kullanıcı Sil'),
  viewCustomers('view_customers', 'Müşterileri Görüntüle'),
  editCustomers('edit_customers', 'Müşterileri Düzenle'),
  
  // Business Management
  viewBusinesses('view_businesses', 'İşletmeleri Görüntüle'),
  createBusinesses('create_businesses', 'İşletme Oluştur'),
  editBusinesses('edit_businesses', 'İşletme Düzenle'),
  deleteBusinesses('delete_businesses', 'İşletme Sil'),
  approveBusinesses('approve_businesses', 'İşletme Onayla'),
  
  // Order Management
  viewOrders('view_orders', 'Siparişleri Görüntüle'),
  editOrders('edit_orders', 'Siparişleri Düzenle'),
  deleteOrders('delete_orders', 'Siparişleri Sil'),
  
  // System Management
  viewAnalytics('view_analytics', 'Analitikleri Görüntüle'),
  manageSystemSettings('manage_system_settings', 'Sistem Ayarlarını Yönet'),
  viewActivityLogs('view_activity_logs', 'Aktivite Loglarını Görüntüle'),
  manageAdminUsers('manage_admin_users', 'Admin Kullanıcılarını Yönet'),
  manageAdmins('manage_admins', 'Adminleri Yönet'),
  manageSystem('manage_system', 'Sistemi Yönet'),
  viewAuditLogs('view_audit_logs', 'Denetim Loglarını Görüntüle'),
  
  // Content Management
  moderateContent('moderate_content', 'İçerik Modere Et'),
  manageCategories('manage_categories', 'Kategorileri Yönet'),
  manageProducts('manage_products', 'Ürünleri Yönet'),
  
  // Reports
  viewReports('view_reports', 'Raporları Görüntüle');

  const AdminPermission(this.value, this.displayName);
  final String value;
  final String displayName;

  static AdminPermission fromString(String value) {
    return AdminPermission.values.firstWhere(
      (perm) => perm.value == value,
      orElse: () => AdminPermission.viewUsers,
    );
  }
}

// =============================================================================
// MAIN USER MODEL
// =============================================================================

class User {
  final String id;
  final String email;
  final String name;
  final String? phone;
  final UserType userType;
  final DateTime createdAt;
  final DateTime updatedAt;
  final bool isActive;
  final bool isEmailVerified;
  final String? avatarUrl;
  final DateTime? lastLoginAt;
  final String? lastLoginIp;
  final String? sessionToken;
  
  // Role-specific data
  final CustomerData? customerData;
  final BusinessData? businessData;
  final AdminData? adminData;

  User({
    required this.id,
    required this.email,
    required this.name,
    this.phone,
    required this.userType,
    required this.createdAt,
    required this.updatedAt,
    required this.isActive,
    required this.isEmailVerified,
    this.avatarUrl,
    this.lastLoginAt,
    this.lastLoginIp,
    this.sessionToken,
    this.customerData,
    this.businessData,
    this.adminData,
  });

  // Factory methods for different user types
  factory User.customer({
    required String id,
    required String email,
    required String name,
    String? phone,
    required DateTime createdAt,
    DateTime? updatedAt,
    bool isActive = true,
    bool isEmailVerified = false,
    String? avatarUrl,
    DateTime? lastLoginAt,
    String? lastLoginIp,
    String? sessionToken,
    CustomerData? customerData,
  }) {
    return User(
      id: id,
      email: email,
      name: name,
      phone: phone,
      userType: UserType.customer,
      createdAt: createdAt,
      updatedAt: updatedAt ?? createdAt,
      isActive: isActive,
      isEmailVerified: isEmailVerified,
      avatarUrl: avatarUrl,
      lastLoginAt: lastLoginAt,
      lastLoginIp: lastLoginIp,
      sessionToken: sessionToken,
      customerData: customerData ?? CustomerData(),
    );
  }

  factory User.business({
    required String id,
    required String email,
    required String name,
    String? phone,
    required DateTime createdAt,
    DateTime? updatedAt,
    bool isActive = true,
    bool isEmailVerified = false,
    String? avatarUrl,
    DateTime? lastLoginAt,
    String? lastLoginIp,
    String? sessionToken,
    required BusinessData businessData,
  }) {
    return User(
      id: id,
      email: email,
      name: name,
      phone: phone,
      userType: UserType.business,
      createdAt: createdAt,
      updatedAt: updatedAt ?? createdAt,
      isActive: isActive,
      isEmailVerified: isEmailVerified,
      avatarUrl: avatarUrl,
      lastLoginAt: lastLoginAt,
      lastLoginIp: lastLoginIp,
      sessionToken: sessionToken,
      businessData: businessData,
    );
  }

  factory User.admin({
    required String id,
    required String email,
    required String name,
    String? phone,
    required DateTime createdAt,
    DateTime? updatedAt,
    bool isActive = true,
    bool isEmailVerified = false,
    String? avatarUrl,
    DateTime? lastLoginAt,
    String? lastLoginIp,
    String? sessionToken,
    required AdminData adminData,
  }) {
    return User(
      id: id,
      email: email,
      name: name,
      phone: phone,
      userType: UserType.admin,
      createdAt: createdAt,
      updatedAt: updatedAt ?? createdAt,
      isActive: isActive,
      isEmailVerified: isEmailVerified,
      avatarUrl: avatarUrl,
      lastLoginAt: lastLoginAt,
      lastLoginIp: lastLoginIp,
      sessionToken: sessionToken,
      adminData: adminData,
    );
  }

  // JSON serialization
  factory User.fromJson(Map<String, dynamic> json, {String? id}) {
    final userType = UserType.fromString(json['userType'] ?? 'customer');
    
    return User(
      id: id ?? json['id'] ?? '',
      email: json['email'] ?? '',
      name: json['name'] ?? '',
      phone: json['phone'],
      userType: userType,
      createdAt: _parseDateTime(json['createdAt']),
      updatedAt: _parseDateTime(json['updatedAt']),
      isActive: json['isActive'] ?? true,
      isEmailVerified: json['isEmailVerified'] ?? false,
      avatarUrl: json['avatarUrl'],
      lastLoginAt: json['lastLoginAt'] != null ? _parseDateTime(json['lastLoginAt']) : null,
      lastLoginIp: json['lastLoginIp'],
      sessionToken: json['sessionToken'],
      customerData: json['customerData'] != null ? CustomerData.fromJson(json['customerData']) : null,
      businessData: json['businessData'] != null ? BusinessData.fromJson(json['businessData']) : null,
      adminData: json['adminData'] != null ? AdminData.fromJson(json['adminData']) : null,
    );
  }

  factory User.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return User.fromJson({...data, 'id': doc.id});
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'email': email,
      'name': name,
      'phone': phone,
      'userType': userType.value,
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt.toIso8601String(),
      'isActive': isActive,
      'isEmailVerified': isEmailVerified,
      'avatarUrl': avatarUrl,
      'lastLoginAt': lastLoginAt?.toIso8601String(),
      'lastLoginIp': lastLoginIp,
      'sessionToken': sessionToken,
      'customerData': customerData?.toJson(),
      'businessData': businessData?.toJson(),
      'adminData': adminData?.toJson(),
    };
  }

  Map<String, dynamic> toFirestore() {
    final data = toJson();
    data.remove('id');
    data['createdAt'] = Timestamp.fromDate(createdAt);
    data['updatedAt'] = Timestamp.fromDate(updatedAt);
    if (lastLoginAt != null) {
      data['lastLoginAt'] = Timestamp.fromDate(lastLoginAt!);
    }
    return data;
  }

  // Helper methods
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

  // Getters
  String get displayName => name.isNotEmpty ? name : email.split('@').first;
  String get username => email.split('@').first;
  String get initials {
    final names = name.split(' ');
    if (names.length >= 2) {
      return '${names[0][0]}${names[1][0]}'.toUpperCase();
    } else if (names.isNotEmpty) {
      return names[0][0].toUpperCase();
    }
    return email[0].toUpperCase();
  }

  // Type checking
  bool get isCustomer => userType == UserType.customer;
  bool get isBusiness => userType == UserType.business;
  bool get isAdmin => userType == UserType.admin;

  // Permission checking
  bool hasBusinessPermission(BusinessPermission permission) {
    if (!isBusiness || businessData == null) return false;
    return businessData!.hasPermission(permission);
  }

  bool hasAdminPermission(AdminPermission permission) {
    if (!isAdmin || adminData == null) return false;
    return adminData!.hasPermission(permission);
  }

  // Copy with
  User copyWith({
    String? id,
    String? email,
    String? name,
    String? phone,
    UserType? userType,
    DateTime? createdAt,
    DateTime? updatedAt,
    bool? isActive,
    bool? isEmailVerified,
    String? avatarUrl,
    DateTime? lastLoginAt,
    String? lastLoginIp,
    String? sessionToken,
    CustomerData? customerData,
    BusinessData? businessData,
    AdminData? adminData,
  }) {
    return User(
      id: id ?? this.id,
      email: email ?? this.email,
      name: name ?? this.name,
      phone: phone ?? this.phone,
      userType: userType ?? this.userType,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      isActive: isActive ?? this.isActive,
      isEmailVerified: isEmailVerified ?? this.isEmailVerified,
      avatarUrl: avatarUrl ?? this.avatarUrl,
      lastLoginAt: lastLoginAt ?? this.lastLoginAt,
      lastLoginIp: lastLoginIp ?? this.lastLoginIp,
      sessionToken: sessionToken ?? this.sessionToken,
      customerData: customerData ?? this.customerData,
      businessData: businessData ?? this.businessData,
      adminData: adminData ?? this.adminData,
    );
  }

  @override
  String toString() {
    return 'User(id: $id, email: $email, name: $name, userType: $userType, isActive: $isActive)';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is User && other.id == id;
  }

  @override
  int get hashCode => id.hashCode;
}

// =============================================================================
// CUSTOMER DATA
// =============================================================================

class CustomerData {
  final CustomerRole role;
  final String? address;
  final String? city;
  final String? district;
  final String? postalCode;
  final Coordinates? location;
  final CustomerPreferences preferences;
  final CustomerStats stats;
  final List<String> favoriteBusinessIds;
  final List<String> recentBusinessIds;
  final List<CustomerFavorite> favorites;
  final List<CustomerOrder> orderHistory;
  final List<CustomerAddress> addresses;
  final List<CustomerPaymentInfo> paymentMethods;
  final DateTime? lastOrderAt;
  final int totalOrders;
  final double totalSpent;
  final bool isPremium;
  final DateTime? premiumExpiry;

  CustomerData({
    this.role = CustomerRole.regular,
    this.address,
    this.city,
    this.district,
    this.postalCode,
    this.location,
    this.preferences = const CustomerPreferences(),
    this.stats = const CustomerStats(),
    this.favoriteBusinessIds = const [],
    this.recentBusinessIds = const [],
    this.favorites = const [],
    this.orderHistory = const [],
    this.addresses = const [],
    this.paymentMethods = const [],
    this.lastOrderAt,
    this.totalOrders = 0,
    this.totalSpent = 0.0,
    this.isPremium = false,
    this.premiumExpiry,
  });

  factory CustomerData.fromJson(Map<String, dynamic> json) {
    return CustomerData(
      role: CustomerRole.fromString(json['role'] ?? 'regular'),
      address: json['address'],
      city: json['city'],
      district: json['district'],
      postalCode: json['postalCode'],
      location: json['location'] != null ? Coordinates.fromJson(json['location']) : null,
      preferences: CustomerPreferences.fromJson(json['preferences'] ?? {}),
      stats: CustomerStats.fromJson(json['stats'] ?? {}),
      favoriteBusinessIds: List<String>.from(json['favoriteBusinessIds'] ?? []),
      recentBusinessIds: List<String>.from(json['recentBusinessIds'] ?? []),
      favorites: (json['favorites'] as List<dynamic>? ?? [])
          .map((f) => CustomerFavorite.fromJson(f))
          .toList(),
      orderHistory: (json['orderHistory'] as List<dynamic>? ?? [])
          .map((o) => CustomerOrder.fromJson(o))
          .toList(),
      addresses: (json['addresses'] as List<dynamic>? ?? [])
          .map((a) => CustomerAddress.fromJson(a))
          .toList(),
      paymentMethods: (json['paymentMethods'] as List<dynamic>? ?? [])
          .map((p) => CustomerPaymentInfo.fromJson(p))
          .toList(),
      lastOrderAt: json['lastOrderAt'] != null ? DateTime.parse(json['lastOrderAt']) : null,
      totalOrders: json['totalOrders'] ?? 0,
      totalSpent: (json['totalSpent'] ?? 0.0).toDouble(),
      isPremium: json['isPremium'] ?? false,
      premiumExpiry: json['premiumExpiry'] != null ? DateTime.parse(json['premiumExpiry']) : null,
    );
  }

  // Alias for fromJson to match the expected method name
  factory CustomerData.fromMap(Map<String, dynamic> map) => CustomerData.fromJson(map);

  Map<String, dynamic> toJson() {
    return {
      'role': role.value,
      'address': address,
      'city': city,
      'district': district,
      'postalCode': postalCode,
      'location': location?.toJson(),
      'preferences': preferences.toJson(),
      'stats': stats.toJson(),
      'favoriteBusinessIds': favoriteBusinessIds,
      'recentBusinessIds': recentBusinessIds,
      'favorites': favorites.map((f) => f.toJson()).toList(),
      'orderHistory': orderHistory.map((o) => o.toJson()).toList(),
      'addresses': addresses.map((a) => a.toJson()).toList(),
      'paymentMethods': paymentMethods.map((p) => p.toJson()).toList(),
      'lastOrderAt': lastOrderAt?.toIso8601String(),
      'totalOrders': totalOrders,
      'totalSpent': totalSpent,
      'isPremium': isPremium,
      'premiumExpiry': premiumExpiry?.toIso8601String(),
    };
  }

  // Alias for toJson to match the expected method name
  Map<String, dynamic> toMap() => toJson();

  CustomerData copyWith({
    CustomerRole? role,
    String? address,
    String? city,
    String? district,
    String? postalCode,
    Coordinates? location,
    CustomerPreferences? preferences,
    CustomerStats? stats,
    List<String>? favoriteBusinessIds,
    List<String>? recentBusinessIds,
    List<CustomerFavorite>? favorites,
    List<CustomerOrder>? orderHistory,
    List<CustomerAddress>? addresses,
    List<CustomerPaymentInfo>? paymentMethods,
    DateTime? lastOrderAt,
    int? totalOrders,
    double? totalSpent,
    bool? isPremium,
    DateTime? premiumExpiry,
  }) {
    return CustomerData(
      role: role ?? this.role,
      address: address ?? this.address,
      city: city ?? this.city,
      district: district ?? this.district,
      postalCode: postalCode ?? this.postalCode,
      location: location ?? this.location,
      preferences: preferences ?? this.preferences,
      stats: stats ?? this.stats,
      favoriteBusinessIds: favoriteBusinessIds ?? this.favoriteBusinessIds,
      recentBusinessIds: recentBusinessIds ?? this.recentBusinessIds,
      favorites: favorites ?? this.favorites,
      orderHistory: orderHistory ?? this.orderHistory,
      addresses: addresses ?? this.addresses,
      paymentMethods: paymentMethods ?? this.paymentMethods,
      lastOrderAt: lastOrderAt ?? this.lastOrderAt,
      totalOrders: totalOrders ?? this.totalOrders,
      totalSpent: totalSpent ?? this.totalSpent,
      isPremium: isPremium ?? this.isPremium,
      premiumExpiry: premiumExpiry ?? this.premiumExpiry,
    );
  }
}

class CustomerPreferences {
  final bool pushNotifications;
  final bool emailNotifications;
  final bool smsNotifications;
  final String language;
  final String currency;
  final bool darkMode;
  final double maxDeliveryDistance;
  final List<String> dietaryRestrictions;
  final List<String> favoriteCategories;

  const CustomerPreferences({
    this.pushNotifications = true,
    this.emailNotifications = true,
    this.smsNotifications = false,
    this.language = 'tr',
    this.currency = 'TRY',
    this.darkMode = false,
    this.maxDeliveryDistance = 10.0,
    this.dietaryRestrictions = const [],
    this.favoriteCategories = const [],
  });

  factory CustomerPreferences.fromJson(Map<String, dynamic> json) {
    return CustomerPreferences(
      pushNotifications: json['pushNotifications'] ?? true,
      emailNotifications: json['emailNotifications'] ?? true,
      smsNotifications: json['smsNotifications'] ?? false,
      language: json['language'] ?? 'tr',
      currency: json['currency'] ?? 'TRY',
      darkMode: json['darkMode'] ?? false,
      maxDeliveryDistance: (json['maxDeliveryDistance'] ?? 10.0).toDouble(),
      dietaryRestrictions: List<String>.from(json['dietaryRestrictions'] ?? []),
      favoriteCategories: List<String>.from(json['favoriteCategories'] ?? []),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'pushNotifications': pushNotifications,
      'emailNotifications': emailNotifications,
      'smsNotifications': smsNotifications,
      'language': language,
      'currency': currency,
      'darkMode': darkMode,
      'maxDeliveryDistance': maxDeliveryDistance,
      'dietaryRestrictions': dietaryRestrictions,
      'favoriteCategories': favoriteCategories,
    };
  }

  // Alias for toJson to match the expected method name
  Map<String, dynamic> toMap() => toJson();
}

class CustomerStats {
  final int totalOrders;
  final double totalSpent;
  final int favoriteBusinesses;
  final int favoriteBusinessCount;
  final int totalVisits;
  final int reviewsGiven;
  final double averageRating;
  final DateTime? firstOrderAt;
  final DateTime? lastOrderAt;
  final Map<String, int> categoryPreferences;
  final Map<String, double> businessSpending;

  const CustomerStats({
    this.totalOrders = 0,
    this.totalSpent = 0.0,
    this.favoriteBusinesses = 0,
    this.favoriteBusinessCount = 0,
    this.totalVisits = 0,
    this.reviewsGiven = 0,
    this.averageRating = 0.0,
    this.firstOrderAt,
    this.lastOrderAt,
    this.categoryPreferences = const {},
    this.businessSpending = const {},
  });

  factory CustomerStats.fromJson(Map<String, dynamic> json) {
    return CustomerStats(
      totalOrders: json['totalOrders'] ?? 0,
      totalSpent: (json['totalSpent'] ?? 0.0).toDouble(),
      favoriteBusinesses: json['favoriteBusinesses'] ?? 0,
      favoriteBusinessCount: json['favoriteBusinessCount'] ?? 0,
      totalVisits: json['totalVisits'] ?? 0,
      reviewsGiven: json['reviewsGiven'] ?? 0,
      averageRating: (json['averageRating'] ?? 0.0).toDouble(),
      firstOrderAt: json['firstOrderAt'] != null ? DateTime.parse(json['firstOrderAt']) : null,
      lastOrderAt: json['lastOrderAt'] != null ? DateTime.parse(json['lastOrderAt']) : null,
      categoryPreferences: Map<String, int>.from(json['categoryPreferences'] ?? {}),
      businessSpending: Map<String, double>.from(json['businessSpending'] ?? {}),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'totalOrders': totalOrders,
      'totalSpent': totalSpent,
      'favoriteBusinesses': favoriteBusinesses,
      'favoriteBusinessCount': favoriteBusinessCount,
      'totalVisits': totalVisits,
      'reviewsGiven': reviewsGiven,
      'averageRating': averageRating,
      'firstOrderAt': firstOrderAt?.toIso8601String(),
      'lastOrderAt': lastOrderAt?.toIso8601String(),
      'categoryPreferences': categoryPreferences,
      'businessSpending': businessSpending,
    };
  }
}

// =============================================================================
// BUSINESS DATA
// =============================================================================

class BusinessData {
  final BusinessRole role;
  final List<BusinessPermission> permissions;
  final List<String> businessIds;
  final BusinessStats stats;
  final BusinessSettings settings;
  final List<String> staffIds;
  final List<String> managedCategoryIds;

  BusinessData({
    this.role = BusinessRole.staff,
    this.permissions = const [],
    this.businessIds = const [],
    required this.stats,
    required this.settings,
    this.staffIds = const [],
    this.managedCategoryIds = const [],
  });

  factory BusinessData.fromJson(Map<String, dynamic> json) {
    return BusinessData(
      role: BusinessRole.fromString(json['role'] ?? 'staff'),
      permissions: (json['permissions'] as List<dynamic>? ?? [])
          .map((perm) => BusinessPermission.fromString(perm))
          .toList(),
      businessIds: List<String>.from(json['businessIds'] ?? []),
      stats: BusinessStats.fromJson(json['stats'] ?? {}),
      settings: BusinessSettings.fromJson(json['settings'] ?? {}),
      staffIds: List<String>.from(json['staffIds'] ?? []),
      managedCategoryIds: List<String>.from(json['managedCategoryIds'] ?? []),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'role': role.value,
      'permissions': permissions.map((p) => p.value).toList(),
      'businessIds': businessIds,
      'stats': stats.toJson(),
      'settings': settings.toJson(),
      'staffIds': staffIds,
      'managedCategoryIds': managedCategoryIds,
    };
  }

  // Permission checking
  bool hasPermission(BusinessPermission permission) {
    if (role == BusinessRole.owner) return true;
    return permissions.contains(permission);
  }

  bool hasAnyPermission(List<BusinessPermission> requiredPermissions) {
    if (role == BusinessRole.owner) return true;
    return requiredPermissions.any((perm) => permissions.contains(perm));
  }

  bool hasAllPermissions(List<BusinessPermission> requiredPermissions) {
    if (role == BusinessRole.owner) return true;
    return requiredPermissions.every((perm) => permissions.contains(perm));
  }

  BusinessData copyWith({
    BusinessRole? role,
    List<BusinessPermission>? permissions,
    List<String>? businessIds,
    BusinessStats? stats,
    BusinessSettings? settings,
    List<String>? staffIds,
    List<String>? managedCategoryIds,
  }) {
    return BusinessData(
      role: role ?? this.role,
      permissions: permissions ?? this.permissions,
      businessIds: businessIds ?? this.businessIds,
      stats: stats ?? this.stats,
      settings: settings ?? this.settings,
      staffIds: staffIds ?? this.staffIds,
      managedCategoryIds: managedCategoryIds ?? this.managedCategoryIds,
    );
  }
}

// =============================================================================
// ADMIN DATA
// =============================================================================

class AdminData {
  final AdminRole role;
  final List<AdminPermission> permissions;
  final AdminStats stats;
  final AdminSettings settings;
  final List<String> managedBusinessIds;
  final List<String> managedCustomerIds;

  AdminData({
    this.role = AdminRole.support,
    this.permissions = const [],
    required this.stats,
    required this.settings,
    this.managedBusinessIds = const [],
    this.managedCustomerIds = const [],
  });

  factory AdminData.fromJson(Map<String, dynamic> json) {
    return AdminData(
      role: AdminRole.fromString(json['role'] ?? 'support'),
      permissions: (json['permissions'] as List<dynamic>? ?? [])
          .map((perm) => AdminPermission.fromString(perm))
          .toList(),
      stats: AdminStats.fromJson(json['stats'] ?? {}),
      settings: AdminSettings.fromJson(json['settings'] ?? {}),
      managedBusinessIds: List<String>.from(json['managedBusinessIds'] ?? []),
      managedCustomerIds: List<String>.from(json['managedCustomerIds'] ?? []),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'role': role.value,
      'permissions': permissions.map((p) => p.value).toList(),
      'stats': stats.toJson(),
      'settings': settings.toJson(),
      'managedBusinessIds': managedBusinessIds,
      'managedCustomerIds': managedCustomerIds,
    };
  }

  // Permission checking
  bool hasPermission(AdminPermission permission) {
    if (role == AdminRole.superAdmin) return true;
    return permissions.contains(permission);
  }

  bool hasAnyPermission(List<AdminPermission> requiredPermissions) {
    if (role == AdminRole.superAdmin) return true;
    return requiredPermissions.any((perm) => permissions.contains(perm));
  }

  bool hasAllPermissions(List<AdminPermission> requiredPermissions) {
    if (role == AdminRole.superAdmin) return true;
    return requiredPermissions.every((perm) => permissions.contains(perm));
  }

  AdminData copyWith({
    AdminRole? role,
    List<AdminPermission>? permissions,
    AdminStats? stats,
    AdminSettings? settings,
    List<String>? managedBusinessIds,
    List<String>? managedCustomerIds,
  }) {
    return AdminData(
      role: role ?? this.role,
      permissions: permissions ?? this.permissions,
      stats: stats ?? this.stats,
      settings: settings ?? this.settings,
      managedBusinessIds: managedBusinessIds ?? this.managedBusinessIds,
      managedCustomerIds: managedCustomerIds ?? this.managedCustomerIds,
    );
  }
}

class AdminStats {
  final int totalUsers;
  final int totalBusinesses;
  final int totalOrders;
  final int totalRevenue;
  final int totalAdmins;
  final int totalCustomers;
  final DateTime? lastActivityAt;

  const AdminStats({
    this.totalUsers = 0,
    this.totalBusinesses = 0,
    this.totalOrders = 0,
    this.totalRevenue = 0,
    this.totalAdmins = 0,
    this.totalCustomers = 0,
    this.lastActivityAt,
  });

  factory AdminStats.fromJson(Map<String, dynamic> json) {
    return AdminStats(
      totalUsers: json['totalUsers'] ?? 0,
      totalBusinesses: json['totalBusinesses'] ?? 0,
      totalOrders: json['totalOrders'] ?? 0,
      totalRevenue: json['totalRevenue'] ?? 0,
      totalAdmins: json['totalAdmins'] ?? 0,
      totalCustomers: json['totalCustomers'] ?? 0,
      lastActivityAt: json['lastActivityAt'] != null ? DateTime.parse(json['lastActivityAt']) : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'totalUsers': totalUsers,
      'totalBusinesses': totalBusinesses,
      'totalOrders': totalOrders,
      'totalRevenue': totalRevenue,
      'totalAdmins': totalAdmins,
      'totalCustomers': totalCustomers,
      'lastActivityAt': lastActivityAt?.toIso8601String(),
    };
  }
}

class AdminSettings {
  final bool emailNotifications;
  final bool pushNotifications;
  final String language;
  final String timezone;
  final bool darkMode;
  final List<String> dashboardWidgets;

  const AdminSettings({
    this.emailNotifications = true,
    this.pushNotifications = true,
    this.language = 'tr',
    this.timezone = 'Europe/Istanbul',
    this.darkMode = false,
    this.dashboardWidgets = const ['users', 'businesses', 'orders', 'revenue'],
  });

  factory AdminSettings.fromJson(Map<String, dynamic> json) {
    return AdminSettings(
      emailNotifications: json['emailNotifications'] ?? true,
      pushNotifications: json['pushNotifications'] ?? true,
      language: json['language'] ?? 'tr',
      timezone: json['timezone'] ?? 'Europe/Istanbul',
      darkMode: json['darkMode'] ?? false,
      dashboardWidgets: List<String>.from(json['dashboardWidgets'] ?? ['users', 'businesses', 'orders', 'revenue']),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'emailNotifications': emailNotifications,
      'pushNotifications': pushNotifications,
      'language': language,
      'timezone': timezone,
      'darkMode': darkMode,
      'dashboardWidgets': dashboardWidgets,
    };
  }
}

// =============================================================================
// SUPPORTING MODELS
// =============================================================================

class Coordinates {
  final double latitude;
  final double longitude;

  const Coordinates({
    required this.latitude,
    required this.longitude,
  });

  factory Coordinates.fromJson(Map<String, dynamic> json) {
    return Coordinates(
      latitude: (json['latitude'] ?? 0.0).toDouble(),
      longitude: (json['longitude'] ?? 0.0).toDouble(),
    );
  }

  Map<String, dynamic> toJson() {
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

// =============================================================================
// CUSTOMER-RELATED MODELS
// =============================================================================

class CustomerOrder {
  final String id;
  final String businessId;
  final String customerId;
  final String businessName;
  final List<OrderItem> items;
  final double totalAmount;
  final String status;
  final DateTime createdAt;
  final DateTime orderDate;
  final DateTime? completedAt;
  final String? notes;
  final String? paymentMethod;
  final bool isPaid;

  CustomerOrder({
    required this.id,
    required this.businessId,
    required this.customerId,
    required this.businessName,
    required this.items,
    required this.totalAmount,
    required this.status,
    required this.createdAt,
    required this.orderDate,
    this.completedAt,
    this.notes,
    this.paymentMethod,
    this.isPaid = false,
  });

  factory CustomerOrder.fromJson(Map<String, dynamic> json) {
    return CustomerOrder(
      id: json['id'] ?? '',
      businessId: json['businessId'] ?? '',
      customerId: json['customerId'] ?? '',
      businessName: json['businessName'] ?? '',
      items: (json['items'] as List<dynamic>? ?? [])
          .map((item) => OrderItem.fromJson(item))
          .toList(),
      totalAmount: (json['totalAmount'] ?? 0.0).toDouble(),
      status: json['status'] ?? 'pending',
      createdAt: DateTime.parse(json['createdAt'] ?? DateTime.now().toIso8601String()),
      orderDate: DateTime.parse(json['orderDate'] ?? DateTime.now().toIso8601String()),
      completedAt: json['completedAt'] != null ? DateTime.parse(json['completedAt']) : null,
      notes: json['notes'],
      paymentMethod: json['paymentMethod'],
      isPaid: json['isPaid'] ?? false,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'businessId': businessId,
      'customerId': customerId,
      'businessName': businessName,
      'items': items.map((item) => item.toJson()).toList(),
      'totalAmount': totalAmount,
      'status': status,
      'createdAt': createdAt.toIso8601String(),
      'orderDate': orderDate.toIso8601String(),
      'completedAt': completedAt?.toIso8601String(),
      'notes': notes,
      'paymentMethod': paymentMethod,
      'isPaid': isPaid,
    };
  }

  // Alias for toJson to match the expected method name
  Map<String, dynamic> toMap() => toJson();
}

class OrderItem {
  final String productId;
  final String productName;
  final int quantity;
  final double unitPrice;
  final double totalPrice;
  final String? notes;

  OrderItem({
    required this.productId,
    required this.productName,
    required this.quantity,
    required this.unitPrice,
    required this.totalPrice,
    this.notes,
  });

  factory OrderItem.fromJson(Map<String, dynamic> json) {
    return OrderItem(
      productId: json['productId'] ?? '',
      productName: json['productName'] ?? '',
      quantity: json['quantity'] ?? 1,
      unitPrice: (json['unitPrice'] ?? 0.0).toDouble(),
      totalPrice: (json['totalPrice'] ?? 0.0).toDouble(),
      notes: json['notes'],
    );
  }

  Map<String, dynamic> toJson() {
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

class CustomerFavorite {
  final String id;
  final String businessId;
  final String customerId;
  final DateTime createdAt;
  final String? businessName;
  final String? businessType;
  final String? businessLogo;
  final int visitCount;
  final double totalSpent;
  final DateTime? addedDate;

  CustomerFavorite({
    required this.id,
    required this.businessId,
    required this.customerId,
    required this.createdAt,
    this.businessName,
    this.businessType,
    this.businessLogo,
    this.visitCount = 0,
    this.totalSpent = 0.0,
    this.addedDate,
  });

  factory CustomerFavorite.fromJson(Map<String, dynamic> json) {
    return CustomerFavorite(
      id: json['id'] ?? '',
      businessId: json['businessId'] ?? '',
      customerId: json['customerId'] ?? '',
      createdAt: DateTime.parse(json['createdAt'] ?? DateTime.now().toIso8601String()),
      businessName: json['businessName'],
      businessType: json['businessType'],
      businessLogo: json['businessLogo'],
      visitCount: json['visitCount'] ?? 0,
      totalSpent: (json['totalSpent'] ?? 0.0).toDouble(),
      addedDate: json['addedDate'] != null ? DateTime.parse(json['addedDate']) : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'businessId': businessId,
      'customerId': customerId,
      'createdAt': createdAt.toIso8601String(),
      'businessName': businessName,
      'businessType': businessType,
      'businessLogo': businessLogo,
      'visitCount': visitCount,
      'totalSpent': totalSpent,
      'addedDate': addedDate?.toIso8601String(),
    };
  }

  // Alias for toJson to match the expected method name
  Map<String, dynamic> toMap() => toJson();
}

class CustomerVisit {
  final String id;
  final String businessId;
  final String customerId;
  final DateTime visitedAt;
  final int visitDuration; // in minutes
  final String? visitPurpose;
  final double? amountSpent;

  CustomerVisit({
    required this.id,
    required this.businessId,
    required this.customerId,
    required this.visitedAt,
    this.visitDuration = 0,
    this.visitPurpose,
    this.amountSpent,
  });

  factory CustomerVisit.fromJson(Map<String, dynamic> json) {
    return CustomerVisit(
      id: json['id'] ?? '',
      businessId: json['businessId'] ?? '',
      customerId: json['customerId'] ?? '',
      visitedAt: DateTime.parse(json['visitedAt'] ?? DateTime.now().toIso8601String()),
      visitDuration: json['visitDuration'] ?? 0,
      visitPurpose: json['visitPurpose'],
      amountSpent: json['amountSpent']?.toDouble(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'businessId': businessId,
      'customerId': customerId,
      'visitedAt': visitedAt.toIso8601String(),
      'visitDuration': visitDuration,
      'visitPurpose': visitPurpose,
      'amountSpent': amountSpent,
    };
  }

  // Alias for toJson to match the expected method name
  Map<String, dynamic> toMap() => toJson();
}

class CustomerAddress {
  final String id;
  final String customerId;
  final String title;
  final String fullAddress;
  final String? apartment;
  final String? floor;
  final String? building;
  final Coordinates? coordinates;
  final bool isDefault;
  final DateTime createdAt;

  CustomerAddress({
    required this.id,
    required this.customerId,
    required this.title,
    required this.fullAddress,
    this.apartment,
    this.floor,
    this.building,
    this.coordinates,
    this.isDefault = false,
    required this.createdAt,
  });

  factory CustomerAddress.fromJson(Map<String, dynamic> json) {
    return CustomerAddress(
      id: json['id'] ?? '',
      customerId: json['customerId'] ?? '',
      title: json['title'] ?? '',
      fullAddress: json['fullAddress'] ?? '',
      apartment: json['apartment'],
      floor: json['floor'],
      building: json['building'],
      coordinates: json['coordinates'] != null ? Coordinates.fromJson(json['coordinates']) : null,
      isDefault: json['isDefault'] ?? false,
      createdAt: DateTime.parse(json['createdAt'] ?? DateTime.now().toIso8601String()),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'customerId': customerId,
      'title': title,
      'fullAddress': fullAddress,
      'apartment': apartment,
      'floor': floor,
      'building': building,
      'coordinates': coordinates?.toJson(),
      'isDefault': isDefault,
      'createdAt': createdAt.toIso8601String(),
    };
  }

  // Alias for toJson to match the expected method name
  Map<String, dynamic> toMap() => toJson();
}

class CustomerPaymentInfo {
  final String id;
  final String customerId;
  final String cardType;
  final String lastFourDigits;
  final String cardholderName;
  final DateTime expiryDate;
  final bool isDefault;
  final DateTime createdAt;

  CustomerPaymentInfo({
    required this.id,
    required this.customerId,
    required this.cardType,
    required this.lastFourDigits,
    required this.cardholderName,
    required this.expiryDate,
    this.isDefault = false,
    required this.createdAt,
  });

  factory CustomerPaymentInfo.fromJson(Map<String, dynamic> json) {
    return CustomerPaymentInfo(
      id: json['id'] ?? '',
      customerId: json['customerId'] ?? '',
      cardType: json['cardType'] ?? '',
      lastFourDigits: json['lastFourDigits'] ?? '',
      cardholderName: json['cardholderName'] ?? '',
      expiryDate: DateTime.parse(json['expiryDate'] ?? DateTime.now().toIso8601String()),
      isDefault: json['isDefault'] ?? false,
      createdAt: DateTime.parse(json['createdAt'] ?? DateTime.now().toIso8601String()),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'customerId': customerId,
      'cardType': cardType,
      'lastFourDigits': lastFourDigits,
      'cardholderName': cardholderName,
      'expiryDate': expiryDate.toIso8601String(),
      'isDefault': isDefault,
      'createdAt': createdAt.toIso8601String(),
    };
  }

  // Alias for toJson to match the expected method name
  Map<String, dynamic> toMap() => toJson();
}
 