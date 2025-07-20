import 'package:cloud_firestore/cloud_firestore.dart';

/// User authentication and session information
class UserAuth {
  final bool isActive;
  final bool isEmailVerified;
  final DateTime? lastLoginAt;
  final String? lastLoginIp;
  final String? sessionToken;
  final int loginAttempts;
  final DateTime? lastLoginAttempt;
  final bool isLocked;
  final DateTime? lockedUntil;

  const UserAuth({
    this.isActive = true,
    this.isEmailVerified = false,
    this.lastLoginAt,
    this.lastLoginIp,
    this.sessionToken,
    this.loginAttempts = 0,
    this.lastLoginAttempt,
    this.isLocked = false,
    this.lockedUntil,
  });

  // Factory constructors
  factory UserAuth.initial() {
    return const UserAuth(
      isActive: true,
      isEmailVerified: false,
      loginAttempts: 0,
      isLocked: false,
    );
  }

  factory UserAuth.fromJson(Map<String, dynamic> json) {
    return UserAuth(
      isActive: json['isActive'] ?? true,
      isEmailVerified: json['isEmailVerified'] ?? false,
      lastLoginAt: json['lastLoginAt'] != null ? _parseDateTime(json['lastLoginAt']) : null,
      lastLoginIp: json['lastLoginIp'],
      sessionToken: json['sessionToken'],
      loginAttempts: json['loginAttempts'] ?? 0,
      lastLoginAttempt: json['lastLoginAttempt'] != null ? _parseDateTime(json['lastLoginAttempt']) : null,
      isLocked: json['isLocked'] ?? false,
      lockedUntil: json['lockedUntil'] != null ? _parseDateTime(json['lockedUntil']) : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'isActive': isActive,
      'isEmailVerified': isEmailVerified,
      'lastLoginAt': lastLoginAt?.toIso8601String(),
      'lastLoginIp': lastLoginIp,
      'sessionToken': sessionToken,
      'loginAttempts': loginAttempts,
      'lastLoginAttempt': lastLoginAttempt?.toIso8601String(),
      'isLocked': isLocked,
      'lockedUntil': lockedUntil?.toIso8601String(),
    };
  }

  Map<String, dynamic> toFirestore() {
    final data = toJson();
    if (lastLoginAt != null) {
      data['lastLoginAt'] = Timestamp.fromDate(lastLoginAt!);
    }
    if (lastLoginAttempt != null) {
      data['lastLoginAttempt'] = Timestamp.fromDate(lastLoginAttempt!);
    }
    if (lockedUntil != null) {
      data['lockedUntil'] = Timestamp.fromDate(lockedUntil!);
    }
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
  bool get isAuthenticated => sessionToken != null && isActive && !isLocked;
  
  bool get canLogin {
    if (!isActive || isLocked) return false;
    if (lockedUntil != null && DateTime.now().isBefore(lockedUntil!)) return false;
    return true;
  }

  // Security methods
  UserAuth incrementLoginAttempts() {
    final attempts = loginAttempts + 1;
    final shouldLock = attempts >= 5; // Lock after 5 failed attempts
    
    return copyWith(
      loginAttempts: attempts,
      lastLoginAttempt: DateTime.now(),
      isLocked: shouldLock,
      lockedUntil: shouldLock ? DateTime.now().add(const Duration(minutes: 30)) : null,
    );
  }

  UserAuth resetLoginAttempts() {
    return copyWith(
      loginAttempts: 0,
      isLocked: false,
      lockedUntil: null,
    );
  }

  UserAuth updateSession({
    required String sessionToken,
    String? ipAddress,
  }) {
    return copyWith(
      sessionToken: sessionToken,
      lastLoginAt: DateTime.now(),
      lastLoginIp: ipAddress,
      loginAttempts: 0,
      isLocked: false,
      lockedUntil: null,
    );
  }

  UserAuth clearSession() {
    return copyWith(
      sessionToken: null,
    );
  }

  UserAuth verifyEmail() {
    return copyWith(isEmailVerified: true);
  }

  UserAuth activate() {
    return copyWith(isActive: true);
  }

  UserAuth deactivate() {
    return copyWith(
      isActive: false,
      sessionToken: null,
    );
  }

  // Copy with
  UserAuth copyWith({
    bool? isActive,
    bool? isEmailVerified,
    DateTime? lastLoginAt,
    String? lastLoginIp,
    String? sessionToken,
    int? loginAttempts,
    DateTime? lastLoginAttempt,
    bool? isLocked,
    DateTime? lockedUntil,
  }) {
    return UserAuth(
      isActive: isActive ?? this.isActive,
      isEmailVerified: isEmailVerified ?? this.isEmailVerified,
      lastLoginAt: lastLoginAt ?? this.lastLoginAt,
      lastLoginIp: lastLoginIp ?? this.lastLoginIp,
      sessionToken: sessionToken ?? this.sessionToken,
      loginAttempts: loginAttempts ?? this.loginAttempts,
      lastLoginAttempt: lastLoginAttempt ?? this.lastLoginAttempt,
      isLocked: isLocked ?? this.isLocked,
      lockedUntil: lockedUntil ?? this.lockedUntil,
    );
  }

  @override
  String toString() {
    return 'UserAuth(isActive: $isActive, isEmailVerified: $isEmailVerified, isAuthenticated: $isAuthenticated)';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is UserAuth &&
        other.isActive == isActive &&
        other.isEmailVerified == isEmailVerified &&
        other.sessionToken == sessionToken;
  }

  @override
  int get hashCode => Object.hash(isActive, isEmailVerified, sessionToken);
} 