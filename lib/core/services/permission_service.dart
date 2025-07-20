import '../permissions/admin_permissions.dart';
import '../permissions/business_permissions.dart';
import '../enums/user_roles.dart';

/// Centralized permission management service
class PermissionService {
  static final PermissionService _instance = PermissionService._internal();
  factory PermissionService() => _instance;
  PermissionService._internal();

  /// Check if admin has permission
  bool hasAdminPermission(AdminRole role, List<AdminPermission> userPermissions, AdminPermission requiredPermission) {
    // Super admin has all permissions
    if (role == AdminRole.superAdmin) return true;
    
    return userPermissions.contains(requiredPermission);
  }

  /// Check if admin has any of the required permissions
  bool hasAnyAdminPermission(AdminRole role, List<AdminPermission> userPermissions, List<AdminPermission> requiredPermissions) {
    if (role == AdminRole.superAdmin) return true;
    
    return requiredPermissions.any((perm) => userPermissions.contains(perm));
  }

  /// Check if admin has all required permissions
  bool hasAllAdminPermissions(AdminRole role, List<AdminPermission> userPermissions, List<AdminPermission> requiredPermissions) {
    if (role == AdminRole.superAdmin) return true;
    
    return requiredPermissions.every((perm) => userPermissions.contains(perm));
  }

  /// Check if business user has permission
  bool hasBusinessPermission(BusinessRole role, List<BusinessPermission> userPermissions, BusinessPermission requiredPermission) {
    // Owner has all permissions
    if (role == BusinessRole.owner) return true;
    
    return userPermissions.contains(requiredPermission);
  }

  /// Check if business user has any of the required permissions
  bool hasAnyBusinessPermission(BusinessRole role, List<BusinessPermission> userPermissions, List<BusinessPermission> requiredPermissions) {
    if (role == BusinessRole.owner) return true;
    
    return requiredPermissions.any((perm) => userPermissions.contains(perm));
  }

  /// Check if business user has all required permissions
  bool hasAllBusinessPermissions(BusinessRole role, List<BusinessPermission> userPermissions, List<BusinessPermission> requiredPermissions) {
    if (role == BusinessRole.owner) return true;
    
    return requiredPermissions.every((perm) => userPermissions.contains(perm));
  }

  /// Get default permissions for admin role
  List<AdminPermission> getDefaultAdminPermissions(AdminRole role) {
    switch (role) {
      case AdminRole.superAdmin:
        return AdminPermission.values;
      
      case AdminRole.systemAdmin:
        return [
          AdminPermission.viewUsers,
          AdminPermission.editUsers,
          AdminPermission.viewBusinesses,
          AdminPermission.editBusinesses,
          AdminPermission.approveBusinesses,
          AdminPermission.viewOrders,
          AdminPermission.viewAnalytics,
          AdminPermission.manageSystemSettings,
          AdminPermission.viewActivityLogs,
          AdminPermission.viewReports,
        ];
      
      case AdminRole.admin:
        return [
          AdminPermission.viewUsers,
          AdminPermission.viewCustomers,
          AdminPermission.viewBusinesses,
          AdminPermission.editBusinesses,
          AdminPermission.approveBusinesses,
          AdminPermission.viewOrders,
          AdminPermission.viewAnalytics,
          AdminPermission.moderateContent,
          AdminPermission.manageCategories,
          AdminPermission.viewReports,
        ];
      
      case AdminRole.moderator:
        return [
          AdminPermission.viewUsers,
          AdminPermission.viewCustomers,
          AdminPermission.viewBusinesses,
          AdminPermission.moderateContent,
          AdminPermission.manageCategories,
          AdminPermission.manageProducts,
        ];
      
      case AdminRole.support:
        return [
          AdminPermission.viewUsers,
          AdminPermission.viewCustomers,
          AdminPermission.viewBusinesses,
          AdminPermission.viewOrders,
        ];
    }
  }

  /// Get default permissions for business role
  List<BusinessPermission> getDefaultBusinessPermissions(BusinessRole role) {
    switch (role) {
      case BusinessRole.owner:
        return BusinessPermission.values;
      
      case BusinessRole.manager:
        return [
          BusinessPermission.viewMenu,
          BusinessPermission.editMenu,
          BusinessPermission.addProducts,
          BusinessPermission.editProducts,
          BusinessPermission.deleteProducts,
          BusinessPermission.manageCategories,
          BusinessPermission.viewOrders,
          BusinessPermission.editOrders,
          BusinessPermission.cancelOrders,
          BusinessPermission.viewAnalytics,
          BusinessPermission.manageSettings,
          BusinessPermission.manageStaff,
          BusinessPermission.manageDiscounts,
          BusinessPermission.viewCustomers,
          BusinessPermission.viewReports,
        ];
      
      case BusinessRole.staff:
        return [
          BusinessPermission.viewMenu,
          BusinessPermission.addProducts,
          BusinessPermission.editProducts,
          BusinessPermission.viewOrders,
          BusinessPermission.editOrders,
          BusinessPermission.viewCustomers,
        ];
      
      case BusinessRole.cashier:
        return [
          BusinessPermission.viewMenu,
          BusinessPermission.viewOrders,
          BusinessPermission.editOrders,
          BusinessPermission.managePayments,
          BusinessPermission.viewCustomers,
        ];
    }
  }

  /// Validate permission combinations
  bool isValidPermissionCombination(List<AdminPermission> permissions) {
    // Business logic to ensure permissions make sense together
    // For example, if someone can delete users, they should be able to view users
    if (permissions.contains(AdminPermission.deleteUsers) && 
        !permissions.contains(AdminPermission.viewUsers)) {
      return false;
    }
    
    if (permissions.contains(AdminPermission.editBusinesses) && 
        !permissions.contains(AdminPermission.viewBusinesses)) {
      return false;
    }
    
    return true;
  }

  /// Get permission hierarchy
  Map<AdminPermission, List<AdminPermission>> getAdminPermissionHierarchy() {
    return {
      AdminPermission.deleteUsers: [AdminPermission.viewUsers, AdminPermission.editUsers],
      AdminPermission.editUsers: [AdminPermission.viewUsers],
      AdminPermission.deleteBusinesses: [AdminPermission.viewBusinesses, AdminPermission.editBusinesses],
      AdminPermission.editBusinesses: [AdminPermission.viewBusinesses],
      AdminPermission.approveBusinesses: [AdminPermission.viewBusinesses],
      AdminPermission.deleteOrders: [AdminPermission.viewOrders, AdminPermission.editOrders],
      AdminPermission.editOrders: [AdminPermission.viewOrders],
      AdminPermission.manageSystemSettings: [AdminPermission.viewAnalytics],
      AdminPermission.manageAdminUsers: [AdminPermission.viewUsers],
      AdminPermission.manageAdmins: [AdminPermission.manageAdminUsers],
      AdminPermission.manageSystem: [AdminPermission.manageSystemSettings],
    };
  }

  /// Auto-add dependent permissions
  List<AdminPermission> addDependentAdminPermissions(List<AdminPermission> permissions) {
    final hierarchy = getAdminPermissionHierarchy();
    final result = <AdminPermission>{...permissions};
    
    for (final permission in permissions) {
      final dependencies = hierarchy[permission];
      if (dependencies != null) {
        result.addAll(dependencies);
      }
    }
    
    return result.toList();
  }

  /// Get readable permission description
  String getPermissionDescription(dynamic permission) {
    if (permission is AdminPermission) {
      return permission.displayName;
    } else if (permission is BusinessPermission) {
      return permission.displayName;
    }
    return permission.toString();
  }

  /// Check if user can perform action on resource
  bool canPerformAction(String action, String resource, List<String> userPermissions) {
    final requiredPermission = '${action}_${resource}';
    return userPermissions.contains(requiredPermission);
  }
} 