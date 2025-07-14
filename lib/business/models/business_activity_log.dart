import 'package:cloud_firestore/cloud_firestore.dart';

enum BusinessActivityType {
  login,
  logout,
  createProduct,
  updateProduct,
  deleteProduct,
  createCategory,
  updateCategory,
  deleteCategory,
  viewAnalytics,
  manageSettings,
  contentModeration,
  businessManagement,
}

class BusinessActivityLog {
  final String id;
  final String businessUserId;
  final String businessUserName;
  final BusinessActivityType activityType;
  final String description;
  final Map<String, dynamic>? details;
  final DateTime timestamp;
  final String? ipAddress;
  final String? userAgent;

  BusinessActivityLog({
    required this.id,
    required this.businessUserId,
    required this.businessUserName,
    required this.activityType,
    required this.description,
    this.details,
    required this.timestamp,
    this.ipAddress,
    this.userAgent,
  });

  factory BusinessActivityLog.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return BusinessActivityLog(
      id: doc.id,
      businessUserId: data['businessUserId'] ?? '',
      businessUserName: data['businessUserName'] ?? '',
      activityType: BusinessActivityType.values.firstWhere(
        (type) => type.toString().split('.').last == data['activityType'],
        orElse: () => BusinessActivityType.login,
      ),
      description: data['description'] ?? '',
      details: data['details'] as Map<String, dynamic>?,
      timestamp: (data['timestamp'] as Timestamp).toDate(),
      ipAddress: data['ipAddress'],
      userAgent: data['userAgent'],
    );
  }

  factory BusinessActivityLog.fromJson(Map<String, dynamic> json) {
    return BusinessActivityLog(
      id: json['id'] ?? '',
      businessUserId: json['businessUserId'] ?? '',
      businessUserName: json['businessUserName'] ?? '',
      activityType: BusinessActivityType.values.firstWhere(
        (type) => type.toString().split('.').last == json['activityType'],
        orElse: () => BusinessActivityType.login,
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
      'businessUserId': businessUserId,
      'businessUserName': businessUserName,
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
      'businessUserId': businessUserId,
      'businessUserName': businessUserName,
      'activityType': activityType.toString().split('.').last,
      'description': description,
      'details': details,
      'timestamp': timestamp.toIso8601String(),
      'ipAddress': ipAddress,
      'userAgent': userAgent,
    };
  }

  BusinessActivityLog copyWith({
    String? id,
    String? businessUserId,
    String? businessUserName,
    BusinessActivityType? activityType,
    String? description,
    Map<String, dynamic>? details,
    DateTime? timestamp,
    String? ipAddress,
    String? userAgent,
  }) {
    return BusinessActivityLog(
      id: id ?? this.id,
      businessUserId: businessUserId ?? this.businessUserId,
      businessUserName: businessUserName ?? this.businessUserName,
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
      case BusinessActivityType.login:
        return 'Login';
      case BusinessActivityType.logout:
        return 'Logout';
      case BusinessActivityType.createProduct:
        return 'Create Product';
      case BusinessActivityType.updateProduct:
        return 'Update Product';
      case BusinessActivityType.deleteProduct:
        return 'Delete Product';
      case BusinessActivityType.createCategory:
        return 'Create Category';
      case BusinessActivityType.updateCategory:
        return 'Update Category';
      case BusinessActivityType.deleteCategory:
        return 'Delete Category';
      case BusinessActivityType.viewAnalytics:
        return 'View Analytics';
      case BusinessActivityType.manageSettings:
        return 'Manage Settings';
      case BusinessActivityType.contentModeration:
        return 'Content Moderation';
      case BusinessActivityType.businessManagement:
        return 'Business Management';
    }
  }

  @override
  String toString() {
    return 'BusinessActivityLog(id: $id, businessUserId: $businessUserId, activityType: $activityType, timestamp: $timestamp)';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is BusinessActivityLog && other.id == id;
  }

  @override
  int get hashCode => id.hashCode;
} 