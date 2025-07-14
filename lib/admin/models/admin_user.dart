import 'package:cloud_firestore/cloud_firestore.dart';

enum AdminRole {
  superAdmin,
  systemAdmin,
  admin,
  moderator,
  support,
}

enum AdminPermission {
  // User Management
  viewUsers,
  createUsers,
  editUsers,
  deleteUsers,
  viewCustomers,
  editCustomers,
  
  // Business Management
  viewBusinesses,
  createBusinesses,
  editBusinesses,
  deleteBusinesses,
  approveBusinesses,
  
  // Order Management
  viewOrders,
  editOrders,
  deleteOrders,
  
  // System Management
  viewAnalytics,
  manageSystemSettings,
  viewActivityLogs,
  manageAdminUsers,
  manageAdmins,
  manageSystem,
  viewAuditLogs,
  
  // Content Management
  moderateContent,
  manageCategories,
  manageProducts,
  
  // Reports
  viewReports,
}

extension AdminRoleExtension on AdminRole {
  String get displayName {
    switch (this) {
      case AdminRole.superAdmin:
        return 'Super Admin';
      case AdminRole.systemAdmin:
        return 'System Admin';
      case AdminRole.admin:
        return 'Admin';
      case AdminRole.moderator:
        return 'Moderator';
      case AdminRole.support:
        return 'Support';
    }
  }

  String get value {
    return toString().split('.').last;
  }
}

extension AdminPermissionExtension on AdminPermission {
  String get displayName {
    switch (this) {
      case AdminPermission.viewUsers:
        return 'View Users';
      case AdminPermission.createUsers:
        return 'Create Users';
      case AdminPermission.editUsers:
        return 'Edit Users';
      case AdminPermission.deleteUsers:
        return 'Delete Users';
      case AdminPermission.viewCustomers:
        return 'View Customers';
      case AdminPermission.editCustomers:
        return 'Edit Customers';
      case AdminPermission.viewBusinesses:
        return 'View Businesses';
      case AdminPermission.createBusinesses:
        return 'Create Businesses';
      case AdminPermission.editBusinesses:
        return 'Edit Businesses';
      case AdminPermission.deleteBusinesses:
        return 'Delete Businesses';
      case AdminPermission.approveBusinesses:
        return 'Approve Businesses';
      case AdminPermission.viewOrders:
        return 'View Orders';
      case AdminPermission.editOrders:
        return 'Edit Orders';
      case AdminPermission.deleteOrders:
        return 'Delete Orders';
      case AdminPermission.viewAnalytics:
        return 'View Analytics';
      case AdminPermission.manageSystemSettings:
        return 'Manage System Settings';
      case AdminPermission.viewActivityLogs:
        return 'View Activity Logs';
      case AdminPermission.manageAdminUsers:
        return 'Manage Admin Users';
      case AdminPermission.manageAdmins:
        return 'Manage Admins';
      case AdminPermission.manageSystem:
        return 'Manage System';
      case AdminPermission.viewAuditLogs:
        return 'View Audit Logs';
      case AdminPermission.moderateContent:
        return 'Moderate Content';
      case AdminPermission.manageCategories:
        return 'Manage Categories';
      case AdminPermission.manageProducts:
        return 'Manage Products';
      case AdminPermission.viewReports:
        return 'View Reports';
    }
  }

  String get value {
    return toString().split('.').last;
  }
}

class AdminUser {
  final String id;
  final String email;
  final String name;
  final AdminRole role;
  final List<AdminPermission> permissions;
  final DateTime createdAt;
  final DateTime? lastLoginAt;
  final bool isActive;
  final String? avatarUrl;

  AdminUser({
    required this.id,
    required this.email,
    required this.name,
    required this.role,
    required this.permissions,
    required this.createdAt,
    this.lastLoginAt,
    required this.isActive,
    this.avatarUrl,
  });

  // Getters for compatibility with admin pages
  String get displayName => name;
  String get username => email.split('@').first;
  String get fullName => name;
  String get adminId => id;
  String get initials {
    final nameParts = name.split(' ');
    if (nameParts.length >= 2) {
      return '${nameParts[0][0]}${nameParts[1][0]}'.toUpperCase();
    }
    return name.isNotEmpty ? name[0].toUpperCase() : 'A';
  }
  bool get isSuperAdmin => role == AdminRole.superAdmin;

  factory AdminUser.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return AdminUser(
      id: doc.id,
      email: data['email'] ?? '',
      name: data['name'] ?? '',
      role: AdminRole.values.firstWhere(
        (role) => role.toString().split('.').last == data['role'],
        orElse: () => AdminRole.support,
      ),
      permissions: (data['permissions'] as List<dynamic>?)
          ?.map((permission) => AdminPermission.values.firstWhere(
                (perm) => perm.toString().split('.').last == permission,
                orElse: () => AdminPermission.viewUsers,
              ))
          .toList() ?? [],
      createdAt: (data['createdAt'] as Timestamp).toDate(),
      lastLoginAt: data['lastLoginAt'] != null
          ? (data['lastLoginAt'] as Timestamp).toDate()
          : null,
      isActive: data['isActive'] ?? true,
      avatarUrl: data['avatarUrl'],
    );
  }

  factory AdminUser.fromJson(Map<String, dynamic> json) {
    return AdminUser(
      id: json['id'] ?? '',
      email: json['email'] ?? '',
      name: json['name'] ?? '',
      role: AdminRole.values.firstWhere(
        (role) => role.toString().split('.').last == json['role'],
        orElse: () => AdminRole.support,
      ),
      permissions: (json['permissions'] as List<dynamic>?)
          ?.map((permission) => AdminPermission.values.firstWhere(
                (perm) => perm.toString().split('.').last == permission,
                orElse: () => AdminPermission.viewUsers,
              ))
          .toList() ?? [],
      createdAt: DateTime.parse(json['createdAt']),
      lastLoginAt: json['lastLoginAt'] != null
          ? DateTime.parse(json['lastLoginAt'])
          : null,
      isActive: json['isActive'] ?? true,
      avatarUrl: json['avatarUrl'],
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'email': email,
      'name': name,
      'role': role.toString().split('.').last,
      'permissions': permissions
          .map((permission) => permission.toString().split('.').last)
          .toList(),
      'createdAt': Timestamp.fromDate(createdAt),
      'lastLoginAt': lastLoginAt != null ? Timestamp.fromDate(lastLoginAt!) : null,
      'isActive': isActive,
      'avatarUrl': avatarUrl,
    };
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'email': email,
      'name': name,
      'role': role.toString().split('.').last,
      'permissions': permissions
          .map((permission) => permission.toString().split('.').last)
          .toList(),
      'createdAt': createdAt.toIso8601String(),
      'lastLoginAt': lastLoginAt?.toIso8601String(),
      'isActive': isActive,
      'avatarUrl': avatarUrl,
    };
  }

  AdminUser copyWith({
    String? id,
    String? email,
    String? name,
    AdminRole? role,
    List<AdminPermission>? permissions,
    DateTime? createdAt,
    DateTime? lastLoginAt,
    bool? isActive,
    String? avatarUrl,
  }) {
    return AdminUser(
      id: id ?? this.id,
      email: email ?? this.email,
      name: name ?? this.name,
      role: role ?? this.role,
      permissions: permissions ?? this.permissions,
      createdAt: createdAt ?? this.createdAt,
      lastLoginAt: lastLoginAt ?? this.lastLoginAt,
      isActive: isActive ?? this.isActive,
      avatarUrl: avatarUrl ?? this.avatarUrl,
    );
  }

  bool hasPermission(AdminPermission permission) {
    return permissions.contains(permission);
  }

  bool hasAnyPermission(List<AdminPermission> requiredPermissions) {
    return requiredPermissions.any((permission) => hasPermission(permission));
  }

  bool hasAllPermissions(List<AdminPermission> requiredPermissions) {
    return requiredPermissions.every((permission) => hasPermission(permission));
  }

  @override
  String toString() {
    return 'AdminUser(id: $id, email: $email, name: $name, role: $role)';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is AdminUser && other.id == id;
  }

  @override
  int get hashCode => id.hashCode;
} 