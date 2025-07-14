import 'package:cloud_firestore/cloud_firestore.dart';

// =============================================================================
// SESSION MODELS
// =============================================================================

class Session {
  final String id;
  final String userId;
  final UserType userType;
  final DateTime createdAt;
  final DateTime expiresAt;
  final String? ipAddress;
  final String? userAgent;
  final bool isActive;
  final String? deviceId;
  final String? deviceName;
  final String? deviceType;
  final Map<String, dynamic>? metadata;

  Session({
    required this.id,
    required this.userId,
    required this.userType,
    required this.createdAt,
    required this.expiresAt,
    this.ipAddress,
    this.userAgent,
    required this.isActive,
    this.deviceId,
    this.deviceName,
    this.deviceType,
    this.metadata,
  });

  // Factory methods for different user types
  factory Session.customer({
    required String id,
    required String userId,
    required DateTime createdAt,
    DateTime? expiresAt,
    String? ipAddress,
    String? userAgent,
    bool isActive = true,
    String? deviceId,
    String? deviceName,
    String? deviceType,
    Map<String, dynamic>? metadata,
  }) {
    return Session(
      id: id,
      userId: userId,
      userType: UserType.customer,
      createdAt: createdAt,
      expiresAt: expiresAt ?? createdAt.add(const Duration(days: 30)),
      ipAddress: ipAddress,
      userAgent: userAgent,
      isActive: isActive,
      deviceId: deviceId,
      deviceName: deviceName,
      deviceType: deviceType,
      metadata: metadata,
    );
  }

  factory Session.business({
    required String id,
    required String userId,
    required DateTime createdAt,
    DateTime? expiresAt,
    String? ipAddress,
    String? userAgent,
    bool isActive = true,
    String? deviceId,
    String? deviceName,
    String? deviceType,
    Map<String, dynamic>? metadata,
  }) {
    return Session(
      id: id,
      userId: userId,
      userType: UserType.business,
      createdAt: createdAt,
      expiresAt: expiresAt ?? createdAt.add(const Duration(hours: 24)),
      ipAddress: ipAddress,
      userAgent: userAgent,
      isActive: isActive,
      deviceId: deviceId,
      deviceName: deviceName,
      deviceType: deviceType,
      metadata: metadata,
    );
  }

  factory Session.admin({
    required String id,
    required String userId,
    required DateTime createdAt,
    DateTime? expiresAt,
    String? ipAddress,
    String? userAgent,
    bool isActive = true,
    String? deviceId,
    String? deviceName,
    String? deviceType,
    Map<String, dynamic>? metadata,
  }) {
    return Session(
      id: id,
      userId: userId,
      userType: UserType.admin,
      createdAt: createdAt,
      expiresAt: expiresAt ?? createdAt.add(const Duration(hours: 12)),
      ipAddress: ipAddress,
      userAgent: userAgent,
      isActive: isActive,
      deviceId: deviceId,
      deviceName: deviceName,
      deviceType: deviceType,
      metadata: metadata,
    );
  }

  // JSON serialization
  factory Session.fromJson(Map<String, dynamic> json, {String? id}) {
    return Session(
      id: id ?? json['id'] ?? '',
      userId: json['userId'] ?? '',
      userType: UserType.fromString(json['userType'] ?? 'customer'),
      createdAt: _parseDateTime(json['createdAt']),
      expiresAt: _parseDateTime(json['expiresAt']),
      ipAddress: json['ipAddress'],
      userAgent: json['userAgent'],
      isActive: json['isActive'] ?? true,
      deviceId: json['deviceId'],
      deviceName: json['deviceName'],
      deviceType: json['deviceType'],
      metadata: json['metadata'] != null ? Map<String, dynamic>.from(json['metadata']) : null,
    );
  }

  factory Session.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return Session.fromJson({...data, 'id': doc.id});
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'userId': userId,
      'userType': userType.value,
      'createdAt': createdAt.toIso8601String(),
      'expiresAt': expiresAt.toIso8601String(),
      'ipAddress': ipAddress,
      'userAgent': userAgent,
      'isActive': isActive,
      'deviceId': deviceId,
      'deviceName': deviceName,
      'deviceType': deviceType,
      'metadata': metadata,
    };
  }

  Map<String, dynamic> toFirestore() {
    final data = toJson();
    data.remove('id');
    data['createdAt'] = Timestamp.fromDate(createdAt);
    data['expiresAt'] = Timestamp.fromDate(expiresAt);
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
  String get sessionToken => id;
  bool get isValid => isActive && !isExpired;
  bool get isExpired => DateTime.now().isAfter(expiresAt);
  Duration get timeUntilExpiry => expiresAt.difference(DateTime.now());
  bool get isExpiringSoon => timeUntilExpiry.inHours <= 1;

  // Type checking
  bool get isCustomerSession => userType == UserType.customer;
  bool get isBusinessSession => userType == UserType.business;
  bool get isAdminSession => userType == UserType.admin;

  // Copy with
  Session copyWith({
    String? id,
    String? userId,
    UserType? userType,
    DateTime? createdAt,
    DateTime? expiresAt,
    String? ipAddress,
    String? userAgent,
    bool? isActive,
    String? deviceId,
    String? deviceName,
    String? deviceType,
    Map<String, dynamic>? metadata,
  }) {
    return Session(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      userType: userType ?? this.userType,
      createdAt: createdAt ?? this.createdAt,
      expiresAt: expiresAt ?? this.expiresAt,
      ipAddress: ipAddress ?? this.ipAddress,
      userAgent: userAgent ?? this.userAgent,
      isActive: isActive ?? this.isActive,
      deviceId: deviceId ?? this.deviceId,
      deviceName: deviceName ?? this.deviceName,
      deviceType: deviceType ?? this.deviceType,
      metadata: metadata ?? this.metadata,
    );
  }

  @override
  String toString() {
    return 'Session(id: $id, userId: $userId, userType: $userType, isActive: $isActive, expiresAt: $expiresAt)';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is Session && other.id == id;
  }

  @override
  int get hashCode => id.hashCode;
}

// =============================================================================
// ACTIVITY LOG MODELS
// =============================================================================

enum ActivityType {
  // Authentication
  login('login', 'Giriş Yapıldı'),
  logout('logout', 'Çıkış Yapıldı'),
  register('register', 'Kayıt Olundu'),
  passwordReset('password_reset', 'Şifre Sıfırlandı'),
  emailVerification('email_verification', 'E-posta Doğrulandı'),
  
  // Customer Activities
  placeOrder('place_order', 'Sipariş Verildi'),
  cancelOrder('cancel_order', 'Sipariş İptal Edildi'),
  addToFavorites('add_to_favorites', 'Favorilere Eklendi'),
  removeFromFavorites('remove_from_favorites', 'Favorilerden Çıkarıldı'),
  writeReview('write_review', 'Yorum Yazıldı'),
  updateProfile('update_profile', 'Profil Güncellendi'),
  
  // Business Activities
  createProduct('create_product', 'Ürün Oluşturuldu'),
  updateProduct('update_product', 'Ürün Güncellendi'),
  deleteProduct('delete_product', 'Ürün Silindi'),
  createCategory('create_category', 'Kategori Oluşturuldu'),
  updateCategory('update_category', 'Kategori Güncellendi'),
  deleteCategory('delete_category', 'Kategori Silindi'),
  updateMenu('update_menu', 'Menü Güncellendi'),
  updateSettings('update_settings', 'Ayarlar Güncellendi'),
  viewAnalytics('view_analytics', 'Analitikler Görüntülendi'),
  manageOrders('manage_orders', 'Siparişler Yönetildi'),
  
  // Admin Activities
  createUser('create_user', 'Kullanıcı Oluşturuldu'),
  updateUser('update_user', 'Kullanıcı Güncellendi'),
  deleteUser('delete_user', 'Kullanıcı Silindi'),
  createBusiness('create_business', 'İşletme Oluşturuldu'),
  updateBusiness('update_business', 'İşletme Güncellendi'),
  deleteBusiness('delete_business', 'İşletme Silindi'),
  approveBusiness('approve_business', 'İşletme Onaylandı'),
  rejectBusiness('reject_business', 'İşletme Reddedildi'),
  viewSystemAnalytics('view_system_analytics', 'Sistem Analitikleri Görüntülendi'),
  manageSystemSettings('manage_system_settings', 'Sistem Ayarları Yönetildi'),
  moderateContent('moderate_content', 'İçerik Modere Edildi'),
  
  // System Activities
  systemError('system_error', 'Sistem Hatası'),
  securityAlert('security_alert', 'Güvenlik Uyarısı'),
  backupCreated('backup_created', 'Yedek Oluşturuldu'),
  maintenanceMode('maintenance_mode', 'Bakım Modu'),
  
  // Payment Activities
  paymentSuccess('payment_success', 'Ödeme Başarılı'),
  paymentFailed('payment_failed', 'Ödeme Başarısız'),
  refundIssued('refund_issued', 'İade Yapıldı'),
  
  // Communication Activities
  sendNotification('send_notification', 'Bildirim Gönderildi'),
  sendEmail('send_email', 'E-posta Gönderildi'),
  sendSms('send_sms', 'SMS Gönderildi');

  const ActivityType(this.value, this.displayName);
  final String value;
  final String displayName;

  static ActivityType fromString(String value) {
    return ActivityType.values.firstWhere(
      (type) => type.value == value,
      orElse: () => ActivityType.login,
    );
  }
}

enum ActivitySeverity {
  info('info', 'Bilgi', 0),
  warning('warning', 'Uyarı', 1),
  error('error', 'Hata', 2),
  critical('critical', 'Kritik', 3);

  const ActivitySeverity(this.value, this.displayName, this.level);
  final String value;
  final String displayName;
  final int level;

  static ActivitySeverity fromString(String value) {
    return ActivitySeverity.values.firstWhere(
      (severity) => severity.value == value,
      orElse: () => ActivitySeverity.info,
    );
  }
}

class ActivityLog {
  final String id;
  final String userId;
  final UserType userType;
  final ActivityType activityType;
  final ActivitySeverity severity;
  final String description;
  final Map<String, dynamic>? details;
  final DateTime timestamp;
  final String? ipAddress;
  final String? userAgent;
  final String? sessionId;
  final String? deviceId;
  final String? location;
  final Map<String, dynamic>? metadata;

  ActivityLog({
    required this.id,
    required this.userId,
    required this.userType,
    required this.activityType,
    this.severity = ActivitySeverity.info,
    required this.description,
    this.details,
    required this.timestamp,
    this.ipAddress,
    this.userAgent,
    this.sessionId,
    this.deviceId,
    this.location,
    this.metadata,
  });

  // Factory methods for different user types
  factory ActivityLog.customer({
    required String id,
    required String userId,
    required ActivityType activityType,
    ActivitySeverity severity = ActivitySeverity.info,
    required String description,
    Map<String, dynamic>? details,
    DateTime? timestamp,
    String? ipAddress,
    String? userAgent,
    String? sessionId,
    String? deviceId,
    String? location,
    Map<String, dynamic>? metadata,
  }) {
    return ActivityLog(
      id: id,
      userId: userId,
      userType: UserType.customer,
      activityType: activityType,
      severity: severity,
      description: description,
      details: details,
      timestamp: timestamp ?? DateTime.now(),
      ipAddress: ipAddress,
      userAgent: userAgent,
      sessionId: sessionId,
      deviceId: deviceId,
      location: location,
      metadata: metadata,
    );
  }

  factory ActivityLog.business({
    required String id,
    required String userId,
    required ActivityType activityType,
    ActivitySeverity severity = ActivitySeverity.info,
    required String description,
    Map<String, dynamic>? details,
    DateTime? timestamp,
    String? ipAddress,
    String? userAgent,
    String? sessionId,
    String? deviceId,
    String? location,
    Map<String, dynamic>? metadata,
  }) {
    return ActivityLog(
      id: id,
      userId: userId,
      userType: UserType.business,
      activityType: activityType,
      severity: severity,
      description: description,
      details: details,
      timestamp: timestamp ?? DateTime.now(),
      ipAddress: ipAddress,
      userAgent: userAgent,
      sessionId: sessionId,
      deviceId: deviceId,
      location: location,
      metadata: metadata,
    );
  }

  factory ActivityLog.admin({
    required String id,
    required String userId,
    required ActivityType activityType,
    ActivitySeverity severity = ActivitySeverity.info,
    required String description,
    Map<String, dynamic>? details,
    DateTime? timestamp,
    String? ipAddress,
    String? userAgent,
    String? sessionId,
    String? deviceId,
    String? location,
    Map<String, dynamic>? metadata,
  }) {
    return ActivityLog(
      id: id,
      userId: userId,
      userType: UserType.admin,
      activityType: activityType,
      severity: severity,
      description: description,
      details: details,
      timestamp: timestamp ?? DateTime.now(),
      ipAddress: ipAddress,
      userAgent: userAgent,
      sessionId: sessionId,
      deviceId: deviceId,
      location: location,
      metadata: metadata,
    );
  }

  // JSON serialization
  factory ActivityLog.fromJson(Map<String, dynamic> json, {String? id}) {
    return ActivityLog(
      id: id ?? json['id'] ?? '',
      userId: json['userId'] ?? '',
      userType: UserType.fromString(json['userType'] ?? 'customer'),
      activityType: ActivityType.fromString(json['activityType'] ?? 'login'),
      severity: ActivitySeverity.fromString(json['severity'] ?? 'info'),
      description: json['description'] ?? '',
      details: json['details'] != null ? Map<String, dynamic>.from(json['details']) : null,
      timestamp: _parseDateTime(json['timestamp']),
      ipAddress: json['ipAddress'],
      userAgent: json['userAgent'],
      sessionId: json['sessionId'],
      deviceId: json['deviceId'],
      location: json['location'],
      metadata: json['metadata'] != null ? Map<String, dynamic>.from(json['metadata']) : null,
    );
  }

  factory ActivityLog.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return ActivityLog.fromJson({...data, 'id': doc.id});
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'userId': userId,
      'userType': userType.value,
      'activityType': activityType.value,
      'severity': severity.value,
      'description': description,
      'details': details,
      'timestamp': timestamp.toIso8601String(),
      'ipAddress': ipAddress,
      'userAgent': userAgent,
      'sessionId': sessionId,
      'deviceId': deviceId,
      'location': location,
      'metadata': metadata,
    };
  }

  Map<String, dynamic> toFirestore() {
    final data = toJson();
    data.remove('id');
    data['timestamp'] = Timestamp.fromDate(timestamp);
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
  bool get isError => severity == ActivitySeverity.error || severity == ActivitySeverity.critical;
  bool get isWarning => severity == ActivitySeverity.warning;
  bool get isInfo => severity == ActivitySeverity.info;
  String get timeAgo {
    final difference = DateTime.now().difference(timestamp);
    if (difference.inDays > 0) {
      return '${difference.inDays} gün önce';
    } else if (difference.inHours > 0) {
      return '${difference.inHours} saat önce';
    } else if (difference.inMinutes > 0) {
      return '${difference.inMinutes} dakika önce';
    } else {
      return 'Şimdi';
    }
  }

  // Type checking
  bool get isCustomerActivity => userType == UserType.customer;
  bool get isBusinessActivity => userType == UserType.business;
  bool get isAdminActivity => userType == UserType.admin;

  // Copy with
  ActivityLog copyWith({
    String? id,
    String? userId,
    UserType? userType,
    ActivityType? activityType,
    ActivitySeverity? severity,
    String? description,
    Map<String, dynamic>? details,
    DateTime? timestamp,
    String? ipAddress,
    String? userAgent,
    String? sessionId,
    String? deviceId,
    String? location,
    Map<String, dynamic>? metadata,
  }) {
    return ActivityLog(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      userType: userType ?? this.userType,
      activityType: activityType ?? this.activityType,
      severity: severity ?? this.severity,
      description: description ?? this.description,
      details: details ?? this.details,
      timestamp: timestamp ?? this.timestamp,
      ipAddress: ipAddress ?? this.ipAddress,
      userAgent: userAgent ?? this.userAgent,
      sessionId: sessionId ?? this.sessionId,
      deviceId: deviceId ?? this.deviceId,
      location: location ?? this.location,
      metadata: metadata ?? this.metadata,
    );
  }

  @override
  String toString() {
    return 'ActivityLog(id: $id, userId: $userId, activityType: $activityType, severity: $severity, timestamp: $timestamp)';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is ActivityLog && other.id == id;
  }

  @override
  int get hashCode => id.hashCode;
}

// =============================================================================
// USER TYPE ENUM (imported from user.dart)
// =============================================================================

enum UserType {
  customer('customer', 'Müşteri'),
  business('business', 'İşletme'),
  admin('admin', 'Yönetici');

  const UserType(this.value, this.displayName);
  final String value;
  final String displayName;

  static UserType fromString(String value) {
    return UserType.values.firstWhere(
      (type) => type.value == value,
      orElse: () => UserType.customer,
    );
  }
} 