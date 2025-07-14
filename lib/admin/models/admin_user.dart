import 'package:cloud_firestore/cloud_firestore.dart';

class AdminUser {
  final String adminId;
  final String username;
  final String email;
  final String fullName;
  final String? avatarUrl;
  final AdminRole role;
  final List<AdminPermission> permissions;
  final bool isActive;
  final bool isSuperAdmin;
  final DateTime lastLoginAt;
  final DateTime createdAt;
  final DateTime updatedAt;
  final String? lastLoginIp;
  final String? sessionToken;

  AdminUser({
    required this.adminId,
    required this.username,
    required this.email,
    required this.fullName,
    this.avatarUrl,
    required this.role,
    required this.permissions,
    required this.isActive,
    required this.isSuperAdmin,
    required this.lastLoginAt,
    required this.createdAt,
    required this.updatedAt,
    this.lastLoginIp,
    this.sessionToken,
  });

  factory AdminUser.fromJson(Map<String, dynamic> data, {String? id}) {
    return AdminUser(
      adminId: id ?? data['adminId'] ?? '',
      username: data['username'] ?? '',
      email: data['email'] ?? '',
      fullName: data['fullName'] ?? '',
      avatarUrl: data['avatarUrl'],
      role: AdminRole.fromString(data['role'] ?? 'moderator'),
      permissions: (data['permissions'] as List<dynamic>? ?? [])
          .map((perm) => AdminPermission.fromString(perm))
          .toList(),
      isActive: data['isActive'] ?? true,
      isSuperAdmin: data['isSuperAdmin'] ?? false,
      lastLoginAt: _parseDateTime(data['lastLoginAt']),
      createdAt: _parseDateTime(data['createdAt']),
      updatedAt: _parseDateTime(data['updatedAt']),
      lastLoginIp: data['lastLoginIp'],
      sessionToken: data['sessionToken'],
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
      'adminId': adminId,
      'username': username,
      'email': email,
      'fullName': fullName,
      'avatarUrl': avatarUrl,
      'role': role.value,
      'permissions': permissions.map((p) => p.value).toList(),
      'isActive': isActive,
      'isSuperAdmin': isSuperAdmin,
      'lastLoginAt': lastLoginAt.toIso8601String(),
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt.toIso8601String(),
      'lastLoginIp': lastLoginIp,
      'sessionToken': sessionToken,
    };
  }

  AdminUser copyWith({
    String? adminId,
    String? username,
    String? email,
    String? fullName,
    String? avatarUrl,
    AdminRole? role,
    List<AdminPermission>? permissions,
    bool? isActive,
    bool? isSuperAdmin,
    DateTime? lastLoginAt,
    DateTime? createdAt,
    DateTime? updatedAt,
    String? lastLoginIp,
    String? sessionToken,
  }) {
    return AdminUser(
      adminId: adminId ?? this.adminId,
      username: username ?? this.username,
      email: email ?? this.email,
      fullName: fullName ?? this.fullName,
      avatarUrl: avatarUrl ?? this.avatarUrl,
      role: role ?? this.role,
      permissions: permissions ?? this.permissions,
      isActive: isActive ?? this.isActive,
      isSuperAdmin: isSuperAdmin ?? this.isSuperAdmin,
      lastLoginAt: lastLoginAt ?? this.lastLoginAt,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      lastLoginIp: lastLoginIp ?? this.lastLoginIp,
      sessionToken: sessionToken ?? this.sessionToken,
    );
  }

  // Helper methods
  bool hasPermission(AdminPermission permission) {
    if (isSuperAdmin) return true;
    return permissions.contains(permission);
  }

  bool hasAnyPermission(List<AdminPermission> requiredPermissions) {
    if (isSuperAdmin) return true;
    return requiredPermissions.any((perm) => permissions.contains(perm));
  }

  bool hasAllPermissions(List<AdminPermission> requiredPermissions) {
    if (isSuperAdmin) return true;
    return requiredPermissions.every((perm) => permissions.contains(perm));
  }

  String get displayName => fullName.isNotEmpty ? fullName : username;
  String get initials => fullName.split(' ').take(2).map((n) => n.isNotEmpty ? n[0] : '').join('').toUpperCase();

  @override
  String toString() {
    return 'AdminUser(adminId: $adminId, username: $username, role: $role, isActive: $isActive)';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is AdminUser && other.adminId == adminId;
  }

  @override
  int get hashCode => adminId.hashCode;
}

enum AdminRole {
  superAdmin('super_admin', 'Süper Yönetici', 'Tam sistem kontrolü'),
  admin('admin', 'Yönetici', 'Genel yönetim yetkileri'),
  moderator('moderator', 'Moderatör', 'İçerik moderasyonu'),
  support('support', 'Destek', 'Müşteri desteği');

  const AdminRole(this.value, this.displayName, this.description);

  final String value;
  final String displayName;
  final String description;

  static AdminRole fromString(String value) {
    return AdminRole.values.firstWhere(
      (role) => role.value == value,
      orElse: () => AdminRole.moderator,
    );
  }
}

enum AdminPermission {
  // Business Management
  viewBusinesses('view_businesses', 'İşletmeleri Görüntüle'),
  editBusinesses('edit_businesses', 'İşletmeleri Düzenle'),
  deleteBusinesses('delete_businesses', 'İşletmeleri Sil'),
  suspendBusinesses('suspend_businesses', 'İşletmeleri Askıya Al'),
  approveBusinesses('approve_businesses', 'İşletmeleri Onayla'),

  // Customer Management
  viewCustomers('view_customers', 'Müşterileri Görüntüle'),
  editCustomers('edit_customers', 'Müşterileri Düzenle'),
  deleteCustomers('delete_customers', 'Müşterileri Sil'),
  banCustomers('ban_customers', 'Müşterileri Yasakla'),

  // Content Management
  moderateContent('moderate_content', 'İçerik Modere Et'),
  deleteContent('delete_content', 'İçerik Sil'),
  editContent('edit_content', 'İçerik Düzenle'),
  approveContent('approve_content', 'İçerik Onayla'),

  // System Management
  viewAnalytics('view_analytics', 'Analitikleri Görüntüle'),
  manageSystem('manage_system', 'Sistem Yönetimi'),
  viewLogs('view_logs', 'Logları Görüntüle'),
  manageAdmins('manage_admins', 'Yönetici Yönetimi'),

  // Reports & Monitoring
  viewReports('view_reports', 'Raporları Görüntüle'),
  manageReports('manage_reports', 'Rapor Yönetimi'),
  viewAuditLogs('view_audit_logs', 'Denetim Logları'),

  // Settings & Configuration
  manageSettings('manage_settings', 'Ayarları Yönet'),
  manageCategories('manage_categories', 'Kategori Yönetimi'),
  manageTags('manage_tags', 'Etiket Yönetimi');

  const AdminPermission(this.value, this.displayName);

  final String value;
  final String displayName;

  static AdminPermission fromString(String value) {
    return AdminPermission.values.firstWhere(
      (perm) => perm.value == value,
      orElse: () => AdminPermission.viewBusinesses,
    );
  }
}

// Admin Activity Log
class AdminActivityLog {
  final String logId;
  final String adminId;
  final String adminUsername;
  final String action;
  final String targetType;
  final String targetId;
  final String? details;
  final String? ipAddress;
  final String? userAgent;
  final DateTime createdAt;

  AdminActivityLog({
    required this.logId,
    required this.adminId,
    required this.adminUsername,
    required this.action,
    required this.targetType,
    required this.targetId,
    this.details,
    this.ipAddress,
    this.userAgent,
    required this.createdAt,
  });

  factory AdminActivityLog.fromJson(Map<String, dynamic> data, {String? id}) {
    return AdminActivityLog(
      logId: id ?? data['logId'] ?? '',
      adminId: data['adminId'] ?? '',
      adminUsername: data['adminUsername'] ?? '',
      action: data['action'] ?? '',
      targetType: data['targetType'] ?? '',
      targetId: data['targetId'] ?? '',
      details: data['details'],
      ipAddress: data['ipAddress'],
      userAgent: data['userAgent'],
      createdAt: data['createdAt'] != null
          ? DateTime.parse(data['createdAt'] as String)
          : DateTime.now(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'logId': logId,
      'adminId': adminId,
      'adminUsername': adminUsername,
      'action': action,
      'targetType': targetType,
      'targetId': targetId,
      'details': details,
      'ipAddress': ipAddress,
      'userAgent': userAgent,
      'createdAt': createdAt.toIso8601String(),
    };
  }

  @override
  String toString() {
    return 'AdminActivityLog(adminId: $adminId, action: $action, targetType: $targetType, createdAt: $createdAt)';
  }
}

// Admin Session
class AdminSession {
  final String sessionId;
  final String adminId;
  final String sessionToken;
  final DateTime expiresAt;
  final String ipAddress;
  final String userAgent;
  final bool isActive;
  final DateTime createdAt;

  AdminSession({
    required this.sessionId,
    required this.adminId,
    required this.sessionToken,
    required this.expiresAt,
    required this.ipAddress,
    required this.userAgent,
    required this.isActive,
    required this.createdAt,
  });

  factory AdminSession.fromJson(Map<String, dynamic> data, {String? id}) {
    return AdminSession(
      sessionId: id ?? data['sessionId'] ?? '',
      adminId: data['adminId'] ?? '',
      sessionToken: data['sessionToken'] ?? '',
      expiresAt: data['expiresAt'] != null
          ? DateTime.parse(data['expiresAt'] as String)
          : DateTime.now().add(const Duration(hours: 24)),
      ipAddress: data['ipAddress'] ?? '',
      userAgent: data['userAgent'] ?? '',
      isActive: data['isActive'] ?? true,
      createdAt: data['createdAt'] != null
          ? DateTime.parse(data['createdAt'] as String)
          : DateTime.now(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'sessionId': sessionId,
      'adminId': adminId,
      'sessionToken': sessionToken,
      'expiresAt': expiresAt.toIso8601String(),
      'ipAddress': ipAddress,
      'userAgent': userAgent,
      'isActive': isActive,
      'createdAt': createdAt.toIso8601String(),
    };
  }

  bool get isExpired => DateTime.now().isAfter(expiresAt);
  bool get isValid => isActive && !isExpired;

  @override
  String toString() {
    return 'AdminSession(sessionId: $sessionId, adminId: $adminId, isActive: $isActive, expiresAt: $expiresAt)';
  }
}

// Default admin user for initial setup
class AdminDefaults {
  static AdminUser createSuperAdmin({
    required String adminId,
    required String username,
    required String email,
    required String fullName,
  }) {
    return AdminUser(
      adminId: adminId,
      username: username,
      email: email,
      fullName: fullName,
      role: AdminRole.superAdmin,
      permissions: AdminPermission.values.toList(),
      isActive: true,
      isSuperAdmin: true,
      lastLoginAt: DateTime.now(),
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
    );
  }

  static AdminUser createModerator({
    required String adminId,
    required String username,
    required String email,
    required String fullName,
  }) {
    return AdminUser(
      adminId: adminId,
      username: username,
      email: email,
      fullName: fullName,
      role: AdminRole.moderator,
      permissions: [
        AdminPermission.viewBusinesses,
        AdminPermission.viewCustomers,
        AdminPermission.moderateContent,
        AdminPermission.viewReports,
        AdminPermission.viewAnalytics,
      ],
      isActive: true,
      isSuperAdmin: false,
      lastLoginAt: DateTime.now(),
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
    );
  }
} 