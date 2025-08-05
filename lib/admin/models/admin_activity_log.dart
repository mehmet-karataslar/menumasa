import 'package:cloud_firestore/cloud_firestore.dart';


enum AdminActivityType {
  login,
  logout,
  createUser,
  updateUser,
  deleteUser,
  createBusiness,
  updateBusiness,
  deleteBusiness,
  viewAnalytics,
  systemSettings,
  contentModeration,
  adminManagement,
}

class AdminActivityLog {
  final String id;
  final String adminUserId;
  final String adminUserName;
  final AdminActivityType activityType;
  final String description;
  final Map<String, dynamic>? details;
  final DateTime timestamp;
  final String? ipAddress;
  final String? userAgent;

  AdminActivityLog({
    required this.id,
    required this.adminUserId,
    required this.adminUserName,
    required this.activityType,
    required this.description,
    this.details,
    required this.timestamp,
    this.ipAddress,
    this.userAgent,
  });

  factory AdminActivityLog.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return AdminActivityLog(
      id: doc.id,
      adminUserId: data['adminUserId'] ?? '',
      adminUserName: data['adminUserName'] ?? '',
      activityType: AdminActivityType.values.firstWhere(
        (type) => type.toString().split('.').last == data['activityType'],
        orElse: () => AdminActivityType.login,
      ),
      description: data['description'] ?? '',
      details: data['details'] as Map<String, dynamic>?,
      timestamp: (data['timestamp'] as Timestamp).toDate(),
      ipAddress: data['ipAddress'],
      userAgent: data['userAgent'],
    );
  }

  factory AdminActivityLog.fromJson(Map<String, dynamic> json) {
    return AdminActivityLog(
      id: json['id'] ?? '',
      adminUserId: json['adminUserId'] ?? '',
      adminUserName: json['adminUserName'] ?? '',
      activityType: AdminActivityType.values.firstWhere(
        (type) => type.toString().split('.').last == json['activityType'],
        orElse: () => AdminActivityType.login,
      ),
      description: json['description'] ?? '',
      details: json['details'] as Map<String, dynamic>?,
      timestamp: DateTime.parse(json['timestamp']),
      ipAddress: json['ipAddress'],
      userAgent: json['userAgent'],
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'adminUserId': adminUserId,
      'adminUserName': adminUserName,
      'activityType': activityType.toString().split('.').last,
      'description': description,
      'details': details,
      'timestamp': Timestamp.fromDate(timestamp),
      'ipAddress': ipAddress,
      'userAgent': userAgent,
    };
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'adminUserId': adminUserId,
      'adminUserName': adminUserName,
      'activityType': activityType.toString().split('.').last,
      'description': description,
      'details': details,
      'timestamp': timestamp.toIso8601String(),
      'ipAddress': ipAddress,
      'userAgent': userAgent,
    };
  }

  AdminActivityLog copyWith({
    String? id,
    String? adminUserId,
    String? adminUserName,
    AdminActivityType? activityType,
    String? description,
    Map<String, dynamic>? details,
    DateTime? timestamp,
    String? ipAddress,
    String? userAgent,
  }) {
    return AdminActivityLog(
      id: id ?? this.id,
      adminUserId: adminUserId ?? this.adminUserId,
      adminUserName: adminUserName ?? this.adminUserName,
      activityType: activityType ?? this.activityType,
      description: description ?? this.description,
      details: details ?? this.details,
      timestamp: timestamp ?? this.timestamp,
      ipAddress: ipAddress ?? this.ipAddress,
      userAgent: userAgent ?? this.userAgent,
    );
  }

  String get activityTypeDisplayName {
    switch (activityType) {
      case AdminActivityType.login:
        return 'Login';
      case AdminActivityType.logout:
        return 'Logout';
      case AdminActivityType.createUser:
        return 'Create User';
      case AdminActivityType.updateUser:
        return 'Update User';
      case AdminActivityType.deleteUser:
        return 'Delete User';
      case AdminActivityType.createBusiness:
        return 'Create Business';
      case AdminActivityType.updateBusiness:
        return 'Update Business';
      case AdminActivityType.deleteBusiness:
        return 'Delete Business';
      case AdminActivityType.viewAnalytics:
        return 'View Analytics';
      case AdminActivityType.systemSettings:
        return 'System Settings';
      case AdminActivityType.contentModeration:
        return 'Content Moderation';
      case AdminActivityType.adminManagement:
        return 'Admin Management';
    }
  }

  @override
  String toString() {
    return 'AdminActivityLog(id: $id, adminUserId: $adminUserId, activityType: $activityType, timestamp: $timestamp)';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is AdminActivityLog && other.id == id;
  }

  @override
  int get hashCode => id.hashCode;
} 