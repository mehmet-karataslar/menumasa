import 'package:cloud_firestore/cloud_firestore.dart';

class BusinessSession {
  final String id;
  final String businessUserId;
  final DateTime createdAt;
  final DateTime expiresAt;
  final String? ipAddress;
  final String? userAgent;
  final bool isActive;

  BusinessSession({
    required this.id,
    required this.businessUserId,
    required this.createdAt,
    required this.expiresAt,
    this.ipAddress,
    this.userAgent,
    required this.isActive,
  });

  // Getters for compatibility with business service
  String get sessionId => id;
  String get businessId => businessUserId;
  String get sessionToken => id; // Using id as session token for simplicity
  bool get isValid => isActive && !isExpired;

  factory BusinessSession.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return BusinessSession(
      id: doc.id,
      businessUserId: data['businessUserId'] ?? '',
      createdAt: (data['createdAt'] as Timestamp).toDate(),
      expiresAt: (data['expiresAt'] as Timestamp).toDate(),
      ipAddress: data['ipAddress'],
      userAgent: data['userAgent'],
      isActive: data['isActive'] ?? true,
    );
  }

  factory BusinessSession.fromJson(Map<String, dynamic> json) {
    return BusinessSession(
      id: json['id'] ?? '',
      businessUserId: json['businessUserId'] ?? '',
      createdAt: DateTime.parse(json['createdAt']),
      expiresAt: DateTime.parse(json['expiresAt']),
      ipAddress: json['ipAddress'],
      userAgent: json['userAgent'],
      isActive: json['isActive'] ?? true,
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'businessUserId': businessUserId,
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
      'businessUserId': businessUserId,
      'createdAt': createdAt.toIso8601String(),
      'expiresAt': expiresAt.toIso8601String(),
      'ipAddress': ipAddress,
      'userAgent': userAgent,
      'isActive': isActive,
    };
  }

  bool get isExpired => DateTime.now().isAfter(expiresAt);

  Duration get timeUntilExpiry => expiresAt.difference(DateTime.now());

  BusinessSession copyWith({
    String? id,
    String? businessUserId,
    DateTime? createdAt,
    DateTime? expiresAt,
    String? ipAddress,
    String? userAgent,
    bool? isActive,
  }) {
    return BusinessSession(
      id: id ?? this.id,
      businessUserId: businessUserId ?? this.businessUserId,
      createdAt: createdAt ?? this.createdAt,
      expiresAt: expiresAt ?? this.expiresAt,
      ipAddress: ipAddress ?? this.ipAddress,
      userAgent: userAgent ?? this.userAgent,
      isActive: isActive ?? this.isActive,
    );
  }

  @override
  String toString() {
    return 'BusinessSession(id: $id, businessUserId: $businessUserId, expiresAt: $expiresAt)';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is BusinessSession && other.id == id;
  }

  @override
  int get hashCode => id.hashCode;
} 