import 'package:cloud_firestore/cloud_firestore.dart';

/// Basic business profile information
class BusinessProfile {
  final String id;
  final String ownerId;
  final String businessName;
  final String businessDescription;
  final String businessType;
  final String businessAddress;
  final String? logoUrl;
  final DateTime createdAt;
  final DateTime updatedAt;
  final List<String> staffIds;
  final List<String> categoryIds;
  final Map<String, dynamic>? metadata;

  const BusinessProfile({
    required this.id,
    required this.ownerId,
    required this.businessName,
    required this.businessDescription,
    required this.businessType,
    required this.businessAddress,
    this.logoUrl,
    required this.createdAt,
    required this.updatedAt,
    this.staffIds = const [],
    this.categoryIds = const [],
    this.metadata,
  });

  // Factory constructor
  factory BusinessProfile.create({
    required String id,
    required String ownerId,
    required String businessName,
    String businessDescription = '',
    required String businessType,
    String businessAddress = '',
    String? logoUrl,
    Map<String, dynamic>? metadata,
  }) {
    final now = DateTime.now();
    return BusinessProfile(
      id: id,
      ownerId: ownerId,
      businessName: businessName,
      businessDescription: businessDescription,
      businessType: businessType,
      businessAddress: businessAddress,
      logoUrl: logoUrl,
      createdAt: now,
      updatedAt: now,
      metadata: metadata,
    );
  }

  // JSON serialization
  factory BusinessProfile.fromJson(Map<String, dynamic> json) {
    return BusinessProfile(
      id: json['id'] ?? '',
      ownerId: json['ownerId'] ?? '',
      businessName: json['businessName'] ?? '',
      businessDescription: json['businessDescription'] ?? '',
      businessType: json['businessType'] ?? '',
      businessAddress: json['businessAddress'] ?? '',
      logoUrl: json['logoUrl'],
      createdAt: _parseDateTime(json['createdAt']),
      updatedAt: _parseDateTime(json['updatedAt']),
      staffIds: List<String>.from(json['staffIds'] ?? []),
      categoryIds: List<String>.from(json['categoryIds'] ?? []),
      metadata: json['metadata'] != null ? Map<String, dynamic>.from(json['metadata']) : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'ownerId': ownerId,
      'businessName': businessName,
      'businessDescription': businessDescription,
      'businessType': businessType,
      'businessAddress': businessAddress,
      'logoUrl': logoUrl,
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt.toIso8601String(),
      'staffIds': staffIds,
      'categoryIds': categoryIds,
      'metadata': metadata,
    };
  }

  Map<String, dynamic> toFirestore() {
    final data = toJson();
    data.remove('id');
    data['createdAt'] = Timestamp.fromDate(createdAt);
    data['updatedAt'] = Timestamp.fromDate(updatedAt);
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

  // Business logic methods
  bool get hasLogo => logoUrl != null && logoUrl!.isNotEmpty;
  bool get hasDescription => businessDescription.isNotEmpty;
  bool get hasStaff => staffIds.isNotEmpty;
  bool get hasCategories => categoryIds.isNotEmpty;
  bool get hasMetadata => metadata != null && metadata!.isNotEmpty;

  // Staff management
  BusinessProfile addStaff(String staffId) {
    if (staffIds.contains(staffId)) return this;
    return copyWith(staffIds: [...staffIds, staffId]);
  }

  BusinessProfile removeStaff(String staffId) {
    return copyWith(staffIds: staffIds.where((id) => id != staffId).toList());
  }

  BusinessProfile updateStaffList(List<String> newStaffIds) {
    return copyWith(staffIds: newStaffIds);
  }

  // Category management
  BusinessProfile addCategory(String categoryId) {
    if (categoryIds.contains(categoryId)) return this;
    return copyWith(categoryIds: [...categoryIds, categoryId]);
  }

  BusinessProfile removeCategory(String categoryId) {
    return copyWith(categoryIds: categoryIds.where((id) => id != categoryId).toList());
  }

  BusinessProfile updateCategoryList(List<String> newCategoryIds) {
    return copyWith(categoryIds: newCategoryIds);
  }

  // Metadata management
  BusinessProfile updateMetadata(Map<String, dynamic> newMetadata) {
    final combinedMetadata = <String, dynamic>{};
    if (metadata != null) combinedMetadata.addAll(metadata!);
    combinedMetadata.addAll(newMetadata);
    return copyWith(metadata: combinedMetadata);
  }

  BusinessProfile removeMetadataKey(String key) {
    if (metadata == null) return this;
    final newMetadata = Map<String, dynamic>.from(metadata!);
    newMetadata.remove(key);
    return copyWith(metadata: newMetadata.isEmpty ? null : newMetadata);
  }

  // Update methods
  BusinessProfile updateProfile({
    String? businessName,
    String? businessDescription,
    String? businessType,
    String? businessAddress,
    String? logoUrl,
  }) {
    return copyWith(
      businessName: businessName,
      businessDescription: businessDescription,
      businessType: businessType,
      businessAddress: businessAddress,
      logoUrl: logoUrl,
      updatedAt: DateTime.now(),
    );
  }

  // Copy with
  BusinessProfile copyWith({
    String? id,
    String? ownerId,
    String? businessName,
    String? businessDescription,
    String? businessType,
    String? businessAddress,
    String? logoUrl,
    DateTime? createdAt,
    DateTime? updatedAt,
    List<String>? staffIds,
    List<String>? categoryIds,
    Map<String, dynamic>? metadata,
  }) {
    return BusinessProfile(
      id: id ?? this.id,
      ownerId: ownerId ?? this.ownerId,
      businessName: businessName ?? this.businessName,
      businessDescription: businessDescription ?? this.businessDescription,
      businessType: businessType ?? this.businessType,
      businessAddress: businessAddress ?? this.businessAddress,
      logoUrl: logoUrl ?? this.logoUrl,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      staffIds: staffIds ?? this.staffIds,
      categoryIds: categoryIds ?? this.categoryIds,
      metadata: metadata ?? this.metadata,
    );
  }

  @override
  String toString() {
    return 'BusinessProfile(id: $id, businessName: $businessName, businessType: $businessType)';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is BusinessProfile && other.id == id;
  }

  @override
  int get hashCode => id.hashCode;
} 