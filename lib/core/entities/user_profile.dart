import 'package:cloud_firestore/cloud_firestore.dart';
import '../enums/user_type.dart';

/// Basic user profile information
class UserProfile {
  final String id;
  final String email;
  final String name;
  final String? phone;
  final UserType userType;
  final String? avatarUrl;
  final DateTime createdAt;
  final DateTime updatedAt;

  const UserProfile({
    required this.id,
    required this.email,
    required this.name,
    this.phone,
    required this.userType,
    this.avatarUrl,
    required this.createdAt,
    required this.updatedAt,
  });

  // Factory constructor
  factory UserProfile.create({
    required String id,
    required String email,
    required String name,
    String? phone,
    required UserType userType,
    String? avatarUrl,
  }) {
    final now = DateTime.now();
    return UserProfile(
      id: id,
      email: email,
      name: name,
      phone: phone,
      userType: userType,
      avatarUrl: avatarUrl,
      createdAt: now,
      updatedAt: now,
    );
  }

  // JSON serialization
  factory UserProfile.fromJson(Map<String, dynamic> json) {
    return UserProfile(
      id: json['id'] ?? '',
      email: json['email'] ?? '',
      name: json['name'] ?? '',
      phone: json['phone'],
      userType: UserType.fromString(json['userType'] ?? 'customer'),
      avatarUrl: json['avatarUrl'],
      createdAt: _parseDateTime(json['createdAt']),
      updatedAt: _parseDateTime(json['updatedAt']),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'email': email,
      'name': name,
      'phone': phone,
      'userType': userType.value,
      'avatarUrl': avatarUrl,
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt.toIso8601String(),
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

  // Copy with
  UserProfile copyWith({
    String? id,
    String? email,
    String? name,
    String? phone,
    UserType? userType,
    String? avatarUrl,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return UserProfile(
      id: id ?? this.id,
      email: email ?? this.email,
      name: name ?? this.name,
      phone: phone ?? this.phone,
      userType: userType ?? this.userType,
      avatarUrl: avatarUrl ?? this.avatarUrl,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  @override
  String toString() {
    return 'UserProfile(id: $id, email: $email, name: $name, userType: ${userType.value})';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is UserProfile && other.id == id;
  }

  @override
  int get hashCode => id.hashCode;
} 