import 'package:cloud_firestore/cloud_firestore.dart';
import '../../data/models/business.dart';

class BusinessUser {
  final String businessId;
  final String username;
  final String email;
  final String fullName;
  final String? avatarUrl;
  final BusinessRole role;
  final List<BusinessPermission> permissions;
  final bool isActive;
  final bool isOwner;
  final DateTime lastLoginAt;
  final DateTime createdAt;
  final DateTime updatedAt;
  final String? lastLoginIp;
  final String? sessionToken;
  final String? businessName;
  final String? businessAddress;
  final String? businessPhone;

  BusinessUser({
    required this.businessId,
    required this.username,
    required this.email,
    required this.fullName,
    this.avatarUrl,
    required this.role,
    required this.permissions,
    required this.isActive,
    required this.isOwner,
    required this.lastLoginAt,
    required this.createdAt,
    required this.updatedAt,
    this.lastLoginIp,
    this.sessionToken,
    this.businessName,
    this.businessAddress,
    this.businessPhone,
  });

  factory BusinessUser.fromJson(Map<String, dynamic> data, {String? id}) {
    return BusinessUser(
      businessId: id ?? data['businessId'] ?? '',
      username: data['username'] ?? '',
      email: data['email'] ?? '',
      fullName: data['fullName'] ?? '',
      avatarUrl: data['avatarUrl'],
      role: BusinessRole.fromString(data['role'] ?? 'staff'),
      permissions: (data['permissions'] as List<dynamic>? ?? [])
          .map((perm) => BusinessPermission.fromString(perm))
          .toList(),
      isActive: data['isActive'] ?? true,
      isOwner: data['isOwner'] ?? false,
      lastLoginAt: _parseDateTime(data['lastLoginAt']),
      createdAt: _parseDateTime(data['createdAt']),
      updatedAt: _parseDateTime(data['updatedAt']),
      lastLoginIp: data['lastLoginIp'],
      sessionToken: data['sessionToken'],
      businessName: data['businessName'],
      businessAddress: data['businessAddress'],
      businessPhone: data['businessPhone'],
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
      'username': username,
      'email': email,
      'fullName': fullName,
      'avatarUrl': avatarUrl,
      'role': role.value,
      'permissions': permissions.map((p) => p.value).toList(),
      'isActive': isActive,
      'isOwner': isOwner,
      'lastLoginAt': lastLoginAt.toIso8601String(),
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt.toIso8601String(),
      'lastLoginIp': lastLoginIp,
      'sessionToken': sessionToken,
      'businessName': businessName,
      'businessAddress': businessAddress,
      'businessPhone': businessPhone,
    };
  }

  BusinessUser copyWith({
    String? businessId,
    String? username,
    String? email,
    String? fullName,
    String? avatarUrl,
    BusinessRole? role,
    List<BusinessPermission>? permissions,
    bool? isActive,
    bool? isOwner,
    DateTime? lastLoginAt,
    DateTime? createdAt,
    DateTime? updatedAt,
    String? lastLoginIp,
    String? sessionToken,
    String? businessName,
    String? businessAddress,
    String? businessPhone,
  }) {
    return BusinessUser(
      businessId: businessId ?? this.businessId,
      username: username ?? this.username,
      email: email ?? this.email,
      fullName: fullName ?? this.fullName,
      avatarUrl: avatarUrl ?? this.avatarUrl,
      role: role ?? this.role,
      permissions: permissions ?? this.permissions,
      isActive: isActive ?? this.isActive,
      isOwner: isOwner ?? this.isOwner,
      lastLoginAt: lastLoginAt ?? this.lastLoginAt,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      lastLoginIp: lastLoginIp ?? this.lastLoginIp,
      sessionToken: sessionToken ?? this.sessionToken,
      businessName: businessName ?? this.businessName,
      businessAddress: businessAddress ?? this.businessAddress,
      businessPhone: businessPhone ?? this.businessPhone,
    );
  }

  // Helper methods
  bool hasPermission(BusinessPermission permission) {
    if (isOwner) return true;
    return permissions.contains(permission);
  }

  bool hasAnyPermission(List<BusinessPermission> requiredPermissions) {
    if (isOwner) return true;
    return requiredPermissions.any((perm) => permissions.contains(perm));
  }

  bool hasAllPermissions(List<BusinessPermission> requiredPermissions) {
    if (isOwner) return true;
    return requiredPermissions.every((perm) => permissions.contains(perm));
  }

  String get displayName => fullName.isNotEmpty ? fullName : username;
  String get initials => fullName.split(' ').take(2).map((n) => n.isNotEmpty ? n[0] : '').join('').toUpperCase();

  @override
  String toString() {
    return 'BusinessUser(businessId: $businessId, username: $username, role: $role, isActive: $isActive)';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is BusinessUser && other.businessId == businessId;
  }

  @override
  int get hashCode => businessId.hashCode;
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

enum BusinessPermission {
  // Menu Management
  viewMenu('view_menu', 'Menüyü Görüntüle'),
  editMenu('edit_menu', 'Menüyü Düzenle'),
  addProducts('add_products', 'Ürün Ekle'),
  editProducts('edit_products', 'Ürün Düzenle'),
  deleteProducts('delete_products', 'Ürün Sil'),
  manageCategories('manage_categories', 'Kategori Yönetimi'),

  // Order Management
  viewOrders('view_orders', 'Siparişleri Görüntüle'),
  editOrders('edit_orders', 'Siparişleri Düzenle'),
  cancelOrders('cancel_orders', 'Siparişleri İptal Et'),
  manageOrders('manage_orders', 'Sipariş Yönetimi'),

  // Business Management
  viewBusinessInfo('view_business_info', 'İşletme Bilgilerini Görüntüle'),
  editBusinessInfo('edit_business_info', 'İşletme Bilgilerini Düzenle'),
  manageSettings('manage_settings', 'Ayarları Yönet'),
  viewAnalytics('view_analytics', 'Analitikleri Görüntüle'),

  // Staff Management
  viewStaff('view_staff', 'Personeli Görüntüle'),
  manageStaff('manage_staff', 'Personel Yönetimi'),
  assignRoles('assign_roles', 'Rol Atama'),

  // Financial Management
  viewSales('view_sales', 'Satışları Görüntüle'),
  viewReports('view_reports', 'Raporları Görüntüle'),
  managePricing('manage_pricing', 'Fiyatlandırma Yönetimi'),

  // QR Code Management
  manageQRCodes('manage_qr_codes', 'QR Kod Yönetimi'),
  generateQRCodes('generate_qr_codes', 'QR Kod Oluştur'),

  // Discount Management
  manageDiscounts('manage_discounts', 'İndirim Yönetimi'),
  createDiscounts('create_discounts', 'İndirim Oluştur'),
  editDiscounts('edit_discounts', 'İndirim Düzenle');

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

// Default business user for initial setup
class BusinessDefaults {
  static final MenuSettings defaultMenuSettings = MenuSettings.defaultRestaurant();

  static BusinessUser createOwner({
    required String businessId,
    required String username,
    required String email,
    required String fullName,
    String? businessName,
    String? businessAddress,
    String? businessPhone,
  }) {
    return BusinessUser(
      businessId: businessId,
      username: username,
      email: email,
      fullName: fullName,
      role: BusinessRole.owner,
      permissions: BusinessPermission.values.toList(),
      isActive: true,
      isOwner: true,
      lastLoginAt: DateTime.now(),
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
      businessName: businessName,
      businessAddress: businessAddress,
      businessPhone: businessPhone,
    );
  }

  static BusinessUser createManager({
    required String businessId,
    required String username,
    required String email,
    required String fullName,
  }) {
    return BusinessUser(
      businessId: businessId,
      username: username,
      email: email,
      fullName: fullName,
      role: BusinessRole.manager,
      permissions: [
        BusinessPermission.viewMenu,
        BusinessPermission.editMenu,
        BusinessPermission.addProducts,
        BusinessPermission.editProducts,
        BusinessPermission.viewOrders,
        BusinessPermission.editOrders,
        BusinessPermission.viewBusinessInfo,
        BusinessPermission.viewAnalytics,
        BusinessPermission.viewSales,
        BusinessPermission.viewReports,
        BusinessPermission.manageQRCodes,
        BusinessPermission.manageDiscounts,
      ],
      isActive: true,
      isOwner: false,
      lastLoginAt: DateTime.now(),
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
    );
  }
} 