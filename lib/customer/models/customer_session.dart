import 'package:cloud_firestore/cloud_firestore.dart';

class CustomerSession {
  final String sessionId;
  final String customerId;
  final String businessId;
  final String? qrCodeId;
  final String? tableNumber;
  final Map<String, dynamic> sessionData;
  final bool isActive;
  final DateTime createdAt;
  final DateTime updatedAt;
  final DateTime? expiresAt;
  final String? deviceInfo;
  final String? ipAddress;

  CustomerSession({
    required this.sessionId,
    required this.customerId,
    required this.businessId,
    this.qrCodeId,
    this.tableNumber,
    required this.sessionData,
    required this.isActive,
    required this.createdAt,
    required this.updatedAt,
    this.expiresAt,
    this.deviceInfo,
    this.ipAddress,
  });

  // Factory constructor from Firestore document
  factory CustomerSession.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    
    return CustomerSession(
      sessionId: doc.id,
      customerId: data['customerId'] ?? '',
      businessId: data['businessId'] ?? '',
      qrCodeId: data['qrCodeId'],
      tableNumber: data['tableNumber'],
      sessionData: Map<String, dynamic>.from(data['sessionData'] ?? {}),
      isActive: data['isActive'] ?? true,
      createdAt: (data['createdAt'] as Timestamp).toDate(),
      updatedAt: (data['updatedAt'] as Timestamp).toDate(),
      expiresAt: data['expiresAt'] != null 
          ? (data['expiresAt'] as Timestamp).toDate()
          : null,
      deviceInfo: data['deviceInfo'],
      ipAddress: data['ipAddress'],
    );
  }

  // Convert to Firestore document
  Map<String, dynamic> toFirestore() {
    return {
      'customerId': customerId,
      'businessId': businessId,
      'qrCodeId': qrCodeId,
      'tableNumber': tableNumber,
      'sessionData': sessionData,
      'isActive': isActive,
      'createdAt': Timestamp.fromDate(createdAt),
      'updatedAt': Timestamp.fromDate(updatedAt),
      'expiresAt': expiresAt != null 
          ? Timestamp.fromDate(expiresAt!)
          : null,
      'deviceInfo': deviceInfo,
      'ipAddress': ipAddress,
    };
  }

  // Create new customer session
  factory CustomerSession.create({
    required String customerId,
    required String businessId,
    String? qrCodeId,
    String? tableNumber,
    Map<String, dynamic>? initialData,
    Duration? sessionDuration,
    String? deviceInfo,
    String? ipAddress,
  }) {
    final now = DateTime.now();
    final duration = sessionDuration ?? const Duration(hours: 24);
    
    return CustomerSession(
      sessionId: '',
      customerId: customerId,
      businessId: businessId,
      qrCodeId: qrCodeId,
      tableNumber: tableNumber,
      sessionData: initialData ?? {},
      isActive: true,
      createdAt: now,
      updatedAt: now,
      expiresAt: now.add(duration),
      deviceInfo: deviceInfo,
      ipAddress: ipAddress,
    );
  }

  // Copy with method for updates
  CustomerSession copyWith({
    String? qrCodeId,
    String? tableNumber,
    Map<String, dynamic>? sessionData,
    bool? isActive,
    DateTime? updatedAt,
    DateTime? expiresAt,
    String? deviceInfo,
    String? ipAddress,
  }) {
    return CustomerSession(
      sessionId: sessionId,
      customerId: customerId,
      businessId: businessId,
      qrCodeId: qrCodeId ?? this.qrCodeId,
      tableNumber: tableNumber ?? this.tableNumber,
      sessionData: sessionData ?? this.sessionData,
      isActive: isActive ?? this.isActive,
      createdAt: createdAt,
      updatedAt: updatedAt ?? DateTime.now(),
      expiresAt: expiresAt ?? this.expiresAt,
      deviceInfo: deviceInfo ?? this.deviceInfo,
      ipAddress: ipAddress ?? this.ipAddress,
    );
  }

  // Helper methods
  bool get isExpired {
    if (expiresAt == null) return false;
    return DateTime.now().isAfter(expiresAt!);
  }

  bool get isValid {
    return isActive && !isExpired;
  }

  Duration get timeRemaining {
    if (expiresAt == null) return const Duration(hours: 24);
    final now = DateTime.now();
    if (now.isAfter(expiresAt!)) return Duration.zero;
    return expiresAt!.difference(now);
  }

  String get formattedTimeRemaining {
    final remaining = timeRemaining;
    
    if (remaining == Duration.zero) {
      return 'Süresi dolmuş';
    }
    
    if (remaining.inHours > 0) {
      return '${remaining.inHours} saat ${remaining.inMinutes % 60} dakika';
    } else if (remaining.inMinutes > 0) {
      return '${remaining.inMinutes} dakika';
    } else {
      return '${remaining.inSeconds} saniye';
    }
  }

  // Session data helpers
  T? getSessionData<T>(String key) {
    return sessionData[key] as T?;
  }

  CustomerSession updateSessionData(String key, dynamic value) {
    final updatedData = Map<String, dynamic>.from(sessionData);
    updatedData[key] = value;
    
    return copyWith(
      sessionData: updatedData,
      updatedAt: DateTime.now(),
    );
  }

  CustomerSession removeSessionData(String key) {
    final updatedData = Map<String, dynamic>.from(sessionData);
    updatedData.remove(key);
    
    return copyWith(
      sessionData: updatedData,
      updatedAt: DateTime.now(),
    );
  }

  // Extend session
  CustomerSession extendSession({Duration? additionalTime}) {
    final extension = additionalTime ?? const Duration(hours: 2);
    final newExpiresAt = (expiresAt ?? DateTime.now()).add(extension);
    
    return copyWith(
      expiresAt: newExpiresAt,
      updatedAt: DateTime.now(),
    );
  }

  // End session
  CustomerSession endSession() {
    return copyWith(
      isActive: false,
      updatedAt: DateTime.now(),
    );
  }

  @override
  String toString() {
    return 'CustomerSession(sessionId: $sessionId, customerId: $customerId, businessId: $businessId, isActive: $isActive)';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    
    return other is CustomerSession &&
        other.sessionId == sessionId &&
        other.customerId == customerId &&
        other.businessId == businessId &&
        other.isActive == isActive;
  }

  @override
  int get hashCode {
    return sessionId.hashCode ^
        customerId.hashCode ^
        businessId.hashCode ^
        isActive.hashCode;
  }
} 