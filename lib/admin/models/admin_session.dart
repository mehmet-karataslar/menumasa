import 'package:cloud_firestore/cloud_firestore.dart';


class AdminSession {
  final String id;
  final String adminUserId;
  final DateTime createdAt;
  final DateTime expiresAt;
  final String? ipAddress;
  final String? userAgent;
  final bool isActive;

  AdminSession({
    required this.id,
    required this.adminUserId,
    required this.createdAt,
    required this.expiresAt,
    this.ipAddress,
    this.userAgent,
    required this.isActive,
  });

  // Getters for compatibility with admin service
  String get sessionId => id;
  String get adminId => adminUserId;
  String get sessionToken => id; // Using id as session token for simplicity
  bool get isValid => isActive && !isExpired;

  factory AdminSession.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return AdminSession(
      id: doc.id,
      adminUserId: data['adminUserId'] ?? '',
      createdAt: (data['createdAt'] as Timestamp).toDate(),
      expiresAt: (data['expiresAt'] as Timestamp).toDate(),
      ipAddress: data['ipAddress'],
      userAgent: data['userAgent'],
      isActive: data['isActive'] ?? true,
    );
  }

  factory AdminSession.fromJson(Map<String, dynamic> json) {
    return AdminSession(
      id: json['id'] ?? '',
      adminUserId: json['adminUserId'] ?? '',
      createdAt: DateTime.parse(json['createdAt']),
      expiresAt: DateTime.parse(json['expiresAt']),
      ipAddress: json['ipAddress'],
      userAgent: json['userAgent'],
      isActive: json['isActive'] ?? true,
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'adminUserId': adminUserId,
      'createdAt': Timestamp.fromDate(createdAt),
      'expiresAt': Timestamp.fromDate(expiresAt),
      'ipAddress': ipAddress,
      'userAgent': userAgent,
      'isActive': isActive,
    };
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'adminUserId': adminUserId,
      'createdAt': createdAt.toIso8601String(),
      'expiresAt': expiresAt.toIso8601String(),
      'ipAddress': ipAddress,
      'userAgent': userAgent,
      'isActive': isActive,
    };
  }

  bool get isExpired => DateTime.now().isAfter(expiresAt);

  Duration get timeUntilExpiry => expiresAt.difference(DateTime.now());

  AdminSession copyWith({
    String? id,
    String? adminUserId,
    DateTime? createdAt,
    DateTime? expiresAt,
    String? ipAddress,
    String? userAgent,
    bool? isActive,
  }) {
    return AdminSession(
      id: id ?? this.id,
      adminUserId: adminUserId ?? this.adminUserId,
      createdAt: createdAt ?? this.createdAt,
      expiresAt: expiresAt ?? this.expiresAt,
      ipAddress: ipAddress ?? this.ipAddress,
      userAgent: userAgent ?? this.userAgent,
      isActive: isActive ?? this.isActive,
    );
  }

  @override
  String toString() {
    return 'AdminSession(id: $id, adminUserId: $adminUserId, expiresAt: $expiresAt)';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is AdminSession && other.id == id;
  }

  @override
  int get hashCode => id.hashCode;
} 